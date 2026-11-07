# /rewind Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Also use superpowers:writing-skills while authoring `SKILL.md`.

**Goal:** Add a `/rewind` skill that rewinds a repo to the commit before a finished feature, walks the developer through rebuilding its core logic by hand (dog-style), and ends with a step-by-step tutorial.

**Architecture:** `skills/rewind/SKILL.md` holds the workflow (survey → sort → route → checkpoint → setup → walk → end → tutorial). Two reference templates hold the file layouts: `references/route-template.md` and `references/tutorial-template.md`. It reuses `/dog`'s flag file and hook unchanged. Plus one README entry.

**Tech Stack:** Markdown + YAML frontmatter (Claude Code skill format). Read-only git and `gh` at runtime.

**Spec:** `docs/superpowers/specs/2026-11-07-rewind-skill-design.md` (normative; read it in full before any task).

## Global Constraints

- **User git rule (implementer):** never run a state-changing git command. Each "commit" step means: print the exact commands for the user to run.
- **User git rule (the skill at runtime):** `SKILL.md` must say that Claude never runs `git worktree add/remove` or any `git … checkout <T> -- …`. It gives them as commands for the developer. The dog hook does not catch `git -C <path> checkout`, so this sentence is the only guard.
- **Dog hook:** reuse `~/.claude/hooks/dog-mode-guard.sh` and the flag `<project>/.claude/dog-mode` as is. No hook change, no new flag.
- **Paths at runtime:** worktree `<repo>/.claude/rewind/<short-T>/`, route `<repo>/.claude/rewind/<short-T>.route.md`, tutorial `<docs-dir>/walkthrough/<feature-slug>.md` in the real checkout. `<short-T>` = 7-char SHA.
- **Frontmatter:** quote the `description` value in double quotes. It contains `: `, and an unquoted value breaks the YAML (the codify sync bug).
- **Repo rule:** add a README `## Skills` entry; link text `rewind`, description copied verbatim from frontmatter (unescaped), list kept alphabetical (after `quality-commitments`, before `schenk`).
- **Sync:** after the skill lands, the user runs `bin/push` to install it into `~/.claude/skills/`.

## Review Focus

1. **Stale dog flag.** `bower` has a `.claude/dog-mode` flag today. Expected: setup notices a flag already present and says so before going on. (Task 4, check R1.)
2. **A support path that is also core.** Expected: no copy-in command ever names a core file, because a checkout overwrites the developer's typing. (Task 4, check R2.)
3. **A public name that does not match `T`.** The developer names a function differently. Expected: the check step flags it before the next copy-in, because copied tests and support files use `T`'s names. (Task 3 text; Task 4, check R3.)
4. **`T` is a merge commit, or not in the local repo.** Expected: use the first parent and say so; or stop and give the `git fetch` command. (Task 3 text; Task 4, check R4.)
5. **`.claude/` not ignored in the target repo.** Expected: setup says so and gives the `.git/info/exclude` line. (Task 3 text; Task 4, check R5.)

---

### Task 1: Route template

**Files:**
- Create: `skills/rewind/references/route-template.md`

**Interfaces:**
- Produces: the route file layout that `SKILL.md` (Task 3) tells Claude to fill at setup and to read on resume. Section names below are fixed; Task 3 and Task 4 refer to them.

- [ ] **Step 1: Write the template**

It is a fill-in markdown file with these parts, in order:
- Header bullets: `Repo`, `Target (T)` (full SHA + subject), `Parent (P)`, `Worktree` (path), `Design doc` (path or none), `Deconstruct pack` (path or none), `Order source` (one of: PR commits / design doc work items / data flow).
- `## Core files` — one bullet per path, with one line on why it is core.
- `## Support files` — one bullet per path, with the step number that brings it in.
- `## Steps` — one `### Step N — <title>` per step, each with these bullets: `Check kind` (`tests` | `compiles` | `read`, plus why if not `tests`), `Copy in` (the exact `git -C .claude/rewind/<short-T> checkout <T> -- …` command, or "none"), `Paste` (test functions or no-decision hunks to paste, by file and symbol), `Build` (core file + location + what to write), `Names` (exact public signatures from `T`), `Why` (2–5 bullets with permalinks into `T`), `Done when` (test names, or the build command, or what to read).

- [ ] **Step 2: Verify**

Run: `grep -c '^## \|^### ' skills/rewind/references/route-template.md`
Expected: at least 4 (`## Core files`, `## Support files`, `## Steps`, `### Step N`).

