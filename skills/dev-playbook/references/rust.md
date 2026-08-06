# Rust — stack file

Read together with `references/baseline.md`. This file is instructions for
you, the executing agent — carry out each section as a step, don't just
summarize it. Apply after the stack's native init has already run, following
baseline's layer order: baseline files → AI files → stack configs (this
file's Config files / Quality gate / CI sections) → `.okf/` seeding.

## Init

1. Interview the user: **library or binary?** (a repo may be both — ask
   which `cargo init` shape applies; if both, run the lib init and add a
   `src/bin/` or a second binary target as needed).
   - Library: `cargo init --lib --vcs none`
   - Binary: `cargo init --vcs none`

   (`--vcs none` matters: bare `cargo init`/`cargo new` silently runs `git
   init` and writes its own `.gitignore`, pre-empting Flow 1 step 8's
   print-only git handoff and fighting baseline's own `.gitignore`
   generation. Every stack's native init that can auto-initialize VCS must
   be told not to; git only ever gets initialized at the hand-off step,
   and only if the user actually runs the printed command.)
2. Ask which **edition** to target; default to the current edition unless
   the user pins one. Write it as `edition = "<edition>"` in `Cargo.toml`.
3. Resolve the **MSRV** (minimum supported Rust version) at scaffold time —
   never hardcode one from memory. Ask the user if they have a floor
   (e.g. "must run on the distro's packaged rustc"), otherwise use current
   stable. Write it to `Cargo.toml` as:

   ```toml
   rust-version = "<resolved-msrv>"
   ```

   This value must agree with `.tool-versions`, the CI matrix's MSRV entry,
   and the devcontainer image tag — the version-consistency rule from
   baseline applies here from the first commit onward.
4. Interview: **which OSS license(s)?** — feeds both baseline's
   `LICENSE-*` copy step and this file's `deny.toml` license allow-list
   below. If the project is copyleft (e.g. GPL-3.0), the allow-list must
   only include licenses compatible with that choice (GPL-compatible or
   more permissive) — flag any conflict to the user before writing
   `deny.toml`.

   Also write the SPDX expression to Cargo.toml's `license` field, joining
   multiple choices with `OR` (e.g. `license = "MIT OR Apache-2.0 OR
   GPL-3.0-or-later"`). This is not optional: if `license` is left unset,
   `cargo-deny` synthesizes an `AND`-joined expression from the LICENSE-*
   files it finds in the repo root instead of an `OR`-joined one, which
   then fails its own `[licenses] allow` check (a multi-licensed crate
   is "licensed under any one of" these terms, not "under all of them at
   once"). When the chosen license set includes a copyleft license (e.g.
   GPL-3.0-or-later), add that exact SPDX identifier to the `deny.toml`
   allow-list too (see below) — the crate's own declared license is
   checked against that allow-list along with every dependency's.

## Toolchain

`.tool-versions` gets exactly **one** line (version resolved at scaffold
time, never hardcoded here):

```
rust <resolved-rust-version>
```

Only `rust` has a real asdf/mise plugin. Do NOT add lines for rustfmt,
clippy, or the cargo-* tools below — asdf/mise cannot resolve them, so a
`mise install`/`asdf install` preflight (SKILL.md step 2) would error on
unknown tools. They install through the toolchain instead:

| Tool | Role | Installed via |
|---|---|---|
| `rustfmt` | formatter | rustup component, ships with the `rust` toolchain |
| `clippy` | linter, dialed up to pedantic | rustup component, ships with the `rust` toolchain |
| `cargo-deny` | license / bans / advisories / sources policy (config in `deny.toml`) | `cargo install cargo-deny` |
| `cargo-audit` | RustSec advisory scanner, used by `bin/security-scan` | `cargo install cargo-audit` |
| `cargo-watch` | dev-loop rebuild-on-save, powers the `watch` Makefile target | `cargo install cargo-watch` |

