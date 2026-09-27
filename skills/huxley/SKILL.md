---
name: huxley
description: Use when the user types /huxley <code>, or asks how a function, type, file, or snippet evolved over time, wants its git lineage or "family tree", asks where some code first came from, or wants its history traced across the several related repositories listed in a .huxley file — even if they never say huxley.
---

# Huxley — Code Evolution Report

## Overview

Huxley writes a markdown report that shows how one piece of code evolved, commit by commit. The code can cross repos. It can be born in one repo, copied into another, ported to another language, and die in the first. The `.huxley` file names the repos that make up this family.

Read-only on git. Use `git log`, `git show`, `git blame`, `git grep` only. Never commit the report.

## The `.huxley` file

Lives at the root of the current repo. One repo per line. `#` starts a comment.

```
# repos that are part of this codebase's history
https://github.com/Owner/older-repo
https://github.com/Owner/port.py
~/src/some/local/repo
```

- A URL `https://github.com/Owner/name` maps to the local clone `$HUXLEY_ROOT/github.com/Owner/name` (`HUXLEY_ROOT` defaults to `~/src`).
- A `~` or absolute path is used as-is.
- The current repo is always part of the family, even if not listed.
- No `.huxley` file? Trace the current repo only, and say so in the report.
- A listed repo with no local clone: list it under **Not searched** in the report. Offer to clone it. Clone only on a yes.

## Workflow

### 1. Pin the target
The argument can be a symbol (`Five::is_flush`), a path, `path:start-end`, or a pasted snippet. Find it in the current tree first and read it. Then make a **term list**:
- the name, plus its case style in each *language the family uses* (`is_flush` for Rust/Python, `isFlush` for JS/TS) — no others, each term costs scan time;
- distinctive identifiers the body depends on (constants, helper functions) — these often give the best copy evidence and expose renames;
- older names you find along the way (renames are common — add them and re-scan);
- one or two distinctive lines from the body, for snippets with no name.

Keep the list to about 2–6 terms. `-S` is a substring match, so a short term also hits longer names.

### 2. Scan the family
Run from the repo root, with all terms in one call:
```bash
bash <skill-dir>/scripts/huxley-scan.sh .huxley "<term>" ["<term>" ...]
```
Output is TSV, oldest first, one line per commit: `iso-datetime  repo  sha  terms-hit  subject  commit-url`. It lists every commit that added or removed a term (`git log -S`). Stderr shows progress, missing repos, and git errors. It can take 10–30 seconds on a large family. It scans HEAD only. Run it again with `HUXLEY_ALL=1` in front to include other branches. List branch-only hits in the report as "unmerged".

Also get the repo table once, for links:
```bash
bash <skill-dir>/scripts/huxley-scan.sh --repos .huxley
```
One line per repo: `repo  local-path  web-url  head-sha  head-pushed`. The web address comes from the `.huxley` URL, or else from the repo's `origin` remote. `-` means the repo is not on GitHub.

### 3. Read the key commits
The scan finds candidates. Most hits are noise (docs, moved files, generated output). For each repo, find the real turning points:
- `git -C <repo> show <sha>` — read the diff.
- `git -C <repo> log -L '/pub fn is_flush(/,+10:<file>'` — full history of one function in one file. Use the regex form: `-L :<fn>:<file>` fails on indented methods (Rust `impl`, Python classes, JS classes). Make the regex tight (`pub fn`, the open paren): `-L` uses the first match, and that can be a test with the same name. `-L` stops at the commit that moved the block into the file. Check the scan output for the real birth.
- `git -C <repo> log --follow -- <file>` — history across file renames.

Huge diffs (an `init` commit of a whole codebase): do not read the whole diff. Use `git show <sha> | grep -n -B3 -A15 '<term>'`.

Pick the 5–15 commits that changed the code's *shape*: birth, copy/port to another repo, big rewrites, API changes, bug fixes, death. Order same-day commits by time. Everything else is **noise**: file moves, docs, diaries, commented-out code, committed build output (`target/`, generated JSON). Skip noise, but count the noise commits (unique commits, not term hits).

