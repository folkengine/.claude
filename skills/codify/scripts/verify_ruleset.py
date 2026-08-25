#!/usr/bin/env python3
"""Verify a /codify ruleset file against its source extraction.

Usage:
    verify_ruleset.py <ruleset>.yaml [--extract extract/<source>.txt] [--expect N]

Checks, in order:
  1. the file parses as YAML
  2. meta carries the required fields, and version is a string
  3. at least one rule was found
  4. no /conformance fields leaked in (applies, implemented, evidence, gap, ...)
  5. ids are present, non-empty, and unique within their series
  6. integer id runs have no holes that `skipped:` does not declare
  7. every rule and clause text appears verbatim in the raw extraction
  8. see_also targets resolve somewhere in the document
  9. no text-bearing field became a YAML boolean by accident

Exit status is 0 only when every hard check passes. Warnings never fail the run,
but a run with no --extract cannot support a claim that the text is verbatim.
"""

import argparse
import re
import sys
import unicodedata

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required:  python3 -m pip install pyyaml")

META_ALIASES = {
    "authority": ("authority", "organization", "publisher"),
    "title": ("title",),
    "version": ("version",),
    "date": ("date",),
    "source_file": ("source_file",),
}
CONFORMANCE_FIELDS = ("applies", "implemented", "evidence", "gap", "engine_note")
TEXTUAL_FIELDS = ("id", "number", "title", "text", "version", "date", "reason")

EDGE = 3          # how many lines at each page edge can be furniture
MIN_FURNITURE = 8 # shorter repeated lines are delimiters, not running headers
PAGE_NO = re.compile(r"\d{1,4}( of \d{1,4}.*)?")

errors = []
warnings = []


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


# ---------------------------------------------------------------- normalising

INVISIBLE = dict.fromkeys(map(ord, "­​‌‍﻿"), None)
PUNCT = {
    0x2018: "'", 0x2019: "'", 0x201a: "'",
    0x201c: '"', 0x201d: '"', 0x201e: '"',
    0x2013: "-", 0x2014: "-", 0x2212: "-",
    0x2026: "...", 0x00a0: " ",
}


def _key(line):
    return re.sub(r"\s+", " ", line).strip()


def strip_furniture(raw, report):
    """Drop repeating page furniture before comparing.

    Headers, footers, copyright bars and page numbers are printed on every page
    and land mid-sentence in the extraction, so any rule spanning a page break
    would look like drift.

    Furniture is identified by POSITION, not by repetition alone. A line that
    merely repeats often may be real content — AUTOSAR specs repeat the
    delimiter line "\u230b" and "Upstream requirements: ..." dozens of times, and
    an earlier repetition-only filter silently ate them. Only the first and last
    couple of lines of a page can be furniture.
    """
    pages = raw.split("\f")
    dropped = []

    if len(pages) < 3:
        # No page markers. Fall back to repetition, but only for lines long
        # enough that they cannot be a structural delimiter.
        counts = {}
        for line in raw.splitlines():
            k = _key(line)
            if len(k) >= 40:
                counts[k] = counts.get(k, 0) + 1
        furniture = {k for k, n in counts.items() if n >= 3}  # already len>=40
        kept = []
        for line in raw.splitlines():
            k = _key(line)
            if k in furniture or re.fullmatch(r"\d{1,4}", k or "x"):
                dropped.append(k)
            else:
                kept.append(line)
        out = "\n".join(kept)
    else:
        head, tail = {}, {}
        for page in pages:
            lines = page.splitlines()
            idx = [i for i, l in enumerate(lines) if l.strip()]
            for i in idx[:EDGE]:
                head[_key(lines[i])] = head.get(_key(lines[i]), 0) + 1
            for i in idx[-EDGE:]:
                tail[_key(lines[i])] = tail.get(_key(lines[i]), 0) + 1
        head_f = {k for k, n in head.items() if n >= 3 and len(k) >= MIN_FURNITURE}
        tail_f = {k for k, n in tail.items() if n >= 3 and len(k) >= MIN_FURNITURE}

        out_pages = []
        for page in pages:
            lines = page.splitlines()
            idx = [i for i, l in enumerate(lines) if l.strip()]
            drop = set()
            for i in idx[:EDGE]:
                if _key(lines[i]) in head_f or PAGE_NO.fullmatch(_key(lines[i])):
                    drop.add(i)
            for i in idx[-EDGE:]:
                if _key(lines[i]) in tail_f or PAGE_NO.fullmatch(_key(lines[i])):
                    drop.add(i)
            dropped.extend(_key(lines[i]) for i in drop)
            out_pages.append("\n".join(l for i, l in enumerate(lines) if i not in drop))
        out = "\n".join(out_pages)

    if dropped:
        longest = max(set(dropped), key=len)
        report.append(f"stripped {len(dropped)} page-furniture line(s) from the "
                      f"extraction across {len(pages)} page(s), longest "
                      f"{longest[:60]!r}")
    return out


