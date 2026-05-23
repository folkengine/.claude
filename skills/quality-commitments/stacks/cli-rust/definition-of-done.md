# Definition of Done — CLI Tool (Rust)

A change is **done** when every applicable item below holds.

## Code

- [ ] Implementation complete and self-reviewed
- [ ] `cargo fmt` and `cargo clippy --all-targets -- -D warnings` clean
- [ ] No `unwrap`/`expect` on user-facing error paths without justification
- [ ] No `dbg!` / `todo!` / `unimplemented!` left in shipping code

## Tests

- [ ] Unit tests cover new behavior with positive and negative cases
- [ ] Integration tests in `tests/` cover any new subcommand or external boundary
- [ ] `trycmd` snapshots reflect intentional help/output changes
- [ ] Doc tests still pass
- [ ] All three CI OSes (Linux, macOS, Windows) green

## Portability

- [ ] No platform-specific syscalls without `cfg` gates
- [ ] Path handling uses `Path`/`PathBuf` (not strings) at API boundaries
- [ ] MSRV check passes

## Errors & UX

- [ ] Errors include actionable context (`anyhow::Context` or equivalent)
- [ ] Exit codes documented; non-zero on failure
- [ ] Help text and usage strings updated for new flags
- [ ] Color and unicode output respects `NO_COLOR` and TTY detection

## Security

- [ ] `cargo audit` clean (or new advisories triaged and noted)
- [ ] No new dependencies pulling in undocumented network calls

## Documentation

- [ ] `--help` output is the source of truth for flags
- [ ] README updated for user-visible changes
- [ ] Man page or generated docs regenerated if shipped
- [ ] `docs/quality-commitments-matrix.md` updated if a new quality type was introduced

## Performance

- [ ] No new O(n²) hot path on common inputs (sample input size noted in PR)

## Exploratory

- [ ] At least one exploratory pass for user-visible changes