### 4. Find the links between repos
When the code shows up in a new repo, label the edge from the source repo:
- **copied** — near-same text.
- **ported** — other language, same logic.
- **replaced by** — same job, new algorithm or design.
- **reinvented** — same idea, new code, no sign the author looked at the older one. If the new repo depends on the old one, or its code names the old one, use **replaced by**.

Draw an edge only when there is a matching line, or a README, comment, or commit message that names the source. Timing alone gives a dashed edge labeled "likely". A source outside the `.huxley` family (a README says "based on X") is an **external** node in the chart. Do not search it.

### 5. Build the GitHub links
Every commit, snippet, and `file:line` in the report gets a link, so a reader can click through to the code in context. Always use the **full sha**, never a branch name: branch links break when the code moves.

| Link to | Form |
|---|---|
| A commit | `<web-url>/commit/<full-sha>` (the scan's last column) |
| Code at a commit | `<web-url>/blob/<full-sha>/<path>#L<start>-L<end>` |
| Code today | same form, with `head-sha` from `--repos` |
| A repo | `<web-url>` |

- Get line numbers from *that* commit's version of the file, not today's: `git -C <repo> grep -n '<term>' <sha> -- <path>`. That gives the start line. Read on from there to the closing brace or end of block for the end line. Start the range at the doc comment and attributes (`///`, `#[...]`, decorators) above the item.
- A commit that **deletes** the code: the code is not in that commit. Link the commit itself, and link the code at the parent: use `git -C <repo> rev-parse <sha>^` for the sha.
- Get the full sha with `git -C <repo> rev-parse <short-sha>`.
- For a `.md` file, add `?plain=1` before `#L` — GitHub ignores line anchors on rendered markdown.
- Check every link before you finish: `curl -s -o /dev/null -w '%{http_code}' <url-without-#fragment>` must give `200`, and `git -C <repo> show <sha>:<file> | sed -n '<start>,<end>p'` must show the code the report names. (In zsh, do not name a loop variable `path` — it overwrites `PATH`.)
- A commit that is not on GitHub yet gives a broken link. Check with `git -C <repo> branch -r --contains <sha>`. Empty output, or `head-pushed` = `no`, or web-url = `-`: write the sha as plain text and add "(local only)".

### 6. Write the report
Save to `docs/huxley/<slug>.md` in the current repo (use the repo's docs folder if it is not `docs/`). Make the folder if needed. Report shape, in this order:

1. **Title** — `# Huxley: <target>`, report date, repos searched, each linked, with each HEAD sha.
2. **Summary** — 3–5 sentences: where it was born, where it lives now, the biggest change.
3. **Lineage** — a mermaid `flowchart LR` of repos, with edges labeled copied / ported / reinvented and a date.
4. **Timeline** — one table row per key commit: `date | repo | sha | code | what changed`. The sha links to the commit. `code` links to the lines at that commit.
5. **Eras** — one section per era with the code as it looked then (short snippet, from `git show <sha>:<path>`), and why it changed. Put a `[view on GitHub](...)` link to those exact lines right above each snippet.
6. **Today** — where live code has it now, as a linked `file:line`, in every repo. Docs and comments do not count.
7. **Not searched** — missing repos, external sources, and the noise commit count.

Then tell the user the path. Leave git to them.

## Common Mistakes
- Tracing only the exact name — renames and case styles hide whole eras. Grow the term list and re-scan.
- Dumping every scan hit into the timeline — the report is about shape changes, not a log dump.
- Claiming "copied from X" on dates alone — show a matching line or say "likely".
- Reading a sha in the wrong repo — always use `git -C <repo>`.
- Skipping repos silently — every missing repo goes under **Not searched**.
- Links to `blob/main/...` — they rot. Use the full sha.
- Line numbers from today's file in a link to an old commit — they point at the wrong lines.
