# /smimd pattern catalog

Mission, from Mitchell Hashimoto's
["Everyone Should Know SIMD"](https://mitchellh.com/writing/everyone-should-know-simd):
*"Every developer should be able to recognize the opportunity"* — SIMD
(and its siblings) is not specialist assembly work; it's a recognizable
loop shape plus a bounded transform. Hashimoto's Ghostty example turned
one scalar line into ~12 lines of pattern-shaped vector code for a 5x
win. This catalog is the recognition guide; the SKILL.md method supplies
the judgment about when recognizing is not enough.

## The five-step SIMD shape (Hashimoto)

Most SIMD code follows one shape. A loop is SIMD-shaped when you can
picture it rewritten as:

1. **Broadcast** constants / initialize vector accumulators
2. **Loop** one vector-width chunk at a time
3. **Lane ops** — the same operation across all lanes, no cross-lane
   branching
4. **Reduce or store** the vector result
5. **Scalar tail** — the original loop handles the remainder

If step 3 needs per-lane branches or data-dependent memory access, the
loop is not SIMD-shaped yet — look for an algorithm-first transform that
makes it so, or classify it "Not worth it".

## Classes

### Algorithm-first

**Shape:** the hot cost is a *search, probe, or scattered access* — work
whose count or layout a better structure removes outright. Vectorizing it
would accelerate waste.

**Signals:** binary search in a hot loop; hash-set/map probes per element
(`HashSet::contains` in an inner loop); branchy data-dependent lookups;
AoS layouts feeding elementwise math; repeated recomputation a
precomputed table or incremental update would kill.

**Canonical transforms:** perfect hash replacing search (multiply + shift
+ index); Eytzinger/BFS layout for a kept binary search
(branch-predictable, prefetch-friendly); structure-of-arrays (SoA) so
later lane work gets contiguous loads; bitset instead of hash-set;
incremental/streaming recomputation.

**Classic trap:** "SIMD the binary search" — lane-comparing pivots on a
data-dependent search fights vectorization and loses to making the
lookup O(1). Algorithm-first is checked before every lane recommendation
(SKILL.md ordering discipline, step 1).

### SWAR (SIMD within a register)

**Shape:** set membership, counting, or per-field arithmetic over small
domains (≤64 elements, or fields packed in a word) — one scalar register
is the vector.

**Signals:** `HashSet<SmallEnum>`/`Vec<bool>` for domains that fit 64
bits; per-element membership/insert/remove in hot loops; popcount-able
questions ("how many set?", "any of these?"); rank/select-style bit
queries; packed small counters.

**Canonical transforms:** `u64` bitmask with `&`/`|`/`^`/`!` set algebra;
`count_ones`, `leading_zeros`, `trailing_zeros` for count/min/max;
carry-less packed-field addition tricks. Safe, stable, no dependencies —
frequently the cheapest big win in the whole audit.

**Classic trap:** packed-field overflow — adding packed counters without
guard bits corrupts neighbors. Reserve a guard bit per field or bound the
add count.

### SIMD (explicit lanes)

**Shape:** the five-step shape above, over thousands of elements per
call, with a serial tail that doesn't dominate (Amdahl).

**Signals:** elementwise arithmetic over contiguous numeric slices;
fixed-size small-array reductions repeated per item; byte
scanning/classification (the Ghostty case); fixed permutation patterns
over contiguous data; "the same 5 ops for each of N independent items".

**Canonical transforms:** in Rust, the `wide` crate on stable or
`core::simd` behind a nightly feature flag — prefer portable lane types
over per-CPU intrinsics (Hashimoto's advice; also keeps WASM targets
buildable). Batch across *independent items* (structure-of-arrays, 8
items per lane) rather than inside one item when the per-item width is
awkward. Check auto-vectorization first: `cargo asm` / godbolt on the
scalar loop — if LLVM already vectorized it, the finding is at most
"make it guaranteed", which is marginal.

**Classic trap:** vectorizing the 10% around a serial table lookup —
the lookup is the cost; fix it first (algorithm-first), then the lanes
have something to win.

### MIMD (thread-level data parallelism)

**Shape:** many *independent* work items (requests, cases, samples,
files) each big enough to amortize scheduling; results combine by
reduction.

**Signals:** embarrassingly parallel outer loops still running serial;
`par_bridge()` on a sequential iterator (mutex handoff, no chunking —
a false-parallelism smell, not a win); per-item allocation of
accumulators later merged; one shared RNG or shared mutable accumulator
forcing serialization.

**Canonical transforms:** in Rust, rayon `into_par_iter` over an
*indexed* range (unrank the index into the work item) so work-stealing
chunks properly; `fold`/`reduce` with per-worker accumulators instead of
locked shared state; per-block RNG seeded from `(seed, block)` to keep
determinism; elsewhere, structured concurrency / worker pools with the
same indexed-chunking idea.

**Classic trap:** parallelizing loops with shared mutable state — the
lock serializes the "parallel" loop; restructure to fold/reduce first.
Second trap: task granularity below scheduler overhead (don't spawn per
tiny item; chunk).

### Composition (threads × lanes)

**Shape:** MIMD across items and SIMD within each worker's batch —
multiplicative, not either/or.

**Signals:** an already-rayon'd loop whose per-item body is itself
SIMD-shaped; batch APIs (evaluate N, score N) hiding lane opportunities
inside thread parallelism.

**Canonical transforms:** SoA batches per worker (e.g. 8 cases per lane
inside each rayon task). Compose with, never replace, the existing
thread layer.

**Classic trap:** nested parallelism *of the same kind* — rayon inside
rayon per tiny item. The inner level should be lanes, not threads.

## Anchor tables

Quote the matched anchor next to every finding. Between two anchors,
take the lower and say why. Never average payoff and risk into one
number.

### Payoff

| Tier | Anchor |
|---|---|
| **dominant-cost** | The finding sits in the profile's (or structural analysis's) single largest cost center; success visibly moves the headline benchmark |
| **significant** | Hot path, but one cost among several; success moves a named benchmark measurably, not the headline |
| **marginal** | Real but small: guaranteed-vs-hoped auto-vectorization, allocation shaving, cold-adjacent cleanup |

