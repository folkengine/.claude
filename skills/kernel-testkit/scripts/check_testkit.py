#!/usr/bin/env python3
"""check_testkit.py — deterministic checks for kernel-testkit invariants.

Usage: python check_testkit.py <path-to-workspace-or-crate>

Python-only (no Rust toolchain). Checks are graded:
  [HARD]   invariant violated with confidence -> nonzero exit
  [WARN]   likely gap, needs judgment
  [REVIEW] heuristic could not decide -> read the code by hand
  [OK]     check passed

Covers (see references/invariants.md):
  T2 seed-determinism  — ambient RNG/clock/env in testkit sources
  T4 textured          — texture map / textures module present
  T7 one-way dep       — test-data crates out of the kernel's default build
  T1 reachability      — heuristic only: do generator files reference the
                         kernel transition fn; derive(Arbitrary) occurrences
"""
import re
import sys
from pathlib import Path

NONDET = {
    r"thread_rng\s*\(": "rand::thread_rng() — ambient RNG",
    r"SystemTime::now\s*\(": "SystemTime::now() — ambient clock",
    r"Instant::now\s*\(": "Instant::now() — ambient clock",
    r"std::env::": "std::env — ambient environment",
    r"\bgetrandom\s*\(": "getrandom() — ambient entropy",
    r"OsRng": "OsRng — ambient entropy",
}
TESTDATA_CRATES = ("proptest", "arbitrary", "quickcheck", "fake", "rand")
TRANSITION_HINTS = ("apply", "legal_actions", "transition", "step")
GENERATOR_FILE_HINTS = ("strateg", "generat", "arbitrary", "testkit", "fake")

findings = {"HARD": [], "WARN": [], "REVIEW": [], "OK": []}


def add(level, msg):
    findings[level].append(msg)


def rust_files(root: Path):
    return [p for p in root.rglob("*.rs") if "target" not in p.parts]


def strip_line_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def find_testkit(root: Path):
    """Return (kind, path): ('crate', dir) or ('feature', cargo_toml) or (None, None)."""
    for cargo in root.rglob("Cargo.toml"):
        if "target" in cargo.parts:
            continue
        name_m = re.search(r'^\s*name\s*=\s*"([^"]+)"', cargo.read_text(errors="ignore"), re.M)
        if name_m and name_m.group(1).endswith(("-testkit", "_testkit", "-testdata")):
            return "crate", cargo.parent
    for cargo in root.rglob("Cargo.toml"):
        if "target" in cargo.parts:
            continue
        text = cargo.read_text(errors="ignore")
        if re.search(r"^\s*(testkit|test-utils|test_utils)\s*=", text, re.M):
            return "feature", cargo
    return None, None


def kernel_manifests(root: Path, testkit_dir):
    out = []
    for cargo in root.rglob("Cargo.toml"):
        if "target" in cargo.parts:
            continue
        out.append(cargo)
    if testkit_dir:
        out = [c for c in out if testkit_dir not in c.parents and c.parent != testkit_dir]
    # drop pure workspace manifests (no [package])
    return [c for c in out if re.search(r"^\[package\]", c.read_text(errors="ignore"), re.M)]


def check_t2(testkit_root: Path):
    hits = []
    for f in rust_files(testkit_root):
        text = strip_line_comments(f.read_text(errors="ignore"))
        for i, line in enumerate(text.splitlines(), 1):
            for pat, why in NONDET.items():
                if re.search(pat, line):
                    hits.append(f"{f}:{i}: {why}")
    if hits:
        for h in hits:
            add("HARD", f"T2 nondeterminism in testkit: {h}")
    else:
        add("OK", "T2: no ambient RNG/clock/env found in testkit sources")


