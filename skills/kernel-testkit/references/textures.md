# Data textures

## Origin and definition

The term generalizes poker's **board texture**: players classify community
cards qualitatively — *dry* (uncoordinated, few draws), *wet* (coordinated,
draw-heavy), *paired*, *monotone* — because strategy differs by texture, not by
individual board. The insight generalizes to any domain: experts reason about
**kinds of situations**, and correct behavior varies across kinds far more than
within them.

**A data texture is a named qualitative equivalence class of states (or
traces), realized in code as a dual object:**

```
texture T = {
  name:        stable identifier ("wet-board", "backhaul-scarce-lane")
  classifier:  State -> bool          -- is this state in T?
  generator:   (Seed) -> State        -- produce a state in T (via traces; see T1)
  prevalence:  note                   -- roughly how common in realistic play/traffic
  rationale:   why behavior might differ here (the branch/risk it exercises)
}
```

Textures are **tags, not a partition** — a board can be both wet and paired;
states may match several textures or none. The set of textures for a domain is
its **texture map**.

## The round-trip law

The classifier is authoritative; the generator is its servant. Their contract:

```
∀ seed: T.classifier(T.generator(seed)) == true
```

Property-test this law itself — it is the cheapest test in the whole testkit
and catches generator drift immediately. The reverse direction (can the
generator produce *all* of the classifier's region, with what distribution?) is
not a law but a documented aspiration; note known unreachable corners in the
texture map.

## Why classifiers, not just generators

The classifier does triple duty:

1. **Round-trip law** — keeps generators honest.
2. **Coverage instrumentation** — classifying every state a test visits is what
   makes state coverage measurable (see `state-coverage.md`). A generator-only
   texture can produce data but can never tell you what your *existing* tests
   already exercise.
3. **Real-data audit** — run the classifiers over production/historical data to
   compare real texture prevalence against generated prevalence. This is how a
   texture map stays connected to reality instead of drifting into fiction.

## Deriving a texture map

In descending order of yield:

1. **Domain vocabulary.** If practitioners already name situations (poker
   textures, freight's "headhaul/backhaul", medicine's presentations), the map
   starts as transcription. This is the strongest signal — the names exist
   because behavior differs.
2. **Branch predicates in kernel logic.** Every `if`/`match` guard in the
   kernel partitions states; guards that encode domain rules (not plumbing)
   suggest textures. This ties textures to state coverage's purpose: a texture
   per meaningful branch means texture coverage subsumes the *semantic* part of
   branch coverage.
3. **History.** Past bugs and incidents each imply a texture ("the state we
   didn't think about"). Fixed bugs contribute both a scenario trace (T6) and
   often a new texture.
4. **Adversarial imagination.** Degenerate, extreme, and pathological regions:
   empty, maximal, all-equal, resource-exhausted, deadline-adjacent.

Aim for a first map of **5–15 textures**. Fewer and the quotient is too coarse
to mean anything; many more and coverage reporting stops guiding attention.
Grow it from untextured-rate findings, not speculation.

## Trace textures

Textures over *states* are the base case; some domains need textures over
*traces* (action sequences): "raise war" (repeated re-raising), "stall then
surge", "rate-limit oscillation". Same dual structure — a trace classifier and
a trace generator — and the same round-trip law. Prefer state textures until a
behavior demonstrably depends on history that state doesn't capture.

## Worked micro-examples

**Poker (pkcore-flavored), textures over board states:**

| name | classifier sketch | rationale |
|------|-------------------|-----------|
| dry-board | no flush draw, no open-ended straight draw, unpaired | c-bet logic's easy case |
| wet-board | ≥2 to a suit and connected within 4 ranks | draw-heavy equity calculations |
| paired-board | any rank appears twice | full-house/trips logic |
| monotone | flop all one suit | flush-dominant evaluation |
| stack-shallow | effective stack < 10 BB | push/fold regime switch |

**Trucking kernel, textures over market/load states:**

| name | classifier sketch | rationale |
|------|-------------------|-----------|
| backhaul-scarce | outbound/inbound load ratio ≫ 1 on a lane | pricing asymmetry paths |
| seasonal-surge | demand > p90 of baseline for region | capacity allocation stress |
| dense-metro | many short-haul loads clustered | routing/consolidation logic |
| deadhead-heavy | assignments forcing long empty miles | cost-model edge |

Each row becomes one classifier fn, one generator strategy, one line in the
coverage report.
