---
name: domain-kernel
description: >-
  Codify, assess, and enforce the **domain kernel** pattern — a pure,
  delivery-agnostic core of one domain's logic behind a narrow, ideally
  language-neutral boundary. Use this whenever the user wants to make a library
  or crate a "pure core", "domain kernel", "functional core", or "hexagonal /
  clean core"; assess or enforce kernel purity (no I/O, no format crate leaking
  into the public API, no default-on serialization); strip filesystem or
  serialization concerns out of a core library; define a WIT / WebAssembly
  component boundary so business logic is reusable across stacks and languages;
  set up clippy / cargo-deny / CI purity gates for a core crate; or write a
  domain-kernel charter or positioning doc. Trigger even when the user only says
  things like "make this crate pure", "keep I/O out of the core", "extract the
  serialization", or "package my logic as a wasm component" without ever naming
  "domain kernel".
---

# Domain Kernel

A **domain kernel** is one domain's logic, isolated so it is:

1. **Pure** — every operation is a total function from state and input to new
   state and emitted events; no filesystem, network, clock, randomness, or
   environment access of its own.
2. **Delivery-agnostic** — it knows nothing about how it is invoked; the same
   kernel backs a CLI, a service, a web frontend, and a test harness unchanged.
3. **Single-domain** — specialized along the domain axis, general along the
   deployment axis (the inverse of a framework).
4. **Narrow-boundaried** — exposed through a small, stable interface, ideally a
   language-neutral one so the kernel can be implemented in one language and
   driven from another.

Naming a component a kernel is both a description and a *constraint*: it commits
the code to staying pure and small, and that commitment is what makes the
boundary trustworthy. The job of this skill is to make that constraint
**assessable and enforceable**, not aspirational.

The canonical invariants and how to detect violations live in
`references/invariants.md` — read it before assessing or enforcing.

## Pick the mode(s)

Most requests map to one or more of these four phases. Do only what's asked;
they compose but are independently useful.

| The user wants… | Mode |
|-----------------|------|
| "is this core actually pure / what's leaking" | **A — Assess** |
| "make the core pure / keep I/O out / enforce it" | **B — Enforce** |
| "expose the logic across stacks / WIT / wasm component" | **C — Boundary** |
| "write up / name / position this pattern" | **D — Document** |

When the request is open-ended ("help me make pkcore a real kernel"), run A
first to ground everything in real findings, then propose B/C/D as follow-ups.

---

## Mode A — Assess

Produce a findings report grounded in the actual code, not assumptions. **Fetch
or read the real source first** — the value is in file:line evidence.

1. Run the deterministic checker against the crate root:
   ```bash
   python scripts/check_purity.py <path-to-crate>
   ```
   It flags: default features that pull I/O/format crates, format-crate types in
   public signatures, and direct `std::fs`/`std::net`/`std::env`/`tokio`/`reqwest`
   use in non-test code. It needs only Python — no Rust toolchain.
2. Read `references/invariants.md` and check the crate against each invariant by
   hand for the things a grep can't catch (e.g. a method that *takes a path* vs.
   one that takes bytes; hidden-info projection present or not).
3. Write the report: one section per violated invariant, each with file:line
   evidence and the minimal fix. Distinguish a **hard leak** (a format/IO type in
   a public return type — forces downstream coupling) from a **cosmetic** one
   (a variant *named* `Yaml` whose payload is already opaque). Lead with the
   single highest-leverage change.

Default features that turn the whole serialization/IO stack on are the most
common and most impactful finding: a kernel should be **pure by default**, with
convenience behind opt-in features.

---

## Mode B — Enforce

Turn the invariants into machine checks. Two levels — apply both.

**Lint level.** Drop in the assets and adapt the banned lists to the crate's
real dependencies:
- `assets/clippy.toml` — `disallowed-types` / `disallowed-methods` for `std::fs`,
  `std::net`, `std::env`, `std::process`, and runtime crates.
