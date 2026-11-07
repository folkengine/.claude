---
name: deconstruct
description: Distill an existing codebase into DECON epics in the /epic house style plus golden test vectors extracted by running the original code. Two modes. NEUTRAL (default) is a portable, language-agnostic regeneration pack so the functionality can be rebuilt in any language without inheriting the original's design choices. SPECIFIC is a code-grounded explainer that keeps the same contract but walks through the actual source with excerpts and line-anchored links. Use when the user types `/deconstruct [neutral|specific] [subsystem]` or asks to "deconstruct this codebase", "distill this repo into epics", "make a regeneration spec", "reverse-engineer a spec from this code", "write specs so another team or agent can rebuild this", or "explain how this subsystem works with links to the code" — even if they never say deconstruct. Do NOT trigger for forward-looking feature design (/epic), teaching exercises (/codebase-kata), or kernel-purity assessment (/domain-kernel).
---

# Deconstruct

Turn a working codebase into a pack of DECON epics plus machine-extracted
golden vectors. `/epic` goes design → code. `/deconstruct` is its inverse:
code → design.

## Modes

| | **NEUTRAL** | **SPECIFIC** |
|---|---|---|
| For | Rebuilding in any language, by people or agents who never see the source | Understanding how *this* code keeps its contract, and rebuilding with it at hand |
| Source code in the pack | Only as `path:line` under `## Provenance (non-normative)` | Excerpts in a `## How <project> does it` walkthrough, plus `## Code references` with line-anchored links |
| Portability | Copy the folder anywhere; nothing depends on the repo | Lives in the repo; excerpts still read offline, links need the repo |
| Plain-language layer | None | `README.md` front door + `## In plain words` in every doc |
| Profile | `references/methodology.md` | `references/methodology.md`, then `references/specific-profile.md` |
| Templates | `decon-epic-template.md`, `manifest-template.md`, `vectors-readme-template.md` | `decon-epic-template-specific.md`, `manifest-template-specific.md`, `readme-template-specific.md` (+ vectors README deltas in the profile) |
| Reference pack | — | `ImperialBower/bower` → `docs/deconstruct/repl/` |

Both modes share the contract: numbered Scope rules in domain words, golden
vectors extracted by running the code, named freedoms, SD flags. In SPECIFIC
the code explains the rules; it never becomes the rules.

## Usage

- `/deconstruct [neutral|specific]` — the whole repo.
- `/deconstruct [neutral|specific] <subsystem>` — a scoped run.
  - NEUTRAL: produce or update only the epics covering `<subsystem>` in the
    one pack, then re-derive the manifest coverage table.
  - SPECIFIC: a self-standing pack under `deconstruct/<subsystem-slug>/`.
