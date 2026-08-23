<!--
  BLANK CANONICAL EPIC TEMPLATE.
  Copy this into the detected docs folder as EPIC-NN_Name.md, fill every section,
  and DELETE these HTML comments as you go. Drop a section only when it truly does
  not apply — and when you do, say why in one line rather than leaving it empty.
  Every factual claim must cite a real path/file.rs:line. Separate top-level
  sections with a `---` horizontal rule.
-->

# EPIC-NN: Title (ABBREV)

<!-- H1 = the id + a human title + a short abbreviation in parens, e.g.
     "# EPIC-30: Fixed-Limit Hold'em (FLHE)". -->

## Context

<!-- Where the code stands TODAY. Cite exact src/path.rs:line anchors for every
     claim about current behavior. End by stating explicitly what this EPIC does
     NOT do and what stays unchanged — the boundary is as important as the goal. -->

---

## Status

<!-- The canonical live progress signal: one row per component/phase, NOT a single
     document-level state. Flip cells to **Complete** / **Deferred** as work lands;
     do not mark a row done without code that proves it. -->

| Component | Status |
|---|---|
| <new type / module / behavior> | Planned |
| <…> | Planned |

<!-- Cell vocabulary: Planned · **Complete** · **Deferred** · 🔒 Gated (design only)
     · Pending release tag. Emoji (✅ / 🟡 / ◻️) is fine if the repo's EPICs use it. -->

---

## Goals

- <Bulleted intent. **Bold** the load-bearing nouns.>

## Scope

<!-- Feature EPICs: the concrete rules this variant/feature must obey. -->

- <rule>

---

## Domain map

<!-- OPTIONAL (cardpack-style). Include when a source-domain → code mapping helps
     the reader see coverage at a glance. Delete if it adds nothing. -->

| Domain concept | Code construct | Status |
|---|---|---|
| <real-world Thing> | `Type` / `module` | ✅ done / 🟡 partial / ❌ absent |

---

## Design

<!-- The bulk. One ### sub-section per new type/module. Give the exact proposed
     API in a fenced rust block, then the rationale: why this shape, why not the
     obvious alternative. -->

### <NewType / module>

`src/path/newthing.rs` (new):

```rust
// exact proposed signatures / enums / struct fields
```

<Rationale.>

---

## Work Items

<!-- The "how", as numbered tasks grouped into phases. Phase 0 = prerequisites /
     feature-gating / scaffolding; middle phases = one module or type each with its
     tests; final phase = docs/roadmap. Each item is self-contained, cites its
     path:line target, names the test to add, and ends with the green-check command.
     Use `- [ ]`; track completion by flipping the Status table, not by checking
     boxes (the cardpack adaptation does check `- [x]` — follow the host repo). -->

### Phase 0 — Prerequisites & feature gating

- [ ] **0a.** <task, with `path:line` target>
- [ ] **0b.** Confirm `cargo check --features <feat>` is green.

### Phase 1 — <name>

- [ ] **1.** <task + the exact test to add>
- [ ] **2.** Unit tests: <named tests and what they assert>

---

## Test Plan

- <named test> — <what it asserts / which requirement it pins>

## Key Files

| File | Role |
|---|---|
| `src/…` | <the change here> |

## Reuse (do NOT recreate)

- `path/file.rs:line` — <existing helper/trait/engine to build on instead of duplicating>

## Compatibility

- **Preserves** <public API / downstream pins>. **Adds** <new surface>. **Breaks** <nothing, ideally>.

## Dependencies

- **Blocks:** EPIC-XX, EPIC-YY
- **Built on:** EPIC-ZZ / <existing infra>
- **Related:** EPIC-AA

## Verification

```bash
cargo build --features <feats>
cargo test --all-features
cargo test --doc --all-features
cargo clippy --all-features -- -D warnings
cargo run --features <feats> --example <demo>
```

Exit criteria:

1. <observable, testable outcome>
2. <no-regression guarantee for existing behavior>
3. <downstream consumers unaffected / release audit clean>

---

## Implementation corrigendum

<!-- Added AFTER shipping. The retrospective: what the design said vs what building
     it surfaced. Delete this whole section until there is something to record. -->

### 1. <delta title>

<What the design assumed, what shipping revealed, the resolution, and which test
verifies it. Repeat per delta.>

### Phase status summary

| Phase | Status | Notes |
|---|---|---|
| 0 (…) | Shipped | |
| 1 (…) | Shipped | |
| N (…) | **Deferred** | see corrigendum item N |

### Pre-existing debt

<clippy / tech-debt inherited at HEAD, explicitly out of scope for this EPIC.>
