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
| **Demo on demand** (`<demo command>`) | Planned |

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
     tests; final phase = docs/roadmap AND the Demo on Demand artifact. Each item
     is self-contained, cites its
     path:line target, names the test to add, and ends with the green-check command.
     Use `- [ ]`; track completion by flipping the Status table, not by checking
     boxes (the cardpack adaptation does check `- [x]` — follow the host repo). -->

### Phase 0 — Prerequisites & feature gating

- [ ] **0a.** <task, with `path:line` target>
- [ ] **0b.** Confirm `cargo check --features <feat>` is green.

### Phase 1 — <name>

- [ ] **1.** <task + the exact test to add>
- [ ] **2.** Unit tests: <named tests and what they assert>

### Phase N — Demo & docs

- [ ] **Na.** Build the demo artifact named in `## Demo on Demand`
      (`examples/<name>.rs` / `<runner> demo-<name>`) and commit it with the code.
- [ ] **Nb.** Run the demo runbook on a clean checkout; paste the real output into
      `docs/demos/<name>.txt` as the recorded fallback.
- [ ] **Nc.** Update README / ROADMAP to point at the demo command.

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
4. The `## Demo on Demand` runbook below runs clean on a fresh clone, at HEAD,
   with no manual setup beyond the documented commands.

---

## Demo on Demand

<!-- REQUIRED SECTION — part of the definition of done. An EPIC is not finished
     until any stakeholder can say "show me" and get a tactile demonstration within
     minutes, from a fresh clone, with no bespoke setup and no author present.
     Write this section at DESIGN time, before the code exists, so the demo shapes
     the work rather than being retrofitted onto it. The demo artifact is a
     committed deliverable, not an improvised terminal session.
     If the slice genuinely has no observable surface, say so in ONE line and name
     the nearest observable proxy (a golden-output test that prints, a benchmark
     table, a debug dump) — do not delete this section. -->

**Demo artifact:** `examples/<name>.rs` — committed alongside the code.
<!-- Pick the cheapest thing that is still tactile: a runnable example, a CLI
     subcommand, a `just`/`make` target, a test whose stdout IS the demo, a short
     screencast script. Prefer something already in the repo's demo idiom. -->

**Audience:** <who asks to see this — product owner, downstream repo owner, new
contributor — and what they care about.>

**Runbook** — exact commands, copy-pasteable, no editing required:

```bash
cargo run --features <feats> --example <name>
```

**What the observer sees:** <the concrete tactile outcome — the dealt hand
printed, the illegal bet rejected with this message, the timing table. Describe it
specifically enough that you could diff this paragraph against real output.>

**Pass signal:** <REQUIRED. The one thing an observer with no knowledge of the
codebase checks to know the demo succeeded — "exits 0 and block 2 prints three
results instead of a panic", "the final line reads WINNER: Seat 3". A demo whose
success only an author can judge is not a demo.>

**Duration:** <target wall-clock, e.g. under 60 seconds.>

**Recorded fallback:** `docs/demos/<name>.txt` — real captured output, refreshed
whenever the demo changes; used when live execution is not possible.

<!-- Honesty: this section describes a demo that RUNS at the cited commit. Never
     describe an aspirational demo as if it exists. -->

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
