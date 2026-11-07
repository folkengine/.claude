# /rewind Skill — Design

Date: 2026-11-07
Status: Approved

## Purpose

`/rewind` takes a developer back to the commit before a finished feature and
walks them through building it again, one step at a time, the way `/dog`
does: Claude guides, the developer types. At the end it writes a
step-by-step tutorial of the feature.

It combines two existing skills:

- **`/dog`** — the walk: one step, the why, wait, check. Claude writes no
  code. The dog flag and hook enforce this.
- **`/deconstruct` SPECIFIC** — reading real code and explaining it with
  excerpts and line-anchored links. `/rewind` uses that voice for the
  "why" of each step and for the tutorial.

## Who it is for

A developer who already knows the codebase but wants to understand exactly
how one feature was built, step by step. Two outcomes:

- They **grok** the feature, because they rebuilt its core by hand.
- They can **explain it to other developers**, using the tutorial.

## Goals

- Rewind to the parent of a feature commit without putting the
  developer's real checkout at risk.
- The developer types only the **core logic**. Everything else is put in
  with commands they paste.
- Every step ends with a clear, honest "done": that step's real tests pass.
- Leave a tutorial behind that someone who never did the walk can follow.

## Non-goals

- Not a kata. `/codebase-kata` makes stub code and a test harness for
  learners new to a concept. `/rewind` replays one real change in the real
  repo.
- Not a spec. `/deconstruct` and `/epic` write contracts. `/rewind` uses
  them if they exist; it does not write them.
- Not for new work. If the feature does not exist yet, use `/dog`.

## Anti-goals (it fails if it does these, even if it "works")

- Claude writes core code, or pastes a full drop-in solution for a core
  step.
