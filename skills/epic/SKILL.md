---
name: epic
description: Generate or update an EPIC design document — a domain-driven, phase-structured spec with Context, a Status table, Design sketches, phased Work Items, and a Verification block — in the pkcore/pkdealer house style. Use when the user types `/epic <thing>` or asks to "write an EPIC", "break this feature into stories or phases", "add a design doc to the docs folder", "story breakdown", "update/close out EPIC-NN", or "a progress report / evaluation of <branch>" — even if they never say the word EPIC. Do NOT trigger for ad-hoc planning of the current conversation's task (plan mode covers that) — only when the user wants a durable numbered document in the repo's docs folder. Project-agnostic: works in any repo, detects the existing documentation folder, and allocates the next EPIC number. Also produces the companion forms: progress/evaluation report, SIDEQUEST, DEFECT epic, TUTORIAL companion, and EXECUTION_PLAN / spec splits.
---

# EPIC

Write an **EPIC** — a durable design document that frames one bounded slice of a
domain as a *kata*: identify the Things, encode the Business Requirements as
Business Logic, and drive it out test-first. An EPIC states the **what and why**
(context, goals, design, verification); its Work Items carry the **how** as
numbered, phase-grouped tasks. This skill produces that document, and its
companion forms, in the house style used across the user's `pkcore` / `pkdealer`
repos and adapted in `cardpack.rs`.

## Usage

`/epic <thing>` — write a new EPIC for `<thing>`.

`<thing>` is whatever the user typed after the command: a feature name, a branch,
an existing `EPIC-NN` id, a subsystem, or a free-form goal. It is authoritative —
take the scope from it. If `<thing>` is empty, ask what the EPIC should cover.

Modes are chosen from the phrasing of the request (no strict flags):

| Ask sounds like | Produce | Filename |
|---|---|---|
| default — "write an EPIC for X" | new EPIC | `EPIC-NN_Name.md` |
| "progress report / evaluation of X" | status + quality eval | `EPIC-NN_Name_Progress.md` (standalone if no parent) |
| "a sidequest off EPIC-NN" | exploratory tangent | `EPIC-NNa_SIDEQUEST_Name.md` |
| "a defect writeup for X" | bug epic | `EPIC-DEFECT-X_Name.md` or `DEFECT_Name.md` |
| "a tutorial for the math behind EPIC-NN" | teaching companion | `TUTORIAL_EPICNN_Name.md` |
| "an execution plan / spec for one slice / a cross-repo contract" | slice or contract | `EPIC-NN_Name_EXECUTION_PLAN.md` / `EPIC-NN_..._spec.md` |
| "update / close out / reconcile EPIC-NN", "write the corrigendum for EPIC-NN" | **update the existing doc** | edit `EPIC-NN_*.md` in place |

## What you must do when invoked

Work through these in order. **Before writing prose, read
`references/methodology.md`** (in this skill dir) to load the voice, the kata
framing, the numbering policy, and the variant decision guide.

**Updating an existing EPIC?** If `<thing>` names an EPIC that already exists
(e.g. "update EPIC-29", "close out EPIC-30", "write the corrigendum"), skip
steps 1–2: locate that file, then do step 3 (ground: verify what actually landed,
at which commit) and apply the lifecycle edits in place — flip `## Status` rows
to `**Complete**`/`**Deferred**` only where cited code proves it, check/uncheck
Work Item boxes per the host repo's convention, and for shipped work append the
`## Implementation corrigendum` (design-vs-actual deltas + Phase status summary).
Never renumber or rename an existing EPIC.

1. **Locate the documentation folder — do NOT assume `docs/`.** Detect where this
   repo keeps design docs: prefer wherever existing `EPIC-*.md` or other design
   markdown already lives. Probe common names in order — `docs/`,
   `documentation/`, `doc/`, and case variants (`Documentation/`) — and if the
   repo uses something unusual, find it by locating existing markdown design docs
   (e.g. `git ls-files | grep -iE '(^|/)(docs?|documentation)/'` or a search for
   files matching `EPIC-*`, `ROADMAP`, `DESIGN`). Only create `docs/` as a last
   resort when the repo has no documentation folder at all. Write the new file
   into the detected folder.

2. **Allocate the number.** Scan the detected folder's existing `EPIC-*.md`. If a
   `ROADMAP.md` / `BACKLOG.md` carries an EPIC-numbering policy, obey it (the
   pkcore family uses ten-block namespacing — see methodology). Otherwise take the
   next number after the **sequential frontier**, zero-padded to two digits —
   NOT max+1: repos in this family park specials at high numbers (66, 79, 95–99,
   999 = meta/backlog/ramblings), so find the highest number in the contiguous
   run from 00 and go one past it (e.g. `…34, 36, 66, 999` → next is `37`).
   Use a sub-letter (`NNa`) for a child/tangent of an existing EPIC. A
   standalone progress doc with no parent EPIC takes a fresh frontier number
   (it becomes the de-facto EPIC id for that work). Confirm the final
   `EPIC-NN_Name.md` (Title in `Snake_Case`) before writing.

