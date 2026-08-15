---
name: qanda
description: Generate a paired self-test Q&A study set — <TOPIC>_QUESTIONS.md and <TOPIC>_ANSWERS.md in the repo's docs folder — that helps developers learn how the code works by answering questions from the code before checking the answers. Use when the user types /qanda or /qanda <topic>, or asks for "comprehension questions about this code", "quiz me on the architecture", "Q&A docs to help developers understand the codebase", "study questions for onboarding" — even if they never say qanda. Project-agnostic. Do NOT trigger for runnable TDD exercises (that is /codebase-kata) or demo runbooks (that is /presentation).
version: 1.0.0
---

# /qanda — self-test Q&A study sets

Generate two files that teach a developer one aspect of the current
codebase: a spoiler-free questions file they attempt first against the
code, and a cited answers file they check themselves against afterward.
The split is the point — a learner must be able to read the questions
file without learning any answers from it.

## Workflow

1. **Resolve the topic.**
   - `/qanda <topic>` — use the argument (e.g. `architecture`, `flow`,
     `error-handling`, `persistence`, or a subsystem name).
   - Bare `/qanda` — survey the codebase (entry points, module layout,
     README, docs folder) and propose 3–5 topics chosen from what is
     genuinely non-obvious in THIS repo — not a fixed menu. Let the user
     pick one via AskUserQuestion.

2. **Locate the docs folder.** Use the repo's existing convention
   (`docs/`, `doc/`, `documentation/`); default to `docs/`, creating it
   if absent. Target files: `<TOPIC>_QUESTIONS.md` and
   `<TOPIC>_ANSWERS.md`, topic uppercased with underscores
   (`error-handling` → `ERROR_HANDLING_QUESTIONS.md`).

3. **Study the code.** Read the parts of the codebase relevant to the
   topic before drafting anything, noting candidate evidence
   (`file:line`) as you go. Questions must be answerable purely by
   reading the code — never from tribal knowledge, git history, or
   external docs.

4. **Draft 10–15 questions in three tiers** (these three tier headings,
   in this order, are the questions file's section structure):
   - **Foundations** — orientation any reader should get right after a
     first pass (what lives where, what calls what).
   - **Design decisions** — why the code is shaped the way it is:
     trade-offs visible in the code such as chosen data structures,
     layering, invariants, error strategy.
   - **Deep cuts** — edge cases, failure paths, subtle interactions.

   **Spoiler-free questions.** A question names *where to look* and
   *what to figure out* — never the mechanism, count, or property that
   is the answer. Write the answer first, then strip every fact of it
   back out of the question:
   - Leaky: "Why is the evaluator organized as a two-pass pipeline?"
     (the answer — that there are two passes — is in the question)
   - Sealed: "How many passes does `eval` make over the input, and what
     does each produce?"

5. **Write the answers, then verify every citation.** Each answer
   mirrors its question number, cites `file:line` evidence, and explains
   *why*, not just *what*. Before writing the answers file, re-read
   every cited line and confirm it supports the answer. An answer that
   cannot be backed by a citation gets rewritten, or its question
   dropped.

6. **Stamp both files** with `Last verified against commit <sha>` using
   `git rev-parse --short HEAD` (read-only git only — this skill never
   changes git state; hand the user commit commands at the end). If the
   repo has no commits, stamp with the date instead.

7. **Refresh mode.** If the pair already exists for the topic, refresh
   in place: re-verify every citation against current code, correct
   stale answers, retire questions about deleted code, add questions for
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

## Design decisions

6. ...

## Deep cuts

11. ...
```

## Answers file template

```markdown
# <Topic> — Answers

Last verified against commit `<sha>`.

Check these only after attempting
[<TOPIC>_QUESTIONS.md](<TOPIC>_QUESTIONS.md). Every answer cites the
code so you can verify it yourself.

## Foundations

1. <answer — the *why*, not just the *what*> (`src/foo.rs:42-57`)
```

## Quality bar

Before delivering, check each item against the generated pair:

- [ ] Numbering identical across the two files; every question has
      exactly one answer entry.
- [ ] Zero answer leakage: for each question, none of the facts stated
      in its answer appear in the question's own wording.
- [ ] Every answer carries at least one `file:line` citation that was
      re-read during step 5.
- [ ] 10–15 questions; all three tiers populated (scale down
      proportionally only if the topic's code is very small).
- [ ] Questions file opens with the "How to use this" note.
