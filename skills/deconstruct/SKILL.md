---
name: deconstruct
description: Distill an existing codebase into a portable regeneration pack — language-agnostic DECON epics in the /epic house style plus golden test vectors extracted by running the original code — so its functionality can be rebuilt by people or agents in any language without inheriting the original's programmatic design choices. Use when the user types `/deconstruct [subsystem]` or asks to "deconstruct this codebase", "distill this repo into epics", "make a regeneration spec", "reverse-engineer a spec from this code", "write specs so another team or agent can rebuild this" — even if they never say the word deconstruct. Do NOT trigger for forward-looking feature design (that is /epic), teaching material or exercises (that is /codebase-kata), or kernel-purity assessment (that is /domain-kernel).
---

# Deconstruct

Turn a working codebase into a **regeneration pack**: a self-contained folder
of language-agnostic epics plus machine-extracted golden vectors, sufficient
for a person or agent to rebuild the functionality in any language, free of
the original's design choices.

`/epic` goes design → code. `/deconstruct` is its inverse: code → design.
Citations into the source prove a behavior is real; they never bind the
rebuilder.

## Usage

- `/deconstruct` — deconstruct the whole repo.
- `/deconstruct <subsystem>` — scoped run: produce or update only the epics
  covering `<subsystem>`, then re-derive the manifest coverage table.

**Update mode:** if a pack already exists (a `deconstruct/MANIFEST.md` under
the repo's docs folder), never clobber it. Refresh vectors at the current
commit, reconcile epic text against current behavior, and record drift in the
manifest's Drift log. Never renumber existing DECON epics.

## The pack

Write into `<docs-dir>/deconstruct/` (detect the repo's docs folder the same
way /epic does — prefer wherever design markdown already lives; default
`docs/`):

    docs/deconstruct/
      MANIFEST.md                       ← index & entry point
      DECON-01_Name.md …                ← epics, own numbering, build order
      APPENDIX_Engineering_Constraints.md
      vectors/
        README.md                       ← vector format contract
        <epic-slug>/*.json              ← golden vectors per epic

The pack must be portable: copy the folder out and hand it to any agent —
nothing in it may depend on access to the source repo.

## What you must do when invoked

**Before writing anything**, read `references/methodology.md` in this skill
dir, and `~/.claude/skills/epic/references/methodology.md` — the /epic voice
and kata framing carry over; this skill's methodology defines the deltas
(the "deconstruct profile").

### Phase 1 — Survey

Fan out subagents over four signals; keep the conclusions, not the file
dumps:

1. **Public surface** — every observable capability: the domain's things,
   operations, orderings, formats, locales.
2. **Test mining** — what the tests promise; note coverage gaps. Where
   coverage is weak, vectors still come from the dumper in Phase 3 (it
   exercises the public API directly, independent of the test suite), but
   the weak grounding means any spec-decision flag on that behavior gets
   extra scrutiny before it's resolved.
3. **Docs mining** — README, CHANGELOG, design docs: what was intended.
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
from `references/manifest-template.md`. Then pause ONCE: present the epic
list, per-epic scope, out-of-scope rows, and the perspectives taxonomy via
AskUserQuestion. The user's approval (with edits) is the gate. No other
checkpoints — after this, generate everything.

### Phase 3 — Generate

For each epic, in dependency order:

1. Write `DECON-NN_Name.md` from `references/decon-epic-template.md`,
   following the deconstruct profile.
2. Extract golden vectors by **running the original code**: write a dumper
   program in the source language, using only the public API, that
   serializes the epic's observable behaviors to JSON under
   `vectors/<epic-slug>/`. The dumper is committed to the source repo (e.g. a
   Rust example) so vectors stay regenerable. **Never hand-write vector
   values.** If you cannot run the code, say so and stop — do not fabricate.
3. Maintain `vectors/README.md` from `references/vectors-readme-template.md`
   (create with the first epic; extend its file table with each subsequent
   one).

Also write `APPENDIX_Engineering_Constraints.md`: platform and engineering
traits (e.g. no_std, wasm targets, MSRV, performance posture, CI matrix) as
context for rebuilders, explicitly marked non-normative.

### Phase 4 — Audit

1. **Coverage** — walk the public surface again; every observable behavior
   must map to an epic or an explicit out-of-scope row in the manifest.
2. **Anti-constraint lint** — search epic bodies for source-language type
   names, crate names, and idioms outside `## Provenance` sections; rewrite
   neutrally or move into Provenance.
3. **Perspective consistency** — every epic's `## Perspectives` section uses
   only perspectives defined in the manifest taxonomy (or N/A); every
   non-Absent **actor** perspective in the taxonomy is addressed by at least
   one epic. Quality lenses (performant, flexibility) are satisfied by their
   manifest ratings plus the engineering appendix; epics mention them only
   where a slice has a notable characteristic, and any lens finding stated
   as binding must carry an SD flag.

Fix findings, then report the audit results in your final summary.

## Rules

- **Essential vs accident.** If a correct rebuild in another language would
  be forced to make the same choice to preserve observable behavior, it is
  domain-essential; otherwise it is an accident and must not appear as a
  requirement.
- **Vectors are extracted, never authored.**
- **Provenance is non-normative.** `path:line` citations prove existence;
  they never bind.
- **Name the freedoms.** Every epic lists implementer's-choice items in
  `## Not specified`. Silence is ambiguous; a named freedom is not.
- **Boundaries as invariants.** Perspective boundaries are domain rules
  ("consumers cannot alter deck vocabulary"), never mechanisms ("const").
- **Absences are recorded** — an unsupported perspective or uncovered
  behavior is written down, so a rebuilder can tell design from omission.
- **Honesty.** /epic's honesty rules apply; all Status rows are `Planned`.
- **Git.** Suggest commit commands; never run state-changing git yourself.
