---
name: untangle
description: Evaluate how entangled a repository is with each of its dependencies and what removing them would take — a standardized audit written to the repo's docs folder (DEPENDENCY_AUDIT.md), per-dependency deep dives, and a guided extraction mode that removes a dependency by vendoring or re-implementing only the portion actually used, with correct license attribution. Use when the user types `/untangle`, `/untangle <dep>`, or `/untangle extract <dep>`, or asks "how entangled are we with X", "audit our dependencies", "what would it take to drop <dep>", "vendor this crate", "cut our supply-chain surface / dependency footprint" — even if they never say untangle. Rust/Cargo-first; the method carries to other ecosystems with thinner tactics. Do NOT trigger for adding or upgrading dependencies, routine manifest edits, or pure vulnerability scans (cargo audit alone covers those).
---

# /untangle

Map how a repository actually depends on each thing it pulls in, what each
dependency would cost to remove, and — when removal is worth it — perform the
removal cleanly. Three guiding principles:

- **This is an ownership map, not a purge manifesto.** `keep` is a first-class
  verdict and must be argued as explicitly as any removal. The output's value
  is knowing *exactly* what you depend on and what each exit would cost, not
  a smaller number in `Cargo.toml`.
- **Evidence before verdicts.** Every score and verdict traces to numbers in
  the Evidence appendix, produced by the standard commands below, so the next
  audit run can be diffed against this one.
- **Shipping vs dev is the first cut.** The audit's subject is the normal
  (shipping) dependency graph — what consumers inherit, including optional
  and target-gated deps. Dev-dependencies (tests, examples, benches) never
  ship and get the light-touch table only. Classify usage by where the call
  site lives, not where the dependency is declared, and label every count in
  the report with the graph it measures.

## Modes

| Invocation | Does |
|---|---|
| `/untangle` | Full audit of every direct dependency → `<docs>/DEPENDENCY_AUDIT.md` |
| `/untangle <dep>` | One dependency's dossier (update its section in an existing audit, else standalone) |
| `/untangle extract <dep>` | Guided removal: preflight gates → approved plan → execute → verify |

Detect the repo's docs folder the way the other house skills do (`docs/` or
wherever existing design docs live). Report mode **refreshes
`DEPENDENCY_AUDIT.md` in place** — regenerate it each run with a fresh audit
header, but preserve any `## Notes (human)` section verbatim, and when a
previous audit exists, add a one-line `Δ` note to any dossier whose score or
verdict changed.

## Report mode

### 1. Establish context

- Host license (from the manifest) — the extraction license gate depends on it.
- Current commit (`git rev-parse --short HEAD`) and toolchain version for the
  audit header. Read-only git only; never run state-changing git commands.
- Workspace? Run from the root; add a Crate column to the summary table when
  members differ.

### 2. Gather evidence (standard commands)

Required baseline is only the package manager + `rg`. Run:

- `cargo metadata --format-version 1` — versions, **licenses**, feature flags,
  which deps are optional. Its package count is **not** a size metric: it is
  unfiltered by target and includes dev-deps and inactive optional edges.
- `cargo tree -e normal` — the **shipping graph**, the audit's subject.
  Record the canonical baselines as unique crates excluding the root:
  host target, `--target all`, and the dev-inclusive count (no `-e` filter)
  for contrast — label each. Per-dep `cargo tree -i <dep>` — what each direct
  dep uniquely drags in (its *baggage*) and what depends on it.
- `cargo tree -d` — duplicate versions. **Partition shipping vs dev-only**
  (reachable only via dev-deps): dev-only duplicates never reach consumers
  and are reported as such, never as shipping bloat.
- Per-dep census with `rg`: `use <dep>` imports, call sites, files touched,
  and `derive(...)` attributes referencing the dep's macros — **two counts
  per dep**: shipping code (`src/` outside `#[cfg(test)]` modules and
  doc-test fences) and dev code (`tests/`, `examples/`, `benches/`, test
  modules). The split is what surfaces misclassified dependencies.
- Opportunistic, if installed — degrade silently when absent: `cargo machete`
  or `cargo udeps` (unused deps → `drop` candidates), `cargo audit` /
  `cargo deny` (advisories), `cargo license`.
- Maintenance signals: last release + advisories (via `cargo audit`, `cargo
  info`, or a web lookup). Offline or unavailable → record `unchecked`, never
  guess.

Raw numbers go into the report's **Evidence appendix** (see template) — that
appendix is what makes the next run comparable.

### 3. Judge each direct dependency

The census can't answer the questions that dominate removal cost. For each
third-party dep, answer explicitly:

