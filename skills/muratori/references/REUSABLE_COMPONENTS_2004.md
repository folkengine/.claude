# Designing and Evaluating Reusable Components (2004) — Distilled

*Casey Muratori, drawn from five years designing Granny 3D at RAD Game Tools.*
[Video](https://www.youtube.com/watch?v=ZQ5_u8Lgvyk) ·
[caseymuratori.com writeup](https://caseymuratori.com/blog_0024) ·
[notes gist](https://gist.github.com/vsapsai/6f524c5095a7ae647f1746c762954f9f) ·
[visual transcript](https://github.com/jceipek/designing-reusable-components/blob/master/ReusableComponents/ReusableComponents.md)

> Context: this is the full 2004 lecture behind the shorter "designing
> libraries well" clip — same person, same underlying experience, more
> mechanism. Granny's 2.x API shipped in 2002, ended up in 2,600+ product
> SKUs, and stayed stable for roughly 12 years; the talk is Muratori's
> retrospective on what made that possible.

## Core problem: integration discontinuities

Code reuse is universally recommended and routinely fails in practice.
Muratori's diagnosis: as a project's requirements shift — a new feature, a
milestone, ship-time pressure — a badly designed API forces disproportionate
rework to get from where the integration currently stands to where it needs
to be. A well-designed API lets you move incrementally toward whatever you
need next. A discontinuity is a gap where the only way forward is a costly
rewrite or workaround instead of an incremental step.

## Three kinds of reuse

These fail differently, so he evaluates them separately:

- **Layer** — a thin abstraction over an underlying service (OpenGL over the
  GPU). Works when the service is standardized; breaks when two layers
  compete for the same resource.
- **Engine** — the reused code owns control flow; you write to its rules
  (you are a plugin to it).
- **Component** — data flows both ways: you feed it input, it hands back
  data that actually drives your game. Hardest to design well, and the
  subject of the rest of the talk.

## The five characteristics

Four originally, plus **flow control** after Chris Hecker pointed out it was
implicit in the other four all along.

| Characteristic | Question it answers | Tension |
|---|---|---|
| **Granularity** | Can an operation decompose into smaller, separately-controllable steps? | Flexibility vs. simplicity — a coarse call should typically decompose into ~2–4 finer ones, not zero and not twenty. |
| **Redundancy** | Are there multiple ways to do the same thing? | Convenience vs. orthogonality — every redundant path is something to design, document, and keep consistent. |
| **Coupling** | Does using capability A silently require B to already be true? | "Always bad," in his words, even when sometimes unavoidable — the cost is that the API doesn't tell you about the dependency until you hit it. |
| **Retention** | Does the API keep its own persistent state you must keep synced with yours (retained mode), or can you call it fresh each time (immediate mode)? | Synchronization burden vs. automation. His physics-API example: retained mode forces you to diff your game state against the API's internal copy — exactly the brittle synchronization code nobody wants to write. |
| **Flow control** | Who calls whom? | Callback- and inheritance-driven designs invert control so the library drives your code; he argues the caller should retain authority, with non-callback alternatives offered wherever the library is tempted to ask for one. |

## Practical checklist

Priority order, condensed from the talk:

1. Write usage code before designing the API — let real call sites drive the shape.
2. Every retained-mode construct needs an immediate-mode equivalent.
3. Every callback/inheritance-based path needs a non-callback alternative.
4. Don't force the caller to adopt API-specific datatypes in place of their own.
5. Operations should decompose into a handful (2–4) of finer-grained calls, not stay monolithic.
6. Data structures should be transparent — constructible, inspectable, serializable by the caller — not opaque handles.
7. Resource management integration should be optional, never mandatory.
8. File-format usage should be optional, never a forced coupling.
9. Ship runtime source, even though (per the shorter clip) few people will actually read it — the point is removing the excuse for a discontinuity, not the expectation that anyone opens the file.

## The thesis

> "The goal ... is to make it so that, at all times — as people integrate the
> product — they are always able to do only what they think they should have
> to do to get the next thing that they need out of the API," rather than
> being forced into a disproportionate workaround because the API had a gap.

---

## Mapping onto the Domain Kernel invariants

Four of the five characteristics land almost directly on what the domain
kernel pattern already enforces structurally rather than by API taste; the
fifth (redundancy) is closer to Muratori's open judgment call than to
anything the kernel pattern currently addresses.

- **Coupling → purity.** "Using A silently requires B" is precisely the
  failure mode kernel purity rules out by construction: no filesystem,
  network, clock, randomness, or environment access means there is no hidden
  dependency for a caller to trip over. Muratori calls coupling "always bad
  but often unavoidable" for an ordinary library; the kernel pattern's bet is
  that for *this* class of component, it's avoidable — because the sandbox
  won't grant the access that hidden coupling usually rides in on.

- **Retention → the pure transition function.** A kernel's `apply(state,
  action) -> state` is immediate-mode by definition — there is no parallel
  API-owned state to synchronize against, because the kernel doesn't retain
  anything the caller doesn't hand it back next call. This is Muratori's
  retained-vs-immediate tension resolved by fiat rather than by offering
  both modes: the kernel only offers the immediate-mode side, and the
  caller's own state (in whatever host language) is the only copy that
  exists.

- **Flow control → delivery-agnosticism.** A kernel never calls back into
  its host — it has no I/O to schedule a callback through, and the
  transition surface (`legal-actions`, `apply`, `view-for`, `outcome`) is
  entirely caller-invoked. This is Muratori's "game retains authority"
  principle taken to its structural limit: the kernel *cannot* invert
  control, because inversion would require capabilities the sandbox doesn't
  grant.

- **Granularity → the WIT boundary's shape.** His 2–4-way decomposition rule
  is a direct design check for Mode C (Boundary) work: a transition surface
  that's one monolithic `play_game(state) -> result` call fails this the
  same way a monolithic `UpdateNode` failed Granny's callers; a boundary
  split into `legal-actions` / `apply` / `view-for` / `outcome` is closer to
  what he's describing as good granularity. Worth checking new kernel
  boundaries against this explicitly rather than assuming purity implies
  good decomposition — they're independent properties.

- **Redundancy → unresolved.** The kernel pattern doesn't currently have a
  position on this one. A pure core has no obvious pressure toward or away
  from offering multiple equivalent ways to reach the same state transition,
  and Muratori himself treats it as a judgment call rather than a rule. This
  is the one dimension of the five where the kernel pattern's discipline
  (purity, narrow boundary) doesn't automatically resolve the design
  question the way it does for the other four — worth flagging in
  `POTENTIAL_LIMITS.md` as a case where structural enforcement runs out and
  ordinary API taste is still required.
