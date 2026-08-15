# The five characteristics — fixed score anchors and detection tactics

These anchors ARE the scale. Never define a scale inline in a report; quote
the matching anchor next to each score. Direction: **5 = best**. Scores are
integers — no halves, no averages.

The characteristics are calibrated for **components** (data flows both ways;
the caller's program stays in charge). Classify the reuse kind first — see
SKILL.md step 1. For an **engine**, flow control and retention are its
contract, not defects: score them n/a-by-design in prose and say so. For a
**layer**, the interesting questions are thinness and whether two layers
compete for the resource underneath.

---

## Granularity

*Can an operation decompose into smaller, separately-controllable steps?*
Muratori's rule of thumb: a coarse call should decompose into ~2–4 finer
ones — not zero, not twenty.

| Score | Anchor |
|---|---|
| 5 | Every coarse operation is a documented composition of 2–4 exposed finer calls; a caller can drop one level anywhere without workarounds. |
| 4 | The fine tier exists for all core operations; one or two coarse-only conveniences remain at the edges. |
| 3 | Mixed: some operations decompose, others are monolithic with no lower tier. |
| 2 | The dominant path is monolithic; finer control exists only via workarounds (round-tripping through internal state, re-implementing steps). |
| 1 | Coarse-only. Nothing decomposes; any variation from the blessed path requires forking or rewriting the library. |

**Detect:** function names that enumerate steps (`load_and_play`,
`init_and_run`); count what a "do everything" call does versus what is
separately callable; try to write the usage sketch that needs just one of
those steps.

## Redundancy

*Are there multiple ways to do the same thing?* The tension is convenience
vs. orthogonality — every redundant path must be designed, documented, and
kept consistent. **This measures coherence, not quantity.** A spartan
single-path API over a fine-grained core is mid-scale, not a failure;
redundancy that *conflicts* is the failure.

| Score | Anchor |
|---|---|
| 5 | Deliberate tiering: convenience wrappers sit over the fine tier, each documents what it composes, and all paths reach identical state. |
| 4 | Mostly tiered; minor overlap where two paths differ subtly but harmlessly. |
| 3 | No redundancy at all (single-path API — spartan but coherent), or redundancy present but undocumented, forcing callers to guess which path is canonical. |
| 2 | Divergent duplicates: two ways to reach "the same" state that behave observably differently. |
| 1 | Redundant paths actively conflict — one path's effect silently clobbers or corrupts another's, and the caller must reverse-engineer which wins. |

**Detect:** map every distinct way to reach the same end state; diff their
observable effects. Watch for a convenience call that mutates state a
lower-level call also owns (the classic clobber).

## Coupling

*Does using capability A silently require B to already be true?* Muratori:
"always bad," even when unavoidable — the cost is that the API doesn't tell
you about the dependency until you hit it.

| Score | Anchor |
|---|---|
| 5 | Any public capability is usable in isolation; construction from plain data; no hidden prerequisites; no third-party types in public signatures. |
| 4 | Capabilities isolated, but one benign, type-visible prerequisite (e.g. a builder you must finish), or format deps present yet feature-gated off by default. |
| 3 | One central object gates everything, or a format/IO crate leaks into public types, but a decoupled path exists. |
| 2 | Hidden runtime prerequisites discovered only at call time (init gates returning errors), or core operations mandate filesystem/network/environment access. |
| 1 | No capability usable without buying unrelated subsystems; construction itself requires external resources; hidden preconditions on most calls. |

**Detect:** the constructor's signature (does it take paths? read files?);
error variants like `NotInitialized` (a hidden dependency confessing);
third-party derives/types on public items; `[features]` absent while format
crates sit in `[dependencies]`.

## Retention

*Does the API keep persistent state you must keep synced with yours
(retained mode), or can you call it fresh each time (immediate mode)?* The
retained-mode tax is the brittle diff-and-sync code nobody wants to write.

| Score | Anchor |
|---|---|
| 5 | Immediate-mode core: the caller's data is the only copy; any retained construct is an optional convenience built on top. |
| 4 | Small retained caches that are semantically invisible (memoization, interning) — nothing for the caller to keep in sync. |
| 3 | Retained mode, but with partial updates and queries — the sync burden exists and is incremental, not wholesale. |
| 2 | A retained mirror the caller must wholesale-replace to stay current, or one the library also mutates (divergence risk on both sides). |
| 1 | The retained mirror is the only interface, the library mutates it behind the caller's back, and correctness depends on the caller re-syncing on a schedule. |

**Detect:** doc phrases like "keep synchronized", "call every frame after
mutating"; whole-struct setter methods (`sync_scene(SceneCopy)`); library
methods that write into the same structure the caller is told to replace.

## Flow control

*Who calls whom?* The caller should retain authority; every callback- or
inheritance-driven path needs a non-callback alternative.

| Score | Anchor |
|---|---|
| 5 | Caller invokes everything; every notification is pollable or returned; callbacks absent or purely optional sugar. |
| 4 | Caller drives; callbacks exist but each has a pollable/returned equivalent. |
| 3 | Caller drives the main loop, but at least one event is callback-only. |
| 2 | Core functionality requires registering callbacks or implementing library traits; caller code routinely runs inside library frames. |
| 1 | The library owns the loop — the caller is a plugin to it. (If this is the *intent*, it is an engine: reclassify instead of scoring 1.) |

**Detect:** `Box<dyn Fn…>` parameters, required trait implementations,
"register a handler" as the only completion channel; check whether data a
callback delivers is also obtainable by polling or from a return value.

---

## Scoring rules

- Quote the anchor you matched; if evidence sits between two anchors, take
  the lower score and say why.
- Every score cites file:line evidence and at least one usage sketch.
- **Never aggregate scores into an overall average.** The headline is the
  discontinuity verdict (prose), not arithmetic.
- Redundancy stays a judgment call at the margins — per the source talk, it
  is the one characteristic where structural rules run out. Say so when it
  decides a score.
