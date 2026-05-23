---
name: cookit
description: Squash all unpushed commits on the current branch into a single fresh commit with a new "now" timestamp. Use when the user types /cookit.
version: 1.0.0
---

Squash every unpushed commit on the current branch into one fresh commit, dated now.

## Preflight — refuse fast on any failure

Run these in order. If any check fails, print the reason and stop. Do not run any state-changing git command.

1. `git rev-parse --is-inside-work-tree` — must succeed.
2. `git symbolic-ref --short HEAD` — refuse on detached HEAD, `main`, or `master`.
3. `git remote` — refuse if output is empty (no configured remote means every commit looks "unpushed").
4. `git status --porcelain` — refuse if output is non-empty. Working tree must be clean: no staged, unstaged, or untracked-but-tracked changes. Tell the user to commit or stash first.
5. `git rev-list HEAD --not --remotes` — capture unpushed commit SHAs (one per line, newest first).
   - 0 lines → exit cleanly: "nothing to cook."
   - 1 line → refuse: "only one unpushed commit, nothing to combine."
   - 2+ lines → continue.
6. `git rev-list --merges HEAD --not --remotes` — refuse if non-empty. Squash semantics across merge commits are ambiguous.
7. Compute `BASE = $(git rev-list HEAD --not --remotes | tail -1)^` — the parent of the oldest unpushed commit. This is the soft-reset target.

## Confirm with the user

Show all of:

- Current branch name.
- `git log $BASE..HEAD --oneline` — the commits about to be squashed.
- The proposed combined commit message: `git log $BASE..HEAD --format=%B` (lists messages newest-first), joined with blank-line separators.

Ask the user to **accept** the message, **edit** it, or **abort**. Do not proceed without an explicit accept or an edited message.

## Execute — the only two state-changing commands this skill is authorized to run

8. `git reset --soft "$BASE"` — un-commits the unpushed range and keeps everything staged.
9. Commit with the final message via stdin, so multi-paragraph messages survive intact:

   ```bash
   git commit -F - <<'EOF'
   <final message>
   EOF
   ```

   This produces a fresh commit with "now" as both the author and committer date.

These two commands are authorized by the **Exceptions** section of `~/.claude/CLAUDE.md`. Do not run any other state-changing git command from within this skill — not `git push`, not `git stash`, not `git rebase`, not `git commit --amend`. If something looks wrong mid-flight, stop and tell the user; do not attempt recovery on their behalf.

## Verify and report

10. `git log -1 --format='%h %an %ai %s' --date=iso` — show the resulting commit. Confirm the author/committer dates are within seconds of now.
11. Tell the user: the original commits remain reachable via `git reflog` for ~90 days if they want to roll back. The recovery command is `git reset --hard <old-HEAD-sha>` (suggest, do not run).
