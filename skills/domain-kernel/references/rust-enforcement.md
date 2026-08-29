# Rust enforcement mechanics

Use this in Mode B. The goal: make the invariants in `invariants.md` checkable by
tooling, at two levels — lint and build/sandbox.

## Level 1 — Lint

### clippy.toml

Drop `assets/clippy.toml` at the crate root (or workspace root). It uses
`disallowed-types` and `disallowed-methods` to ban I/O and runtime entry points.
Adapt the list to the crate: remove bans for anything the kernel legitimately
needs, and add crate-specific offenders. Run with:

```bash
cargo clippy --all-targets -- -D warnings
```

Note clippy lints the configured build; to also lint gated code, run it with the
relevant features. Don't silently widen lint scope in CI if it would surface
pre-existing pedantic warnings — introduce that as its own change.

### cargo-deny [bans]

Merge `assets/deny-bans.toml` into the crate's `deny.toml` (create one if absent).
It denies format/transport crates as *wildcards* so they can't sneak in as
non-optional deps. Keep them allowed as `optional = true` feature deps. Run:

```bash
cargo deny check bans
```

## Level 2 — Build / sandbox

### Flip the default posture

This is the highest-leverage change and usually pure-Cargo.toml:

```toml
default = []
## Convenience umbrella so examples, doctests, and `make test` still resolve.
full = ["serialization", "persistence", "..."]   # the previous default set
```

### The ripple this creates — handle it or CI breaks

Empty defaults change what builds and tests run. Audit every invocation:

- A bare `cargo test` now runs only ungated tests. Bump coverage-critical
  invocations to `cargo test --features full`.
- **A `cargo test --test <name>` (or `--example <name>`) whose target declares
  `required-features` will ERROR — not skip — under empty defaults.** This is the
  one that breaks CI silently-not-silently. Add `--features full` to those.
- `cargo run --example X` now needs the features; document
  `cargo run --example X --features full` in the README.
- Update Makefile `test` / `nextest` / doc targets similarly.

Grep first: `grep -rn "cargo \(test\|run\|build\|nextest\)" .github/ Makefile`.

### The purity CI job

Add `assets/kernel-purity.yml` (a job, or a whole workflow). It:
1. builds `--no-default-features` (proves the pure kernel compiles), and
2. asserts banned crates are absent from the pure dependency tree:
   ```bash
   ! cargo tree --no-default-features | grep -E "serde_yaml|tokio|reqwest|rusqlite"
   ```

A crate that passes this job has a *testable* claim to being a domain kernel —
that is the definition to hand people.

## The opaque-error refactor (de-leaking Level-2 of `invariants.md` #2)

Mechanical and low-risk; verify it touches no external call site first:

1. Add a small format-agnostic error the kernel owns:
   ```rust
   #[derive(Debug)]
   pub struct CodecError(Box<dyn std::error::Error + Send + Sync + 'static>);
   impl CodecError {
       pub fn new(e: impl std::error::Error + Send + Sync + 'static) -> Self { Self(Box::new(e)) }
   }
   // `Send + Sync` is not optional: without it the error cannot cross a
   // thread, feed `anyhow`, or be returned from an async fn — which defeats
   // the point of a kernel meant to back services.
   // + Display and Error (source) impls
   ```
2. Change public signatures `-> Result<T, serde_yaml::Error>` to
   `-> Result<T, CodecError>`; bodies `.map_err(|e| CodecError::new(e))`.
3. For an error enum, change the payload to the opaque type and box at the
   `From<FormatError>` seam. **Grep for external match sites first**
   (`grep -rn "MyError::Yaml"`); if matches are confined to the defining module,
   the refactor is safe. Keeping the variant *name* avoids breaking doc links and
   matchers; rename later at a version bump.

## Note on no_std

`#![no_std]` is the strongest purity forcing-function but is usually too strong
for a real kernel (it rules out `std` collections, threads, rayon). Reserve it for
an innermost transition core if at all; do not impose it crate-wide by default.
