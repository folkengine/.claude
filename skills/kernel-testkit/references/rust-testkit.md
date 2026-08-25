# Rust testkit recipes

## Layout

Preferred: a companion crate in the same workspace, versioned in lockstep.

```
workspace/
├── pkcore/                 # the kernel — default build stays pure
└── pkcore-testkit/         # depends on pkcore; never the reverse
    ├── src/
    │   ├── lib.rs
    │   ├── textures.rs     # classifiers + texture registry
    │   ├── strategies.rs   # proptest strategies (actions & traces)
    │   ├── scenarios.rs    # named golden traces
    │   └── coverage.rs     # CoverageRecorder + report
    ├── fixtures/           # canonical serialized golden states/traces
    └── TEXTURES.md         # the texture map (human-readable, reviewed)
```

Acceptable alternative: a `testkit` feature on the kernel crate. Then all
testkit modules are `#[cfg(feature = "testkit")]`, and `proptest`/`arbitrary`
are optional dependencies enabled only by that feature — never in `default`.
This mirrors the kernel's own pure-by-default invariant; `check_testkit.py`
verifies it.

## Trace generators (the T1-honest primitive)

Never derive `Arbitrary` on the **state**. Generate **actions**, and get states
by folding through `apply`. Two patterns:

**Legal-by-construction** (preferred when the kernel exposes `legal_actions`):

```rust
use proptest::prelude::*;

/// A seeded walk: at each step, pick uniformly among legal actions.
pub fn arb_trace(max_len: usize) -> impl Strategy<Value = Trace> {
    (any::<u64>(), 1..=max_len).prop_map(|(seed, len)| {
        let mut rng = StdRng::seed_from_u64(seed);   // T2: seeded, never thread_rng
        let mut state = State::initial(&mut_config_from(&mut rng));
        let mut actions = Vec::new();
        for _ in 0..len {
            let legal = kernel::legal_actions(&state);
            if legal.is_empty() { break }
            let a = legal[rng.gen_range(0..legal.len())].clone();
            state = kernel::apply(state, a.clone()).expect("legal action applied");
            actions.push(a);
        }
        Trace { seed, actions }
    })
}
```

**Generate-then-filter** (when there's no `legal_actions`): derive `Arbitrary`
on the *action* type, `prop_filter_map` sequences through `apply`, discarding
illegal steps. Costlier, but still reachability-honest.

Shrinking falls out: proptest shrinks the action *sequence*, and every shrunk
candidate is re-validated through `apply`, so minimal counterexamples are
always real, replayable traces.

## Texture-directed generation

A texture's generator is a biased trace strategy plus the round-trip law:

```rust
/// Generator: bias the walk until the classifier is satisfied.
pub fn arb_in_texture(t: TextureId, max_len: usize) -> impl Strategy<Value = State> {
    arb_trace(max_len)
        .prop_map(|tr| tr.replay())                       // fold through apply
        .prop_filter("state not in texture", move |s| textures::classify(s).contains(&t))
}

proptest! {
    #[test]                                               // the round-trip law, T4
    fn round_trip_wet_board(s in arb_in_texture(TextureId::WetBoard, 12)) {
        prop_assert!(textures::classify(&s).contains(&TextureId::WetBoard));
    }
}
```

Filtering is the honest baseline; when a texture is rare enough that filtering
starves (proptest rejects too many), write a *targeted* trace strategy that
steers action choice toward the region — and keep the same round-trip test,
which is what licenses the steering.

## Golden fixtures & scenarios

- Serialize with a canonical, stable format (`postcard` or canonical JSON);
  pin content hashes in a `fixtures/manifest.toml`; a test fails if bytes
  drift without a manifest bump.
- If the kernel has a WIT boundary, fixtures are serialized **at the boundary
  types**, so a JS host and the Rust guest load byte-identical data — the
  fixtures *are* the cross-language contract.
- `scenarios.rs` holds named traces: `pub fn split_pot_three_way() -> Trace`.
  Every fixed bug adds one, named after the bug. A CI check asserts each
  scenario still replays to its pinned terminal state.

## Coverage wiring

`coverage.rs` implements the recorder from `state-coverage.md`. Practical
notes:

- Expose `apply_recorded` and have property tests fold through it; a
  `thread_local!` or explicitly-passed recorder both work — explicit is better.
- Dump `coverage-report.json` in a test with `#[ignore]`-by-default off, or
  from a dedicated `cargo test --features coverage-report` run.
- Gate in CI with a ~30-line Python script comparing the report against
  thresholds in `TEXTURES.md` frontmatter — same pattern as the kernel's
  purity CI job.

## Dependency hygiene (T7)

In the kernel's `Cargo.toml`, if using the feature approach:

```toml
[features]
default = []                       # unchanged from the kernel skill
testkit = ["dep:proptest", "dep:rand"]

[dependencies]
proptest = { version = "1", optional = true }
rand     = { version = "0.8", optional = true }
```

In the companion-crate approach, the kernel's manifest doesn't change at all —
which is the argument for preferring it.
