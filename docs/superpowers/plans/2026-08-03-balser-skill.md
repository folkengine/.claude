# /balser Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `/balser` skill that generates a paired self-test Q&A study set (`<TOPIC>_QUESTIONS.md` + `<TOPIC>_ANSWERS.md`) in a repo's docs folder.

**Architecture:** Single skill file `skills/balser/SKILL.md` (Approach A from the spec) containing the workflow and both output templates inline, plus one README index entry. No code, no `references/` directory.

**Tech Stack:** Markdown + YAML frontmatter (Claude Code skill format).

## Global Constraints

- Spec: `docs/superpowers/specs/2026-08-03-balser-skill-design.md` — the content contract there (spoiler-free tiered questions, cited answers, verified-commit line, refresh-in-place) is normative.
- Repo rule (project CLAUDE.md): every new skill gets a README `## Skills` entry — link text = skill `name`, description = frontmatter `description`, list kept alphabetical.
- User rule (global CLAUDE.md): the implementer must NOT run state-changing git commands. Read-only git is fine. Each "commit" step means: print the exact commands for the user to run themselves.
- The skill itself must also obey that rule at runtime: read-only git only (`git rev-parse HEAD`).

---

### Task 1: Author `skills/balser/SKILL.md`

**Files:**
- Create: `skills/balser/SKILL.md`

**Interfaces:**
- Produces: frontmatter `name: balser` and a `description` string that Task 2 copies verbatim into README.md.

- [ ] **Step 1: Write the skill file**

Write `skills/balser/SKILL.md` with exactly this content (frontmatter description must stay one single line in the actual file):

````markdown
---
name: balser
description: Generate a paired self-test Q&A study set — <TOPIC>_QUESTIONS.md and <TOPIC>_ANSWERS.md in the repo's docs folder — that helps developers learn how the code works by answering questions from the code before checking the answers. Named for a great developer-mentor. Use when the user types /balser or /balser <topic>, or asks for "comprehension questions about this code", "quiz me on the architecture", "Q&A docs to help developers understand the codebase", "study questions for onboarding" — even if they never say balser. Project-agnostic. Do NOT trigger for runnable TDD exercises (that is /codebase-kata) or demo runbooks (that is /presentation).
version: 1.0.0
---

# /balser — self-test Q&A study sets

Generate two files that teach a developer one aspect of the current codebase:
a spoiler-free questions file they attempt first against the code, and a
cited answers file they check themselves against afterward.

## Workflow

1. **Resolve the topic.**
   - `/balser <topic>` — use the argument (e.g. `architecture`, `flow`,
     `error-handling`, `persistence`, or a subsystem name).
   - Bare `/balser` — survey the codebase (entry points, module layout,
     README, docs folder) and propose 3–5 topics chosen from what is
     genuinely non-obvious in THIS repo — not a fixed menu. Let the user
     pick one via AskUserQuestion.

2. **Locate the docs folder.** Use the repo's existing convention
   (`docs/`, `doc/`, `documentation/`); default to `docs/`, creating it
   if absent. Target files: `<TOPIC>_QUESTIONS.md` and
   `<TOPIC>_ANSWERS.md`, topic uppercased with underscores
   (`error-handling` → `ERROR_HANDLING_QUESTIONS.md`).

3. **Study the code.** Read the parts of the codebase relevant to the
   topic before drafting anything. Note candidate evidence
   (`file:line`) as you go. Questions must be answerable purely by
   reading the code — never from tribal knowledge, git history, or
   external docs.

4. **Draft 10–15 questions in three tiers:**
   - **Foundations** — orientation any reader should get right after a
     first pass (what lives where, what calls what).
   - **Design decisions** — why the code is shaped the way it is
     (trade-offs visible in the code: chosen data structures, layering,
     invariants).
   - **Deep cuts** — edge cases, failure paths, subtle interactions.

   Questions must be spoiler-free: a question may not restate its own
   answer. Ask "How many passes does the parser make, and why?" — not
   "Why does the parser use a two-pass design?". No hints, no teasers.

5. **Write the answers, then verify every citation.** Each answer mirrors
   its question number, cites `file:line` evidence, and explains *why*,
   not just *what*. Before writing the answers file, re-read every cited
   line and confirm it supports the answer. An answer that cannot be
   backed by a citation gets rewritten, or its question dropped.

