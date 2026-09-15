# Kernel invariants and how to detect violations

Use this when assessing (Mode A) or deciding what to enforce (Mode B). Each
invariant has a definition, the failure mode, and how to spot it in real code.
Borrowed terms are defined in plain words in `glossary.md`.

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

**Detection.** `scripts/check_purity.py` greps for these (HARD findings; it
has its own test suite in `scripts/test_check_purity.py`). Also read every public
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

**Fix.** Introduce an opaque error
(`struct CodecError(Box<dyn Error + Send + Sync + 'static>)` — the
`Send + Sync` matters; without it the error cannot cross a thread or feed
`anyhow`)
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

## 7. Things that must change together live in one kernel

**Definition.** One `apply` is the only all-or-nothing step the pattern
offers. So anything that must change all-or-nothing belongs in one kernel
(DDD: *consistency boundary*). A change that spans two kernels cannot be
all-or-nothing. Model it as explicit in-between states that the kernels
already know — `held`, `awaiting-capture`, `awaiting-settlement` — and let
the shell move each kernel through them.

**The intra-kernel question.** One kernel can hold several natural groups of
data that change together — several accounts in a ledger, several hands in a
tournament. Does one `apply` change the whole state at once, or only one
group, with the others catching up later? Both answers are fine. Pick one on
purpose and record it in the kernel's decision record
(`assets/KERNEL_ADR.md`). Vernon's rules (*Implementing Domain-Driven Design*,
2013) for sizing a cluster of data that changes together (DDD: *aggregate*)
are the best guide.

**Failure mode.** A shell updates two kernels and assumes both succeed or
both fail — for example, "post to the ledger and update the exposure limit
together" — with no in-between state to land in when one of them fails.

**Detection.** Ask: "Name an operation that must never half-happen. Do its
writes cross a kernel boundary?" If they do, either the two parts belong in
one kernel, or the domain needs explicit in-between states. Crossing *with*
in-between states is fine. Crossing *without* them is a hard finding.

## 8. State belongs to the kernel that changes it

**Definition.** Every piece of state has exactly one owner: the kernel whose
`apply` changes it. Other kernels and consumers get a projection
(`view_for`) — never a direct read of the owner's state, and never a shared
copy they can write.

**When two domains claim the same data.** *Software Architecture: The Hard
Parts* (ch. 9) gives four answers. The kernel's version of each:

| The book's answer | Plain meaning | Kernel answer |
|---|---|---|
| one owner, others ask (Hard Parts: *delegate*) | One side owns the data; the other asks it | **Default.** The owner kernel changes it; the other gets a projection. |
| split the data (Hard Parts: *table split*) | Each side takes the part it changes | Split the kernel along the same line. |
| merge the owners (Hard Parts: *service consolidation*) | Put both sides in one unit | **Resist.** This is how a god-kernel grows — one kernel covering more than one domain. |
| a schema both sides write (Hard Parts: *data domain*) | Both sides share one set of tables | **Refuse.** It is DDD's Shared Kernel in database form. |

**Failure mode.** Two kernels — or a kernel and a service — both write the
same state. Or a consumer reads full state and filters it itself (see
invariant 5).

**Detection.** For each state field, ask: which kernel's `apply` changes it?
No answer, or two answers, is a finding. Classify a shared-data finding by
its row in the table above.

## Events: inside the contract vs. on the wire

The `event` values a kernel emits are facts in the domain's own words
(DDD: *domain event*). They stay inside the kernel's contract. A message sent to
another system in a shared wire format (DDD: *integration event*) is made by
a shell or a translator from those events — never by the kernel. If a
kernel's event type carries a wire format, a topic name, or another system's
field names, a delivery concern has leaked in (invariant 4).

---

## Output shape for an assessment

For each violated invariant: the invariant, file:line evidence, hard-vs-cosmetic
classification, and the minimal fix. Then a recommended sequence — almost always
"flip default + de-leak public error types first" (near-zero risk, ~80% of the
benefit), then extract I/O to an adapter, then the boundary work.