Rationale notes (feed these one-line whys into
`.okf/decisions/toolchain.md` during OKF seeding, do not restate them in
`CLAUDE.md` or the README):

- **clippy pedantic** — dialed up to 11: pedantic catches API-design and
  idiom issues `clippy::all` misses; the cost is a few justified
  `#[allow(clippy::...)]` annotations at call sites, which is cheaper than
  the bugs it prevents.
- **cargo-deny** — one tool for four supply-chain concerns: license
  compliance, banned/duplicate crates, advisory checks, and source
  allow-listing (only crates.io + explicitly allowed git sources).
- **cargo-audit** — narrower than cargo-deny: it is the dedicated RustSec
  advisory-database client and is what `bin/security-scan` calls alongside
  `cargo deny check advisories` (belt and suspenders — deny's advisory
  check and audit's use overlapping but not identical data paths and
  update cadences).
- **miri** — OPTIONAL, OFF by default. It is heavy (interprets MIR, much
  slower than native test runs) and mainly pays off for unsafe-heavy or
  data-structure crates. Ask the user during the interview; only add a
  `miri` CI job and `cargo miri test` usage if they opt in. Do not add it
  to `ayce` even when opted in — keep it a manual/CI-only check so the
  default local loop stays fast.
- **docs warning-free** — `cargo doc` must build without warnings
  (missing docs, broken intra-doc links, etc.) treated as errors via
  `RUSTDOCFLAGS="-D warnings"`; this keeps documentation debt from
  silently accumulating.

## Config files

Write `.rustfmt.toml` in the repo root verbatim (ported from
`rs_blank/.rustfmt.toml`; comment-only bloat trimmed, all active settings
survive — only `max_width` is active, uncomment others per-project as
needed):

```toml
# rustfmt config. Only max_width is active; uncomment others to customize.
# Run `rustfmt --print-config=default <any-file.rs>` to see all current
# defaults.

# Maximum width of each line.
# Default: 100
max_width = 100

# Reorder import statements alphabetically.
# Default: true
#   reorder_imports =

# Replace uses of the try! macro by the ? shorthand.
# Default: false
#   use_try_shorthand =
```

Write `deny.toml` in the repo root, ported from `rs_blank/deny.toml`. The
`[licenses] allow` list below is the rs_blank default (permissive-license
set) — **you MUST replace it at scaffold time** with the licenses the user
chose in the Init interview; never leave a stale or mismatched allow-list:

```toml
# Configuration for cargo-deny
# https://embarkstudios.github.io/cargo-deny/
#
# `cargo deny check` (no args) runs advisories + bans + licenses + sources.

[advisories]
db-path = "~/.cargo/advisory-db"
db-urls = ["https://github.com/rustsec/advisory-db"]
yanked = "deny"
ignore = []

[licenses]
# Set this allow-list to exactly the license(s) the user chose during
# Init. Only list licenses actually needed by direct + transitive deps to
# avoid false confidence; add more as new dependencies require them.
allow = [
    "MIT",
    "Apache-2.0",
    "Apache-2.0 WITH LLVM-exception",
    "BSD-2-Clause",
    "BSD-3-Clause",
    "ISC",
    "0BSD",
    "CC0-1.0",
    "Unlicense",
    "Zlib",
    "Unicode-3.0",
    "Unicode-DFS-2016",
    # If the project's own license is copyleft (e.g. GPL-3.0-or-later),
    # add the exact SPDX identifier used in Cargo.toml's `license` field
    # here too (e.g. "GPL-3.0-or-later") — cargo-deny checks the crate's
    # own declared license against this allow-list, not just dependencies'.
    # Keep the permissive entries; they remain GPL-compatible for deps.
]
confidence-threshold = 0.8
exceptions = []
private = { ignore = true }

[bans]
multiple-versions = "warn"
wildcards = "warn"
highlight = "all"
allow = []
deny = []
skip = []
skip-tree = []

[sources]
unknown-registry = "warn"
unknown-git = "warn"
allow-registry = ["https://github.com/rust-lang/crates.io-index"]
allow-git = []
```

