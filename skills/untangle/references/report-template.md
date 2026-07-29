# Templates: DEPENDENCY_AUDIT.md, VENDORED.md, attribution headers

Skeletons for everything /untangle emits. Fields marked REQUIRED must appear;
omit optional fields only when genuinely inapplicable (say why in one clause
if it might look like an oversight).

## `<docs>/DEPENDENCY_AUDIT.md`

```markdown
# Dependency Audit

**Audited:** <YYYY-MM-DD> at <short-commit> · <toolchain, e.g. rustc 1.94.1>
**Scope:** <N> direct shipping dependencies (<M> third-party, <K>
first-party), shipping graph of <T> crates (host target; <T2> across all
targets). Dev-dependencies add <D> crates that never ship.
**Method:** /untangle — evidence commands in the appendix; scores use the
1–5 anchors, verdicts use the controlled vocabulary.

## Summary

<!-- REQUIRED columns, exactly these. One row per direct SHIPPING (normal)
     dependency — including optional and target-gated ones (mark them in
     their dossiers). Dev-dependencies never get rows here; they live in
     the Dev-dependencies table.
     Verdict ∈ keep | drop | demote-to-dev | replace-std | rewrite |
     vendor-partial | vendor-full | absorb
     Unique baggage = crates that leave the shipping graph if this
     dependency's node vanishes entirely. When another dependency still holds
     the crate, write `0 via <holder>` here and give both numbers
     (direct-edge removal vs node-vanishes) in the Evidence appendix. -->
| Dependency | Version | License | Score | Unique baggage | Effort | Verdict |
|---|---|---|---|---|---|---|
| serde | 1.0.228 | MIT OR Apache-2.0 | 5 | 0 crates | XL | keep |
| thousands | 0.2.0 | MIT OR Apache-2.0 | 1 | 0 crates | S | rewrite |

## Cross-cutting findings

<!-- REQUIRED section. Tree-level observations no single dossier owns:
     duplicate versions (cargo tree -d), heaviest unique subtrees,
     unmaintained/advisory-flagged crates, license outliers. -->

## Third-party dossiers

### <dep> <version>

<!-- REQUIRED fields below; keep this ordering. -->
- **License:** <SPDX> · **Last release:** <date or `unchecked`> ·
  **Advisories:** <none | RUSTSEC-… | unchecked>
- **Features used:** <list; note if the dep is optional/feature-gated>
- **Usage census:** shipping: <F> files, <C> call sites, <D> derive sites,
  <I> imports (`src/` outside `#[cfg(test)]`); dev: <X> call sites in
  tests/examples/benches — **both halves REQUIRED, even when a half is 0**
- **Public API leakage:** <none | list each leaking item `path:line`>
- **Contract exposure:** <persisted files / wire formats / downstream repos
  that depend on this dep's output, or none>
- **Unique baggage:** <crates only this dep brings in; count + notable names>
- **Replaceability:** <std | rewrite-blind ~N LOC | vendorable ~N LOC | hard>
- **Score:** <1–5> — <one line citing the anchor it matches>
- **Effort:** <S|M|L|XL> <if L/XL: "— run /epic before attempting">
- **Verdict:** `<verdict>` — <rationale; for `keep`, argue it as explicitly
  as a removal>
- **Δ since last audit:** <only when a previous audit existed and score or
  verdict changed>

## First-party dependencies

### <dep> <version> (first-party)

- **Relationship:** <same author/org; repo link>
- **Usage census:** <same numbers as above>
- **Public API leakage:** <same as above>
- **Absorption analysis:** <(a) two-place maintenance cost vs folding it in,
  (b) other consumers of the standalone crate and what absorption breaks,
  (c) is the boundary itself wrong — should the sibling's API change
  instead?>
- **Score / Effort / Verdict:** <as above; `absorb` is available here>

## Dev-dependencies

<!-- Light touch only — these never ship to consumers. No dossiers.
     Note duplicate versions that exist only via this graph, marked
     non-shipping, so nobody chases them as consumer bloat. -->
| Dependency | Version | License | Role |
|---|---|---|---|

## Evidence appendix

<!-- REQUIRED. Raw, diffable outputs the next audit compares against.
     Include at minimum: -->
- Graph-size baselines from `cargo tree` (never `cargo metadata` package
  counts), unique crates excluding the root, each labeled: shipping graph
  host target, shipping graph `--target all`, dev-inclusive graph
- `cargo tree -d` output, partitioned shipping vs dev-only
- Per-dep census numbers as one table: dep | shipping files | shipping call
  sites | derives | dev-side count
- Per-dep unique-baggage counts (`cargo tree -i` / subtree analysis)
- Tool availability: which opportunistic tools ran (machete/udeps, audit/
  deny, license) and which were absent or offline

## Notes (human)

<!-- Never regenerate this section. Preserve verbatim on every refresh;
     create it empty on first run. -->
```

## `<docs>/VENDORED.md` (ledger — copied code only)

One entry per vendored portion. Rewritten-from-behavior replacements do NOT
go here (their provenance note lives in the module docs and the audit doc).

```markdown
# Vendored code ledger

Code copied into this repository from external projects, with provenance and
license. Each entry's upstream license text is reproduced in full.

## <crate> <version> → `src/vendored/<dep>.rs`

- **Source:** <repository URL> @ <tag or commit>
- **License:** <SPDX> · **Copyright:** <upstream copyright line>
- **Vendored:** <YYYY-MM-DD> · **Portion:** <what was copied>
- **Changes:** <summary of modifications, or "none">
- **Reason:** <why the dependency was removed>

### Upstream license text

<full text, fenced>
```

## Attribution header (copied code — top of the vendored module)

```rust
//! Vendored from the [`<crate>`](<repository URL>) crate v<version>
//! (<commit or tag>), reduced to <portion description>.
//!
//! Copyright (c) <upstream copyright line>.
//! Licensed under <SPDX>; full license text in `docs/VENDORED.md`.
//! Changes from upstream: <summary, or "none">.
```

## Provenance note (rewritten code — top of the replacement module)

```rust
//! <What this module does.>
//!
//! Replaces the [`<crate>`](<crates.io or repo URL>) crate v<version>
//! (<SPDX license>, by <author>): re-implemented fresh from its documented/
//! observed behavior — no upstream code copied. <Name kept identical so call
//! sites are unchanged / other compatibility notes.>
```
