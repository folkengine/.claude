---
name: codebase-kata
description: Turn a real codebase into a TDD-style coding kata that teaches the core technology or algorithm behind it. Use this skill whenever the user wants to create a kata, exercise, coding challenge, or training material derived from an existing codebase or library — whether they say "make a kata from this repo," "build an exercise that teaches how X works," "I want to onboard contributors to this project," or "help people learn the algorithm behind this code." Trigger this even when the user just points at a repo and says they want to teach the concepts in it, even if they don't use the word "kata." Also trigger when they want to focus on one specific area — a single rule, function, or module within a larger codebase — or to cover several related concepts together as a progression of exercises.
---

# Codebase Kata

This skill turns a real codebase into a self-contained, TDD-style kata: a learner is handed stubbed functions and a failing test suite, and they make the tests pass by re-implementing a core concept from the codebase themselves. The original implementation becomes a hidden reference solution.

The goal is to teach **the core technology behind the codebase**, not the codebase's incidental plumbing. A good kata isolates **one teachable idea per exercise** (a hand-ranking algorithm, a parser, a scheduling rule, an encoding scheme) and lets the learner rebuild it from a spec and tests.

A kata can be a single exercise, or a short **ordered series** of exercises that each isolate one idea — when the interesting concept is naturally layered. It can also zoom in on a **sub-part** of a larger unit (one rule within a ruleset) rather than a whole function. These modes are covered in Step 2; the discipline is the same in all of them — each exercise isolates exactly one idea, and a series must be a genuine progression of a related idea-family, never a grab-bag of unrelated concepts.

The audience is dual: **new contributors** to the specific codebase, and **learners** studying the underlying tech in general. The README must serve both — teach the concept from first principles for outsiders, and point to where it lives in the real repo for contributors.

## The core idea: extract, don't invent

The single most important principle: a kata must be **faithful to the real code**. You are extracting a concept that already exists and works, not inventing a plausible-looking exercise. This matters because:

- Faithful tests teach real behavior, including the edge cases the original authors actually cared about.
- A learner who finishes the kata has genuinely reconstructed a piece of the real system.
- The reference solution is real, working code, not something you wrote and hope compiles.

So: **read the source, derive the tests from the codebase's own tests and behavior, and use the real implementation as the solution.** Do not fabricate test cases from imagination when the codebase already has a test suite you can adapt.

## Workflow

### 1. Locate and read the codebase

If a repo path or URL is given, read it. If only a name is given (e.g. a GitHub repo), ask for a path/URL or clone it if network access allows. Build a quick mental model: language, build system, test framework, and the handful of modules that contain the *interesting* logic (as opposed to config, glue, or I/O).

Identify the test framework and run command up front — you'll need it for the harness. See `references/language-harnesses.md`.

### 2. Choose the scope and concept(s)

First decide the **shape** of the kata. There are three:

- **Single** (default): one concept becomes one exercise.
- **Series**: several *related* concepts become an ordered, multi-stage kata. Use this when the interesting idea is naturally layered (e.g. tokenizer → parser → evaluator, or card → rank → hand evaluation) and each layer is worth rebuilding on its own. Every stage must independently meet the selection criteria below; the stages together must form a genuine progression, not a grab-bag.
- **Sub-concept (focused)**: isolate a *sub-part* of a larger unit — one rule within a ruleset, one branch within a dispatcher, one case within a match — when the whole unit is too big but a single piece is the teachable core. This uses partial stubbing (see Step 3).

**Honor explicit user targeting.** If the user names a module, function, or rule ("make a kata for the straight-flush detection," "teach how the parser handles X"), scope directly to that and skip the broad candidate-scan. Only scan *within* the named target if a sub-concept still needs choosing.

Otherwise, scan for a unit (or, for a series, a small ordered set of units) that is:

- **Self-contained**: can be lifted out with a small, clear interface (a function or a small set of functions/types).
- **Conceptually rich**: there's a real idea to learn — an algorithm, a domain rule, a clever encoding — not just boilerplate.
- **Testable in isolation**: behavior can be pinned down with input/output assertions without standing up a database, network, or huge fixture.
- **Appropriately sized**: a focused learner should be able to finish in 30–90 minutes (per exercise — a series multiplies this across stages).