---

### Task 2: Tutorial template

**Files:**
- Create: `skills/rewind/references/tutorial-template.md`

**Interfaces:**
- Produces: the tutorial layout that `SKILL.md` (Task 3) tells Claude to write at the end.

- [ ] **Step 1: Write the template**

Bullets first (the `/deconstruct` writing shape). Parts, in order:
- `# Rebuilding <feature>` and an intro of bullets: what the feature does, `T` as a GitHub permalink (`https://github.com/<owner>/<repo>/commit/<T>`), the design doc, the deconstruct pack if any.
- `## Before you start` — the worktree command and how to run the tests.
- `## Step N — <title>`, one per step: what was built, why (bullets), short excerpts from `T` (under 25 lines, copied from `T`, never from memory) each with a permalink `…/blob/<T>/<path>#Lx-Ly`, and the copy-in command.
- `## Questions from the walk` — Q/A bullets, only those still in the conversation.
- `## Where my version differs` — optional; only if the developer asked for it.

- [ ] **Step 2: Verify**

Run: `grep -n 'blob/<T>' skills/rewind/references/tutorial-template.md`
Expected: at least one line. Links are pinned to `T`, not to a branch.

---

### Task 3: `SKILL.md`

**Files:**
- Create: `skills/rewind/SKILL.md`

**Interfaces:**
- Consumes: the section names of Task 1 and Task 2.
- Produces: frontmatter `name: rewind` and the `description` that Task 5 copies into README.md.

- [ ] **Step 1: Write the frontmatter, exactly**

```yaml
---
name: rewind
description: "Rewind a repo to the commit before a finished feature and walk the developer through rebuilding its core logic by hand, dog-style — Claude explains and checks each step, the developer types. Support files and the real tests come in through git commands the developer pastes, and the walk ends with a step-by-step tutorial in the docs folder. Use when the user types `/rewind <commit|PR|EPIC>`, `/rewind`, or `/rewind off`, or asks to 'replay how this feature was built', 'walk me through rebuilding this commit', 'rewind to before this feature', or 'let me re-implement this PR step by step' — even if they never say rewind. Do NOT trigger for new work (/dog), stub-and-test exercises (/codebase-kata), or written explainers with no walk (/deconstruct specific)."
version: 1.0.0
---
```

- [ ] **Step 2: Write the body**

Sections, in order. Each one states the rule from the spec section named; do not copy the spec's reasoning in full.
- **Intro** — two lines: what `/rewind` is, and that it combines `/dog` (the walk) and `/deconstruct` SPECIFIC (the code-grounded why). Spec: Purpose.
- **Usage** — `/rewind <commit|PR|EPIC>`, bare `/rewind` (resume or ask), `/rewind off`. Spec: Invocation.
- **Hard rules** (near the top, bold): Claude never writes core code or a drop-in for it; Claude never runs a state-changing git command, including `git -C … checkout` and `git worktree add/remove`; the real checkout and its uncommitted work are never touched. Spec: Anti-goals, Constraints.
- **Phase 1 — Survey.** Resolve `T` and `P`. If `T` is a merge, use the first parent and say so. If `T` is not local, stop and give `git fetch`. Order source priority: PR commits (`gh pr view <n> --json commits`) if more than one → design doc work items → data flow. Read any deconstruct pack. Detect the build and test commands from the repo (point to `~/.claude/skills/codebase-kata/references/language-harnesses.md`). Spec: flow §1, Constraints (language-agnostic).
- **Phase 2 — Sort.** Core vs support rules, per file, a mixed file is core, and the paste-block line. Spec: flow §2.
- **Phase 3 — Route.** Steps and check kinds. Order so each step's tests compile at that step; mixed test files are pasted per step and checked out whole at their last step. Spec: flow §3, walk route rule.
- **Phase 4 — Checkpoint.** One message: core list, support list, step list. Approval gates setup. Spec: flow §4.
- **Phase 5 — Setup.** Check for an existing `.claude/dog-mode` flag and say so. Check `git check-ignore -q .claude/rewind/x`; if not ignored, give the `.git/info/exclude` line. Give the worktree command → verify the worktree is at `P` → write the route from `references/route-template.md` → `mkdir -p .claude && touch .claude/dog-mode`. Spec: flow §5.
- **Phase 6 — The walk.** The four beats (copy in, explain, wait, check). Follow `/dog`'s snippet rules (point to `~/.claude/skills/dog/SKILL.md`, "The walk" step 2). At check: if a public name differs from `T`, flag it before the next copy-in. If tests pass but the code differs from `T`, show a short side-by-side and do not ask for a change. "When a step's tests cannot pass": say so, adjust in chat. Spec: flow §6.
- **Phase 7 — The end.** Full test suite, `git -C … diff <T> -- <core files>`, `rm -f .claude/dog-mode`, tutorial from `references/tutorial-template.md` at `<docs-dir>/walkthrough/<feature-slug>.md`, then the cleanup command. Spec: flow §7, The tutorial.
- **Resuming.** Find `.claude/rewind/*.route.md`; if several, ask; work out the step from the worktree state, never from stored progress. Spec: Resuming.
- **Conduct.** Project standards (project CLAUDE.md, the no-free-functions rule in Rust) apply to every dictated step. Pace like `/dog`.

