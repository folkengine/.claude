---
name: blooper
description: Use when the user asks for a "blooper report" or wants to dig through a repo's git history to find its most embarrassing early coding mistakes and see which ones survive in the current code. Optional argument narrows the hunt (a topic like "string handling", a path, or a tag/era range).
---

# Blooper Report

## Overview

A "blooper" is an embarrassing mistake the author made in the repo's early history — clumsy idioms, anti-patterns, things they would never write today. This skill digs them up from git history, ranks the worst, shows how the code got better, and flags any bloopers still alive in the current tree.

Tone: affectionate roast, not code review. The point is showing growth.

Read-only on git: use `git tag`, `git show`, `git log`, `git ls-tree` only. Never run state-changing git commands.

## Workflow

### 1. Scope the hunt
- If an argument was given, treat it as the focus: a topic ("string handling", "error handling"), a path, or a tag/era. Otherwise hunt broadly.
- Find the earliest history: `git tag -l --sort=version:refname` for the earliest tags, or `git log --reverse --oneline` if the repo has no tags.

### 2. Dig
- List old files with `git ls-tree -r --name-only <tag>`, read them with `git show <tag>:<path>`.
- Sample 2–4 tags spread across the history so you can see evolution, not just the start.
- Look for era-typical mistakes: redundant trait bounds, needless allocations/clones, stringly-typed data, hand-rolled parsing instead of `FromStr`/`TryFrom`, bare `unwrap()`s, copy-paste blocks, God functions, tests that assert nothing.
- For each candidate blooper capture: the snippet, the tag/version it lived in, why it is bad, and when it was fixed (compare later tags, or `git log -S '<snippet>'`).

### 3. Check what is still outstanding
- For every blooper pattern found, grep the CURRENT working tree for the same pattern.
- Anything still present goes in a "Still outstanding" section with `file:line` citations. These are live cleanup candidates.
- This pass is mandatory even when the focus argument is narrow.

### 4. Report
Present the top 3–7 bloopers, worst first. For each:
- **The blooper** — the old snippet, with the version it lived in
- **Why it's a blooper** — one or two plain sentences
- **The fix** — how current code does it now (or "fixed in vX.Y")

End with:
- **Still outstanding** — bloopers alive today, with `file:line` (or "None — all cleaned up 🎉")

### 5. Offer to save
Ask the user if they want the report saved to `docs/bloopers/` (create the folder if missing) as `docs/bloopers/YYYY-MM-DD-<focus-or-general>.md`. Only write the file on a yes. Never commit it — leave git to the user.

## Common Mistakes
- Roasting current code as if it were old — always attribute a blooper to the version it lived in.
- Skipping the outstanding check — "is it still here?" is the payoff of the whole report.
- Dumping every flaw found — rank and cut; the 3–7 biggest only.
- Saving the report without asking first, or committing it.
