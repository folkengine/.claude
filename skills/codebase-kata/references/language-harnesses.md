# Language harnesses

Per-language guidance for making the `exercise/` folder runnable and choosing the right stub and test conventions. The goal in every case: the learner can run one command, see the tests fail for the right reason, and iterate to green.

For each language: how to stub a not-yet-implemented function, what the test command is, and what project scaffolding the exercise folder needs.

## Rust

- **Stub body:** `todo!()` — compiles, panics at runtime with a clear "not yet implemented" message. (`unimplemented!()` also works.)
- **Test command:** `cargo test`
- **Scaffolding:** `exercise/` should be a real crate with a `Cargo.toml`. Put stubbed source in `src/lib.rs` (or modules), tests in `tests/` (integration) or `#[cfg(test)] mod tests` (unit). Adapt the original crate's tests.
- **Faithfulness tip:** preserve the original `pub` signatures, derives, and type definitions exactly. If the concept uses a custom enum (e.g. `Suit`, `Rank`), bring it across intact — the learner needs it and it's not the part being tested.
- **Verify:** `cargo test` in `exercise/` should compile and report failures (panics from `todo!()`). `cargo test` against the solution source should pass. Tip: `cargo test --lib` (or `--test <name>`) gives cleaner RED/GREEN summaries by skipping the empty doctest bucket in katas without doctests.

## Python

- **Stub body:** `raise NotImplementedError`
- **Test command:** `pytest`
- **Scaffolding:** `exercise/` with the stubbed module(s) and a `test_*.py` file. A `requirements.txt` or `pyproject.toml` only if there are third-party deps. Keep type hints from the original — they document the interface.
- **Faithfulness tip:** adapt the repo's existing `pytest`/`unittest` cases. Keep fixtures small and inline where possible so the exercise is self-contained.
- **Verify:** `pytest` fails on stubs (NotImplementedError), passes on solution.

## JavaScript / TypeScript

- **Stub body:** `throw new Error("not implemented")`
- **Test command:** `npm test` (wire it to jest/vitest/node:test in `package.json`)
- **Scaffolding:** `exercise/` with `package.json`, stubbed source, and a test file. For TS, keep the original types/interfaces — they're a big part of the spec.
- **Faithfulness tip:** if the original uses a specific runner, match it so adapted tests run unchanged.
- **Verify:** `npm test` fails on stubs, passes on solution.

## Go

- **Stub body:** `panic("not implemented")`
- **Test command:** `go test ./...`
- **Scaffolding:** `exercise/` as a module (`go.mod`), stubbed `.go` files, and `_test.go` files adapted from the original.
- **Verify:** fails on stubs, passes on solution.

## Other languages

Apply the same pattern: find the idiomatic "not implemented" stub that still compiles/parses, find the standard test runner, and make `exercise/` a minimal but real project for that ecosystem so a single test command works. Always adapt the codebase's existing tests rather than inventing new ones.

## If the toolchain isn't available

If you can't run the target language's tests in your environment, do not claim the harness works. Instead:

1. Double-check the stub syntax and test command against the conventions above.
2. Tell the user explicitly: "I couldn't run `<command>` here — please run it in `exercise/` to confirm the tests fail, and in the solution to confirm they pass."
3. Make the run commands in the README copy-pasteable so verification is one step for them.
