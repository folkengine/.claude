# State coverage

## The metric, precisely

Code coverage answers "which logic ran?". **State coverage answers "which
worlds did it run against?"** They are orthogonal: 100% line coverage achieved
entirely on dry boards says nothing about wet ones. High code coverage against
one texture is the signature failure mode this metric exists to expose.

Raw state spaces are astronomically large (poker deals alone: ~10²⁴ orderings),
so coverage over raw states is vacuous — every run scores ≈0%. **The texture
map is the quotient that makes the metric finite and meaningful.** Lines are to
code coverage what textures are to state coverage.

Three numbers, reported together:

1. **Texture coverage** = textures visited ÷ textures defined.
   A texture is *visited* when at least `depth` distinct states matching its
   classifier flowed through `apply` during the test run (`depth` defaults
   to 1; raise it per-texture for regions where one sample is noise).
2. **Transition coverage** = (texture, action-class) pairs exercised ÷ pairs
   declared reachable. Action-classes are the coarse action kinds (fold /
   raise / deal; book / cancel / reprice). Declare the reachable pairs in the
   texture map rather than assuming the full product — many pairs are
   structurally impossible, and counting them as misses poisons the ratio.
3. **Untextured rate** = states visited matching *no* texture ÷ states visited.
   This is the meta-metric: it audits the map itself. Texture coverage without
   untextured rate is gameable (define one texture, cover it, declare victory).

## Instrumentation

The kernel's purity makes this nearly free: all state flows through `apply`,
so one wrapper sees everything.

```rust
// in the testkit
pub struct CoverageRecorder {
    counts: HashMap<TextureId, u64>,
    transitions: HashMap<(TextureId, ActionClass), u64>,
    untextured: u64,
    total: u64,
}

impl CoverageRecorder {
    pub fn observe(&mut self, state: &State, action: &Action) {
        let tags = textures::classify(state);       // all matching textures
        if tags.is_empty() { self.untextured += 1; }
        for t in &tags {
            *self.counts.entry(*t).or_default() += 1;
            *self.transitions.entry((*t, action.class())).or_default() += 1;
        }
        self.total += 1;
    }
    pub fn report(&self) -> CoverageReport { /* serialize to JSON */ }
}

// tests fold through an instrumented apply:
pub fn apply_recorded(rec: &mut CoverageRecorder, s: State, a: Action)
    -> Result<State, KernelError>
{
    rec.observe(&s, &a);
    kernel::apply(s, a)
}
```

Emit `coverage-report.json` from the test harness; a small script asserts
thresholds in CI, exactly like a line-coverage gate:

```
state-coverage gate:
  texture coverage      >= 0.90
  transition coverage   >= 0.75      (of declared-reachable pairs)
  untextured rate       <= 0.05
  every golden scenario replayed     (bool)
```

Start gates loose and ratchet — the same discipline as introducing code
coverage to an existing codebase.

## Reading the report

- **Uncovered texture** → either write/point a generator at it, or discover the
  texture is unreachable and document why (which is itself domain knowledge).
- **Uncovered transition** → the interesting ones: "we never tested a re-raise
  on a monotone board", "never a cancellation during seasonal-surge".
- **Rising untextured rate** → the map lags the domain; mine the untextured
  states (log a sample of them) for the next texture.
- **One texture absorbing most counts** → distribution skew; bias generators or
  add per-texture depth requirements.

## Honest caveats (say these in any writeup)

- **The metric is only as good as the map.** State coverage is coverage *of the
  quotient you chose*. The untextured rate and periodic real-data audits
  (running classifiers over production data) are the checks on the map itself.
- **Goodhart.** A team gated on texture coverage will write generators that
  tickle classifiers minimally. Mitigations: depth requirements, transition
  coverage (harder to game), and treating the map as reviewable code owned by
  domain experts.
- **Not a substitute for code coverage.** Complementary axes; report both.
  The compound claim worth making: *N% of lines, exercised across M% of
  textures.*
- **Overlap inflates counts.** A state matching three textures increments
  three buckets; that's correct for coverage (each region was visited) but
  means counts don't sum to totals. Report ratios per texture, not a pie chart.
