#!/usr/bin/env python3
"""Static domain-kernel purity checker.

Flags the most common kernel-purity violations in a Rust crate WITHOUT needing a
Rust toolchain: default features that pull I/O/format crates, banned crate types
in public signatures, paths in public signatures, and direct I/O or
non-determinism in non-test code. Heuristic by design — a grep, not a compiler —
so review findings rather than trusting them blindly.

Usage:
    python3 check_purity.py <path-to-crate-root>

Severity contract:
    HARD  a documented invariant violation. Exit code 1. Gate CI on this.
    WARN  needs a human read; does not change the exit code.

`BANNED_CRATES` below is the single source of truth for the crate list. The three
other gates this skill ships (`assets/clippy.toml`, `assets/deny-bans.toml`,
`assets/kernel-purity.yml`) carry their own copies — keep them in sync, and
extend all four for crates specific to your stack.

Tests: `python3 scripts/test_check_purity.py`.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# Crates that must not reach the pure kernel. The `serde` *trait* crate is
# deliberately absent — deriving is fine; a concrete format is not.
BANNED_CRATES = [
    # concrete serialization formats
    "serde_json", "serde_yaml", "serde_yaml_bw", "serde_cbor", "ciborium",
    "bincode", "postcard", "rmp", "rmp_serde", "toml", "ron", "csv",
    "quick_xml", "serde_xml_rs", "plist",
    # async runtimes
    "tokio", "async_std", "smol",
    # transport / server / client
    "reqwest", "hyper", "ureq", "tonic", "axum", "actix_web", "warp", "rocket",
    # storage
    "rusqlite", "sqlx", "diesel", "sled", "redb",
    # non-determinism (a kernel takes an injected seed, it does not source one)
    "rand", "getrandom", "fastrand", "oorandom",
    # delivery concerns
    "clap", "structopt",
]

HARD, WARN = "HARD", "WARN"


def _aliases(name: str) -> set[str]:
    """Cargo lets `-` and `_` alias each other; compare on both spellings."""
    return {name, name.replace("-", "_"), name.replace("_", "-")}


BANNED_LOOKUP = {a for c in BANNED_CRATES for a in _aliases(c)}


def is_banned(name: str) -> bool:
    return bool(_aliases(name) & BANNED_LOOKUP)


def parse_cargo(cargo: Path):
    """Return (deps, features) where deps maps name->is_optional, features is the
    [features] table as name->list. Uses tomllib if available, else a minimal
    fallback parser good enough for the two tables we need."""
    text = cargo.read_text(encoding="utf-8", errors="replace")
    try:
        import tomllib
        data = tomllib.loads(text)
        deps = {}
        for name, spec in (data.get("dependencies") or {}).items():
            deps[name] = bool(spec.get("optional")) if isinstance(spec, dict) else False
        feats = {k: list(v) for k, v in (data.get("features") or {}).items()}
        return deps, feats
    except Exception:
        return _fallback_parse(text)


def _fallback_parse(text: str):
    deps, feats, section = {}, {}, None
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("[") and s.endswith("]"):
            section = s.strip("[]")
            continue
        if not s or s.startswith("#") or "=" not in s:
            continue
        key, _, val = s.partition("=")
        key, val = key.strip().strip('"'), val.strip()
        if section == "dependencies":
            deps[key] = "optional = true" in val or "optional=true" in val
        elif section == "features":
            items = re.findall(r'"([^"]+)"', val)
            feats[key] = items
    return deps, feats


def cargo_findings(cargo: Path):
    out = []
    deps, feats = parse_cargo(cargo)

    # Non-optional banned deps are ALWAYS in the graph -> hard.
    for name, optional in deps.items():
        if is_banned(name) and not optional:
            out.append((HARD, "Cargo.toml",
                        f"banned crate '{name}' is a non-optional dependency "
                        f"(make it `optional = true` behind a feature, or inject "
                        f"the capability it provides at the seam)"))

    # Default features that turn the convenience stack on (invariant #3).
    default = feats.get("default", [])
    if default:
        # Resolve which banned optional deps `default` reaches.
        reachable = set()

        def walk(feat, seen=None):
            seen = seen or set()
            if feat in seen:
                return
            seen.add(feat)
            for item in feats.get(feat, []):
                if item.startswith("dep:"):
                    reachable.add(item[4:])
                elif item in feats:
                    walk(item, seen)
                else:
                    reachable.add(item.split("/")[0])
        for f in default:
            walk(f)
        hit = sorted(d for d in reachable if is_banned(d))
        if hit:
            out.append((HARD, "Cargo.toml",
                        f"default features enable banned crate(s) {hit} — a kernel "
                        f"should be pure by default (set `default = []`, add a "
                        f"`full` umbrella for examples/tests)"))
        else:
            out.append((WARN, "Cargo.toml",
                        f"default features are non-empty ({default}); confirm none "
                        f"pull I/O — prefer `default = []` for a kernel"))
    return out


_CRATE_ALT = "|".join(sorted({re.escape(a) for a in BANNED_LOOKUP if "-" not in a},
                             key=len, reverse=True))

# A banned crate named as a path anywhere (`serde_json::Value`, `tokio::spawn`).
BANNED_PATH = re.compile(r"\b(" + _CRATE_ALT + r")::")
# The start of a public item whose signature callers must compile against.
PUB_ITEM = re.compile(r"\bpub(\s*\([^)]*\))?\s+(fn|struct|enum|type|trait|const|static)\b")
PUB_TYPE_BLOCK = re.compile(r"\bpub(\s*\([^)]*\))?\s+(struct|enum|trait)\b")
PUB_PATH = re.compile(r"\b(Path|PathBuf)\b")
DIRECT_IO = re.compile(
    r"\bstd::fs::|\bstd::net::|\bstd::env::(var|vars)\b|\bstd::process::Command|"
    r"\bSystemTime::now\b|\bInstant::now\b|\b(Utc|Local)::now\b|"
    r"\bthread_rng\s*\(|\bOsRng\b|\bgetrandom\b|"
    r"\breqwest::|\btokio::|\bhyper::|\brand::")


def _scan_file(f: Path):
    """Walk one file, tracking brace depth so `#[cfg(test)]` suppression ends
    with its module, and buffering multi-line public signatures."""
    out = []
    depth = 0
    suppress_until = None     # depth the enclosing #[cfg(test)] block started at
    pending_cfg_test = False  # saw the attribute, waiting for the item it marks
    pub_type_until = None     # depth a `pub struct`/`pub enum` body started at
    sig_start = None          # line number a buffered public signature began on
    sig_text = ""

    for i, raw in enumerate(
            f.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        code = raw.split("//", 1)[0]
        delta = code.count("{") - code.count("}")
        loc = f"{f}:{i}"

        # --- #[cfg(test)] scoping -------------------------------------------
        # Read the comment-stripped line, so a comment mentioning the attribute
        # cannot switch suppression on.
        if suppress_until is None and "#[cfg(test)]" in code:
            pending_cfg_test = True
            depth += delta
            continue
        if pending_cfg_test:
            if "{" in code:
                suppress_until = depth   # cleared when depth returns here
                pending_cfg_test = False
            elif ";" in code:
                pending_cfg_test = False  # annotated a single item, not a block
            depth += delta
            continue
        if suppress_until is not None:
            depth += delta
            if depth <= suppress_until:
                suppress_until = None
            continue

        # --- public signature leaks (invariant #2) ---------------------------
        if sig_start is not None:
            sig_text += " " + code.strip()
        elif PUB_ITEM.search(code):
            sig_start, sig_text = i, code.strip()

        if sig_start is not None and ("{" in code or ";" in code):
            sig_loc = f"{f}:{sig_start}"
            hit = BANNED_PATH.search(sig_text)
            if hit:
                out.append((HARD, sig_loc,
                            f"'{hit.group(1)}' named in a public signature — every "
                            f"caller now compiles against it (use an opaque kernel "
                            f"type; convert at the seam)"))
            if PUB_PATH.search(sig_text):
                out.append((HARD, sig_loc,
                            "path in a public signature — that is I/O policy in the "
                            "kernel (take bytes/&str; let an adapter own the "
                            "filesystem)"))
            if PUB_TYPE_BLOCK.search(sig_text) and "{" in code:
                pub_type_until = depth
            sig_start, sig_text = None, ""

        # --- leaks in public struct fields / enum variant payloads -----------
        if pub_type_until is not None:
            hit = BANNED_PATH.search(code)
            if hit:
                out.append((HARD, loc,
                            f"'{hit.group(1)}' in a public field or variant payload "
                            f"(box it behind an opaque kernel error)"))

        # --- direct I/O and non-determinism (invariant #1) -------------------
        hit = DIRECT_IO.search(code)
        if hit:
            out.append((HARD, loc,
                        f"direct I/O / non-determinism in non-test code "
                        f"('{hit.group(0)}') — move it to an adapter; inject time, "
                        f"randomness and the filesystem"))

        depth += delta
        if pub_type_until is not None and depth <= pub_type_until:
            pub_type_until = None

    return out


def source_findings(src: Path):
    out = []
    for f in sorted(src.rglob("*.rs")):
        parts = set(f.parts)
        if "tests" in parts or "benches" in parts or "examples" in parts:
            continue
        out.extend(_scan_file(f))
    return out


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    root = Path(sys.argv[1])
    cargo = root / "Cargo.toml"
    src = root / "src"
    if not cargo.exists():
        print(f"no Cargo.toml at {root}", file=sys.stderr)
        sys.exit(2)

    findings = cargo_findings(cargo) + (source_findings(src) if src.exists() else [])
    hard = [f for f in findings if f[0] == HARD]
    warn = [f for f in findings if f[0] == WARN]

    print(f"\nDomain-kernel purity report for {root}\n" + "=" * 52)
    if not findings:
        print("No purity violations detected. (Still run the build-level checks: "
              "`cargo check --no-default-features` and the cargo tree assertions.)")
        sys.exit(0)

    for sev, label, items in (("HARD (fix first)", HARD, hard), ("WARN (review)", WARN, warn)):
        if items:
            print(f"\n{sev}: {len(items)}")
            for _, loc, msg in items:
                print(f"  {loc}\n      {msg}")

    print(f"\n{len(hard)} hard, {len(warn)} warn. "
          "Heuristic results — confirm against the source and run the build checks.")
    sys.exit(1 if hard else 0)


if __name__ == "__main__":
    main()
