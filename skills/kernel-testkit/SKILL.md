---
name: kernel-testkit
description: >-
  Codify, assess, and build the **kernel testkit** pattern — the controllability
  corollary to the domain kernel: fake data generation, data textures, and state
  coverage shipped as part of a kernel's contract. Use this whenever the user
  wants to make a kernel-shaped system testable through generated or fake data;
  define, generate, or classify "data textures"; measure "state coverage" (the
  analog of code coverage over the state space); build or assess a testkit,
  test-data crate, fixture set, generator, or property-based testing strategy
  for a pure core; make golden fixtures or scenario traces; or write up the
  controllability/testability philosophy of a kernel. Trigger even when the user
  only says things like "how do I fake data for this", "generate test hands /
  test loads", "are my tests hitting enough of the state space", "make this
  controllable", or "add proptest to the core" without ever naming "testkit".
---

# Kernel Testkit

**Corollary to the domain kernel.** A domain kernel is *observable* by
construction — state is a plain value you can inspect. But observability is only
half of testability. The other half is **controllability**: the ability to put
the system into any state a test needs. A kernel makes that *possible*; it does
not make it *provided*. The testkit is what provides it.

> A kernel without a testkit is a system you can watch but not steer.

The claim this skill codifies: **fake data is part of the kernel's contract.**
Every kernel ships with (1) a definition of what its fake data *is*, (2) pure,
seeded generators that produce it, (3) a **texture map** naming the qualitative
regions of its state space, and (4) a **state coverage** metric reporting which
of those regions the tests actually visited.

Two load-bearing ideas, defined precisely in the references:

- **Data textures** (`references/textures.md`) — named qualitative equivalence
  classes of states or traces (from poker's *board texture*: wet, dry, paired,
  monotone). Each texture is a dual object: a **classifier** (`is this state in
  the texture?`) and a **generator** (`produce a state in it`), bound by a
  round-trip law. Textures are how domain knowledge about "kinds of situations"
  becomes executable.
- **State coverage** (`references/state-coverage.md`) — the coverage metric.
  Raw state spaces are astronomically large, so coverage over raw states is
  meaningless; **textures are the quotient that makes it finite**. Code
  coverage counts lines executed; state coverage counts textures visited.
  High code coverage against one texture is false confidence.

The testkit invariants (reachability, seed-determinism, shipped-with-the-kernel,
textured, measured, taxonomy, one-way dependency) live in
`references/invariants.md` — read it before assessing or building.

## Pick the mode(s)

| The user wants… | Mode |
|-----------------|------|
| "is this kernel actually controllable / are my tests hitting the state space" | **A — Assess** |
| "build the testkit / generators / fixtures / proptest strategies" | **B — Build** |
| "define textures / measure state coverage / gate it in CI" | **C — Texture & Coverage** |
| "write up / name / position this philosophy" | **D — Document** |

When the request is open-ended ("make pkcore properly testable"), run A first to
ground everything in real findings, then propose B/C/D as follow-ups. A and C
overlap deliberately: assessing without a texture map usually *produces* the
first draft of one.

---

## Mode A — Assess

Produce a findings report grounded in the actual code. **Fetch or read the real
source first** — the value is in file:line evidence.

1. Run the deterministic checker against the kernel workspace:
   ```bash
   python scripts/check_testkit.py <path-to-workspace>
   ```
   It flags: no testkit found; ambient nondeterminism in generators
   (`thread_rng`, `SystemTime::now`, `Instant::now`, `std::env`); test-data
   machinery leaking into the kernel's default build; and reports whether a
   texture map exists. Python-only — no Rust toolchain needed.
2. Read `references/invariants.md` and check each testkit invariant by hand for
   what a grep can't catch — above all **T1 (reachability)**: do generators
   build states by folding legal actions through the kernel's own `apply`, or
   do they hand-assemble struct literals that may be type-valid but unreachable?
3. Write the report: one section per violated invariant, file:line evidence,
   minimal fix. Distinguish a **hard gap** (no generators at all; generators
   that fabricate unreachable states; nondeterministic generation) from a
   **maturity gap** (textures undefined; coverage unmeasured; taxonomy
   incomplete). Lead with the single highest-leverage change — usually
   "generate traces through `apply`, seeded".

---

## Mode B — Build

Scaffold the testkit. Full Rust recipes in `references/rust-testkit.md`;
the shape is language-agnostic:

1. **Placement.** A companion crate (`<kernel>-testkit`) is preferred; a
   `testkit` cargo feature is acceptable. Either way the kernel's default build
   must stay pure — the testkit depends on the kernel, never the reverse (T7).
2. **Trace generators first.** The primitive is not "a random state" but "a
   random *legal action sequence*", folded through `apply` from an initial
   state. This buys reachability (T1) by construction and gets shrinking to
   minimal counterexample traces for free from proptest.
3. **Seeded everything.** Generators are pure functions of a seed (T2). Take an
   RNG or seed as a parameter; never `thread_rng()`. Every failure is then a
   replayable `(seed, trace)` pair.
4. **The four kinds of fake data** (T6) — build each deliberately, label them:
   - **arbitrary-valid** — broad property-testing distributions;
   - **adversarial / edge** — boundary and worst-case states, often hand-picked
     seeds or dedicated textures;
   - **golden fixtures** — canonical serialized states/traces, hash-pinned, the
     cross-language contract if a WIT boundary exists;
   - **scenario traces** — named, replayable action sequences encoding known
     situations (bug reproductions become permanent scenarios).

---

## Mode C — Texture & Coverage

1. **Draft the texture map** with the domain expert. Sources, in order of
   yield: domain vocabulary (poker already *names* its textures), branch
   predicates in kernel logic (every `if` suggests a region), past bugs, and
   adversarial imagination. Template in `assets/TEXTURE_MAP.md`; method and the
   classifier/generator duality in `references/textures.md`.
2. **Implement textures as code**: a classifier function per texture plus a
   generator biased to produce it. Property-test the **round-trip law**:
   `classify(generate(texture, seed))` contains `texture`.
3. **Instrument for state coverage**: wrap `apply` in tests with a recording
   hook, classify every pre-state, emit a report — textures hit / textures
   defined, transition coverage (texture × action-class), and the
   **untextured rate** (reachable states matching no texture — the metric that
   audits the map itself). Definitions, CI gating, and Goodhart caveats in
   `references/state-coverage.md`.

---

## Mode D — Document

Write the charter that names and positions the pattern. Template in
`assets/TESTKIT_CHARTER.md`. The rule that keeps it from reading as "we wrote
some test helpers": **lead with the controllability corollary** — observability
comes free with purity, controllability must be shipped — and position
explicitly against faker libraries (type-valid, not reachable), ObjectMother /
test-data builders (construction, not distribution), bare property-based
testing (mechanism without a contract or a metric), and deterministic
simulation testing à la FoundationDB/TigerBeetle (closest prior art; textures
and state coverage are what it usually leaves implicit).

---

## Principles

- **Reachable, not just type-valid.** The compiler checks shape; only `apply`
  checks history. Generate through the kernel.
- **The classifier is authoritative.** A texture is what its classifier says it
  is; generators are servants of classifiers, and the round-trip law is itself
  a test.
- **Coverage of the map, then coverage by the map.** Untextured-rate audits the
  texture map; texture coverage audits the tests. Report both — one without the
  other is gameable.
- **Bugs become scenarios.** Every fixed bug leaves behind a named golden trace.
- **Build and verify before presenting.** Where a toolchain exists, run the
  generators and the round-trip law; where it doesn't, validate statically and
  say plainly what wasn't compiled.