- **Choosing the mode.** Use the mode the user named. Map "portable",
  "language-agnostic", "rebuild in another language" to NEUTRAL; "with links
  to the code", "how does our code do it", "explainer", "walkthrough" to
  SPECIFIC. If nothing says, ask at the Phase 2 checkpoint (recommend
  NEUTRAL for a hand-off, SPECIFIC for the repo's own maintainers).

**Update mode:** if a pack already exists (a `MANIFEST.md` under the repo's
`deconstruct/` folder or its subfolders), never clobber it. Keep its mode:
read the manifest's `**Mode:**` line; a pack without one is SPECIFIC if its
epics have `## Code references`, else NEUTRAL. Refresh vectors at the current
commit, reconcile epic text against current behavior, and record drift in
the manifest's Drift log. Never renumber existing DECON epics. Switching a
pack's mode is a rewrite: confirm with the user first.

## The pack

Detect the repo's docs folder the same way /epic does (prefer wherever
design markdown already lives; default `docs/`).

    docs/deconstruct/[<subsystem-slug>/]  ← subfolder: SPECIFIC scoped runs only
      README.md                         ← SPECIFIC only: plain-words front door
      MANIFEST.md                       ← index & entry point
      DECON-01_Name.md …                ← epics, own numbering, build order
      APPENDIX_Engineering_Constraints.md
      vectors/
        README.md                       ← vector format contract
        <epic-slug>/*.json              ← golden vectors per epic

NEUTRAL packs must be portable: nothing in them may depend on access to the
source repo.

## What you must do when invoked

**Before writing anything**, read `references/methodology.md` in this skill
dir, and `~/.claude/skills/epic/references/methodology.md` — the /epic voice
and kata framing carry over; this skill's methodology defines the deltas
(the "deconstruct profile"). For SPECIFIC, also read
`references/specific-profile.md`, and open the reference pack if it is on
disk.

### Phase 1 — Survey

Fan out subagents over four signals; keep the conclusions, not the file
dumps. In SPECIFIC, have each subagent also return `path#Lx-Ly` anchors for
the code behind each behavior — Phase 3 needs them.

1. **Public surface** — every observable capability: the domain's things,
   operations, orderings, formats, locales.
2. **Test mining** — what the tests promise; note coverage gaps. Where
   coverage is weak, vectors still come from the dumper in Phase 3 (it
   exercises the public API directly, independent of the test suite), but
   the weak grounding means any spec-decision flag on that behavior gets
   extra scrutiny before it's resolved.
3. **Docs mining** — README, CHANGELOG, design docs: what was intended. In
   SPECIFIC, note every place the design doc and the code disagree.
4. **Perspective analysis** — which actor perspectives the code supports
   (god-mode / administrative / user-client / observer-operator, plus any
   repo-specific ones), each rated Full / Partial / Absent with evidence,
   behind what boundary invariants. For observer: which domain events are
   visible without side effects. Also rate the two quality lenses:
   **performant** (how performant is it — complexity, allocation behavior,
   benchmarks) and **flexibility** (where and how can it run — environments,
   optional-capability layering), as characteristics in observable terms.

Merge into a **behavior inventory**: each entry tagged `domain-essential` or
`implementation-accident` (litmus test in the methodology), plus a draft
**perspectives taxonomy** from signal 4's ratings. Where the signals
disagree — or an observable output hangs off an accidental choice — record a
**spec decision** flag; never silently resolve.

### Phase 2 — Map (the one checkpoint)

Cluster the inventory into epics with a dependency order. Draft `MANIFEST.md`
from the mode's manifest template. Then pause ONCE: present the epic list,
per-epic scope, out-of-scope rows, the perspectives taxonomy, and — if the
user did not name one — the mode, via AskUserQuestion. The user's approval
(with edits) is the gate. No other checkpoints — after this, generate
everything.

### Phase 3 — Generate

For each epic, in dependency order:

1. Write `DECON-NN_Name.md` from the mode's epic template, following the
   mode's profile. In SPECIFIC, copy every excerpt from the pinned commit
   (read the file; never quote from memory) and anchor every link to the
   lines you read.
2. Extract golden vectors by **running the original code**: write a dumper
   program in the source language, using only the public API, that
   serializes the epic's observable behaviors to JSON under
   `vectors/<epic-slug>/`. The dumper is committed to the source repo (e.g. a
   Rust example) so vectors stay regenerable. **Never hand-write vector
   values.** If you cannot run the code, say so and stop — do not fabricate.
3. Maintain `vectors/README.md` from `references/vectors-readme-template.md`
   (create with the first epic; extend its file table with each subsequent
   one). In SPECIFIC, apply the vectors README deltas in the profile.

Also write `APPENDIX_Engineering_Constraints.md`: platform and engineering
traits (e.g. no_std, wasm targets, MSRV, performance posture, CI matrix) as
context for rebuilders, explicitly marked non-normative. Write it as
bold-led bullets, grouped under short headings, with no prose paragraphs.

In SPECIFIC, write `README.md` last, from `readme-template-specific.md`: it
walks one real example through every epic, so the epics must exist first.

### Phase 4 — Audit

1. **Coverage** — walk the public surface again; every observable behavior
   must map to an epic or an explicit out-of-scope row in the manifest.
2. **Anti-constraint lint** — NEUTRAL: search epic bodies for
   source-language type names, crate names, and idioms outside
   `## Provenance` sections; rewrite neutrally or move into Provenance.
   SPECIFIC: run the same search over `## Scope`, `## Domain map` and
   `## Not specified` only; source names elsewhere are expected.
3. **Perspective consistency** — every epic's `## Perspectives` section uses
   only perspectives defined in the manifest taxonomy (or N/A); every
   non-Absent **actor** perspective in the taxonomy is addressed by at least
   one epic. Quality lenses (performant, flexibility) are satisfied by their
   manifest ratings plus the engineering appendix; epics mention them only
   where a slice has a notable characteristic, and any lens finding stated
   as binding must carry an SD flag.
4. **Shape** — read each file for paragraphs that list three or more
   parallel things (rules, cases, gaps, steps) and rewrite them as bullets.
   Leave the paragraphs the methodology keeps as prose.
5. **Links (SPECIFIC)** — run
   `python3 -I ~/.claude/skills/deconstruct/scripts/check_links.py <pack-dir>`
   and fix every line it prints. Then spot-check that each excerpt still
   matches the lines its link anchors.

Fix findings, then report the audit results in your final summary.

## Rules

- **Essential vs accident.** If a correct rebuild in another language would
  be forced to make the same choice to preserve observable behavior, it is
  domain-essential; otherwise it is an accident and must not appear as a
  requirement. In SPECIFIC, accidents may appear in the walkthrough, as what
  the original happens to do.
- **Vectors are extracted, never authored.**
- **Code explains; it never binds.** NEUTRAL: `path:line` citations live only
  in Provenance. SPECIFIC: excerpts and links live in the walkthrough and
  Code references; Scope rules and vectors remain the contract.
- **Pin one commit.** Every citation, excerpt and vector comes from the
  commit in the manifest's Source line.
- **Bullets first.** Write every set of items as a list, one idea per
  bullet. Keep paragraphs for chains of reasoning only. The shape rules are
  in the methodology's "Writing shape: bullets first".
- **Name the freedoms.** Every epic lists implementer's-choice items in
  `## Not specified`. Silence is ambiguous; a named freedom is not.
- **Boundaries as invariants.** Perspective boundaries are domain rules
  ("consumers cannot alter deck vocabulary"), never mechanisms ("const").
- **Absences are recorded** — an unsupported perspective or uncovered
  behavior is written down, so a rebuilder can tell design from omission.
- **Honesty.** /epic's honesty rules apply; all Status rows are `Planned`.
- **Git.** Suggest commit commands; never run state-changing git yourself.