6. **Stamp both files** with `Last verified against commit <sha>` using
   `git rev-parse --short HEAD` (read-only git only — this skill never
   changes git state; hand the user commit commands at the end).

7. **Refresh mode.** If the pair already exists for the topic, refresh in
   place: re-verify every citation against current code, correct stale
   answers, retire questions about deleted code, add questions for
   significant new code, re-sequence numbering if needed, and update the
   verified-commit line.

## Questions file template

```markdown
# <Topic> — Questions

Last verified against commit `<sha>`.

**How to use this:** Answer each question by reading the code — write
your answer down before opening [<TOPIC>_ANSWERS.md](<TOPIC>_ANSWERS.md).
If you can't find where to look, that's a finding too: note it, then
check the answer's citations.

## Foundations

1. ...
2. ...

## Design decisions

6. ...

## Deep cuts

11. ...
```

## Answers file template

```markdown
# <Topic> — Answers

Last verified against commit `<sha>`.

Check these only after attempting [<TOPIC>_QUESTIONS.md](<TOPIC>_QUESTIONS.md).
Every answer cites the code so you can verify it yourself.

## Foundations

1. <answer — the *why*, not just the *what*> (`src/foo.rs:42-57`)
```

## Quality bar

- Numbering identical across the two files; every question has exactly
  one answer entry.
- Zero answer leakage into the questions file.
- Every answer carries at least one `file:line` citation that was
  re-read during step 5.
- 10–15 questions total; all three tiers populated.
````

- [ ] **Step 2: Verify the file mechanically**

Run: `head -6 skills/balser/SKILL.md` and confirm the frontmatter opens/closes with `---` and `name: balser` is present. Run: `grep -c 'QUESTIONS.md' skills/balser/SKILL.md` — expected: ≥ 4.

- [ ] **Step 3: Hand the user the commit commands (do not run them)**

```bash
git add skills/balser/SKILL.md docs/superpowers/specs/2026-08-03-balser-skill-design.md docs/superpowers/plans/2026-08-03-balser-skill.md
git commit -m "Add /balser skill: paired self-test Q&A study sets"
```

### Task 2: README index entry

**Files:**
- Modify: `README.md:6-7` (insert between `backlog` and `codebase-kata` — list is alphabetical)

**Interfaces:**
- Consumes: the exact `description` frontmatter string from Task 1.

- [ ] **Step 1: Insert the entry**

Insert after the `backlog` line:

```markdown
- [balser](skills/balser/SKILL.md) — <description string copied verbatim from skills/balser/SKILL.md frontmatter>
```

- [ ] **Step 2: Verify**

Run: `grep -n 'balser' README.md` — expected: one line, positioned between `backlog` and `codebase-kata`. Confirm the link target `skills/balser/SKILL.md` exists.

- [ ] **Step 3: Hand the user the commit commands (do not run them)**

```bash
git add README.md
git commit -m "README: index /balser skill"
```

### Task 3: Fixture smoke test

**Files:**
- Create (scratchpad only, not committed): a tiny fixture crate/module and generated `QUESTIONS`/`ANSWERS` pair under the session scratchpad directory.

**Interfaces:**
- Consumes: the workflow and templates from Task 1's SKILL.md, followed literally.

- [ ] **Step 1: Build a minimal fixture**

In the scratchpad, create `fixture/src/lib.rs` (~30 lines) with one deliberate design decision (e.g. a two-pass function) and one edge case (e.g. an early-return guard), so all three question tiers have material.

- [ ] **Step 2: Run the /balser workflow against the fixture**

Follow SKILL.md steps 1–6 with topic `architecture`, writing output to the scratchpad `fixture/docs/`.

- [ ] **Step 3: Grade the output against the quality bar**

Check: numbering mirrors across files; no answer leakage in questions; every answer cites `file:line` that actually supports it; 10–15 questions is relaxed to ≥ 6 for a 30-line fixture (note this deviation in the report). Any contract violation → fix SKILL.md wording that permitted it, and note the fix.

- [ ] **Step 4: Report results to the user** (nothing to commit — scratchpad output is disposable).
