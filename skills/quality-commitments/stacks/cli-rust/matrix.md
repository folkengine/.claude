# Quality Commitments Matrix — CLI Tool (Rust)

> Starter matrix. Customize rows, owners, and DoD entries. Delete rows you won't honor.

## Prioritized quality attributes

- **Functional:** correctness, completeness
- **Usability:** operability (clear flags/commands), user error protection (helpful errors), learnability (docs/help text)
- **Portability:** adaptability (OS/shell compatibility), installability
- **Reliability:** fault tolerance, recoverability
- **Maintainability:** testability, modifiability
- **Performance:** response time (startup, execution)

## Matrix

| Quality Type | Phase | In Definition of Done? | Runs on CI? | Covers Regressions? | Documents Findings? | Boundary Coverage | Perspective |
|---|---|---|---|---|---|---|---|
| Cargo unit tests | Development | Yes | Yes | Yes | Partial | Positive, Negative, Edge | White box |
| Integration tests (`tests/` dir) | Development / PR | Yes | Yes | Yes | Partial | Positive, Negative | Grey box |
| End-to-end CLI tests (`assert_cmd` + `trycmd`) | PR | Yes | Yes | Yes | Yes (`.trycmd` files versioned) | Positive, Negative, Edge | Black box |
| Clippy (`-D warnings`) | Development | Yes | Yes | Partial | No | — | White box |
| `cargo fmt --check` | Development | Yes | Yes | — | No | — | White box |
| Cross-platform build (Linux/macOS/Windows) | PR / Release | Partial | Yes | Partial | Yes (build artifact list) | Edge | Black box |
| MSRV check (`cargo +<msrv> check`) | PR | Yes | Yes | Partial | No | Edge | White box |
| Dependency audit (`cargo audit`) | Merge | Yes | Yes | Partial | Yes (advisory log) | Negative | Black box |
| Doc tests (`cargo test --doc`) | Development | Yes | Yes | Partial | No | Positive | White box |
| Help-text / man-page review | Release | Partial | No | No | Yes (docs in repo) | — | Black box |
| Performance (startup time, large input) | Release | No | Manual trigger | No | Yes (criterion report) | Edge | White box |
| Exploratory testing | UAT | No | No | No | Yes (session notes) | Edge | Black box |