- `assets/deny-bans.toml` — a `cargo-deny` `[bans]` fragment keeping format /
  transport crates out of the default build (merge into an existing `deny.toml`).

**Sandbox / build level.**
- Set `default = []` (or a minimal pure default); move convenience into a `full`
  umbrella feature so examples and `make test` still resolve. Update any CI or
  Makefile invocation that relied on default features to pass `--features full` —
  **a test that names `--test <name>` with `required-features` will *error*, not
  skip, under empty defaults**, so this step is mandatory, not cosmetic.
- Add `assets/kernel-purity.yml` — a CI job that builds `--no-default-features`
  and asserts (via `cargo tree`) that banned crates are absent from the pure
  build. This is the testable definition of "kernel".

Details, rationale, and the full mapping live in `references/rust-enforcement.md`.

---

## Mode C — Boundary

Express the kernel's transition surface as a **WIT world** so any language can
drive it, and (with a no-import world) let the component sandbox enforce purity
structurally — a component cannot touch I/O it is not granted.

1. Identify the transition surface. For a state machine it is typically:
   `to-act(state) -> option<seat>`, `legal-actions(state, …) -> list<action>`,
   `apply(state, …) -> result<state, error>`, a hidden-info `view-for(state, …)`,
   and `outcome(state) -> option<…>`. Map the domain's state/action/event/view
   types to WIT `record`/`enum`/`variant`/`list`.
2. Write the `.wit`. Use `assets/trick-taking.wit` as a worked example. Watch the
   mapping pitfalls (`usize → u32`, `list<u8> → bytes`, `result<T,E>` is signalled
   by raise/throw, Rust enum-with-payload → WIT `variant`). Full recipe in
   `references/wit-boundary.md`.
3. **Validate without a Rust toolchain** by generating bindings:
   `componentize-py -d <wit> -w <world> bindings out/`. If the world resolves,
   the contract is well-formed and implementable in any language.
4. Scaffold the guest (the real kernel via `cargo component build`) and a host
   (JS via `jco`, or Python via `componentize-py`). Recipes and the honest
   caveats (the CPython guest pulls WASI; the Rust guest imports nothing; no
   server-side threading) are in `references/hosts.md`.

Keep any *shared* kernel trait thin — state, action, apply, event, projection.
Pushing scoring/trump/pots into a cross-domain contract yields an abstraction
that fits everything and helps nothing.

---

## Mode D — Document

Write the charter that names and positions the pattern. Use
`assets/DOMAIN_KERNEL_CHARTER.md` as the template. The one rule that keeps it
from reading as a rename: **lead with the synthesis** — functional-core purity +
hexagonal delivery-agnosticism, made portable and runtime-enforced via the
component model — and position explicitly against DDD's Shared Kernel and Core
Domain, against Microkernel architecture, and against hexagonal architecture
itself, since readers will otherwise pattern-match it to one of those (or
assume it's just hexagonal by another name). Rationale and the prior-art map
are in `references/charter.md`; the detailed hexagonal-vs-domain-kernel
comparison — including a walkthrough against a conventional TS/Java/Kotlin/Go
hexagonal implementation — is in `references/hexagonal-comparison.md`.

---

## Principles

- **Build and verify before presenting.** Where a toolchain is available, compile
  and run; where it is not (e.g. no Rust in the environment), validate statically
  (parse the WIT, generate bindings, grep ripple sites) and say plainly what was
  and wasn't compiled. Never present untested code as verified.
- **Hand leaks vs. cosmetic.** Spend effort on format/IO types in public
  signatures and default-on IO; a variant *name* that mentions a format is a
  later cleanup, not a coupling.
- **Pure by default.** The headline fix for most crates is flipping `default` to
  empty and moving convenience behind opt-in features.
- **The contract is the artifact.** Once a WIT world exists, it — not any one
  language's types — is the thing other stacks depend on.