def normalise(text):
    """Whitespace-, ligature- and punctuation-insensitive comparison form.

    Deliberately case-sensitive: RFC 2119 keywords are load-bearing.
    """
    text = unicodedata.normalize("NFKC", str(text))
    text = text.translate(INVISIBLE).translate(PUNCT)
    text = re.sub(r"-\s*\n\s*", "", text)      # rejoin hyphenated line breaks
    text = re.sub(r"\s+", " ", text)
    return text.strip()


# ------------------------------------------------------------------- walking

def rule_id(node):
    """The schema says `id`. Older files and some sources use `number`."""
    return node.get("id", node.get("number"))


def is_rule(node):
    return isinstance(node, dict) and ("id" in node or "number" in node) and (
        "text" in node or "clauses" in node or "title" in node
    )


def walk(node, path, out):
    """Collect (kind, series, path, node) for every rule- and clause-shaped node."""
    if isinstance(node, dict):
        if is_rule(node):
            series = path.rsplit("[", 1)[0] if "[" in path else path
            out.append(("rule", series, path, node))
            for i, clause in enumerate(node.get("clauses") or []):
                if isinstance(clause, dict):
                    out.append(("clause", path, f"{path}.clauses[{i}]", clause))
            return
        for key, value in node.items():
            walk(value, f"{path}.{key}" if path else key, out)
    elif isinstance(node, list):
        for i, item in enumerate(node):
            walk(item, f"{path}[{i}]", out)


def find_bools(node, path, field, out):
    if isinstance(node, bool):
        out.append((path, field))
    elif isinstance(node, dict):
        for key, value in node.items():
            find_bools(value, f"{path}.{key}" if path else key, key, out)
    elif isinstance(node, list):
        for i, item in enumerate(node):
            find_bools(item, f"{path}[{i}]", field, out)


def divergence_hint(needle, haystack):
    """Where does the text stop matching? Locates the drift instead of just naming it."""
    words = needle.split()
    lo, hi = 0, len(words)
    while lo < hi:
        mid = (lo + hi + 1) // 2
        if " ".join(words[:mid]) in haystack:
            lo = mid
        else:
            hi = mid - 1
    if lo == 0:
        return "no prefix matched — wrong document, or heavily reworded"
    return f"matched {lo}/{len(words)} words, then: ...{' '.join(words[lo:lo + 12])}"