- **Does it actually ship?** — decided by call site, not declaration: a
  `[dependencies]` entry whose only usage is in `tests/`, `examples/`,
  `benches/`, or `#[cfg(test)]` modules is misclassified — verdict
  `demote-to-dev`, not `keep` or `drop`. Converse trap: usage behind a
  feature that examples enable via `required-features` is still shipping
  usage.
- **Public API leakage** — do the dep's types/traits appear in this crate's
  exported signatures (including trait impls downstream consumers rely on)?
  This is the single biggest cost driver: leakage means removal is a breaking
  release, not an internal refactor.
- **Derive/macro saturation** — attribute macros on N types are structural
  entanglement that call-site counts miss entirely.
- **Contract exposure** — do persisted files, wire formats, or downstream
  repos depend on output this dep produces?
- **Replaceability** — std equivalent? Re-implementable blind from observed
  behavior (≲50 lines)? Bounded enough to vendor? Or genuinely hard?
- **Vendorable LOC** — estimate what a copy-out would actually take. A dep
  can look small and balloon ("part of serde" is not a thing); this estimate
  is the trap detector.

**First-party deps** (same author/org — check repository/authors fields) get
the **absorption rubric** instead: license work is moot; the real questions
are (a) does maintaining it in two places cost more than folding it in, (b)
who else consumes the standalone crate and what breaks for them, (c) is the
boundary itself wrong (fix the sibling crate's API rather than absorb).

### 4. Score, size, and issue verdicts

**Entanglement score (1–5)** — use these anchors, not ad-hoc prose labels:

1. Contained — optional/feature-gated or leaf usage, few call sites, no leakage.
2. Spread-shallow — many call sites but one narrow API surface, no leakage;
   removal is mechanical.
3. Structural — leaks into public API in one bounded place, OR saturates one
   subsystem.
4. Leaks and spreads — public API leakage plus wide module spread, or
   persisted/wire contracts depend on it.
5. Ecosystem hub — derive/format machinery with downstream consumers pinned
   to its output; removal is a coordinated breaking release.

**Effort (S/M/L/XL):** S = under an hour, single file. M = one focused
session, a few files, no API break. L = multi-session, API or persisted-format
impact. XL = cross-repo, coordinated releases. **For L/XL, recommend running
`/epic` to give the removal a proper phased design doc — do not attempt it
ad hoc.**

**Verdict (controlled vocabulary — summary tables use exactly these):**

| Verdict | Meaning |
|---|---|
| `keep` | Ownership cost < removal cost; justify explicitly |
| `drop` | Unused (confirm with machete/udeps); just delete |
| `demote-to-dev` | Declared in `[dependencies]` but used only by tests/examples/benches; move it to `[dev-dependencies]` — consumers stop inheriting it, no code changes |
| `replace-std` | Standard library already covers the usage |
| `rewrite` | Re-implement the small used slice fresh from observed behavior; no upstream code copied |
| `vendor-partial` | Copy the used portion in-tree with full attribution |
| `vendor-full` | Copy the whole crate in-tree (rare — e.g. unmaintained upstream you must patch) |
| `absorb` | First-party only: fold the sibling crate (or the used part) into this repo |

**Copy vs. rewrite is a real fork with legal consequences.** If the used
slice is ≤~10 lines or fully specified by observable behavior, `rewrite`
beats `vendor-partial`: no license text to carry, only a module-doc
provenance note crediting the crate you're replacing (name, version, license,
author, link). But if you closely studied upstream *implementation* code to
produce "your" version, it is a copy — attribute it fully. Reading docs,
signatures, and observed behavior is fine; reading the source and
transcribing is not a rewrite. Never launder.

### 5. Emit the report

Fill `references/report-template.md`. Every summary-table column and every
dossier field marked REQUIRED in the template must be present — a dossier
without a License line or a numeric score is not done. Dev-dependencies get
the light-touch table only (they never ship to consumers). Cross-cutting
findings (duplicate versions, heaviest unique subtrees, unmaintained crates)
get their own short section — tree-level wins hide there, not in any single
dossier.

## Extraction mode (`/untangle extract <dep>`)

A runbook with hard gates. Do not touch a repo file before gate 4 passes.

**Gate 1 — license.** Check the *upstream* license against the *host* license
(this table assumes a permissive host, the common case — re-derive if the
host is copyleft):