- [ ] **Step 3: Verify the frontmatter parses**

Run: `ruby -ryaml -e 'f=File.read("skills/rewind/SKILL.md"); y=YAML.safe_load(f.split(/^---$/)[1]); puts y["name"]; puts y["description"].length'`
Expected: `rewind` and a number above 500. No `Psych::SyntaxError`.

- [ ] **Step 4: Verify the hard rules are present**

Run: `grep -n 'git -C\|worktree add\|never' skills/rewind/SKILL.md`
Expected: lines covering all three hard rules, and the `git -C … checkout` ban by name.

---

### Task 4: Dry-run test on EPIC-25

**Files:**
- Create (scratchpad only, not in the repo): the dry-run output.

**Interfaces:**
- Consumes: `skills/rewind/SKILL.md` and its references.

- [ ] **Step 1: Run Phases 1–4 read-only**

Dispatch a fresh subagent. Prompt: "Read `/Users/christoph/src/github.com/folkengine/.claude/skills/rewind/SKILL.md` and its references. Act as that skill for `/rewind d134f244cc9947ec50a9a5ff32153d55ed57f0be` in `~/src/github.com/ImperialBower/bower`, Phases 1 to 4 only. Do not write files in that repo, do not run state-changing git, do not set the dog flag. Return the checkpoint message you would show the developer, plus the route file you would write after approval."

- [ ] **Step 2: Check the output against this rubric**

Each line must hold. If one fails, fix `SKILL.md` and rerun Step 1.
- Order source is the EPIC-25 work items (Phases 0–5), because PR #23 has one commit.
- `bower/src/repl.rs`, `bower-core/src/plan.rs`, and `bower/src/verify.rs` are core. `books/hello-playbook/src/ch08-talk-to-it.md`, `bower.lock`, `BACKLOG.md`, and `SUMMARY.md` are support.
- Every step has a check kind; any non-`tests` kind has a reason.
- **R2:** no path appears in both a copy-in command and the core list.
- Every copy-in command has the form `git -C .claude/rewind/d134f24 checkout d134f244… -- …`.
- Every step names public signatures copied from `T`.
- Every `Why` link is a permalink to `T`.
- **R1:** the output mentions the existing `bower/.claude/dog-mode` flag (it is there today).
- **R4:** the output says how it resolved `T` (not a merge; present locally).
- **R5:** the output reports that `.claude/` is ignored (global gitignore).

- [ ] **Step 3: R3 spot check**

Ask the same subagent (SendMessage): "At step 2 the developer named the main function `parse_repl` instead of the name in `T`. What do you say at the check?" Expected: it flags the mismatch and asks for the rename before the next copy-in, and explains that later copied files use `T`'s name.

---

### Task 5: README entry and hand-off

**Files:**
- Modify: `README.md` (`## Skills` list, between `quality-commitments` and `schenk`)

- [ ] **Step 1: Add the line**

`- [rewind](skills/rewind/SKILL.md) — <description from Task 3, without the outer quotes>`

- [ ] **Step 2: Verify**

Run: `grep -n '^- \[' README.md | sed -n '/quality-commitments/,/schenk/p'`
Expected: three lines, `rewind` in the middle.

- [ ] **Step 3: Commit and install (the user runs these)**

```bash
git add skills/rewind README.md docs/superpowers/specs/2026-11-07-rewind-skill-design.md docs/superpowers/plans/2026-11-07-rewind-skill.md
git commit -m "rewind: replay a feature commit as a dog-style walk with a tutorial"
bin/push
```

- [ ] **Step 4: Live test (the user)**

In `~/src/github.com/ImperialBower/bower`, run `/rewind d134f244` and walk at least the first two steps. That is the acceptance test.
