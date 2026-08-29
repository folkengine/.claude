# Domain Kernel vs. Hexagonal Architecture

> **Note on the ECC comparison below:** the `hexagonal-architecture`
> skill it is compared against is an external artifact that is not
> present in this repo. Treat that section as author context, not as
> something a reader can verify from here; the rest of this document
> stands on published sources.

An addendum for Mode D (and for anyone who reaches for this skill already knowing
hexagonal architecture). Hexagonal is the closest ancestor — the charter's
synthesis line names it, and `charter.md`'s neighbor list points here for the
full comparison behind its hexagonal entry. Two comparisons: hexagonal as
Cockburn defined it, and hexagonal as one concrete team implements it (ECC's
`hexagonal-architecture` skill, which targets TypeScript/Java/Kotlin/Go
services). Read this before writing the charter's positioning section if the
audience will already know hexagonal.

## The one-line difference

Hexagonal architecture inverts *dependencies*: the core depends on interfaces,
adapters depend on the core, and nothing points inward-to-outward. A domain
kernel does that too, but adds two things hexagonal doesn't require: a
**totality/purity mandate on the core itself** (not just "no framework imports,"
but no I/O of any kind, expressed as total functions over state), and a
**structurally enforced, language-neutral boundary** (a WIT world / WASM
component) instead of a same-language interface plus code review.

Put differently: every domain kernel's core could pass as a hexagonal core.
Not every hexagonal core is a domain kernel — most aren't, and don't need to be.

## Against hexagonal architecture in general (Cockburn)

| Axis | Hexagonal / Ports & Adapters | Domain Kernel |
|---|---|---|
| **What's mandated** | Dependency direction: core depends on ports, adapters depend on core. | Dependency direction *plus* purity: the core is a total function `(state, input) -> (state, events)` with no ambient effects at all. |
| **How compliance is checked** | Code review, architecture tests (e.g. dependency-direction linters like ArchUnit/dependency-cruiser), convention. | Compiles or it doesn't: `--no-default-features` build, clippy `disallowed-types`, `cargo-deny` bans, and — at the boundary — a WASM component that structurally cannot import I/O it wasn't granted. Purity-as-discipline becomes purity-as-physics. |
| **Boundary language** | Ports are interfaces/traits/protocols in the core's own language. Language-neutral contracts *do* exist in hexagonal practice — gRPC/protobuf or OpenAPI ports are common — but they buy a network hop and a separate service, not a shared core. | A WIT world: the same compiled kernel binary is embedded in-process and driven from Rust, JS (`jco`), or Python (`componentize-py`). What's unique isn't language-neutrality itself but combining it with in-process embedding and a sandbox that enforces purity. |
| **Effect handling** | Ports abstract *specific* dependencies (a `ClockPort`, a `LoggerPort`, a `UserRepositoryPort`) — the core still calls out through them mid-operation. | The core takes *no* ports. Effects the outside world needs (persistence, clock, randomness) are supplied as plain input before the call or read from the return value after — the kernel itself never calls out. |
| **Granularity** | Typically one hexagon per service/bounded context, often several use cases sharing one set of ports. | One kernel per domain, deliberately smaller — a kernel wrapping "scoring/trump/pots" as a single interface is flagged as too broad (see Mode C). |
| **Portability claim** | "Swap the database without rewriting business rules" — true within one language/runtime. | "Drive the same compiled logic from a CLI, a web frontend, and a service in a different language" — true across languages/runtimes. |
| **Testing story** | Fakes/stubs implement the ports; unit-test the core against them. | Fakes aren't needed for the core (it has no ports to fake) — you assert on returned state/events directly. Ports reappear only at the host layer that drives the WASM component. |
| **Maturity / cost** | Decades old, boring, well-tooled in every mainstream language. | Newer and uneven — Rust tooling polished, other languages and server-side concerns (threading, WASI async) historically lagging. These specifics date fast: per `charter.md`'s honest-limits rule, check current component-model status before asserting them in a charter — search, don't quote this table from memory. |

The practical takeaway: hexagonal architecture is a *shape* (dependencies point
inward); a domain kernel is that shape with the inner hexagon additionally
required to be pure and its boundary additionally required to be
runtime-checkable and language-neutral. If a codebase only needs "swap Postgres
for DynamoDB without touching business logic," hexagonal alone is the right
amount of structure — a domain kernel is over-engineering for that ask.