If several candidates exist, briefly list them for the user and let them pick, with a one-line "what you'd learn" for each. When the natural answer is a progression, offer the series rather than silently picking one stage. Don't silently choose when the choice is interesting.

Avoid concepts whose only difficulty is wiring (deeply entangled with framework internals, or requiring large mocked environments). Those make frustrating katas.

### 3. Extract the exercise

Create the exercise folder (see Output Structure below). Then:

- **Stub the implementation.** Keep the real signatures, type definitions, doc comments, and any types/enums the learner needs. Replace function *bodies* with a stub that compiles/parses but fails — `todo!()` in Rust, `raise NotImplementedError` in Python, `throw new Error("not implemented")` in JS/TS. The learner should be able to run the test suite immediately and see it fail for the right reason, not because of a syntax error.
- **Preserve necessary context.** Bring along the types, constants, and helper code the concept genuinely depends on, so the exercise is self-contained and compiles. Strip everything else.
- **Don't leak the answer.** Remove implementation comments that give away the algorithm step-by-step. A doc comment describing *what* a function does is good; an inline comment narrating *how* the original solved it defeats the kata.
- **For a sub-concept kata, stub partially.** When the teachable core is one rule inside a larger unit, keep the rest of the unit intact and working, and stub *only* the targeted rule/branch. The learner's edits stay confined to one place while the real surrounding code supplies realistic context. Caution: keep just enough surrounding code to make the rule exercisable — if the learner ends up wiring five collaborators, you've over-stubbed and the exercise is plumbing, not the concept. "Intact and working" means a faithful *slice*, not necessarily the literal original file: faithfulness applies to the data and behavior the rule actually observes — reproduce *that* exactly (e.g. the real constants/values it reads) — but you may simplify collaborators that merely feed it, as long as their outputs are identical.
- **For a series, extract each stage independently.** Repeat this step per stage. A later stage may reuse types or helpers from an earlier one; that's fine, but each stage's stubbed target must stand as its own exercise. Keep each stage self-contained: copy the earlier stage's solved code in as already-working context, rather than depending across crates.

### 4. Derive the tests

This is where faithfulness is won or lost.

- **Start from the codebase's own tests.** Find the existing tests covering the concept and adapt them into the kata's test suite. Translate them to run against the stubbed interface. This guarantees the tests reflect real expected behavior.
- **If the codebase has thin or no tests**, derive tests by reading the implementation carefully and capturing its actual input/output behavior, including edge cases visible in the code (boundary conditions, error handling, special-cased inputs). Note in your head that these are reconstructed, and lean conservative.
- **Order tests pedagogically.** Arrange so earlier tests exercise the simple/common path and later tests add edge cases. A learner making them pass in order experiences a natural difficulty ramp. Where the test framework supports it, group or name tests so this progression is visible.
- **For a series, order the stages too.** Each stage gets its own derived tests. Order the stages by dependency and difficulty so the whole kata is a difficulty ramp across stages, mirroring the ramp within each stage's suite. A sub-concept kata's tests should drive the stubbed rule *through* the surrounding real code, so passing them proves the rule works in context.
- **Make failures legible.** Test names and assertion messages should tell the learner what behavior is expected, not just "assertion failed."

### 5. Write the README

The README is the teaching surface. Use `references/readme-template.md` as the structure. It must:

- Explain the **concept from first principles** — enough that someone who has never seen this codebase understands what they're building and why it matters. This is what serves the "learning the underlying tech" audience.
- State the **challenge** concretely: which files to edit, how to run the tests, what "done" looks like.
- Give a **difficulty ramp / hints** section, ideally collapsible or clearly separated, so learners can self-rescue without seeing the full solution.
- Include a **"where this lives in the real codebase"** note with the original file path(s) and a sentence on how the real version differs (e.g. "the real version also handles N-card hands; here we simplify to 5"). This serves the contributor audience.

