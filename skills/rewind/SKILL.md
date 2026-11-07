---
name: rewind
description: "Use when the user types `/rewind <commit|PR|EPIC>`, `/rewind`, or `/rewind off`, or wants to replay how an existing feature was built by re-implementing it by hand, step by step, from the commit before it — 'rewind to before this feature', 'walk me through rebuilding this commit', 'let me re-implement this PR myself', 'I want to grok how EPIC-NN was done' — even if they never say rewind. Ends with a tutorial they can hand to other developers. Do NOT trigger for new work (/dog), stub-and-test exercises (/codebase-kata), or a written explainer with no hands-on walk (/deconstruct specific)."
version: 1.0.0
---

# /rewind

Replay one finished feature. The developer goes back to the commit before
it and rebuilds its core logic by hand while Claude guides and checks, as in
`/dog`. Each step's "why" is read from the real code, as in `/deconstruct`
SPECIFIC. The walk ends with a tutorial.

`T` = the feature commit. `P` = its parent. `<short-T>` = the first 7
characters of `T`.

## Hard rules

- **Claude writes no code in the worktree.** Not core logic, not
  skeletons, not `todo!()` stubs, not "just the plumbing". Every change in
  the worktree is typed or pasted by the developer, or comes in through a
  command the developer runs.
- **Claude runs no state-changing git command.** That includes
  `git worktree add`, `git worktree remove`, and every
  `git -C … checkout <T> -- …`. Give them as commands for the developer.
  The dog hook does not catch `git -C <path> checkout`; this rule is the
  only guard, so keep it.
- **Never copy files in with `cp`, `git show … >`, or Write.** Support
  files come in only through the developer's `git checkout <T> -- …`.
- **The real checkout is never touched.** No rewind in place, no new
  branch. Its uncommitted work stays as it is.
- **Excerpts, names and "why" come from `T`** (`git show <T>:<path>`),
  never from memory.

## Usage

- `/rewind <commit|PR|EPIC>` — start. Resolve a PR number or EPIC name to
  one commit and confirm it with the developer.
- `/rewind` — resume if a route exists (see Resuming), else ask which
  commit.
- `/rewind off` — stop early: `rm -f .claude/dog-mode`, then run Phase 7
  steps 3 to 6 for the steps done so far (the tutorial is optional; ask).
  Tell the developer the route file is still there, so a later bare
  `/rewind` will offer to pick the walk up again.

Run the session in the developer's real checkout (the project dir). All
rewind files live under `<repo>/.claude/`:

    .claude/dog-mode                    the /dog flag; the hook reads it here
    .claude/rewind/<short-T>/           the worktree at P
    .claude/rewind/<short-T>.route.md   the route, beside the worktree

## Phase 1 — Survey (read-only)

1. Resolve `T` and `P` (`git rev-parse <T>^`).
   - `T` is a merge commit → `P` = `T^1` (its first parent), so the diff
     covers the whole merge. Say so.
   - `T` is not in the local repo → stop and give the `git fetch` command.
2. Read the commit message, `git diff --stat P T`, and the full diff.
3. Read the design doc that `T` or `P` adds or names (EPIC, ADR, spec).
4. Find the order of the work, first match wins:
   1. the PR's own commits (`gh pr view <n> --json commits`), if more than
      one;
   2. the design doc's work items or phases;
   3. the order data moves through the code, deepest dependency first.
5. If a `/deconstruct` pack covers the feature (`<docs>/deconstruct/…`),
   read it. Use it for the "why", and link it from the tutorial.
6. Find the build and test commands, and how to run one test by name. See
   `~/.claude/skills/codebase-kata/references/language-harnesses.md`.

## Phase 2 — Sort the files

Put every file in the diff in one group. Sorting is per file: a support
file comes in by checking out the whole file from `T`, which overwrites
it.

- **Core** — the developer types it: files that hold the feature's rules
  and logic.
- **Support** — a copy-in command brings it in: docs, book or example
  content, lock files, config, fixtures, test-only files, assets, and
  files whose change is only wiring.
- **A file with both logic and wiring is core.** Its no-decision hunks are
  given as verbatim paste blocks.
- **Paste-block line:** a hunk is a paste block only if it makes no
  decision: a `mod` line, a `use`, a re-export, a derive, a new field or
  enum variant, a match arm that only forwards to a function. Anything
  with a branch, a loop, a computation or an error path is typed.
- **Deleted files** cannot come in with `checkout <T> -- <path>`; that
  fails on a path `T` does not have. Give the developer
  `rm .claude/rewind/<short-T>/<path>` at the step where it goes. A
  rename is a delete plus an add: sort the new path as usual.

## Phase 3 — Draft the route

Split the work into ordered steps, using the layout in
`references/route-template.md`. Each step has a **check kind**:

- `tests` — named tests that compile and pass at this step. The normal
  case.
- `compiles` — the build passes, but no test can pass until later.
- `read` — Claude checks by reading the diff.

Use `compiles` or `read` only when the real code's order forces it, and
write the reason in the route.

Order the steps so each step's tests compile at that step. If a test file
holds tests for several steps, do not check it out whole early: give that
step's test functions as paste blocks, and check out the whole file at
the last step that touches it. Tests inside a core file (a Rust
`#[cfg(test)] mod tests`) are always paste blocks.

Give every step the exact public names and signatures from `T`. Copied
tests and support files use those names, so they must match. The insides
of the functions are the developer's to write.

The route is checked by reading `T`, not by running a build. It is a
careful plan, not a proven one.

## Phase 4 — Checkpoint (the only one)

Show the developer, in one message:

- the core file list;
- the support file list, each with its step;
- the step list: title, files, and check kind for each.

