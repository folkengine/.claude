# Defining the boundary as a WIT world

Use this in Mode C. WIT (WebAssembly Interface Types) lets you express the
kernel's surface as a language-neutral contract. A `world` that **imports
nothing** compiles to a component that physically cannot do I/O — purity enforced
by the sandbox, not a lint.

`assets/trick-taking.wit` is a complete worked example (a trick-taking play-phase
kernel). Adapt it.

## The shape

A state-machine kernel exports a transition surface. The general template:

```wit
package <org>:<domain>@0.1.0;

interface kernel {
    // ... domain types as record / enum / variant / list ...

    to-act:        func(state: <state>) -> option<actor>;
    legal-actions: func(state: <state>, who: actor) -> list<action>;
    apply:         func(state: <state>, who: actor, a: action) -> result<<state>, error>;
    view-for:      func(state: <state>, who: actor) -> <view>;   // hidden-info projection
    outcome:       func(state: <state>) -> option<<result-type>>;
}

world <domain> {
    export kernel;     // imports nothing -> the sandbox enforces purity
}
```

State goes *in* and *out* of every call: the component is stateless, the host
holds the state. That is exactly the pure-kernel model, and it is why a no-import
component works.

## Type mapping (Rust → WIT) and the pitfalls

| Rust | WIT | Pitfall |
|------|-----|---------|
| `struct { a, b }` | `record { a: …, b: … }` | field names kebab-cased in bindings |
| `enum E { A, B }` (no payload) | `enum e { a, b }` | becomes string values in JS/Python |
| `enum E { A(X), B }` (payload) | `variant e { a(x), b }` | distinct from `enum`; has `tag`/`val` |
| `u8`/`u16`/`u32` | `u8`/`u16`/`u32` | — |
| `usize` | `u32` (or `u64`) | **no `usize` in WIT** — pick a width |
| `Vec<T>` | `list<t>` | — |
| `Vec<u8>` | `list<u8>` | maps to **`bytes`/`Uint8Array`**, not a number list |
| `Option<T>` | `option<t>` | host sees value-or-`undefined`/`None` |
| `Result<T, E>` | `result<t, e>` | **signalled by raise/throw**, not a return wrapper |
| `String`/`&str` | `string` | — |

## Validate without a Rust toolchain

Generating bindings parses the WIT and resolves the world — a free correctness
check that needs only Python:

```bash
pip install componentize-py
componentize-py -d path/to/world.wit -w <world-name> bindings out_bindings/
```

If it succeeds, the contract is well-formed and implementable in any language.
Inspect `out_bindings/.../exports/__init__.py` to see the protocol a guest must
satisfy — a quick sanity check that the surface is what you intended.

## Keep a shared cross-domain trait thin

If you lift a single `Kernel` trait across multiple domains, include only
state / action / apply / event / projection. Scoring, trump, pots, books — those
stay domain-specific (e.g. a separate `score` hook). A trait that tries to be
universal over domains fits everything and helps nothing. Two or three real
implementors are enough to know the abstraction is grounded rather than
speculative; fewer is a warning sign.
