# Design: `/smimd` — global parallelism-opportunity audit skill

**Date:** 2026-08-07
**Status:** Approved (brainstorming session, 2026-08-07)
**Deliverable:** `~/.claude/skills/smimd/` (this spec lives with the skill;
modeled on pkcore's `docs/ANALYSIS_SIMD_Opportunities.md`, where the
pattern was first worked out by hand)
**Inspiration:** [Mitchell Hashimoto, "Everyone Should Know
SIMD"](https://mitchellh.com/writing/everyone-should-know-simd)

## Purpose

A standardized, re-runnable audit that surveys a codebase's hot paths for
places where SIMD lanes, SWAR bit-tricks, MIMD/thread-level data
parallelism, or an algorithm/data-structure change would pay off, ranks
them by payoff-per-risk, and writes `PARALLELISM_AUDIT.md` to the repo's
docs folder. Analysis only — it never applies optimizations. It follows
the `/reusability` / `/untangle` house pattern: fixed method, anchored
scoring, `file:line` evidence, report refreshed in place.

**Scope decisions (settled in brainstorming):**

- **Full spectrum:** SIMD, SWAR, MIMD (rayon-style data parallelism), and
  algorithm-first alternatives. Excludes async I/O concurrency,
  distributed systems, and GPU offload.
- **Evidence — use if present:** static analysis of hot paths is the core
  method; when the repo has benchmarks or a perf harness, their results
  ground the ranking. The skill never runs long benchmarks itself unless
  asked; the report's Verification section prescribes before/after runs.
- **Structure:** `SKILL.md` + `references/pattern-catalog.md` +
  `references/report-template.md` (the reusability layout — bulky stable
  content in references, loaded only on invocation).

## Skill identity

- **Name:** `smimd` (SIMD + MIMD portmanteau).
- **Location:** `~/.claude/skills/smimd/`.
- **Triggers (description frontmatter):** `/smimd`, `/smimd <target>`, and
  phrasings like "where could SIMD help", "find vectorization
  opportunities", "can we parallelize this", "hot loop audit", "should
  this use rayon/threads", "SWAR opportunities" — even when the user never
  says smimd.
- **Do NOT trigger for:** implementing an already-identified optimization
  (regular coding), dependency entanglement (`/untangle`), API design
  (`/reusability`), kernel purity (`/domain-kernel`). Multi-session reworks
  discovered by the audit route to `/epic` as recommendations.

## Modes

| Invocation | Does |
|---|---|
| `/smimd` | Audit the whole repo's hot paths → `<docs>/PARALLELISM_AUDIT.md` |
| `/smimd <path-or-subsystem>` | Focused audit of one module/crate/pipeline; same file, scoped section |

Docs-folder detection follows the other house skills (`docs/` or wherever
design docs live).

**Re-run behavior (reusability pattern):**

- Regenerate `PARALLELISM_AUDIT.md` in place with a fresh header.
- Preserve `## Notes (human)` verbatim.
- `TODO-PAR-N` IDs are stable across runs; checked/unchecked state
  survives regeneration; retired items move to a superseded list rather
  than vanishing.
- Add a one-line `Δ` note to any finding whose tier changed since the
  previous run.
- If the repo has a prior ad-hoc analysis (e.g. pkcore's
  `ANALYSIS_SIMD_Opportunities.md`), the first run links it as a
  predecessor and carries its open TODOs forward under stable IDs instead
  of duplicating them.

## Method (SKILL.md body)

1. **Find hot paths first, opportunities second.** Evidence hierarchy:
   existing benchmark/perf-harness results > profiling artifacts >
   structural signals (innermost loops over large collections,
   per-element work, table lookups, hashing inside loops, allocation in
   loops). Every ranked opportunity names the hot path it sits in; a
   vectorizable loop that isn't hot goes to "Not worth it".
2. **Classify each candidate** against the pattern catalog:
   *algorithm-first*, *SWAR*, *SIMD*, *MIMD*, or *composition* (threads ×
   lanes). SIMD candidacy uses Hashimoto's five-step shape test:
   broadcast constants → loop one vector-width chunk at a time → lane ops
   → reduce/store → scalar tail.
3. **Ordering discipline** (the core judgment):
   - Algorithm/data-structure change beats vectorization; check it first
     (perfect hash before lane-parallel search, SoA layout before
     scattered loads).
   - Amdahl check: name the serial tail; if it dominates, SIMD on the
     rest is noise.
   - Auto-vectorization check: simple reduction loops the compiler
     already vectorizes are not findings.
   - Data-size check: lanes want thousands of elements; small-N goes to
     "Not worth it".
4. **Rank into anchored tiers**, defined once in the catalog and quoted
   per finding (anchors are the scale — never invent a scale inline):
   payoff (dominant-cost / significant / marginal) × risk (safe-stable /
   feature-gated / unsafe-or-nightly-or-big-table). No arithmetic
   headline; the TL;DR is a prose verdict.
5. **Emit the report** from the template. Every claim cited as
   `file:line`; benchmark numbers included when the repo has them.
   Mandatory sections: **"Not worth it"** and **Verification**
   (output-invariance tests — bit-identical results; before/after
   benchmark runs per TODO; feature-gating — scalar path stays default
   until benchmarks justify flipping).

## `references/pattern-catalog.md`

Opens with the link to Hashimoto's article and his framing — "every
developer should be able to recognize the opportunity" — as the mission
statement. Contents:

- **Per-class entries** (algorithm-first, SWAR, SIMD, MIMD, composition):
  what the shape looks like, mechanical grep signals, canonical
  transforms (Eytzinger layout, perfect hash, `u64` bitmask,
  `wide`/`core::simd`, rayon/structured concurrency), and each class's
  classic trap (SIMD-ing a data-dependent search; MIMD-ing loops with
  shared mutable state; SWAR overflow across packed fields).
- **Payoff/risk anchor tables** used for ranking.
- **Rust-first tactics with carry-over notes** for other ecosystems:
  C/C++/Zig (intrinsics, `std.simd`), Go (limited lane story, goroutine
  chunking), Python (the "NumPy question": is scalar Python looping over
  data a vectorized library should own?). Method is language-agnostic;
  tactics are swapped; thinner tooling is stated in the report rather
  than silently skipped.

## `references/report-template.md`

`PARALLELISM_AUDIT.md` skeleton, structurally matching
`ANALYSIS_SIMD_Opportunities.md`:

1. Header — date, files surveyed, companion docs, evidence sources used
   (benchmarks / profiles / structural-only).
2. TL;DR — prose verdict naming the few real targets.
3. Current-architecture sketch of the hot paths.
4. Ranked opportunity dossiers — class, tier + quoted anchor, evidence,
   recommended transform, and explicit "what beats what" ordering.
5. "Not worth it" — REQUIRED, with reasons.
6. Decision-point items — "this is a decision, not code" entries (e.g.
   pkcore's 2+2/DAG evaluator) with what would trigger them.
7. `TODO-PAR-N` checklist ordered by payoff per unit of risk.
8. Verification — invariance tests, benchmark procedure, feature-gate
   policy.
9. `## Notes (human)` — preserved verbatim.

## Common-mistakes table (SKILL.md closer)

| Mistake | Fix |
|---|---|
| Recommending SIMD before the algorithm-first check | Data-structure change is checked first, always |
| Ranking a loop nobody proved hot | Every finding names its hot path and evidence tier |
| New filename per run | Always `PARALLELISM_AUDIT.md`, refreshed in place |
| Vague payoff claims | Quote the matched anchor; cite `file:line` |
| Nightly/unsafe recommendation when a stable equivalent exists | Stable-safe path first; gate the rest |
| Dropping human notes on regeneration | `## Notes (human)` preserved verbatim, always |
| Skipping the "Not worth it" section | It is REQUIRED — restraint is a finding |
| Applying optimizations during the audit | Analysis only; implementation is a separate task/epic |

## Implementation plan

Implemented via `superpowers:writing-skills` (the specific skill for
authoring skills), producing:

```
~/.claude/skills/smimd/
├── SKILL.md                      # triggers, modes, method, mistakes table
└── references/
    ├── pattern-catalog.md        # taxonomy, signals, anchors, ecosystems
    └── report-template.md        # PARALLELISM_AUDIT.md skeleton
```

Verification: dry-read the skill as if triggered cold; sanity-check that
running it against pkcore would reproduce the substance of
`ANALYSIS_SIMD_Opportunities.md` (same three real targets, same
algorithm-first ordering, PRODUCTS/bitmask items ranked above the SIMD
items, 2+2 evaluator as a decision point).
