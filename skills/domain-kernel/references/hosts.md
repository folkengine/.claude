# Guests and hosts

Use this in Mode C after the WIT exists. The same contract is implemented by a
guest and consumed by a host; they meet only at the WIT.

## Guest A — Rust (the production kernel)

The real kernel is the Rust crate; exporting it is a thin binding, not a rewrite.

```toml
# Cargo.toml
[lib]
crate-type = ["cdylib"]
[package.metadata.component]
package = "<org>:<domain>"
[package.metadata.component.target]
path = "wit"
```

```rust
wit_bindgen::generate!({ world: "<domain>" });
use exports::<org>::<domain>::kernel::Guest;

struct Component;
impl Guest for Component {
    // delegate to the crate's existing pure functions; convert WIT<->native
    // types with mechanical `From` impls (the WIT was modelled on them).
}
export!(Component);
```

```bash
cargo component build --release   # -> tens of KB, imports NOTHING (the truly-pure artifact)
```

## Guest B — Python (validation / stand-in when no Rust toolchain)

Useful to prove the contract runs end-to-end in an environment without Rust.

```bash
componentize-py -d wit -w <domain> bindings py_bindings     # generate guest bindings
# implement class <Interface>(wit_world.exports.<Interface>) in app.py,
# raising componentize_py_types.Err(...) for the result-error case
PYTHONPATH=py_bindings componentize-py -d wit -w <domain> componentize app -o kernel.wasm
```

## Host — JavaScript via jco (ties to a web frontend)

```bash
npm install @bytecodealliance/jco @bytecodealliance/preview2-shim
npx jco transpile kernel.wasm -o gen        # (omit --no-nodejs-compat for Node)
node run.mjs                                 # import { kernel } from "./gen/<name>.js"
```

In JS: kebab names become camelCase (`legal-actions` -> `legalActions`); enums are
strings; `variant` values are `{ tag, val }`; `result` errors are thrown and
catchable; `list<u8>` is a `Uint8Array`.

## Host — Python via wasmtime, or any WASI-capable runtime

Any runtime that supports the component model can instantiate `kernel.wasm` and
call its exports. Generate host bindings against the WIT for ergonomic calls.

## Honest caveats — state these, don't hide them

- **A Python (componentize-py) build pulls WASI** because it bundles the CPython
  runtime (clocks/random/io), so *that* artifact is ~15-20 MB and is not
  import-free. The **Rust** guest compiles to tens of KB and imports nothing — it
  is the artifact that actually demonstrates sandbox-enforced purity. The contract
  is identical either way.
- **Server-side wasm still lacks a threading model**, so parallel analysis
  (rayon-based equity/solving) cannot run *inside* the component. Keep heavy
  parallel compute host-side; only the pure transition core belongs in the
  component.
- **WASI's async story is still stabilizing.** For a synchronous pure transition
  surface this does not matter; for streaming hosts, check current WASI/runtime
  support rather than assuming.

## A reproducible end-to-end proof

The strongest demonstration: author the kernel in Python, compile to a component,
transpile with jco, and drive it from a JS host running a scripted scenario with
a `self-check: PASS/FAIL` at the end. That single run proves the contract crosses
two non-Rust languages over the WIT boundary. `assets/trick-taking.wit` plus the
recipes above are enough to reconstruct it.