Add to `Cargo.toml` (modernization: configure clippy pedantic here, NOT via
a `#![warn(clippy::pedantic)]` crate-root attribute — this form works since
Rust 1.74, survives crate-root file renames, and is visible without opening
source):

```toml
[lints.clippy]
all = { level = "warn", priority = -1 }
pedantic = { level = "warn", priority = -1 }
```

Add stack-appropriate ignores to the shared `.gitignore` (baseline writes
the file; these are the Rust-specific lines): exactly the lines `cargo
init` itself would generate — nothing more. Because the real init runs
with `--vcs none` (which suppresses `.gitignore` generation), discover
them at scaffold time with a throwaway probe rather than from memory:

```sh
d=$(mktemp -d) && (cd "$d" && cargo init --vcs git --name probe -q) && cat "$d/.gitignore" && rm -rf "$d"
```

(currently that's just `/target`, for both lib and bin shapes). Do NOT
add `Cargo.lock` to the ignores — cargo stopped ignoring it and current
guidance is to commit the lockfile even for pure libraries. Do not add
`**/*.rs.bk` or other legacy patterns cargo no longer emits.

For `.editorconfig`, add a Rust override: 4-space indent for `*.rs`.

For the devcontainer, use the `mcr.microsoft.com/devcontainers/rust` image
family. Its tags (e.g. `2.0.9-bookworm`, `bookworm`, `latest`) version the
devcontainer image build and Debian codename, NOT the Rust toolchain — do
not try to write a Rust version as the tag. Pick a current stable
codename/latest tag, then pin the actual toolchain version to agree with
`.tool-versions` via a `postCreateCommand` in `devcontainer.json`:

```json
"postCreateCommand": "rustup install <resolved-version> && rustup default <resolved-version>"
```

(the base image already ships `rustup`, so this just points it at the
resolved version instead of whatever shipped with the image).

## Quality gate

Fill the baseline Makefile skeleton's phase bodies exactly as follows.
Never rename these seven targets, never change what `ayce` depends on:

```makefile
clean: ## remove build artifacts
	cargo clean

fmt: ## format all sources
	cargo fmt

build: ## compile/build
	cargo build

test: ## run all tests
	cargo test

lint: ## static analysis at the pedantic end
	cargo clippy --all-targets -- -D warnings
	cargo deny check

security-scan: ## dependency vulnerability scan
	./bin/security-scan

docs: ## build docs, fail on warnings
	RUSTDOCFLAGS="-D warnings" cargo doc --no-deps
```

Notes:
- `test` covers doc-tests too — `cargo test` runs unit, integration, and
  doc tests in one invocation; no separate phase or target is needed for
  doc-tests.
- `lint` runs two tools in sequence: clippy (code-level lints, pedantic
  configured via `Cargo.toml` as above, elevated to hard failures here via
  `-D warnings`) and `cargo deny check` (supply-chain policy: advisories +
  bans + licenses + sources). Both must pass for `lint` to succeed.
- `docs` fails the build on any rustdoc warning (broken links, missing
  docs if `#![warn(missing_docs)]` is set, etc.) via `RUSTDOCFLAGS`.

Write `bin/security-scan`'s body (baseline owns the shebang/`set -euo
pipefail` skeleton and the `chmod +x` step):

```bash
cargo audit
cargo deny check advisories
```

This is the single definition of Rust's security checks — the Makefile's
`security-scan` target and the CI `security.yaml` workflow both call this
script; do not duplicate `cargo audit` or `cargo deny check advisories`
anywhere else.

Extra targets — add these after `docs` in the Makefile, per baseline's
"stacks may add extra targets" allowance (ported from `rs_blank/Makefile`,
trimmed to the two the brief calls for):

```makefile
.PHONY: watch install-tools

watch: ## rebuild/retest on save (requires cargo-watch)
	cargo watch -x "check --workspace" -x "test --workspace"

install-tools: ## install cargo-deny, cargo-audit, and cargo-watch
	cargo install cargo-deny
	cargo install cargo-audit
	cargo install cargo-watch
```

(rs_blank additionally installed `cargo-udeps` for an `unused-deps` target
gated on nightly — drop it; this playbook does not use nightly toolchains,
see `## CI` below.)

## CI

Generate `.github/workflows/ci.yaml` from baseline's triggers block (push,
pull_request, monthly cron) with these jobs. Use `dtolnay/rust-toolchain`
for toolchain setup in every job (structure ported from
`rs_blank/.github/workflows/CI.yaml`); pin `actions/checkout` and
`dtolnay/rust-toolchain` to current major versions at scaffold time:

