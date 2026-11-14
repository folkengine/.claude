---
name: slop-guard
description: Slop guard — a per-repository review gate for outgoing work. While on, a hook holds back `git push` and `gh pr create` until a human has read a large diff, and PR bodies get an optional "AI assistance" section. Use when the user types /slop-guard, /slop-guard on [lines], /slop-guard off, or /slop-guard status, asks to turn the slop guard or review gate on or off or change its threshold, or asks why a push or PR was blocked by it.
version: 1.0.0
---

Slop guard: nothing large leaves this repository until a human has read it. A `PreToolUse` hook (`~/.claude/hooks/slop-guard.sh`) enforces this while the flag file `.claude/slop-guard` exists at the repository root. This skill is the switch, plus the conduct that goes with it. The hook does the enforcing; you do not get a vote.

The flag is per-repository and persists across sessions. It and the review marker stay out of commits through `.git/info/exclude`.

## Toggle

Always go through the script. Never create, edit, or delete `.claude/slop-guard` or `.claude/slop-reviewed` yourself; the hook denies it.

| Request | Do this |
|---|---|
| `/slop-guard on` | `~/.claude/hooks/slop-guard.sh on` |
| `/slop-guard on <lines>` | `~/.claude/hooks/slop-guard.sh on <lines>` |
| `/slop-guard off` | `~/.claude/hooks/slop-guard.sh off` |
| `/slop-guard status`, or bare `/slop-guard` | `~/.claude/hooks/slop-guard.sh status`; if it is off, ask whether to turn it on |

**Plain-language requests map onto the same rows.** "Turn the review gate on", "guard this repo" → row 1. "Raise the limit to 800" → row 2. "Stop gating pushes here" → row 3. "Is the slop guard on?" → row 4.

Turning it off, or changing the threshold while it is on, raises a permission prompt: loosening the guard is the human's call even when they typed the command. If they decline, the guard stays as it was. Say so and stop.

After any toggle, run `status` and report what it prints. Do not assume the switch took.

Only an explicit request switches the guard. Never turn it off or raise the threshold to get a push through.

## What the guard does

- **Review-size gate.** `git push` and `gh pr create` are denied when the branch's diff against its base (where it forked from the default branch) is over the threshold and no human has marked that exact diff as reviewed. The threshold is 400 changed lines unless set otherwise; lockfiles are not counted. Commits are never gated.
- **Optional disclosure.** `gh pr create` whose body has no "AI assistance" section becomes a permission prompt. The human may approve it as is.
- **Fails open.** No repository, or no base branch, means no gate. `status` says when that is the case, so report it.

## When a push or PR is denied

The denial is not an obstacle to route around. It is the cue to make the human's review cheap. In the chat:

1. Say what the change is for, in two sentences.
2. Give a reading order: the files that carry the risk first, the mechanical ones last, and what is safe to skim. The "Largest files" list in the denial is raw material, not the order. Size is not risk.
3. Say whether it can be split or cut down. Deleting code is a valid answer.

Then stop and wait. The human reads the diff and marks it themselves:

```
! ~/.claude/hooks/slop-guard.sh reviewed
```

You never run `reviewed`. The marker records that a person read the diff; written by you it would be false. Any new commit invalidates it, so once the diff is marked, push it. If the human asks for one more change first, make it and tell them the diff needs marking again.

Splitting a change is fine when the human chooses it. It is not a way to get a large change out unread in pieces.

## PR bodies

When you draft a PR body in a guarded repository, offer an `## AI assistance` section: what the agent wrote, and what the human checked. Two or three plain lines. It is optional. If the user does not want it, leave it out and let them approve the prompt.

Never fill in "what the human checked" from guesswork. Ask, or leave that line for them to write.

## If the hook is not installed

The skill alone guards nothing. Check that `~/.claude/settings.json` registers `~/.claude/hooks/slop-guard.sh` under `PreToolUse` with the matcher `Bash|Edit|Write`. If it is missing, say so plainly and offer to add it. Do not report the guard as on.

## Red flags

- A large push went through with the guard on → the hook is not firing, or there is no base branch. Run `status` and check the registration.
- You are about to run `reviewed`, touch the flag file, or toggle the guard without being asked → stop.
- Your reading order is the file list in diff order → redo it. The point is to rank by risk.
- The "AI assistance" section says the human checked something they have not told you they checked → remove the claim.
