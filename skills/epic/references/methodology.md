# EPIC methodology — voice, kata framing, numbering, variants

Read this before drafting an EPIC. It carries the operating philosophy to write
*in-voice*, the numbering policy, and the decision guide for which document form
to produce. Sourced from the `pkcore` / `pkdealer` EPIC corpus (`EPIC-00*`,
`EPIC-97_Philosophy`, `pkcore/ROADMAP.md`) and the `cardpack.rs` adaptation.

## The philosophy (write in this voice)

Domain-driven and test-obsessed. The author's own framing: *"I am not a test
driven developer. I am a domain driven developer that is test obsessed"*
(`pkcore/docs/EPIC-00.md`). Build the **domain kernel** first — the *"rock solid
kernel definition of truth"* — before product or money concerns are allowed to
warp it: *"Your domain is the seed. Your product is the flower. Focus on the seed,
and you will have a garden full of flowers."*

Work in tight loops: *"Write a test that fails testing on one individual scenario,
make it pass, refactor, repeat"* (`EPIC-00e_Dev_Cadence.md`). Treat CI and tooling
as a license to be fallible — *"Set yourself so that you can be stupid… Assume
that failure is the normal human state"* (`EPIC-00.md`). Reject vanity coverage:
*"The unexamined test is not worth running,"* and hold the Gold Standard that any
real behavioral change *"should make a test that passed in the past fail"*
(`EPIC-00f_Coverage.md`). And reject anyone selling *The Answer™* — *"The moment
you decide that you know everything… that's the true moment you have truly
failed."* The recurring metaphor: **your code is the hero; your tests tell the
hero's journey.**

## Demo on demand (core value)

Tests prove the code to a machine. A **demo proves it to a human.** The house rule:
*any slice of work must be demonstrable on demand* — a stakeholder says "show me",
and within minutes they get something tactile, from a fresh clone, with no bespoke
setup and without the author in the room.

This is a **definition-of-done clause, not a nicety.** An EPIC with green tests and
no runnable demo is not finished. Consequences that follow from taking it
seriously:

- **Design the demo first.** Write the `## Demo on Demand` section while the code
  is still imaginary. A slice you cannot describe demoing is a slice whose value
  you cannot describe either — that is a scoping signal, so re-cut the slice.
- **The demo is a committed artifact**, not an improvised terminal session:
  `examples/<name>.rs`, a CLI subcommand, a `just`/`make` target, or a test whose
  stdout *is* the demo. It lives in the repo, runs in CI where possible, and rots
  loudly rather than silently.
- **It gets a Status row and a Work Item.** Same honesty rules as any other
  component: `Planned` until it runs at a named commit.
- **Tactile beats comprehensive.** Sixty seconds of visible behavior beats a
  ten-minute tour. Show the domain doing its job, not the framework booting.
- **No observable surface?** Say so in one line and name the nearest proxy — a
  golden-output test that prints, a benchmark table, a debug dump. The section is
  never deleted, only answered.

The `/presentation` skill consumes this section to produce a live demo runbook;
`## Demo on Demand` is the durable source it reads.

## An EPIC *is* a domain kata