```yaml
name: CI

on:
  push:
  pull_request:
  schedule:
    - cron: "40 1 1 * *"   # monthly — toolchain freshness check

permissions:
  contents: read

env:
  RUSTFLAGS: -Dwarnings

jobs:
  test:
    name: Rust ${{ matrix.rust }}
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        # stable, beta, and the resolved MSRV — no nightly job.
        rust: [stable, beta, "<resolved-msrv>"]
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@master
        with:
          toolchain: ${{ matrix.rust }}
      - run: cargo test --all

  clippy:
    name: Clippy
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@master
        with:
          toolchain: stable
          components: clippy
      - run: cargo clippy --all-targets -- -D warnings

  fmt:
    name: Fmt
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@master
        with:
          toolchain: stable
          components: rustfmt
      - run: cargo fmt --all -- --check

  doc:
    name: Doc
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@master
        with:
          toolchain: stable
      - run: cargo doc --no-deps
        env:
          RUSTDOCFLAGS: "-D warnings"

  deny:
    name: Deny
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
      - uses: EmbarkStudios/cargo-deny-action@v2
```

Replace `"<resolved-msrv>"` in the matrix with the actual MSRV string
resolved during Init — do not leave the placeholder literal in the
generated file.

Modernization vs. rs_blank's CI, apply these drops/changes:
- **Drop the `nightly` matrix include** — this playbook's toolchain story
  is stable/beta/MSRV only; no job requires nightly.
- **Drop `cargo-outdated`/any `outdated` job** — broken on edition 2024
  (see `kbknapp/cargo-outdated#419`); do not port it even commented out.
- **Miri is opt-in only.** If the user opted into miri during Init, add:

  ```yaml
  miri:
    name: Miri
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@miri
      - run: cargo miri test
  ```

  Otherwise omit the job entirely — do not add it commented out.

Generate `.github/workflows/security.yaml` per baseline's exact verbatim
shape, inserting this stack's toolchain setup step (daily cron, unchanged
from baseline):

```yaml
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: taiki-e/install-action@cargo-deny
      - uses: taiki-e/install-action@cargo-audit
      - run: ./bin/security-scan
```

## CLAUDE.md addenda

Copy this section verbatim into the target repo's `CLAUDE.md`, after the
baseline's "Definition of done" and "Knowledge bundle pointer" sections
(ported from `rs_blank/CLAUDE.md`, trimmed to standards only — command
lists and inline code-pattern examples are dropped; the Makefile is the
single source of commands):

---

### Rust: Testing Requirements

**Unit Tests**
- Every public function must have at least one unit test covering the
  happy path.
- Every public struct/enum must have tests that validate construction,
  methods, and trait implementations.
- Place unit tests in a `#[cfg(test)]` module at the end of the file, or
  in a `tests/` directory for integration tests.
- Name tests descriptively: `<function_or_struct_name>_<scenario>`.
- Cover edge cases, error conditions, and boundary conditions.

**Doc Tests**
- Every public function and method must include at least one doc test
  (in the `///` doc comment, triple-backtick `rust` block) demonstrating
  basic usage.
- Doc tests must compile and run successfully — they are exercised by
  `cargo test` (no separate invocation needed).
- Show the most common usage pattern; if a function can fail, show a
  success-case example.

### Rust: Documentation Requirements

