# Writing the charter / positioning the pattern

Use this in Mode D. `assets/DOMAIN_KERNEL_CHARTER.md` is the fill-in template;
this file is the *why* so the result doesn't read as a rename of something older.

## The one rule

**Lead with the synthesis.** The two ancestors are well known:
- **Functional Core, Imperative Shell** (Gary Bernhardt) → the purity discipline.
- **Hexagonal / Ports and Adapters** (Alistair Cockburn) → delivery-agnosticism.

If that were all, "domain kernel" is a relabel and reviewers will say so. The
contribution is the third leg: **the boundary is a language-neutral contract and
purity is enforced by the runtime, not by convention.** A kernel compiled to a
WebAssembly component imports nothing it isn't granted, so it *cannot* do I/O —
the property you'd otherwise lint for is guaranteed structurally, and the same
contract is implementable in any language. Purity-as-discipline becomes
purity-as-physics; portability-across-stacks becomes a property of the boundary.

State that synthesis up front, or the piece has no reason to exist.

### Saying it to a *Hard Parts* reader

Readers of *Software Architecture: The Hard Parts* already trust automated
checks that a design rule still holds (Hard Parts: *fitness function*).
`check_purity.py`, the lint configs and `kernel-purity.yml` are fitness
functions in exactly that sense. The third leg is the step past them: **a
fitness function is a test that fails; a no-import WIT world is a capability
that does not exist.** The check catches a violation after someone writes
it. The sandbox makes the violation impossible to write. One sentence for
that reader: *a domain kernel is the purity check, moved from CI into the
runtime.*

## Ancestors worth naming

The two ancestors above give the two legs. Two more show where purity came
from. Name them for DDD and functional-programming readers:

- **Evans, *Domain-Driven Design* (2003), ch. 10 "Supple Design."** Evans
  asks for as much logic as possible in functions that return a result and
  change nothing else (DDD: *side-effect-free functions*), and for
  operations whose output has the same type as their input, so calls chain
  (DDD: *closure of operations*). `apply : state × action → state` is both.
  He also asks you to cut the model along the domain's natural seams
  (DDD: *conceptual contours*) — the reason a kernel's boundary has a best
  size, not a smallest one. Ch. 15 "Distillation" adds two more: keep the
  core model physically apart from support code (DDD: *segregated core*),
  and split a pure algorithm the domain uses out of the model
  (DDD: *cohesive mechanism*). A kernel can package either, but only the
  first is a *domain* kernel.
- **Jérémie Chassaing, "Functional Event Sourcing Decider" (2021).** The
  functional-DDD community's standard four-part shape for data that
  changes together (functional DDD: *Decider*):

  ```
  decide  : (command, state) -> list<event>
  evolve  : (state, event)   -> state
  initial : state
  terminal: state -> bool
  ```

  A kernel's transition surface is this shape folded together: `apply` runs
  `decide`, then `evolve` over each event; `outcome` is `terminal`. Say so —
  it makes the functional-DDD line an ancestor, not an omission.

So DDD is an ancestor as well as a neighbor. Keep Shared Kernel and Core
Domain as the two look-alikes to position against (below). The honest
lineage: Evans described the pure core as a discipline in 2003; hexagonal
architecture gave it a boundary; the component model made it enforceable.

## A companion, not an ancestor

Ford, Richards, Sadalage and Dehghani, *Software Architecture: The Hard
Parts* (2021), is about the layer above the kernel: how many deployable
units to have, how they talk, and where the data lives. It is neither
ancestor nor neighbor. Its unit is the smallest thing you can deploy alone,
data included (Hard Parts: *architecture quantum*). A kernel is never one:
it has no I/O, store or clock. The deployable unit is always shell +
kernel(s) + store.

The book decides how to cut the deployable units. The kernel decides what is
pure inside each one — and it makes the book's hard choices cheaper to
revisit, because re-cutting the units does not touch the kernel. (Mark
Richards, a co-author, also wrote up the microkernel pattern positioned
against below.)

## Reuse: a fifth option

*The Hard Parts* (ch. 8) lists four ways to reuse code. A kernel packaged as
a WebAssembly component is a fifth. Without this table, readers of the book
file it under "shared library" and bring that row's objections with it.

