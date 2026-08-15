---
name: smimd
description: Evaluate a codebase for parallelism opportunities — SIMD lanes, SWAR bit-tricks, MIMD/thread-level data parallelism, and the algorithm or data-structure changes that beat all three — ranked by payoff-per-risk against fixed anchors and written as a standardized, re-runnable audit in the repo's docs folder (PARALLELISM_AUDIT.md). Use when the user types `/smimd` or `/smimd <target>`, or asks "where could SIMD help", "find vectorization opportunities", "can we parallelize this", "hot loop audit", "should this use rayon/threads", "SWAR opportunities", "why is this loop slow / can it go wide" — even if they never say smimd. Do NOT trigger for implementing an already-identified optimization (regular coding), dependency entanglement (/untangle), API design (/reusability), or kernel purity (/domain-kernel). Analysis only — never applies optimizations.
---

# /smimd

Survey a codebase's hot paths for places where SIMD, SWAR, MIMD, or — just
as importantly — an algorithm/data-structure change would pay off, and
write the findings as a standardized audit. The question the audit
answers: **where would going parallel actually pay, and what cheaper
change beats it there?**

Inspired by Mitchell Hashimoto's
["Everyone Should Know SIMD"](https://mitchellh.com/writing/everyone-should-know-simd)
— "every developer should be able to recognize the opportunity." This
skill turns that recognition into a repeatable audit.

Three guiding principles:

- **Hot paths first, opportunities second.** Every finding names the hot
  path it sits in and the evidence tier that makes it hot (benchmark >
  profile > structural signal). A vectorizable loop nobody proved hot is
  a "Not worth it" entry, not a finding.
- **Algorithm beats lanes.** Before recommending vectorization, check
  whether a data-structure or algorithmic change wins outright (perfect
  hash before lane-parallel search, SoA layout before scattered loads).
  The ordering discipline in the Method section is mandatory per finding.
- **Anchored tiers, not ad-hoc scales.** Findings are ranked payoff ×
  risk against the fixed anchor tables in
  `references/pattern-catalog.md`; quote the matched anchors next to each
  finding. Never invent a per-run scale (P1/P2/... by gut feel) — anchors
  are what make consecutive audits diffable. No arithmetic headline; the
  TL;DR is a prose verdict.

Read `references/pattern-catalog.md` before the first audit in a session.

## Modes

| Invocation | Does |
|---|---|
| `/smimd` | Audit the whole repo's hot paths → `<docs>/PARALLELISM_AUDIT.md` |
| `/smimd <path-or-subsystem>` | Focused audit of one module/crate/pipeline; same file, scoped section |

Detect the repo's docs folder the way the other house skills do (`docs/`
or wherever existing design docs live). The audit **refreshes
`PARALLELISM_AUDIT.md` in place** — regenerate each run with a fresh
header, preserve any `## Notes (human)` section verbatim, keep
`TODO-PAR-N` IDs stable across runs (checked/unchecked state survives;
retired items move to a Superseded list rather than vanishing), and add a
one-line `Δ` note to any finding whose tier changed since the last run.

**Predecessor docs:** if the repo already has an ad-hoc parallelism
analysis (e.g. an `ANALYSIS_SIMD*.md`), the first run links it as a
predecessor and carries its open TODOs forward under stable `TODO-PAR-N`
IDs instead of duplicating them. A predecessor item that is
decision-shaped (big table, architecture swap) carries into Decision
points, not the TODO list — record the mapping in the Predecessor header
line and note it under Superseded without marking it retired.

## Method

### 1. Find the hot paths

Evidence hierarchy, best first:

1. **Benchmark/perf-harness results** already in the repo (bench targets,
   perf crates, CI perf jobs) — read their results; never run long
   benchmarks yourself unless asked. Numbers recorded secondhand (in a
   predecessor doc, EPIC, or README) still count as benchmark-tier —
   cite the provenance.
2. **Profiling artifacts** (flamegraphs, perf reports) if present.
3. **Structural signals** — innermost loops over large collections,
   per-element work, table lookups or hashing inside loops, allocation
   inside loops, O(n·m) nestings on data-plane types.

Record which tier each hot path rests on in the report header and per
finding. Structural-only evidence is fine — say so, and let the
Verification section prescribe the measurement.

### 2. Classify candidates

Match each candidate against the catalog's classes: **algorithm-first**,
**SWAR**, **SIMD**, **MIMD**, or **composition** (threads × lanes). SIMD
candidacy uses Hashimoto's five-step shape test (broadcast → chunked loop
→ lane ops → reduce/store → scalar tail) — details in the catalog.

### 3. Apply the ordering discipline (per finding, in order)

1. **Algorithm-first check** — does a data-structure/algorithm change
   beat vectorizing the current shape? If yes, that's the finding; lane
   work is at most a follow-on.
2. **Amdahl check** — name the serial tail. If it dominates, parallelism
   on the rest is noise; say so.
3. **Auto-vectorization check** — simple reduction loops the compiler
   already vectorizes are not findings.
4. **Data-size check** — lanes want thousands of elements per call;
   small-N goes to "Not worth it".

### 4. Rank with the anchors

Score payoff (dominant-cost / significant / marginal) × risk
(safe-stable / feature-gated / heavy) against the anchor tables in the
catalog. Integer tiers; between two anchors, take the lower and say why.
Every finding quotes its matched anchors and cites `file:line` evidence.

### 5. Emit the report

Fill `references/report-template.md` — every REQUIRED slot. Structure:
header (evidence sources used), TL;DR prose verdict, architecture sketch
of the hot paths, ranked finding dossiers, **"Not worth it"** (REQUIRED —
restraint is a finding), **Decision points** (big-ticket "this is a
decision, not code" items like precomputed-table evaluators, with the
trigger that would justify them), `TODO-PAR-N` checklist, Verification
(output-invariance tests, before/after benchmark procedure per TODO,
feature-gate policy: scalar path stays default until benchmarks justify
flipping), preserved `## Notes (human)`.

Large reworks (multi-session, architecture-changing) → recommend `/epic`
for a phased design doc rather than inlining a plan.

## Other ecosystems

The method is language-agnostic; only the mechanical tactics are
Rust-first. The catalog has per-ecosystem signal swaps (C/C++/Zig, Go,
Python). Thinner tooling → say so in the report rather than skipping
fields.

## Common mistakes

| Mistake | Fix |
|---|---|
| Recommending SIMD before the algorithm-first check | The ordering discipline runs per finding, in order, always |
| Ranking a loop nobody proved hot | Every finding names its hot path and evidence tier |
| Inventing a per-run ranking scale | Quote the catalog's anchors; that's what makes re-runs diffable |
| New filename per run | Always `PARALLELISM_AUDIT.md`, refreshed in place |
| Prose sequencing instead of the TODO checklist | `TODO-PAR-N` IDs, stable across runs, state preserved |
| Folding big-table/architecture options into a finding | They go in Decision points with an explicit trigger |
| Nightly/unsafe recommendation when a stable equivalent exists | Stable-safe path first; gate the rest |
| Dropping human notes on regeneration | `## Notes (human)` preserved verbatim, always |
| Skipping the "Not worth it" section | It is REQUIRED — restraint is a finding |
| Applying optimizations during the audit | Analysis only; implementation is a separate task or `/epic` |