- **Functions**: single-sentence summary first line; explain what/why/when
  and caveats; document parameters, return value, `# Errors` (all failure
  cases), `# Panics` (if it can panic), `# Examples` (working doc test),
  and `# Safety` (if `unsafe`, explaining why and how to use safely).
- **Structs/enums**: purpose and role; document each field's meaning and
  invariants; show construction/usage examples; explain non-obvious trait
  behavior.
- **Modules**: start each file with a module-level `//!` doc comment
  explaining its purpose, plus common-usage examples.
- **Crate root (`lib.rs`)**: comprehensive overview, module-organization
  links, a quick-start guide, and complete working examples.

### Rust: Error Handling

- Never use `unwrap()`, `expect()`, or `panic!()` in library code. Tests
  may use them.
- Prefer `Result<T, E>` over `Option<T>` when failure carries meaningful
  information; create custom error types for domain-specific errors and
  implement `std::error::Error` for them.
- Document all error cases; use `?` for error propagation in library code.

### Rust: Naming

- `snake_case` for functions, variables, and modules; `PascalCase` for
  types, structs, enums, and traits.
- Avoid single-letter names except loop indices (`i`, `j`, `k`); prefer
  full words (`cards` not `c`, `rank` not `r`).

### Rust: Trait Guidance

- Implement `Display` for user-facing types.
- Implement `Debug` for all public types.
- Implement `Default` for types with a sensible default.
- Implement `Clone`/`Copy` when semantically appropriate.
- Document non-obvious trait behavior at the impl site.

### Rust: Code Organization

- Keep functions focused and single-purpose.
- Extract complex logic into well-named helper functions.
- Group related functions and types in logical modules.
- Use visibility modifiers (`pub`, `pub(crate)`, private) appropriately.

### Rust: Other Guidelines

- Prefer `&T` over `T` when a borrow suffices; use `&mut T` only when
  mutation is needed; document borrowing/lifetime requirements for
  non-trivial signatures.
- Avoid unnecessary cloning; prefer `&[T]` over `&Vec<T>` for slice
  parameters; pre-allocate with `with_capacity()` when the size is known;
  document performance characteristics of expensive operations.
- Prefer type-safe abstractions and enums over primitives/strings for
  fixed value sets; let the type system rule out invalid states.

---

## Update

On `/dev-playbook update` for a Rust repo:

1. `rustup update` (refresh local toolchains), then `cargo update` (bump
   dependency lockfile within semver constraints).
2. Re-resolve the MSRV if the user wants to raise the floor (e.g. to pick
   up a new language feature); otherwise leave `rust-version` in
   `Cargo.toml` untouched.
3. Propagate any version change across all four
   version-consistency-rule locations, per baseline's propagation table:
   - `Cargo.toml`'s `rust-version`
   - `.tool-versions`' `rust <version>` line
   - `ci.yaml`'s `test` job matrix MSRV entry
   - `.devcontainer/devcontainer.json`'s toolchain pin — for the
     `mcr.microsoft.com/devcontainers/rust` family the image tag does NOT
     encode the Rust version (see § Devcontainer under Config files); update
     the `postCreateCommand`'s `rustup install/default <version>` instead
4. Run `cargo deny check` after any dependency or license-set change —
   catches newly introduced disallowed licenses, banned crates, or
   yanked advisories before they land.
5. **Drift probe: `.gitignore`** (feeds SKILL.md Flow 2's drift-check
   step). Re-run the probe from `## Config files`:

   ```sh
   d=$(mktemp -d) && (cd "$d" && cargo init --vcs git --name probe -q) && cat "$d/.gitignore" && rm -rf "$d"
   ```

   The repo's `.gitignore` should be exactly this output plus the
   baseline-owned `.idea/` line (and any lines the user added themselves —
   user additions are not drift). If cargo's output has gained or changed
   lines the repo lacks, report the diff; never silently rewrite.
6. Run `make ayce` and confirm it is green before considering the update
   done.
