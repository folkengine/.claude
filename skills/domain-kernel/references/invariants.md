# Kernel invariants and how to detect violations

Use this when assessing (Mode A) or deciding what to enforce (Mode B). Each
invariant has a definition, the failure mode, and how to spot it in real code.

## 1. Pure — no I/O of its own

**Definition.** Every public operation is a total function: state + input in,
new state + emitted events out. No filesystem, network, clock, randomness, or
environment access.

**Failure modes.**
- A method that performs `std::fs::*`, opens a socket, reads `std::env`, or calls
  a runtime (`tokio`, `reqwest`).
- A method that *takes a path* (`impl AsRef<Path>`, `&Path`) — that is I/O policy
  living in the kernel. Prefer taking bytes/`&str` and returning a value; let an
  adapter own paths and directories.
- Hardcoded path opinions (e.g. `std::fs::write("generated/…")`) — the kernel is
  asserting a CWD layout.

**Detection.** `scripts/check_purity.py` greps for these. Also read every public
`fn` signature for `Path`/`PathBuf`. A pure conversion (`to_yaml(&self) -> String`)
is fine; a persisting one (`save(&self, run: &str)` that writes a file) is not.

## 2. No format/transport crate in the public API

**Definition.** The kernel may depend on a serialization *trait* (e.g. `serde`),
but a concrete *format* crate (`serde_yaml`, a specific JSON lib) and transport
crates must never appear in a public signature.

**Failure modes (graded).**
- **Hard leak:** a public return type or struct field names the format crate —
  `fn to_yaml(&self) -> Result<String, serde_yaml::Error>`, or
  `enum MyError { Yaml(serde_yaml::Error) }`. This forces every downstream caller
  to depend on the format to handle the error.
- **Cosmetic:** a variant *named* `Yaml` whose payload is already opaque
  (`Yaml(Box<dyn Error>)`). Lower priority — a later rename, not a coupling.

**Fix.** Introduce an opaque error (`struct CodecError(Box<dyn Error + 'static>)`)
the kernel owns; convert at the seam (`.map_err(CodecError::new)`). The one place
the format type may legitimately appear is a `From<FormatError>` impl that boxes
it — that is the adapter seam, not a leak.

## 3. Pure by default

**Definition.** A bare add of the crate yields the pure kernel. Convenience
(serialization, persistence, bot harnesses) is opt-in.

**Failure mode.** `default = ["serialization", "persistence", …]` — the most
common and highest-impact violation. A consumer must *know* to pass
`default-features = false` to get a kernel.

**Fix.** `default = []` (or a minimal pure default) plus a `full` umbrella so
examples/tests still resolve. See `rust-enforcement.md` for the CI/Makefile
ripple this creates.

## 4. Delivery-agnostic

**Definition.** The kernel contains no awareness of its caller — no gRPC types,
no HTTP, no CLI parsing, no UI.

**Detection.** Look for `tonic`/`axum`/`clap`/web types in the core modules. These
belong in adapters that *wrap* the kernel.

## 5. Hidden-information projection (for multi-party domains)

**Definition.** If different actors are entitled to see different things, the
kernel exposes a projection (`view_for(state, actor) -> View`) rather than letting
callers read full state. This is the seam a crypto / privacy layer plugs into.

**Detection.** Present and used? Or do callers reach into full state and filter
themselves (a leak of the entitlement rule out of the kernel)?

## 6. Narrow, stable boundary

**Definition.** The surface is small and a change to internals does not ripple to
callers. A transition surface (`to_act` / `legal_actions` / `apply` / `view_for` /
`outcome`) is the ideal shape; it is also what maps cleanly to a WIT world.

---

## Output shape for an assessment

For each violated invariant: the invariant, file:line evidence, hard-vs-cosmetic
classification, and the minimal fix. Then a recommended sequence — almost always
"flip default + de-leak public error types first" (near-zero risk, ~80% of the
benefit), then extract I/O to an adapter, then the boundary work.
