# Testkit invariants and how to detect violations

Use this when assessing (Mode A) or deciding what to build (Modes B/C). Each
invariant has a definition, the failure mode, and how to spot it in real code.
They parallel the kernel invariants: where the kernel's invariants guarantee
*observability*, these guarantee *controllability*.

## T1. Reachable, not just type-valid

**Definition.** Every generated state is producible by folding legal actions
through the kernel's own `apply` from a legitimate initial state — or is proven
equivalent to one that is. The type system checks shape; only `apply` checks
history.

**Failure modes.**
- Generators that hand-assemble states via struct literals, `Default`, or
  builder chains that bypass the transition function. These can encode states
  the kernel can never enter (e.g. a poker pot inconsistent with the betting
  history), and tests against them verify behavior on impossible worlds.
- `#[derive(Arbitrary)]` on the state type itself. Deriving on the *action*
  type is fine and encouraged; deriving on state is the canonical T1 violation.

**Detection.** Read the generator module: does it reference `apply` (or the
kernel's transition entry point)? `check_testkit.py` reports this as a
heuristic ("manual review") — a generator file that never mentions the
transition function is suspect. The rigorous check: a property test asserting
every generated state is reproduced by replaying its generating trace.

**Legitimate exception.** A direct state constructor is acceptable when
accompanied by a proof obligation — a test that replays a trace into the same
state — or when the domain genuinely has no history (pure value domains). Say
so explicitly in the texture map.

## T2. Seed-deterministic

**Definition.** Generators are pure functions: seed in, data out. Same
discipline as the kernel itself — no ambient randomness, clock, or environment.

**Failure modes.** `rand::thread_rng()`, `SystemTime::now()`, `Instant::now()`,
`std::env`, direct `getrandom` in generator code. Any of these makes a failing
test unreproducible.

**Detection.** `check_testkit.py` greps for these in the testkit source.

**Consequence when held.** Every failure is a replayable `(seed, trace)` pair;
CI logs the seed; shrinking produces a minimal counterexample trace.

## T3. Ships with the kernel

**Definition.** The testkit is part of the kernel's contract: versioned with
it, released with it, documented with it. A consumer of the kernel gets the
means to test against it without inventing fake data themselves.

**Failure modes.** Test helpers copy-pasted per downstream project; fixtures
living only in one consumer's repo; generators in `#[cfg(test)]` modules
invisible to consumers.

**Fix.** Companion crate `<kernel>-testkit` (preferred) or a `testkit` feature.
If the kernel has a WIT/serialized boundary, golden fixtures serialize
canonically so every host language tests against byte-identical data.

## T4. Textured

**Definition.** Fake data comes in named textures — qualitative equivalence
classes — not one undifferentiated distribution. Each texture is a
classifier + generator pair satisfying the round-trip law
(`classify(generate(texture, seed))` contains `texture`).

**Failure modes.** A single `arb_state()` strategy with no named regions; a
texture that has a name in prose but no classifier in code; a generator whose
output its own classifier rejects (round-trip violation).

**Detection.** Does a texture map exist (`TEXTURES.md` or a `textures` module)?
Is the round-trip law property-tested? `check_testkit.py` reports presence.

## T5. Measured — state coverage

**Definition.** Test runs report which textures (and texture × action-class
transitions) they visited, plus the untextured rate. See
`state-coverage.md` for the metric definitions and CI gating.

**Failure modes.** Coverage claimed from code coverage alone; textures defined
but never instrumented; a texture defined with no generator able to reach it
(a permanently-uncovered bucket is either dead weight or a finding).

## T6. Complete taxonomy

**Definition.** All four kinds of fake data are present and labeled:
arbitrary-valid, adversarial/edge, golden fixtures, scenario traces. They have
different jobs; the absence of any one is a specific blind spot:
- no arbitrary-valid → no breadth, unknown unknowns untested;
- no adversarial → boundaries untested;
- no golden fixtures → no cross-version / cross-language contract;
- no scenario traces → fixed bugs can silently regress.

## T7. One-way dependency

**Definition.** Testkit depends on kernel; kernel never depends on testkit.
The kernel's *default build* contains no test-data machinery — `proptest`,
`arbitrary`, faker crates appear only in the testkit crate or behind the
opt-in feature (mirrors the kernel's "pure by default" invariant).

**Detection.** `check_testkit.py` checks the kernel's `Cargo.toml` default
features and non-dev dependencies for test-data crates.

---

## Output shape for an assessment

For each violated invariant: the invariant, file:line evidence, hard-gap vs
maturity-gap classification, and the minimal fix. Then a recommended sequence —
almost always: **seeded trace generators through `apply` first** (T1+T2,
~80% of the value), then the texture map and round-trip law (T4), then
coverage instrumentation (T5), then taxonomy fill-in and packaging (T3/T6/T7).