## Against ECC's `hexagonal-architecture` skill specifically

That skill is a solid, conventional hexagonal implementation guide for
TypeScript/Java/Kotlin/Go services — domain / application (use cases) / ports
(inbound + outbound) / adapters / composition root, with a migration playbook
and a per-language mapping table. Concretely, where it differs from this skill:

- **No purity gate.** Its "Best Practices Checklist" says domain/use-case layers
  should import only internal types, and lists anti-patterns (ORM models leaking
  into entities, use cases reading `req` directly) — but nothing enforces this
  beyond code review. There's no equivalent of Mode B's clippy/cargo-deny/CI
  triad, and no build configuration (`default = []`) that makes an impure core
  fail to compile. A reviewer has to *notice* the leak; this skill's Mode A
  finds it with a script and a file:line report.
- **Outbound ports still model effects, not just data.** Its `OrderRepositoryPort`,
  `PaymentGatewayPort`, `ClockPort` are exactly the kind of ambient-effect ports a
  domain kernel eliminates — the ECC use case *calls out* through them mid-flow
  (`await this.paymentGateway.authorize(...)`). A domain kernel's core would
  instead take everything it needs as input and return events describing what
  should happen, leaving the actual `authorize` call to the host driving the
  kernel. This isn't a flaw in the ECC skill — it's a different, more common
  design point (imperative-shell-adjacent orchestration) that most teams should
  use instead of the stricter one.
- **Same-language boundary only.** Its "Multi-Language Mapping" section shows
  how to *re-implement* the same pattern independently in four languages — each
  service's ports are still native interfaces in that service's own language.
  There's no shared contract one implementation can be driven through from
  another language; each hexagon is language-local. A domain kernel's WIT
  boundary is the thing that would let one team's Go adapter drive another
  team's Rust core directly, no reimplementation.
- **Mutation discipline is a convention, not a contract.** Its example comment
  says `markAuthorized` "returns a new Order instance; it does not mutate in
  place" — correct, but nothing stops the next contributor from mutating in
  place. A domain kernel's `apply(state, action) -> result<state, error>`
  shape makes new-value-out the only way the contract can express a
  transition. Be precise about what that guarantees: inside a Rust guest,
  by-value ownership means the old state is genuinely gone after the call;
  across the WIT boundary, values are *copied*, so a host still holds its copy
  of the old state — the guarantee there is that the kernel never mutates it,
  not that the host can't.
- **Scope.** ECC's skill is deliberately broad — four language ecosystems, a
  full migration playbook for legacy systems, testing guidance per layer. This
  skill is deliberately narrow — one pattern, four modes, Rust/WASM-first. Reach
  for the ECC skill when *decoupling from infrastructure* is the goal in an
  existing multi-language codebase; reach for this skill when *cross-language
  portability and structurally-verified purity* of one specific domain's logic
  is the goal.

## When to use which (or both)

- **Just need swappable infrastructure** (DB, external API, message bus) inside
  one service, one language → ECC's `hexagonal-architecture` skill is
  sufficient; it covers the conventional path for TS/Java/Kotlin/Go more
  broadly than this skill does, and the pattern itself is the decades-proven
  one.
- **Need the same business logic driven from more than one language/runtime**,
  or need purity to be a build-time/CI-time guarantee rather than a review
  checklist item → this skill.
- **Both at once is normal, not redundant.** A domain kernel's WIT-bound guest
  is naturally the innermost hexagon of a larger hexagonal system: the kernel is
  the domain core, and each language-specific host that drives it (via `jco` in
  a Node service, via `componentize-py` in a Python one) is itself a hexagonal
  adapter layer wiring the kernel's outputs to real ports (a `PaymentGatewayPort`,
  a `UserRepositoryPort`) in that host's language. The kernel doesn't replace the
  outer hexagon's ports/adapters — it replaces what would otherwise be that
  hexagon's domain/application layer with something portable and structurally
  pure.

## For the charter (Mode D)

`charter.md`'s neighbor list includes hexagonal architecture and points here —
keep that entry when writing or updating `assets/DOMAIN_KERNEL_CHARTER.md`,
because hexagonal is the one ancestor readers are most likely to already know
well, and without an explicit entry they will collapse "domain kernel" into
"hexagonal with new branding." Use the one-line difference at the top of this
file as the charter's positioning sentence, and link here for the full
comparison rather than inlining the table — the charter should stay ~1.5
pages.
