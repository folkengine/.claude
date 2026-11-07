#!/usr/bin/env python3
"""Check every relative link in a deconstruct pack.

Usage: python3 check_links.py <pack-dir>

For each Markdown file under <pack-dir> (fenced code blocks skipped), every
link that is not an external URL must resolve:

- the target file or directory exists;
- a line anchor (#L12 or #L12-L40) lies inside the target file;
- a named anchor (#sd-03, #spec-decisions-index) exists in the target
  Markdown file as an <a id="..."> tag or a heading slug.

Prints one line per broken link and exits 1 if any; prints a count and
exits 0 otherwise.
"""

import re
import sys
from pathlib import Path

LINK = re.compile(r"\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
LINE_ANCHOR = re.compile(r"^L(\d+)(?:-L(\d+))?$")
HTML_ID = re.compile(r"<a\s+id=\"([^\"]+)\"")
HEADING = re.compile(r"^#{1,6}\s+(.*?)\s*#*\s*$")
FENCE = re.compile(r"^\s*(```|~~~)")


def slug(heading: str) -> str:
    text = re.sub(r"[`*_]|\[|\]\([^)]*\)", "", heading).strip().lower()
    text = re.sub(r"[^\w\- ]", "", text)
    return text.replace(" ", "-")


def prose_lines(path: Path):
    in_fence = False
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if FENCE.match(line):
            in_fence = not in_fence
            continue
        if not in_fence:
            yield number, line


def anchors(path: Path, cache: dict) -> set:
    if path not in cache:
        found = set()
        for _, line in prose_lines(path):
            found.update(HTML_ID.findall(line))
            heading = HEADING.match(line)
            if heading:
                found.add(slug(heading.group(1)))
        cache[path] = found
    return cache[path]


def check(pack: Path) -> list:
    problems, cache = [], {}
    for md in sorted(pack.rglob("*.md")):
        for number, line in prose_lines(md):
            for target in LINK.findall(line):
                if re.match(r"^[a-z][a-z0-9+.-]*:", target):
                    continue  # http:, https:, mailto:
                path_part, _, fragment = target.partition("#")
                dest = (md.parent / path_part).resolve() if path_part else md
                where = f"{md.relative_to(pack)}:{number}"
                if not dest.exists():
                    problems.append(f"{where}: missing target {target}")
                    continue
                if not fragment:
                    continue
                line_anchor = LINE_ANCHOR.match(fragment)
                if line_anchor:
                    last = int(line_anchor.group(2) or line_anchor.group(1))
                    length = len(dest.read_text(encoding="utf-8", errors="replace").splitlines())
                    if last > length:
                        problems.append(f"{where}: {target} past end of file ({length} lines)")
                elif dest.suffix == ".md" and fragment not in anchors(dest, cache):
                    problems.append(f"{where}: no anchor #{fragment} in {path_part or md.name}")
    return problems


def main() -> int:
    if len(sys.argv) != 2 or not Path(sys.argv[1]).is_dir():
        print(__doc__.strip().splitlines()[2], file=sys.stderr)
        return 2
    pack = Path(sys.argv[1]).resolve()
    problems = check(pack)
    for problem in problems:
        print(problem)
    if problems:
        print(f"{len(problems)} broken link(s)")
        return 1
    links = sum(len(LINK.findall(l)) for md in pack.rglob("*.md") for _, l in prose_lines(md))
    print(f"ok: {links} links checked")
    return 0


if __name__ == "__main__":
    sys.exit(main())