# ---------------------------------------------------------------------- main

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ruleset")
    ap.add_argument("--extract", help="raw text extraction of the source document")
    ap.add_argument("--expect", type=int,
                    help="total rule count the source document claims")
    ap.add_argument("--no-strip-furniture", action="store_true",
                    help="compare against the extraction exactly as extracted")
    args = ap.parse_args()

    try:
        doc = yaml.safe_load(open(args.ruleset, encoding="utf-8").read())
    except yaml.YAMLError as exc:
        sys.exit(f"FAIL  {args.ruleset} does not parse:\n{exc}")
    if not isinstance(doc, dict):
        sys.exit(f"FAIL  {args.ruleset} is not a mapping at the top level")

    # ---- 2. meta
    meta = doc.get("meta")
    if not isinstance(meta, dict):
        err("meta: block is missing")
        meta = {}
    for canonical, aliases in META_ALIASES.items():
        present = [a for a in aliases if meta.get(a)]
        if not present:
            err(f"meta.{canonical} is missing")
        elif present[0] != canonical:
            warn(f"meta.{present[0]} is used where the schema says meta.{canonical}")
    if "version" in meta and not isinstance(meta["version"], str):
        err(f"meta.version is {type(meta['version']).__name__}, not a string "
            f"— quote it, or 1.10 silently becomes 1.1")
    if not meta.get("extraction"):
        warn("meta.extraction is not set — the verbatim claim has no saved proof")
    rights = meta.get("rights") or {}
    if not rights:
        warn("meta.rights is missing — step 0 (rights check) was skipped")
    elif rights.get("class") in ("restricted", "unknown"):
        warn(f"meta.rights.class is \"{rights.get('class')}\" — do not commit or "
             f"publish this file without the publisher's permission")

    # ---- 3. rules
    found = []
    walk(doc, "", found)
    found = [e for e in found if not e[2].startswith("meta")]
    rules = [e for e in found if e[0] == "rule"]
    clauses = [e for e in found if e[0] == "clause"]
    if not rules:
        err("no rule-shaped entries found — check the file structure")

    # ---- 4. leaked /conformance fields
    for _, _, path, node in found:
        for field in CONFORMANCE_FIELDS:
            if field in node:
                err(f"{path}: has '{field}:' — that belongs in the /conformance "
                    f"audit file, not the verbatim ruleset")

    # ---- 5. ids present and unique within their series
    seen = {}
    global_ids = set()
    legacy_number = set()
    for kind, series, path, node in found:
        if "id" not in node and "number" in node:
            legacy_number.add(series)
        rid = rule_id(node)
        if rid is None or str(rid).strip() == "":
            err(f"{path}: empty id")
            continue
        if kind == "rule":
            global_ids.add(str(rid))
        key = (series, str(rid))
        if key in seen:
            err(f"{path}: duplicate id {rid!r} in {series} (also at {seen[key]})")
        else:
            seen[key] = path
    for series in sorted(legacy_number):
        warn(f"{series}: uses 'number:' where the schema says 'id:' "
             f"(ids are not always integers)")

    # ---- 6. holes in integer id runs
    by_series = {}
    for kind, series, path, node in rules:
        by_series.setdefault(series, []).append(rule_id(node))
    declared = normalise(yaml.safe_dump(doc.get("skipped") or []))
    for series, ids in sorted(by_series.items()):
        ints = [i for i in ids if isinstance(i, int)]
        if len(ints) < 2 or len(ints) != len(ids):
            continue
        holes = sorted(set(range(min(ints), max(ints) + 1)) - set(ints))
        undeclared = [h for h in holes if str(h) not in declared]
        if undeclared:
            err(f"{series}: ids {undeclared} missing from the run and not "
                f"accounted for in skipped:")
        elif holes:
            warn(f"{series}: ids {holes} absent, declared in skipped:")

    # ---- 7. verbatim against the extraction
    checked = untexted = 0
    if args.extract:
        raw_extract = open(args.extract, encoding="utf-8", errors="replace").read()
        notes = []
        if not args.no_strip_furniture:
            raw_extract = strip_furniture(raw_extract, notes)
        for note in notes:
            warn(note)
        source = normalise(raw_extract)
        for _, _, path, node in found:
            text = node.get("text")
            if not text:
                untexted += 1
                continue
            # `text` may be a list when the source states one item as several
            # separate passages (prose plus its parameter table). Each passage is
            # verbatim on its own; the concatenation is not.
            parts = text if isinstance(text, list) else [text]
            for n, part in enumerate(parts):
                checked += 1
                needle = normalise(part)
                if needle not in source:
                    where = f"{path}.text[{n}]" if len(parts) > 1 else f"{path}"
                    err(f"{where}: text is not verbatim in the extraction — "
                        f"{divergence_hint(needle, source)}")
    else:
        warn("no --extract given: the verbatim check did NOT run, so this run "
             "cannot support a claim that the text matches the source")

    # ---- 8. see_also resolves anywhere in the document
    for _, _, path, node in found:
        targets = node.get("see_also") or []
        if not isinstance(targets, list):
            targets = [targets]
        for target in targets:
            if str(target) not in global_ids:
                err(f"{path}: see_also {target!r} does not resolve to any rule id")

    # ---- 9. text-bearing fields that became booleans
    leaked = []
    find_bools(doc, "", None, leaked)
    hard = [(p, f) for p, f in leaked if f in TEXTUAL_FIELDS]
    soft = [(p, f) for p, f in leaked if f not in TEXTUAL_FIELDS]
    for path, field in hard:
        err(f"{path}: '{field}' parsed as a YAML boolean — quote it "
            f"(bare yes/no/on/off are booleans in YAML 1.1)")
    if soft:
        shown = ", ".join(sorted({f for _, f in soft}))
        warn(f"{len(soft)} boolean value(s) in field(s): {shown} — fine if "
             f"intended, but confirm none was meant to be text")

    # -------------------------------------------------------------- reporting
    print(f"ruleset      {args.ruleset}")
    print(f"extraction   {args.extract or '(none given)'}")
    print(f"rules        {len(rules)} in {len(by_series)} series, "
          f"{len(clauses)} clauses")
    for series, ids in sorted(by_series.items()):
        print(f"               {series or '(root)':<40} {len(ids)}")
    if args.extract:
        print(f"verbatim     {checked} texts checked, {untexted} entries had no text")
    if args.expect is not None:
        print(f"expected     {args.expect} vs {len(rules)} found")
        if args.expect != len(rules):
            err(f"count mismatch: source claims {args.expect}, file has {len(rules)}")

    for w in warnings:
        print(f"WARN  {w}")
    for e in errors:
        print(f"FAIL  {e}")

    print()
    if errors:
        print(f"FAILED  {len(errors)} error(s), {len(warnings)} warning(s)")
        return 1
    print(f"PASSED  0 errors, {len(warnings)} warning(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