### Risk

| Tier | Anchor |
|---|---|
| **safe-stable** | Stable toolchain, no new dependencies, no unsafe, output bit-identical, small diff |
| **feature-gated** | New dependency or nightly feature, gated off by default; scalar path remains the shipped default until benchmarks justify flipping |
| **heavy** | unsafe code, large precomputed tables/memory budget, architecture-specific paths, or output-contract changes (e.g. RNG stream structure) — belongs in Decision points unless the payoff anchor is dominant-cost |

## Ecosystem tactics

Method is language-agnostic; swap the mechanical signals. State thinner
tooling in the report rather than skipping fields.

- **Rust (first-class):** grep `par_bridge`, `HashSet`/`HashMap` in hot
  modules, `collect()` in inner loops, `[T; N]` reductions;
  transforms via `u64` SWAR, `wide`/`core::simd`, rayon indexed ranges;
  verify with `cargo asm`/criterion; mind WASM targets when reaching for
  `core::arch`.
- **C/C++/Zig:** compiler vector extensions, `#pragma omp simd`, Zig
  `@Vector` / `std.simd`; check auto-vectorization reports
  (`-Rpass=loop-vectorize`, `-fopt-info-vec`); threads via OpenMP/TBB or
  Zig `std.Thread` pools.
- **Go:** no practical lane story in pure Go (assembly or cgo only —
  usually "Not worth it"); MIMD via goroutine chunking with per-worker
  accumulators; SWAR via `math/bits` is fully available.
- **Python:** the "NumPy question" — scalar Python looping over numeric
  data *is* the finding; the transform is handing the loop to
  NumPy/Numba/Polars vectorized ops, not hand-rolling lanes. MIMD needs
  process-level parallelism or nogil-aware libraries; note the GIL in
  the report.