| Option | Runs | Contract | Main cost |
|---|---|---|---|
| Copy the code into each consumer | In-process | None | Copies drift apart |
| Shared library | In-process | One language's API | Versioning; dependency conflicts |
| Shared service | Over the network | Language-neutral (HTTP, gRPC) | Network hop; if it is down, callers fail |
| Sidecar / service mesh | Next to each service | Operational only | Fits cross-cutting ops concerns, not domain logic |
| **Kernel as a Wasm component** | In-process | Language-neutral (WIT), sandboxed | Versioning (see `assets/CONTRACT_POLICY.md`) |

The kernel row takes the good column from both library and service. It runs
in-process like a library: no network hop, and no failure when another
service is down. It is language-neutral and isolated like a service, with one
artifact for every consumer. It has no transitive dependencies to conflict.
Versioning stays a real cost — do not hide it.

## Position against the crowded neighbors

The exact phrase is free, but the search space around it is fully occupied:
looking up "domain kernel" returns DDD Shared Kernel, Core Domain and
microkernel — the very neighbors below. A reader who hears the term and
searches lands on the wrong pattern, not on nothing. That is *why* this
positioning section exists; differentiate each:

- **DDD Shared Kernel** — a subset of a domain *model* that two teams'
  domain areas (DDD: *bounded contexts*) agree to co-own. About sharing
  between teams; a domain kernel is a whole domain's logic behind a portable
  boundary. Different problem.
- **DDD Core Domain** — the part delivering the most competitive value. A
  *strategic* designation about where to invest; a domain kernel is a *structural*
  one about purity and boundary. Orthogonal.
- **Microkernel (plug-in) architecture** — the closest structural neighbor: a
  minimal core plus plug-ins behind a stable interface. A domain kernel adds the
  purity mandate and the language-neutral, sandbox-enforced boundary, and aims the
  core at one business domain.
- **Clean Architecture entities/use-cases** — compatible, but framed around
  dependency direction; the domain kernel is framed around purity + a portable,
  runtime-enforced boundary.
- **Hexagonal / Ports and Adapters (Cockburn)** — the closest ancestor, not just
  a neighbor: a domain kernel is a hexagonal core with purity additionally
  mandated and the boundary additionally made language-neutral and
  structurally enforced. State that subset relationship explicitly, or readers
  will assume "domain kernel" is hexagonal with new branding. Full comparison,
  including a walkthrough against a conventional multi-language hexagonal
  implementation, in `references/hexagonal-comparison.md`.

## Honest limits to include

- **Naming.** Adjacent to Shared Kernel / Core Domain; without the synthesis,
  readers collapse it into one of those.
- **Tooling maturity.** As of writing, the component model has largely solved
  cross-language composition and Rust's toolchain is polished, but other languages
  are uneven, server-side wasm lacks threading, and WASI async is stabilizing.
  Check current status before claiming maturity — this dates fast; search rather
  than assert from memory.
- **Abstraction risk.** A cross-domain kernel contract must stay thin or it
  becomes useless.
- **Strict contracts cost something.** WIT is an exact, typed contract
  (Hard Parts: *strict contract*), chosen on purpose. The bill is
  brittleness and versioning work: every change is visible, and every
  consumer feels it. A loose contract around a
  pure core would bring back the ambiguity that purity removes. Own the
  cost, and ship a change policy (`assets/CONTRACT_POLICY.md`).
- **What the kernel does not do.** Scaling, uptime, fault tolerance and
  deployment belong to the deployable unit — the shell — not to the kernel.
  The kernel helps testability and maintainability only. Its help with scale
  is indirect: you can re-cut the deployable units without touching the
  domain. Never claim a scaling benefit.
- **Don't oversell.** Every charter ends with where the pattern loses.
  *The Hard Parts* (ch. 15) warns against evangelizing: once you are selling a pattern
  instead of analyzing a situation, you have stopped being an architect.

## Structure

The template covers: definition + invariants; "what makes it more than a rename";
positioning against neighbors; the two enforcement levels (lint + sandbox); the
WIT boundary; what the kernel does not do; honest limits; where this loses; a
one-line citable definition. Keep it ~1.5 pages — a manifesto, not a book.
