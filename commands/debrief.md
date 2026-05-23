---
description: Bullet-point summary of changes on current branch vs main
allowed-tools: Bash
---

Run `git log main..HEAD --oneline` and `git diff main...HEAD --stat` to summarize what has changed on the current branch versus main. Output a concise bullet-point list grouped by type (features, fixes, refactors, config/docs). Keep each bullet to one line. No preamble, no trailing summary — just the list.