def check_t4(root: Path, testkit_root):
    map_files = [p for p in root.rglob("TEXTURES.md") if "target" not in p.parts]
    tex_mods = []
    search_root = testkit_root or root
    tex_mods = [p for p in rust_files(search_root) if p.stem == "textures"]
    if map_files or tex_mods:
        where = ", ".join(str(p) for p in (map_files + tex_mods))
        add("OK", f"T4: texture map present ({where})")
        if map_files and not tex_mods:
            add("WARN", "T4: TEXTURES.md exists but no textures module found — "
                        "textures named in prose need classifiers in code")
    else:
        add("WARN", "T4: no texture map found (no TEXTURES.md, no textures.rs) — "
                    "fake data appears untextured")


def check_t7(root: Path, testkit_dir, testkit_kind):
    for cargo in kernel_manifests(root, testkit_dir):
        text = cargo.read_text(errors="ignore")
        # default features pulling testkit
        m = re.search(r"^\s*default\s*=\s*\[([^\]]*)\]", text, re.M)
        if m and re.search(r"testkit|test-utils|test_utils", m.group(1)):
            add("HARD", f"T7 {cargo}: default features enable the testkit")
        # non-optional, non-dev test-data crates
        dep_section = re.split(r"^\[dev-dependencies\]", text, flags=re.M)[0]
        for crate in TESTDATA_CRATES:
            for dm in re.finditer(rf"^\s*{crate}\s*=\s*(.+)$", dep_section, re.M):
                if "optional = true" not in dm.group(1):
                    lvl = "HARD" if crate != "rand" else "WARN"
                    add(lvl, f"T7 {cargo}: '{crate}' is a non-optional dependency "
                             f"of a kernel crate (test-data machinery in default build)")
    if not findings["HARD"] and testkit_kind:
        add("OK", "T7: no test-data crates found in kernel default builds")


def check_t1(search_root: Path):
    gen_files = [p for p in rust_files(search_root)
                 if any(h in p.name.lower() for h in GENERATOR_FILE_HINTS)]
    if not gen_files:
        add("REVIEW", "T1: no generator-looking files found — locate generators by hand")
        return
    for f in gen_files:
        text = strip_line_comments(f.read_text(errors="ignore"))
        if not any(h in text for h in TRANSITION_HINTS):
            add("REVIEW", f"T1 {f}: generator file never references the kernel "
                          f"transition fn ({'/'.join(TRANSITION_HINTS)}) — "
                          f"may hand-assemble unreachable states")
        else:
            add("OK", f"T1: {f} references the transition surface")
    for f in rust_files(search_root):
        text = f.read_text(errors="ignore")
        for i, line in enumerate(text.splitlines(), 1):
            if re.search(r"derive\([^)]*Arbitrary", line):
                add("REVIEW", f"T1 {f}:{i}: derive(Arbitrary) — fine on action "
                              f"types, a T1 violation on state types; check which")


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    root = Path(sys.argv[1]).resolve()
    if not root.exists():
        print(f"error: {root} does not exist")
        sys.exit(2)

    kind, loc = find_testkit(root)
    if kind == "crate":
        add("OK", f"T3: companion testkit crate found at {loc}")
        testkit_root, testkit_dir = loc, loc
    elif kind == "feature":
        add("OK", f"T3: testkit feature found in {loc}")
        add("WARN", "T3: feature-based testkit — companion crate preferred "
                    "(keeps kernel manifest untouched)")
        testkit_root, testkit_dir = root, None
    else:
        add("HARD", "T3: no testkit found (no *-testkit crate, no testkit feature) — "
                    "the kernel ships without controllability")
        testkit_root, testkit_dir = root, None

    check_t2(testkit_root)
    check_t4(root, testkit_root if kind == "crate" else None)
    check_t7(root, testkit_dir, kind)
    check_t1(testkit_root)

    print(f"\n=== kernel-testkit check: {root} ===\n")
    for level in ("HARD", "WARN", "REVIEW", "OK"):
        for msg in findings[level]:
            print(f"[{level:6}] {msg}")
    hard = len(findings["HARD"])
    print(f"\n{hard} hard finding(s), {len(findings['WARN'])} warning(s), "
          f"{len(findings['REVIEW'])} manual review item(s)")
    sys.exit(1 if hard else 0)


if __name__ == "__main__":
    main()