### 6. Produce the reference solution

Place the **real, original implementation** as the solution, in a location separate from the exercise (see Output Structure). Verify it actually passes the kata's test suite — if it doesn't, your extraction drifted from the source and you must reconcile before shipping. If the drift is because faithful behavior depends on a layer you deliberately excluded, don't import the plumbing or fake the assertion — scope the test to the extracted layer's real behavior and record the difference in the README's "how the real version differs" note. Add a short solution walkthrough in prose explaining the key insight, so the solution teaches and isn't just a code dump.

### 7. Verify end to end

Before presenting:

1. The stubbed exercise builds/parses and the test suite **runs and fails** (not errors out).
2. The reference solution **passes** the same test suite.
3. The run commands in the README are correct for the detected language/framework.

For a **series**, run this check for **each stage independently** — every stage's exercise must build and fail, and every stage's solution must pass. For a **sub-concept** kata, confirm the surrounding (non-stubbed) code still builds and that only the targeted rule is failing.

If you have a runtime for the language, actually execute both states. If you can't run it (e.g. language toolchain unavailable), say so explicitly to the user and ask them to run the verification, rather than claiming it works.

## Output Structure

Produce a runnable exercise folder plus a separate solution. Exact layout depends on language conventions, but follow this shape:

```
<concept-name>-kata/
├── README.md              # the teaching surface + challenge + hints
├── exercise/              # what the learner works in (runnable, tests fail)
│   ├── <stubbed source>   # real signatures, todo!()-style bodies
│   └── <tests>            # derived from the real codebase's tests
└── solution/
    ├── <real source>      # the original working implementation
    └── SOLUTION.md         # walkthrough of the key insight
```

For languages where the test runner expects a specific project layout (Cargo, npm, etc.), make `exercise/` a real buildable project so the learner can `cargo test` / `npm test` directly. See `references/language-harnesses.md` for per-language specifics.

A **sub-concept** kata uses this same single layout — only the stub is partial (the surrounding unit stays in `exercise/` intact and working; just the targeted rule is stubbed).

A **series** uses a multi-stage layout: each stage is its own self-contained `exercise/` + `solution/` pair, with one top-level README mapping the stages.

```
<topic>-kata/
├── README.md              # overview + how the stages relate + recommended order
├── stage-1-<concept>/
│   ├── exercise/          # runnable, tests fail
│   └── solution/
├── stage-2-<concept>/
│   ├── exercise/
│   └── solution/
└── ...
```

Each stage internally mirrors the single-kata shape above. The top-level README follows `references/readme-template.md` but adds a "stages" map (what each stage teaches and the order to do them in); a stage may also carry a short local note, or fold its specifics into the top-level README.

## Anti-patterns to avoid

- **Inventing tests from imagination** when the codebase has real ones to adapt. Faithfulness is the whole point.
- **Choosing a concept that's all plumbing** — if the hard part is mocking five dependencies, it's a bad kata.
- **Leaking the algorithm** in comments left in the stubs.
- **Shipping unverified** — claiming the harness works without running it (or without flagging that you couldn't).
- **A README that only makes sense to existing contributors** — remember the second audience is learning the tech cold.
- **An exercise that doesn't compile** — the learner's first action is running the tests; that must work.
- **Padding a "series" with unrelated concepts** to make it look bigger. Stages must form a genuine progression of one related idea-family; if they don't build on each other, ship separate single katas instead.
- **Over-stubbing the surrounding unit** in a sub-concept kata until it becomes a wiring exercise. Stub only the targeted rule; keep the rest of the unit working so the learner rebuilds the *concept*, not the plumbing around it.

## A note on judgment

Different codebases teach different things. A parser library teaches state machines and grammar; a poker library teaches combinatorics and ranking; a scheduler teaches constraint logic. Let the codebase's actual substance drive what the kata emphasizes. The structure above is a frame, not a cage — adapt it so the *interesting idea* in this particular codebase is what the learner ends up rebuilding.
