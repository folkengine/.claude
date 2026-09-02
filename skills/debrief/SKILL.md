---
name: debrief
description: Bullet-point summary of what changed on the current branch versus main. Use when the user types /debrief, or asks for a branch summary, "what's on this branch", "what did we change", "recap this branch", or "summarize my work since main".
---

# /debrief

Run `git log main..HEAD --oneline` and `git diff main...HEAD --stat` to
summarize what has changed on the current branch versus main. Output a
concise bullet-point list grouped by type (features, fixes, refactors,
config/docs). Keep each bullet to one line. No preamble, no trailing
summary — just the list.

Read-only. Never run a git command that changes state.
