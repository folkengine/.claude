# /balser Skill — Design

Date: 2026-08-03
Status: Approved

## Purpose

`/balser` (named for a great developer and mentor) generates a paired,
self-test style Q&A document set that helps developers understand how a
codebase works. The developer reads the questions file, attempts to answer
each question by reading the code, then checks the answers file.

## Invocation

- `/balser <topic>` — generate the pair for that topic (e.g.
  `architecture`, `flow`, `error-handling`).
- `/balser` (bare) — survey the codebase, propose 3–5 high-value topics
  chosen from what is actually non-obvious in this repo (not a fixed
  menu), and let the user pick one.
- Project-agnostic: works in any repo, any language.

## Output

Two files in the repo's docs folder (detect existing convention — `docs/`,
`doc/`, `documentation/`; default `docs/`, creating it if absent):

- `<TOPIC>_QUESTIONS.md`
- `<TOPIC>_ANSWERS.md`

Topic name is uppercased with underscores (e.g. `ERROR_HANDLING_QUESTIONS.md`).

## Content contract

### Questions file (spoiler-free)

- Opens with a short "How to use this" note: attempt each question against
  the code before opening the answers file.
- 10–15 questions in three tiers:
  1. **Foundations** — orientation questions any reader should get right
     after a first pass.
  2. **Design decisions** — why the code is shaped the way it is.
  3. **Deep cuts** — edge cases, invariants, subtle interactions.
- Every question is answerable purely by reading the code — no tribal
  knowledge required.
- Spoiler-free: a question must not restate its own answer (ask "How many
  passes does the parser make, and why?", not "Why does the parser use a
  two-pass design?"). No hints or teasers leak into the questions file.
- Carries a "last verified against commit `<sha>`" line.

### Answers file (cited)

- Mirrors the questions file's numbering exactly.
- Every answer cites `file:line` evidence and explains *why*, not just
  *what*.
- Carries the same "last verified against commit `<sha>`" line.

## Verification step

Before writing the answers file, every citation is re-checked by actually
reading the cited lines. An answer that cannot be backed by a citation is
rewritten, or its question dropped.

## Re-run behavior

If the pair already exists for a topic, refresh in place:

- Re-verify each answer's citations against current code.
- Correct stale answers; retire questions about deleted code; add
  questions for significant new code.
- Numbering may be re-sequenced. Update the verified-commit line.

## Skill structure

Approach A: single `skills/balser/SKILL.md` with the two output templates
embedded inline. No `references/` directory unless the taxonomy grows.

## Repo rules

- Add a README entry under `## Skills` (link text = skill `name`,
  description = frontmatter `description`), per project CLAUDE.md.
- The skill never runs state-changing git commands; it reads git only
  (e.g. `git rev-parse HEAD` for the verified-commit line) and hands the
  user commit commands.

## Out of scope (YAGNI)

- Subagent fan-out per subsystem.
- Grading or scoring the developer's answers (that is `/codebase-kata`
  territory).
- Fixed topic menus.
