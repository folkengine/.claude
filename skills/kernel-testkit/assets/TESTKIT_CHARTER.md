# <Kernel Name> Testkit — Charter

## The corollary

Testability is two capabilities: **observability** (see what the system did)
and **controllability** (put the system into any state a test needs). A domain
kernel delivers observability by construction — state is a plain value, every
transition a pure function. It only makes controllability *possible*. This
testkit is the artifact that makes it *provided*:

> A kernel without a testkit is a system you can watch but not steer.
> Fake data is part of the kernel's contract, not an afterthought of its
> consumers.

## What ships

1. **A definition of fake data.** Four kinds, each present and labeled:
   arbitrary-valid, adversarial/edge, golden fixtures, scenario traces.
2. **Pure, seeded generators** that produce states by folding legal actions
   through the kernel's own `apply` — *reachable*, not merely type-valid,
   and replayable from a seed.
3. **A texture map**: named qualitative regions of the state space, each a
   classifier + generator pair bound by a round-trip law.
4. **State coverage**: a reported metric — textures visited, transitions
   exercised, untextured rate — gated in CI like line coverage.

## Positioning (what this is not)

- **Not a faker library.** Faker produces type-valid values with no notion of
  reachability, textures, or coverage; it manufactures plausible-looking
  impossible worlds.
- **Not ObjectMother / test-data builders.** Builders solve *construction* of
  individual known states; the testkit governs *distribution over* the state
  space, and measures it.
- **Not bare property-based testing.** Proptest is the mechanism here, not the
  pattern. PBT without a texture map has no contract for *what kinds* of data
  matter and no metric for what was reached.
- **Nearest prior art: deterministic simulation testing** (FoundationDB,
  TigerBeetle's VOPR). Same commitments — seeded determinism, generated
  histories, replayable failures. The testkit pattern adds what DST usually
  leaves implicit: a *named*, reviewable quotient of the state space
  (textures) and a coverage metric over it — and packages the whole thing as
  part of the kernel's public contract rather than an internal harness.

## Invariants (summary)

T1 reachable · T2 seed-deterministic · T3 ships with the kernel ·
T4 textured · T5 measured · T6 complete taxonomy · T7 one-way dependency.

## Governance

The texture map is code: owned by <domain owners>, changed by PR, audited
against real data <cadence>. Every fixed bug contributes a scenario trace and
is considered for a new texture. Coverage gates ratchet, never loosen, without
a charter amendment.