3. **Gather & ground.** Read the code, branch, or feature `<thing>` names. Every
   factual claim in the doc must cite a real `path/file.rs:line`. For a
   progress/evaluation doc, actually run the checks — `git log`, `cargo test`,
   `cargo clippy`, `cargo build --no-default-features`, etc. — and report the true
   results and counts, not assumptions. Delegate broad reads to subagents so you
   keep the conclusions, not the file dumps.

4. **Frame as a domain kata.** Before drafting sections, name the domain **Things**
   (the nouns/types), the **Business Requirements** (the rules), and the
   **Business Logic** (the code that enforces them). Scope one bounded slice — an
   EPIC is a kata, not the whole product.

5. **Write the document.** Copy `references/epic-template.md` as the skeleton and
   fill every section, deleting the guidance comments and any section that
   genuinely does not apply (say why in one line rather than leaving it blank).
   For a progress/evaluation doc, use `references/progress-template.md` instead.
   Match the repo's own tone and, if it has existing EPICs, their exact heading
   conventions.

6. **Verify honesty before finishing.** Status-table rows and any checkboxes must
   reflect work that has *actually landed*, pinned to a named commit/branch, as of
   a stated date — never aspiration. Re-read the doc: if a box is checked or a row
   says Complete, the cited code must prove it.

## Output structure

The canonical EPIC section order (full skeleton in `references/epic-template.md`):

1. `# EPIC-NN: Title (ABBREV)`
2. `## Context` — where the code stands today, `file.rs:line`-cited; state what
   this EPIC explicitly does **not** do.
3. `## Status` — a `| Component | Status |` table (`Planned` / `**Complete**` /
   `**Deferred**` / `🔒 Gated`). This is the canonical live progress signal.
4. `## Goals` — bulleted intent, load-bearing nouns **bold**.
5. `## Scope` — the concrete rules the feature must obey.
6. `## Domain map` *(optional, cardpack-style)* — a table of domain concept →
   code construct → status (✅/🟡/❌) when the mapping aids the reader.
7. `## Design` — `###` per new type/module, each with a fenced ```rust API sketch
   and the rationale (why this shape, not the alternative).
8. `## Work Items` — `### Phase N — name` groups of numbered tasks
   (`- [ ] **0a.** …`), each citing its `path:line` target and the test/command
   that proves it. Phase 0 = prerequisites/feature-gating.
9. `## Test Plan` — the named tests to add and what each asserts.
10. `## Key Files` — a `| File | Role |` table.
11. `## Reuse (do NOT recreate)` — existing code to build on, `path:line`-cited.
12. `## Compatibility` — what is preserved vs added for downstream consumers.
13. `## Dependencies` — **Blocks / Built on / Related**, naming other `EPIC-NN`s.
14. `## Verification` — a fenced ```bash block of exact commands + numbered exit
    criteria.
15. `## Implementation corrigendum` — *added after shipping*: numbered
    design-vs-actual deltas + a Phase-status-summary table + inherited-debt note.

## Variants & naming

Detailed in `references/methodology.md`. In brief:

- `EPIC-NN_Name.md` — the standard doc. `NN` zero-padded, sequential, banded
  (00-series = foundational/meta; specials sit at high numbers like 95–99).
- Sub-letter `NNa` — a child/follow-on/tangent of a base EPIC (`15a`, `19a`).
- Type tokens — `_SIDEQUEST_` (exploratory tangent), `TUTORIAL_EPICNN_` (teaching
  companion, embeds parent number), `DEFECT_` / `EPIC-DEFECT-` (bug epic),
  `EPIC_FEATURE_` / bare `EPIC_Name` (unsequenced).
- `_Progress.md` — the evaluation companion (a cardpack adaptation; the pkcore
  repos instead journal in `DEVLOG.md` / `DIARY.md` and flip Status rows).
- `_EXECUTION_PLAN.md` / `_spec.md` — split out only when one implementable slice
  needs step-by-step scoping, or when the work crosses a repo boundary (the driver
  repo hosts the `_spec` contract, the target repo hosts the implementation).

## Philosophy

An EPIC is a **domain kata**: pick a bounded slice of the domain, model its Things,
encode its Requirements as Business Logic, and drive it out in tight test-first
loops. Domain first — the seed before the flower. Your code is the hero; your
tests tell the hero's journey. CI is a license to be fallible, not a vanity
metric: a real behavioral change should make a previously-passing test fail.
Full statement and quotes in `references/methodology.md`.

## Honesty rules

- Cite `path/file.rs:line` for every factual claim; if you cannot cite it, don't
  assert it.
- Status/checkbox state = landed work at a named commit and date. Never fabricate
  a green box or a `Complete` row.
- Say what an EPIC does **not** cover; name the deferrals and the out-of-scope
  debt explicitly.
- For evaluations, run the checks and report real output — including failures and
  skips — rather than inferring.
