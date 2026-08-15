# Fixtures

`gremlin-audio/` is the skill's test fixture — a deliberately
Muratori-hostile 157-line mixer crate that violates all five
characteristics: a five-verb monolith (`load_register_attach_and_play`),
a config-file-only constructor with `NotInitialized` gates, a retained
scene mirror the library also mutates (so two write paths clobber each
other), callback-only completion, forced `GremlinScene` datatypes, an
opaque `Sound`, and un-gated serde in the public API.

Its `docs/REUSABILITY_AUDIT.md` is a known-good audit produced by an agent
following the skill, against a seeded previous audit — so it demonstrates
the refresh-in-place conventions too: Δ notes on changed scores and a
`## Notes (human)` section preserved verbatim.

Use it to re-verify the skill after editing: point a fresh agent at
SKILL.md with this crate as the target and compare the output's shape
(not necessarily the exact scores) against the checked-in report. It is
not an example of good API design — the opposite is the point.
