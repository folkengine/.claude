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

## Position against the crowded neighbors

The term is mostly unclaimed but sits among look-alikes; differentiate each:

- **DDD Shared Kernel** — a subset of a domain *model* two bounded contexts agree
  to co-own. About sharing between teams; a domain kernel is a whole domain's
  logic behind a portable boundary. Different problem.
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

## Structure

The template covers: definition + invariants; "what makes it more than a rename";
positioning against neighbors; the two enforcement levels (lint + sandbox); the
WIT boundary; honest limits; a one-line citable definition. Keep it ~1.5 pages —
a manifesto, not a book.