Wait for approval, with any edits. Do no setup before it.

## Phase 5 — Setup, in this order

1. If `.claude/dog-mode` already exists, it is left over from an old
   `/dog` walk, and it would block step 5. Say so, ask, then run
   `rm -f .claude/dog-mode`. Step 7 turns it back on.
2. Run `git check-ignore -q .claude/rewind/x`. If `.claude/` is not
   ignored, give the developer this line to add to `.git/info/exclude`:
   `.claude/`
3. Give the developer the worktree command:

       git worktree add --detach .claude/rewind/<short-T> <P>

4. When they say it is done, check it:
   `git -C .claude/rewind/<short-T> rev-parse HEAD` must equal `P`.
5. Write the route to `.claude/rewind/<short-T>.route.md` from
   `references/route-template.md`.
6. Run the full test suite in the worktree once, so the starting state is
   known. If `P` does not build, or some tests fail, tell the developer
   which ones. Leave those tests out of every step's "Done when", and say
   so in the walk.
7. Turn dog mode on: `mkdir -p .claude && touch .claude/dog-mode`. From
   now on the hook blocks all of Claude's writes.

## Phase 6 — The walk

Each step has four beats. Give one step, then stop.

1. **Copy in.** The step's copy-in command, for the developer to run:

       git -C .claude/rewind/<short-T> checkout <T> -- <path> <path>

   Then any paste blocks: test functions and no-decision hunks, verbatim
   from `T`, each with its file and where it goes. Never put a core file
   in a copy-in command.
2. **Explain.** Which core file, where in it, what to build, and why. Give
   the exact names and signatures. Follow `/dog`'s snippet rules
   (`~/.claude/skills/dog/SKILL.md`, "The walk", step 2): a short, real,
   compilable snippet only when the syntax is not obvious, never a
   drop-in for the logic.
3. **Wait.** The developer types and says when they are done. Answer
   questions and side trips, then come back to the route.
4. **Check.** Use the step's check kind (read-only commands only). Read
   the changed files. Then:
   - **A public name or signature differs from `T`** → flag it now, and
     ask for the rename before the next copy-in, because later copied
     files use `T`'s names.
   - **Tests pass but the code is not like `T`** → show a short
     side-by-side, explain the difference, and do not ask for a change.
   - **Something is wrong** → explain why, and let the developer fix it
     (as in `/dog`, step 4).

**When a step's tests cannot pass** because the route order was wrong:
say so plainly, and tell the developer how the step changes ("this test
needs `X` from the next step; we check it there"). The route file cannot
be edited while dog mode is on, so the change lives in the conversation
and goes into the tutorial.

## Phase 7 — The end

1. Run the full test suite in the worktree.
2. Compare each core file with `T`. New files are untracked in the
   worktree and `git diff` skips them, so compare file by file:
   `diff -u <(git show <T>:<path>) .claude/rewind/<short-T>/<path>`.
   Name the differences that matter.
3. Turn dog mode off: `rm -f .claude/dog-mode`.
4. Ask whether the tutorial should include "Where my version differs".
   Then write it from `references/tutorial-template.md` to
   `<docs-dir>/walkthrough/<feature-slug>.md` **in the real checkout**,
   not the worktree. Quote `T`, not the developer's version. Pin every
   link to `T`.
5. Offer to save the developer's version before cleanup, new files
   included (dog mode is off now, so Claude may run it):

       tar -czf .claude/rewind/<short-T>.mine.tgz -C .claude/rewind/<short-T> $(git -C .claude/rewind/<short-T> ls-files -m -o --exclude-standard)
 Then give the cleanup
   command for the developer. The worktree is always dirty by now, so it
   needs `--force`, which throws the developer's version away:

       git worktree remove --force .claude/rewind/<short-T>

   The route file stays until they delete it.
6. Suggest the commit command for the tutorial; do not run it.

## Resuming

On bare `/rewind`: look for `.claude/rewind/*.route.md`. If there are
several, ask which. Then check the state before you resume:

- **The worktree is gone** (not in `git worktree list`) → the walk is
  over or was removed. Offer a fresh start from Phase 1, not a resume.
- **The tutorial already exists** at `<docs-dir>/walkthrough/` → the
  walk is done. Offer a fresh start or a tutorial refresh.
- **The walk is still open** → if `.claude/dog-mode` is missing, turn
  it back on (`mkdir -p .claude && touch .claude/dog-mode`) before
  anything else. Read the route. Work out the current step from which
  tests pass and from `git -C .claude/rewind/<short-T> status` and
  `diff`. Never trust stored progress; there is none. Say where the
  developer is, then continue with that step's first beat.

## Conduct

- Project standards apply to every step you give: the project's
  CLAUDE.md, and in Rust the user's rule that every function lives in an
  `impl` block.
- Pace like `/dog`: bigger strides if the developer is breezing through,
  smaller ones with the concept first if they struggle.
- If a tool call is denied with a 🐕 message, dog mode is on: turn what
  you were about to do into a step or a command for the developer.

## Common mistakes

| Mistake | Instead |
|---|---|
| Worktree beside the repo (`../repo-rewind`) or on a new branch | `.claude/rewind/<short-T>`, `--detach` |
| `cp` or `git show … >` to bring files in | The developer runs `git -C … checkout <T> -- …` |
| A skeleton with `todo!()` bodies written by Claude | Paste blocks for no-decision hunks; the developer types the rest |
| A step with no code ("read the design first") | Fold the reading into the first coding step's "why" |
| Tutorial in the worktree | `<docs-dir>/walkthrough/` in the real checkout |
| Tutorial quotes the developer's code | Quote `T`; differences go in "Where my version differs" |
| Starting setup before the checkpoint | Phase 4 approval first |
