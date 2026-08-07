# PARALLELISM_AUDIT.md template

Fill every REQUIRED slot. Preserve `## Notes (human)` verbatim from any
previous run. Keep `TODO-PAR-N` IDs stable across runs. Wide content
stays in the repo's prose style; every claim cites `file:line`.

```markdown
# Parallelism Audit

**Date:** <run date>                                          <!-- REQUIRED -->
**Scope:** <whole repo | subsystem given to /smimd>           <!-- REQUIRED -->
**Files surveyed:** <list>                                    <!-- REQUIRED -->
**Evidence sources:** <benchmarks read (live or recorded secondhand — cite provenance) | profiles read | structural-only>  <!-- REQUIRED: the tier this audit rests on -->
**Companion docs:** <perf harness, EPICs, predecessor analyses>
**Predecessor:** <link to any prior ad-hoc analysis; its open TODOs are
carried forward below under stable IDs>                       <!-- REQUIRED if one exists -->
**Method:** /smimd (pattern catalog + anchors: references/pattern-catalog.md)

**TL;DR:** <prose verdict, 2–5 sentences: the few real targets, what
beats what, and what is deliberately not worth doing. No arithmetic
score.>                                                       <!-- REQUIRED -->

---

## 1. Hot-path architecture

<Short sketch of the data representations and the hot paths the findings
live in, with file:line. Reader should be able to follow every finding
from here.>                                                   <!-- REQUIRED -->

## 2. Findings

<One dossier per finding, ordered by payoff-per-risk. Δ note on any
finding whose tier changed since the previous run.>

### F<N>. <title>
- **Class:** algorithm-first | SWAR | SIMD | MIMD | composition   <!-- REQUIRED -->
- **Hot path & evidence tier:** <which hot path, and benchmark/profile/structural>  <!-- REQUIRED -->
- **Payoff:** <tier> — "<quoted anchor>"                      <!-- REQUIRED -->
- **Risk:** <tier> — "<quoted anchor>"                        <!-- REQUIRED -->
- **Evidence:** <file:line citations; benchmark numbers if available>  <!-- REQUIRED -->
- **Ordering discipline:** <result of the four checks: algorithm-first /
  Amdahl serial tail / auto-vectorization / data size — one line each>  <!-- REQUIRED -->
- **Recommended transform:** <canonical transform from the catalog,
  concretized; what beats what if tiered>                     <!-- REQUIRED -->

## 3. Not worth it                                            <!-- REQUIRED section -->

<Candidates examined and rejected, each with the reason (cold path,
auto-vectorized already, small-N, serial-tail-dominated, API-surface
cost). Restraint is a finding.>

## 4. Decision points                                         <!-- REQUIRED section; "none" is a valid entry -->

<"This is a decision, not code" items — big tables, architecture swaps,
output-contract changes. Each names the trigger that would justify it
(e.g. a throughput target the incremental findings cannot meet) and
routes to /epic if taken.>

## 5. TODO checklist

<Ordered by payoff per unit of risk. IDs stable across runs; state
survives regeneration. IDs are identity, not order — a new TODO takes
the next unused N and may sort between older IDs in the display.>

- [ ] **TODO-PAR-1** — <action, files, verification hook>
- [ ] **TODO-PAR-2** — …

### Superseded
<TODO-PAR IDs retired by later runs, with one line why. Never reuse an ID.>

## 6. Verification                                            <!-- REQUIRED section -->

- **Invariance:** <the tests proving output-identical behavior per TODO —
  bit-identical results, deterministic-seed contracts>
- **Measurement:** <the before/after benchmark procedure per TODO; if
  the repo has no harness, the minimal one worth adding>
- **Feature-gate policy:** scalar/serial path stays the shipped default
  until benchmarks justify flipping; gates named per TODO.

## Notes (human)

<Preserved verbatim across regenerations. Never edited by the skill.
On the first run, emit the section empty so later runs have an anchor.>
```

## Re-run mechanics (for the agent, not the report)

1. Read the existing `PARALLELISM_AUDIT.md` first, if any: capture
   `## Notes (human)`, TODO IDs + checked state, and previous tiers.
2. Regenerate all generated sections fresh; re-attach preserved content.
3. New findings/TODOs take the next unused N — never renumber, never
   reuse retired IDs.
4. Tier changed since last run → one-line `Δ:` note in that dossier.
