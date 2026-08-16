# MURATORI_AUDIT.md template

Every slot marked REQUIRED must be present — an audit without a reuse-kind
classification, an anchor quote per score, or the usage sketches is not
done. Refresh the file in place each run; preserve `## Notes (human)`
verbatim; when a previous audit exists, add a one-line `Δ` note to any
characteristic whose score changed.

```markdown
# Muratori Audit — <library name>

<!-- REQUIRED header block -->
| | |
|---|---|
| Subject | <name> <version> — <public surface, one line> |
| Commit | <short hash> (read-only git) |
| Date | <YYYY-MM-DD> |
| Method | Muratori, *Designing and Evaluating Reusable Components* (2004); anchors per the /muratori skill |
| Reuse kind | **layer / engine / component** — <one-sentence justification> (REQUIRED) |

<!-- If reuse kind is engine or layer: one short paragraph on which
     characteristics are its contract rather than defects, before scoring. -->

## Summary

<!-- REQUIRED: all five rows, integer scores, no overall average row -->
| Characteristic | Score | One-line verdict |
|---|---|---|
| Granularity | n/5 | … |
| Redundancy | n/5 | … |
| Coupling | n/5 | … |
| Retention | n/5 | … |
| Flow control | n/5 | … |

**Discontinuity verdict** (REQUIRED, prose — the headline, no arithmetic):
<Where will a real integration hit a gap that forces a rewrite or workaround
instead of an incremental step? One short paragraph.>

## Characteristics

<!-- One section per characteristic, all five REQUIRED, each with: -->
### <Characteristic> — n/5
> Anchor matched: "<quote the anchor line from characteristics.md>" (REQUIRED)

- Evidence: file:line citations + the sketch(es) that exposed it (REQUIRED)
- Δ from previous audit, if score changed
- Minimal fix: <the smallest API change that moves the score> (REQUIRED)

## Practical checklist

<!-- REQUIRED: all 9 rows, status ∈ pass / partial / fail / n-a, each with evidence -->
| # | Item | Status | Evidence |
|---|---|---|---|
| 1 | Usage code written before API design (or: sketches integrate cleanly now) | | |
| 2 | Every retained-mode construct has an immediate-mode equivalent | | |
| 3 | Every callback/inheritance path has a non-callback alternative | | |
| 4 | Callers keep their own datatypes (no forced API types) | | |
| 5 | Operations decompose into 2–4 finer-grained calls | | |
| 6 | Data structures transparent (constructible, inspectable, serializable by caller) | | |
| 7 | Resource-management integration optional, never mandatory | | |
| 8 | File-format usage optional, never forced | | |
| 9 | Runtime source shipped / readable by integrators | | |

## Kernel lens

<!-- REQUIRED section. Map the findings onto the domain-kernel invariants:
     coupling→purity, retention→pure transition function (immediate mode),
     flow control→delivery-agnosticism, granularity→boundary shape;
     redundancy stays unmapped (structural enforcement runs out there).
     End with a recommendation: if low coupling/retention/flow-control
     scores trace to I/O, hidden state, or callback inversion, recommend
     running /domain-kernel (Mode A first). If not kernel-shaped, say so
     in one line — do not force the mapping. -->

## Recommendations

<!-- Ordered by leverage; each names the characteristic(s) it moves and the
     expected score change. L-size rework → recommend /epic for a phased
     design doc rather than attempting it ad hoc. -->

## Evidence appendix

### Usage sketches (REQUIRED — at least these three)

<!-- Short code sketches, ~10–25 lines each, written against the public API
     as it exists. Each ends with a one-line verdict: incremental step or
     discontinuity? -->
1. **First integration** — the minimal happy path a new adopter writes.
2. **Requirement shift** — a plausible mid-project change (new data source,
   different lifecycle, one step needed without its siblings).
3. **Ship-week workaround** — the API's blessed path fails late; what does
   the workaround cost?

### Mechanical signals

<!-- The grep-able facts: callback-typed parameters, third-party types on
     public items, path-taking functions, init/error gates, feature flags.
     Label counts with what was searched. -->

## Notes (human)

<!-- Preserved verbatim across refreshes. Never regenerate this section. -->
```
