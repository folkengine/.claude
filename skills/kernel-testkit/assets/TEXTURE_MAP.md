# Texture Map — <domain / kernel name>

<!-- This file is reviewable code: owned by domain experts, changed by PR.
     Thresholds here are read by the CI state-coverage gate. -->

```yaml
gates:
  texture_coverage: 0.90
  transition_coverage: 0.75
  untextured_rate_max: 0.05
```

## Textures

<!-- One entry per texture. classifier/generator name the code symbols.
     prevalence: rough share in realistic data (audit against real data when available).
     depth: min distinct states required for the texture to count as "visited". -->

### <texture-name>
- **classifier:** `textures::is_<name>`
- **generator:** `strategies::arb_<name>`
- **rationale:** <which behavior/branch/risk differs in this region>
- **prevalence:** <e.g. ~20% of real hands / rare-but-critical>
- **depth:** 1
- **known unreachable corners:** <sub-regions the generator can't reach, and why>

### <texture-name-2>
- …

## Trace textures

<!-- Only if some behavior depends on history that state doesn't capture. -->

### <trace-texture-name>
- **classifier:** `textures::trace_is_<name>`
- **generator:** `strategies::arb_trace_<name>`
- **rationale:** …

## Declared-reachable transitions

<!-- (texture, action-class) pairs the domain says are possible.
     Transition coverage is measured against this list, not the full product. -->

| texture | action-classes |
|---------|----------------|
| <texture-name> | <a, b, c> |

## Direct-construction exceptions (T1)

<!-- Any state constructors that bypass apply, each with its proof obligation
     (the replay test showing an equivalent trace exists). -->

| constructor | proof test |
|-------------|-----------|
| — | — |

## Changelog

<!-- Textures added from untextured-rate findings, bugs, or real-data audits. -->

- <date> — added `<texture>` (source: <bug #/audit/expert>)
