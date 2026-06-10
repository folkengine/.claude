# README template for a codebase kata

Use this as the structure for the kata's `README.md`. Adapt headings to fit, but keep all the sections — each one serves a purpose and one of the two audiences (learners new to the tech, or contributors new to the repo).

```markdown
# <Concept Name> Kata

> Reconstruct <one-line description of what they'll build> by making a failing
> test suite pass.

## What you'll learn

<2–4 sentences explaining the concept FROM FIRST PRINCIPLES. Assume the reader
has never seen this codebase and may not know the domain. This is the section
that teaches the underlying tech. Explain *why* the concept matters and what
makes it interesting, not just what it is.>

## The challenge

You've been given <files> with the implementation removed — the function
bodies are stubbed out and the tests are failing. Your job is to implement
<the thing> so that all the tests pass.

- **Edit:** `<path to stubbed file(s)>`
- **Don't edit:** the test file (that's your spec)
- **Run the tests:** `<exact command, e.g. cargo test>`

When every test is green, you've rebuilt <the concept>.

## Getting started

<Setup steps: install toolchain if needed, cd into exercise/, run tests to see
them fail. Show the expected initial failing output so the learner knows they're
set up correctly.>

## How to approach it

Work through the tests in order — they're arranged from the simplest case to
the trickiest edge cases. Start by getting the first test green, then move down.

<Optionally: a sentence on the recommended strategy for this specific concept.>

## Hints

<Progressive hints, most-oblique first. Keep them behind a collapsible block or
clearly separated so a learner can choose not to look. Aim for 2–4 hints that
unstick without solving.>

<details>
<summary>Hint 1</summary>
<gentle nudge toward the core idea>
</details>

<details>
<summary>Hint 2</summary>
<more concrete pointer>
</details>

## Where this lives in the real codebase

This kata is extracted from [`<repo>`](<url if known>):

- Original implementation: `<real path>`
- Original tests: `<real path>`

**How the real version differs:** <one or two sentences. e.g. "The production
version also handles 6- and 7-card hands and caches results; this kata
simplifies to the 5-card case to keep the focus on the ranking logic.">

If you're here to contribute to the project, finishing this kata means you
understand <the concept> well enough to work on `<area>`.

## Solution

A reference solution and a walkthrough of the key insight live in
`../solution/`. Try to finish (or get thoroughly stuck) before looking.
```

## Notes on tone

- The "What you'll learn" section is the most important for the learner audience. Spend real effort here. A kata whose README just says "implement these functions" teaches mechanics but not understanding.
- The "Where this lives" section is the bridge for the contributor audience. Always include the real paths, even if the URL is unknown.
- Keep hints genuinely progressive. The first hint should be almost philosophical; the last can name the data structure or algorithm.

## For a multi-stage (series) kata

When the kata is an ordered **series** of stages (see the skill's Output
Structure), the top-level `README.md` orients the whole series; each stage's
specifics can live in a short per-stage README or fold into the top one. Add a
**stages map** after "What you'll learn" so the learner knows the path and order:

```markdown
## Stages

Work the stages in order — each builds on the last.

1. **`stage-1-<concept>/`** — <what you rebuild and why it comes first>
2. **`stage-2-<concept>/`** — <what it adds, and which earlier stage it depends on>
3. ...

Each stage is its own `exercise/` + `solution/` pair with its own failing tests;
`cd` into a stage and run its test command to begin.
```

Keep the per-stage sections (challenge, getting started, hints, where-this-lives,
solution) scoped to that stage — either in the stage's own README or as clearly
labelled subsections under each stage in the top-level file.
