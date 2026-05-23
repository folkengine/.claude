## What

<!-- One or two sentences. What does this PR do and why? -->

## Quality commitments checklist

Tick the rows of `docs/quality-commitments-matrix.md` this change touches. Explain unchecked items in **Why not** below.

- [ ] **Unit tests** — added or updated, negative cases included
- [ ] **Integration tests** (`tests/`) — covered if subcommand boundaries changed
- [ ] **CLI end-to-end** (`trycmd` / `assert_cmd`) — flags, help, and error paths exercised
- [ ] **Clippy** clean with `-D warnings`
- [ ] **`cargo fmt`** clean
- [ ] **Cross-platform** — passes on Linux, macOS, Windows
- [ ] **MSRV check** — still builds on the declared MSRV
- [ ] **`cargo audit`** clean (or new advisories triaged)
- [ ] **Doc tests** — examples in rustdoc still compile and run
- [ ] **Help text / man page** — updated for new or changed flags
- [ ] **Definition of Done** — see `docs/definition-of-done.md`

### Why not

<!-- Be specific. -->

## Exploratory pass

<!-- Tried piping input/output? Empty inputs? Huge inputs? Symlinks, non-UTF8 paths, signals? -->

## Output sample

<!-- For visible changes, paste a sample of new help text or output. -->
