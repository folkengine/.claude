# The Domain Kernel — <PROJECT/ORG> Charter

*A pure, delivery-agnostic core of one domain's logic, with its boundary defined
as a language-neutral interface and its purity enforced by the runtime it ships
in.*

> Template — replace bracketed parts; keep the structure. See
> `references/charter.md` for the rationale behind each section.

## Definition

A **domain kernel** in this project is a unit that:

1. **Is pure** — total functions from state + input to new state + events; no
   filesystem, network, clock, randomness, or environment access.
2. **Is delivery-agnostic** — unaware of how it is invoked; the same kernel backs
   <list the deliverables: CLI, service, web, tests>.
3. **Owns exactly one domain** — <name the domain(s)>; specialized along the
   domain axis, general along deployment.
4. **Exposes a narrow, ideally language-neutral boundary** — <name the boundary:
   a trait, a WIT world>.

## What makes it more than a rename

Functional Core / Imperative Shell gives purity; Hexagonal gives
delivery-agnosticism. Our addition: **the boundary is a language-neutral contract
and purity is enforced by the runtime.** A kernel compiled to a WebAssembly
component imports nothing it isn't granted, so it cannot perform I/O — the
property is structural, not lint-dependent — and the same contract is
implementable in any language.

## Invariants (enforced, not aspirational)

- Pure by default: `cargo add <crate>` yields the pure kernel; convenience is opt-in.
- No format/transport crate in any public signature.
- Passes the `kernel-purity` CI job (`--no-default-features` builds; banned crates
  absent from the pure tree) and the kernel clippy/deny lints.

## Positioning

- vs **DDD Shared Kernel** — that shares a model subset between bounded contexts;
  this isolates a whole domain behind a portable boundary.
- vs **DDD Core Domain** — that is a strategic value designation; this is a
  structural purity/boundary one.
- vs **Microkernel architecture** — closest structurally; we add the purity
  mandate and the sandbox-enforced, language-neutral boundary.

## What is NOT a kernel here

<list the adapters: the gRPC service, the web frontend, the persistence layer,
the CLI — these wrap the kernel and own all I/O.>

## Honest limits

- Naming is adjacent to Shared Kernel / Core Domain — we lead with the synthesis.
- Component-model tooling is strong in Rust, uneven elsewhere; server-side wasm
  lacks threading, so parallel compute stays host-side. (Verify current status.)
- Any cross-domain shared trait stays thin: state, action, apply, event,
  projection.

## One-line definition

> A **domain kernel** is one domain's pure logic behind a language-neutral,
> sandbox-enforced boundary: a functional core that is delivery-agnostic by
> design and portable across stacks by construction.
