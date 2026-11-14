---
name: twice
description: Turn a mistake that has happened twice into a guardrail, choosing the most deterministic check that can catch it — a type, a lint, a test, a CI check, a Claude Code hook — and falling back to a CLAUDE.md line only when nothing mechanical can. Use when the user types `/twice <mistake>` or says "that's the second time", "this keeps happening", "you did it again", "make sure this can't happen again", "add a guardrail for this", "can a lint catch this" — even if they never say twice. Do NOT trigger for fixing a single bug (regular coding), a team defect retrospective or matrix update (/quality-commitments), an inventory of outstanding work (/backlog), or switching the push review gate (/slop-guard).
version: 1.0.0
---

# /twice

A mistake made once gets fixed. A mistake made twice means the system allows it, and fixing the output a second time only schedules the third. This skill fixes the system: it finds what let the mistake through and adds the cheapest guardrail that catches the whole class next time, without a person or a model having to remember.

The bias throughout is **mechanical over remembered**. Anything a compiler, linter, test, or script can catch, it should catch. A rule written in prose is the last resort: it can be ignored, and it costs context in every session whether or not it is needed.

## Method

1. **Name the class, not the instance.** "The handler panicked on a missing header" is an instance. "Library code calls `unwrap()` on input it does not control" is a class. Write the class in one sentence; everything after is measured against it. Too narrow and the guardrail misses the third occurrence. Too broad and it cries wolf until someone turns it off.

2. **Show both occurrences.** Find the two or more times it happened, each with evidence: this conversation, `git log -S` or `--grep` for earlier fixes of the same thing, review comments, an existing rule that already forbids it. Cite a commit, a file:line, or a quote for each. If you can find only one, say so and stop at fixing the instance. A guardrail built on one occurrence is a guess about the future. The user can overrule this; if they do, build it and say in the report that it rests on one occurrence.

3. **Find what let it through.** Ask why the system allowed it, never who made it. The usual answers: nothing checks it; a check exists but does not run where the mistake is made (only in CI, only on some paths); the design invites it (a misleading name, a wrong default, two ways to do one thing); the rule exists only in prose.

4. **Start at rung 0 and stop at the first rung that holds.**

   | Rung | Guardrail | Fits when |
   |---|---|---|
   | 0 | **Remove the possibility.** Delete or rename the footgun; tighten the type (newtype, private constructor, exhaustive enum, `#[must_use]`) | The mistake is a misuse the design permits. Nothing to run, nothing to remember |
   | 1 | **Compiler or linter configuration.** A `deny` lint, clippy's `disallowed-methods` or `disallowed-types`, a strict compiler flag, an ESLint rule, `cargo deny` | A tool already in the build knows how to see it |
   | 2 | **A test.** A regression, doc, or property test that fails on the mistake | It is wrong behaviour, not a wrong construct |
   | 3 | **A scripted check.** A small script wired into the repo's existing lint or CI entry point | It is a pattern across files that no linter models: an import in the wrong direction, a doc out of step with the code, a missing changelog line |
   | 4 | **A Claude Code hook.** `PreToolUse`, `PostToolUse`, or `Stop` | The mistake is in what the agent does, not in what the code says: a command it should not run, a generated file it should not edit, finishing without running the tests |
   | 5 | **Prose.** One line in `CLAUDE.md`, or an edit to a skill | It needs judgment that nothing above can exercise |

   Say in one line why each rung above your choice does not work. If a prose rule for this already exists and was broken, rung 5 has been tried: go higher.

5. **Put it where the mistake happens.** A repo-specific mistake is guarded in that repo. Agent behaviour that follows the user across repos is guarded in their Claude configuration (a hook, the global `CLAUDE.md`, or a skill). Use the entry points the repo already has, such as its Makefile, justfile, CI workflow, or lint config. Do not add a second way to run checks.

   Ask before changing anything outside the current repository, adding a hook, or making a CI check required. Those bind every session or every contributor, so they are the user's call.

6. **Watch it fail.** Reintroduce the mistake in a scratch edit or a fixture and show the guardrail catching it. Then show it passing on the corrected code, and revert the scratch edit. A guardrail that has never been seen to fail is a hope.

   Then run it over the whole codebase. Existing violations are fixed now or, when there are too many, listed by name as a baseline with the count stated. Never leave a check that is red on arrival, and never widen an allowlist until the check goes green.

7. **Subtract.** If the guardrail makes a prose rule, a comment, a review-checklist item, or an older and weaker check redundant, delete it in the same change. Guardrails compound like everything else, and the set should not only grow.

8. **Leave the why at the guardrail.** One comment line where it lives: the class it catches, and that it was added after a second occurrence. No new ledger document. That line and the commit message are the record. Leave the change uncommitted for the human to read unless they asked for a commit.

If the repository keeps a Quality Commitments Matrix, say that the guardrail may deserve a row there. Updating the matrix is `/quality-commitments`' job, not this skill's.

## Report

In the conversation, in this order, and short:

1. **The class** — one sentence.
2. **The occurrences** — each with its evidence.
3. **The guardrail** — which rung, where it lives, and why not a higher one.
4. **Proof** — the output of it failing on the reintroduced mistake, then passing.
5. **Removed** — what it made redundant, or "nothing".
6. **Still uncaught** — the part of the class the guardrail cannot see. There usually is one. Name it.

## Common mistakes

| Mistake | Fix |
|---|---|
| Reaching for a `CLAUDE.md` line first | Start at rung 0. Prose is where you land once everything mechanical is ruled out, with reasons |
| Guarding the instance | Restate the class, then test the guardrail against a *different* example of it |
| Building on one occurrence | Fix the instance and stop, unless the user overrules |
| A guardrail never seen failing | Reintroduce the mistake and paste the failure |
| A check that is red on arrival, or green only through a broad allowlist | Fix the existing violations, or baseline them by name with a count |
| A new script nobody runs | Wire it into the entry point CI and people already use |
| Only ever adding | Delete what the guardrail supersedes in the same change |
| Asking who made the mistake | Ask what let it through |
| A hook, global rule, or required CI check added without asking | Anything that binds every session or contributor is the user's call |