- Claude runs a state-changing git command (the user's global rule).
- The developer's real checkout or uncommitted work changes.
- A step's "why" is made up instead of read from the real code, the
  commit, or its design doc.
- The developer types boilerplate (lock files, book chapters, one-line
  re-exports) instead of logic.

## Invocation

- `/rewind <commit>` — start a walk for that feature commit. A PR number
  or an EPIC name may stand in for the commit; Claude resolves it to one
  commit and confirms.
- `/rewind` (bare) — if a route exists, resume it. If not, ask which
  commit.
- `/rewind off` — stop early. Turn dog mode off and offer a tutorial of
  the steps done so far.

First test case: commit `d134f244cc9947ec50a9a5ff32153d55ed57f0be`
(EPIC-25, a REPL control) in `~/src/github.com/ImperialBower/bower`. Its
parent `78d7d17` adds only `docs/EPIC-25_Repl.md`, so the start point
already has the design doc. The PR (#23) has one commit, so the step order
must come from the EPIC's work items (Phases 0–5). A SPECIFIC deconstruct
pack for this feature exists at `docs/deconstruct/repl/`.

## The flow

### 1. Survey (dog mode off)

- Resolve the target commit `T` and its parent `P`. If `T` is a merge
  commit, use its first parent and say so.
- Read the full diff `P..T`, the commit message, and any design doc the
  commit or its parent adds or names (EPIC, ADR, spec).
- Find the original order of the work:
  1. The PR's own commits (`gh pr view <n> --json commits`), if there is
     more than one.
  2. Otherwise the design doc's work items or phases.
  3. Otherwise the order data moves through the code, deepest dependency
     first.
- If a `/deconstruct` pack covers the feature, read it. Use its epics to
  explain, and link to them from the tutorial.

### 2. Sort the files: core and support

Sort every file in the diff into one group:

- **Core** — the developer types it. Files that hold the feature's rules
  and logic.
- **Support** — put in with a command. Docs, book or example content,
  lock files, config, fixtures, test-only files, and files whose change is
  only wiring (a `mod` line, a re-export, a new enum arm with no logic).

Rules:

- Sorting is per file, because a support file is put in by checking out
  the whole file from `T`. That overwrites the file, so a support file must
  never hold changes the developer typed.
- A file with both logic and boilerplate is core. Its boring hunks are
  given as verbatim paste blocks, labelled as support (see step 6).
- **Paste-block line** (builder's call): a hunk inside a core file is a
  verbatim paste block only if it makes no decision: a `mod` line, a
  `use`, a re-export, a derive, a new field or enum variant, a match arm
  that only forwards to a function. Anything with a branch, a loop, a
  computation or an error path is typed by the developer.

### 3. Draft the route

- Split the work into ordered steps. Each step has: a title, the core
  files and the parts of them to build, the support files and tests for
  that step, the public names and signatures to use, the why (read from
  the code and the design doc, with links), and a **check kind**:
  - `tests` — named tests that compile and pass at this step (the normal
    case);
  - `compiles` — the build passes, but no test can pass until a later
    step;
  - `read` — Claude checks by reading the diff (for example, a step that
    only adds a type the next step uses).
  Prefer `tests`. Use the others only when the order of the real code
  forces it, and say why in the route.
- The route is checked by reading `T`, not by running a stubbed build.
  It is a careful plan, not a proven one; a step that turns out not to
  pass is fixed in the walk (see "When a step's tests cannot pass").

### 4. The checkpoint (the only one)

Show the developer, in one message:

- the core and support file lists;
- the step list (titles, files and check kind for each step).

Get approval (with edits) before any setup. A wrong step order costs more
than a wrong file sort, so both are approved together.

### 5. Set up (in this order)

Where things live (builder's call): the session runs in the developer's
real checkout, the project dir. Everything goes under `<repo>/.claude/`,
which the user's global gitignore already ignores, so nothing shows in
`git status` and Claude never leaves the project root.

    <repo>/.claude/dog-mode                      ← the /dog flag (hook reads it here)
    <repo>/.claude/rewind/<short-T>/             ← the worktree at P
    <repo>/.claude/rewind/<short-T>.route.md     ← the route, outside the worktree

1. Give the developer the worktree command. They run it:

       git worktree add --detach .claude/rewind/<short-T> <P>

2. Claude checks the worktree exists at `P`, then writes
   `.claude/rewind/<short-T>.route.md`. The route sits beside the
   worktree, not in it, so it is never caught in a checkout and it
   outlives `git worktree remove`.
3. Claude turns dog mode on: `mkdir -p .claude && touch .claude/dog-mode`.
   The existing hook (`~/.claude/hooks/dog-mode-guard.sh`) now blocks
   Claude from all writes.

If a `.claude/dog-mode` flag is already there before setup, say so; it may
be left over from an old `/dog` walk.

### 6. The walk (dog mode on)

Each step:

1. **Copy in.** One command for the developer to paste. It checks out
   that step's support files and test files from `T` into the worktree:

       git -C .claude/rewind/<short-T> checkout <T> -- <path> <path> …

   Tests that live inside a core file (for example a Rust
   `#[cfg(test)] mod tests` block) cannot come in that way. Claude shows
   those test functions verbatim from `T` for the developer to paste.
   Boring support hunks inside a core file come in the same way.
2. **Explain.** What to build, in which file and where, and why. Give the
   exact public names and signatures from `T`: later copied tests and
   support files use those names, so they must match. The inside of each
   function is the developer's to write. Follow `/dog`'s snippet rules:
   short, real, compilable code only when the syntax is not obvious;
   never a full drop-in for core logic.
3. **Wait.** The developer types it and says when they are done.
   Questions and side trips are part of the walk.
4. **Check.** Use the step's check kind: run its named tests, or the
   build, or read the diff (read-only commands only). Read the changed
   files and give feedback. If the tests pass but the code is not
   like `T`, show a short side-by-side and explain the difference. Do not
   ask the developer to change it.

Route rule: order the steps so that each step's tests compile and can pass
at that step. If a test file mixes tests from several steps, do not check
it out whole; paste only that step's test functions, and check out the
whole file at the last step that touches it.

**When a step's tests cannot pass** because the route order was wrong:
say so plainly, and tell the developer how the step changes (for example,
"this test needs `X` from the next step; we will check it there"). Claude
cannot edit the route file while dog mode is on, so the change is only
in the conversation, and it goes into the tutorial at the end.

### 7. The end

- Run the full test suite in the worktree.
- Show the developer's version next to `T` for the core files, file by
  file (`diff -u <(git show <T>:<path>) <worktree>/<path>`; `git diff`
  skips the new, untracked files) and name the meaningful differences.
- Turn dog mode off (`rm -f .claude/dog-mode`).
- Write the tutorial.
- Offer to save the developer's version (a tarball of modified and new
  files), then give the cleanup command for the developer to run:
  `git worktree remove --force .claude/rewind/<short-T>`. `--force` is
  needed because the worktree is always dirty by then. The route file
  stays until the developer deletes it.

(Updated after the final review: stale-flag removal at setup, failing
baseline, deleted files, resume states, and `/rewind off` cleanup are in
`SKILL.md`.)

## Resuming

On `/rewind` (bare): look for `.claude/rewind/*.route.md` in the project
dir. If there is one, read it; if there are several, ask which. Find the
current step from which tests pass and from
`git -C .claude/rewind/<short-T> status` / `diff`, say where the developer
is, and continue. Claude cannot update the route while dog mode is on, so
progress is always worked out from the worktree, never stored.

## The tutorial

- **Where:** the source repo's docs folder (detected as `/epic` does;
  default `docs/`), at `docs/walkthrough/<feature-slug>.md`. Written in the
  developer's real checkout, not the worktree, so it outlives the
  worktree.
- **Shape:** bullets first, as in `/deconstruct`.
  - A short intro: what the feature does, the commit, the design doc, the
    deconstruct pack if one exists.
  - One section per step: what was built, why, short excerpts from `T`
    with permalinks (`https://github.com/<owner>/<repo>/blob/<T>/<path>#Lx-Ly`),
    and the copy-in command for support files.
  - The questions the developer asked during the walk, with answers,
    where they are still in the conversation.
  - "Where my version differs" — optional, only if the developer wants it.
- **Links** are pinned to `T`, because the tutorial must still match the
  code after `main` moves on.

## Constraints

- **Git:** Claude never runs a state-changing git command. Worktree
  add/remove and every `checkout <T> -- …` are given as commands for the
  developer. Read-only git (`show`, `diff`, `log`, `status`) is fine.
- **Dog hook:** reused as is. No new flag, no hook change. Known gap: the
  hook's git pattern matches `git checkout` but not `git -C <path>
  checkout`. So the rule that Claude never runs the copy-in commands
  rests on `SKILL.md`, which must state it plainly.
- **Project standards** apply to every step Claude dictates (the
  project's CLAUDE.md, and the user's global rule of no free functions in
  Rust).
- **Language-agnostic:** detect the build and test commands from the
  repo, as `/codebase-kata`'s harness reference does.
- **README:** add a `rewind` link under `## Skills` in this repo's
  `README.md` (project rule).

## Known limits

- Questions asked in an earlier session may be gone by tutorial time;
  `route.md` holds the plan, not the conversation.
- The worktree reuses the main repo's git objects, so `T` must exist
  locally. If it does not, say so and give the `git fetch` command.
- Placing the worktree under `<repo>/.claude/` relies on `.claude/` being
  ignored. If a repo does not ignore it, say so at setup and give the
  developer the line to add to `.git/info/exclude`.
- The route is a plan checked by reading, not by running. Some steps may
  need to change during the walk.

## Left to the builder

- The exact layout of `route.md` and of the tutorial.
- How to detect test commands per language, and how to pick that step's
  tests (by test name, module or file).
- The heuristics that sort files into core and support, beyond the rules
  above.
- Whether `SKILL.md` keeps details in `references/` files (route template,
  tutorial template), following the other skills in this repo.