The methodology grows from the [EverCraft Kata](https://github.com/PuttingTheDnDInTDD/EverCraft-Kata),
cited in `EPIC-00c_Domain.md` as the canonical domain-driven-design exercise. The
kata move — three layers — is applied to every EPIC:

1. **Things** — the domain nouns/types (in EverCraft: Characters, Ability Scores,
   Hit Points; in poker: the French Deck).
2. **Business Requirements** — the rules (HP hits zero → dead; the rules of Texas
   Hold'em).
3. **Business Logic** — the code that enforces those rules, driven out test-first.

So before writing the sections: name the Things, name the Requirements, then let
the Design and Work Items be the Business Logic that satisfies them. An EPIC is
one bounded kata — a slice of the domain — not the whole product. This lineage is
why the toolbox also ships `codebase-kata` and `domain-kernel` skills: the whole
project is the practice of hardening a domain kernel, kata by kata.

## Numbering & naming

- **File:** `EPIC-<NN>[<letter>]_Title_In_Snake_Case.md`. `NN` is zero-padded and
  sequential; number bands are semantic (00-series = foundational/meta; the main
  run = features in rough build order; high numbers 66/79/95–999 = specials, meta,
  backlog, ramblings).
- **Cross-repo ten-block namespacing** (the `pkcore` family): one continuous EPIC
  number space shared across repos, allocated in blocks and registered in
  `pkcore/ROADMAP.md` under "EPIC Numbering Policy." E.g. EPIC-00–39 are
  pkcore-rooted (including cross-repo EPICs where pkcore owns a contract doc and a
  downstream repo hosts the implementation); EPIC-40+ are pkdealer-internal. A new
  downstream repo claims the next free ten-block by editing that section. **When a
  repo has such a policy, follow it; otherwise number locally** within the repo's
  own docs folder (a standalone repo like `cardpack.rs` just takes its next
  number). "Next" means one past the **sequential frontier** — the contiguous run
  from 00 — never max+1, because the specials band (66/79/95–99/999) parks meta
  docs at high numbers.
- **Sub-letters** append a lowercase letter for a child/follow-on/tangent of a base
  number: `00c` (sub-doc of EPIC-00), `15a` (follow-on to 15), `19a` (tangent off
  19).
- **Type tokens:**
  - `_SIDEQUEST_` infix — an exploratory tangent, not a planned deliverable
    (`EPIC-19a_SIDEQUEST_Mutants.md`).
  - `TUTORIAL_EPICNN_` prefix — a teaching companion; embeds the parent number
    (`TUTORIAL_EPIC28_ES_Math.md`).
  - `DEFECT_` / `EPIC-DEFECT-` — bug write-ups, and defect-driven epics.
  - `EPIC_FEATURE_` / bare `EPIC_Name` (no number) — unsequenced/named epics.

## Which document form to write

Four tiers, split by the question they answer:

| Form | Filename | Answers | When |
|---|---|---|---|
| **EPIC** | `EPIC-NN_Name.md` | what & why | default; keep everything here while the work is small — Work Items + Phase tables ARE the execution plan. |
| **EXECUTION_PLAN** | `EPIC-NN_Name_EXECUTION_PLAN.md` | how, precisely, now | a single implementable slice of a large EPIC needs concrete step-by-step scoping (with an explicit "out of scope for this slice"). |
| **spec** | `EPIC-NN_..._spec.md` | cross-repo contract | the work crosses a repo boundary: the driver repo writes the `_spec` (target repo, driven-by EPIC, exact signatures, "additive, behind a feature flag"); the target repo hosts an implementation EPIC that consumes it. |
| **progress / eval** | `EPIC-NN_Name_Progress.md` | did it actually work | a status + quality evaluation of shipped/WIP work (a `cardpack.rs` adaptation). In the pkcore repos this role is filled instead by `DEVLOG.md` / `DIARY.md` narrative journals plus flipping the EPIC's own `## Status` rows. |

Default to a single EPIC. Split out a plan or spec only for a genuinely large or
cross-repo effort.

## Progress tracking, in practice

- The **`## Status` table** inside the EPIC is the canonical live signal — one row
  per component, flipped to `**Complete**` / `✅` as code lands, reconciled
  retroactively against reality (Status tables are allowed to trail and be audited).
- **Checkbox lists** (`- [ ]`) inside Work Items / execution plans track task-level
  progress. The pkcore modern EPICs leave boxes unchecked and rely on the Status
  table + a Phase-status-summary; the cardpack adaptation does check `- [x]`.
  **Follow the host repo's existing convention.**
- **`DEVLOG.md` / `DIARY.md`** carry the narrative journal, organized by phase/EPIC.

## Honesty (non-negotiable)

Cite `path/file.rs:line` for every factual claim. A checked box or a `Complete`
row must be backed by code that proves it, pinned to a named commit and date.
A demo described in the present tense must actually run at that commit.
State what the EPIC does **not** do. For evaluations, run the checks and report the
real output — failures, skips, and all.