| Upstream | Copy into a permissive host? |
|---|---|
| MIT / BSD-2/3 / ISC / Zlib / Unlicense / CC0 / 0BSD | Yes — preserve copyright notice + license text |
| Apache-2.0 | Yes — preserve NOTICE file contents if one exists; state changes made |
| MPL-2.0 | Caution — copied files remain MPL-2.0 with file-level notices; flag prominently |
| GPL / LGPL / AGPL | **No copy.** `rewrite` from observed behavior only — and do not read upstream source while doing it |
| None / unknown | **No copy.** No license means all rights reserved; `rewrite` only |

**Gate 2 — enumerate and estimate.** List the exact items used (traits,
functions, types, macros) and estimate vendored LOC including transitive
internal helpers. Confirm each used item actually has callers (src, examples,
tests, known downstream) — a dependency serving dead code is a `drop`, and
one whose callers are all in tests/examples/benches is a `demote-to-dev` (a
manifest move, not an extraction); abort either back to report mode. If the
estimate balloons past what the audit predicted, abort
back to report mode and change the verdict — do not keep pulling thread.

**Gate 3 — choose copy or rewrite** per the fork above.

**Gate 4 — present the plan and STOP for approval.** The plan names: new
file(s) with their attribution/provenance headers, every edit to existing
files (manifest, imports) as before/after snippets, the ledger entry (copy
path only), and the verification commands. Wait for explicit approval.

**Execute:**

- *Copied code* → `src/vendored/<dep>.rs` (or the ecosystem equivalent), with
  the attribution header from the template: upstream crate, version, source
  repo URL @ tag/commit, copyright line, SPDX license, summary of changes.
  Add a ledger entry to `<docs>/VENDORED.md` (template has the skeleton)
  carrying the **full upstream license text**. **Attribution must ship with
  the published artifact:** docs folders are commonly excluded from packaging
  (check the manifest's `exclude`/`include`), so also add or extend a
  root-level `LICENSE-THIRD-PARTY.md` with the same notice and license text,
  and prove it packages (`cargo package --list` or the ecosystem
  equivalent).
- *Rewritten code* → normal module placement in house style, module-doc
  provenance note; no license text, no ledger entry; note the replacement in
  the audit doc instead.
- Remove the dependency from the manifest; the lockfile regenerates on the
  next build — never hand-edit it.

**Verify — evidence, not assertions.** Run and show: the test suite (unit +
doc), the linter, `cargo tree -i <dep>` — expect the crate gone, or, when
other dependencies still hold it, predict the expected remaining holders and
confirm only they remain (say plainly that the win is ownership, not tree
size) — and an `rg` sweep proving no references remain. Then hand the user suggested `git add`
/ `git commit` commands — **never run state-changing git commands yourself.**

## Other ecosystems

Same three-phase method (evidence → judgment → template); swap the evidence
commands: npm → `npm ls --all`, `npx license-checker`; Python → `pipdeptree`,
`pip-licenses`; Go → `go mod graph`, `go-licenses`. Census stays `rg`-based.
The shipping/dev split carries everywhere the names differ: npm
`dependencies` vs `devDependencies`, Python project deps vs dev groups /
extras, Go imports appearing only in `_test.go` files. Expect thinner
tooling and say so in the report rather than skipping fields.

## Common mistakes

| Mistake | Fix |
|---|---|
| Prose entanglement labels ("very entangled") | Use the 1–5 anchors; cross-run comparability is the point |
| Omitting licenses because "we're not vendoring yet" | License is a REQUIRED column — half the verdicts depend on it |
| Vendoring a ≤10-line utility | `rewrite` — provenance note, no license text |
| Partial-vendoring a hub crate (a "part of serde") | Gate 2 balloon-abort; the verdict was wrong, fix it in the report |
| Treating first-party crates as third-party risk | Absorption rubric; the cost is two-place maintenance, not trust |
| Analyzing only direct deps' own code | Duplicates (`cargo tree -d`) and unique baggage are where tree wins hide |
| Quoting `cargo metadata`'s package count as the footprint | It counts dev-deps, all targets, and inactive optionals; size the shipping graph with `cargo tree -e normal` |
| Chasing duplicates that exist only via dev-deps | Partition `cargo tree -d` first; dev-only duplicates never reach consumers |
| A census that merges `src/` with tests/examples usage | Two counts per dep (shipping vs dev); the split is what surfaces `demote-to-dev` candidates |
| Reading upstream source, then calling it a rewrite | That is a copy — attribute it fully |
| Skipping the approval gate because the change is small | Gate 4 is unconditional in extract mode |
| Attribution only in a docs folder the package excludes | Root-level `LICENSE-THIRD-PARTY.md` + prove it ships (`cargo package --list`) |
| Regenerating the audit and losing human edits | `## Notes (human)` is preserved verbatim, always |
