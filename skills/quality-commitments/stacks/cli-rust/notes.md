# Notes for the Scaffold skill — cli-rust

## Bundle contents

| File | Default destination | Purpose |
|---|---|---|
| `matrix.md` | `docs/quality-commitments-matrix.md` | Starter matrix |
| `github-workflows-ci.yml` | `.github/workflows/ci.yml` | CI: fmt, clippy, test on Linux/macOS/Windows, doc tests, MSRV check, `cargo audit`; optional bench |
| `clippy.toml` | `clippy.toml` (repo root) | Clippy config — pairs with `[lints.clippy]` in Cargo.toml |
| `pr-template.md` | `.github/pull_request_template.md` | PR checklist |
| `definition-of-done.md` | `docs/definition-of-done.md` | DoD |

## Customization checkpoints

1. **MSRV** — workflow pins `1.75` for the MSRV check. Update to match the project's declared MSRV (usually in `Cargo.toml` `[package] rust-version`).
2. **`trycmd` vs. `assert_cmd`** — matrix references both. The test job runs `cargo test` which covers either. If the project uses neither, the CLI end-to-end row is aspirational — flag in post-scaffold checklist.
3. **Cross-platform matrix** — if the CLI is intentionally Linux-only, drop macOS and Windows from the `test` job matrix.
4. **Cargo.toml `[lints]` block** — the `clippy.toml` is only half the lint story. Add a `[lints.clippy]` table to `Cargo.toml` (sample in the `clippy.toml` header comment).
5. **Bench** — runs on `workflow_dispatch` only. Project must have benches in `benches/` for this to do anything.
6. **`cargo audit`** — uses `rustsec/audit-check@v2`; opens an issue on advisories. No token needed beyond `GITHUB_TOKEN`.

## Required secrets

- None for the default workflow

## Things this template intentionally does *not* do

- No release/publish job — packaging and `crates.io` publishing is a separate concern
- No coverage tooling — `cargo-llvm-cov` works but adds friction; add deliberately if coverage is a team commitment
- No fuzz testing — `cargo-fuzz` is high-value for parsers but out of scope for a starter scaffold; add manually if the CLI parses untrusted input
