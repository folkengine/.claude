# Deconstruct methodology — the profile

Read `~/.claude/skills/epic/references/methodology.md` first. Everything
there about voice, kata framing, and honesty applies. This file defines the
deltas for regeneration specs.

## The deconstruct profile (deltas vs /epic)

| /epic convention | deconstruct profile |
|---|---|
| Status rows reflect landed work | All rows `Planned` — the spec describes work not yet done |
| Design carries ```rust API sketches | Language-neutral prose, tables, pseudocode; rationale states the *domain constraint*, never the original mechanism |
| Domain map: concept → code construct | Concept → required behavior → vector file |
| Verification: ```bash of exact commands | Contract clause: "any implementation must reproduce `vectors/<slug>/*.json`" + prose exit criteria |
| `path:line` citations are normative | Citations live only in `## Provenance (non-normative)` |
| — | `## Perspectives`: per-slice actor boundaries |
| — | `## Not specified (implementer's choice)`: named freedoms |
| — | `## Spec decisions`: SD-NN flags |

## Litmus: domain-essential vs implementation-accident

Ask: **"Would a correct rebuild in another language be forced to make the
same choice to preserve observable behavior?"** Yes → essential (spec it).
No → accident (omit it, or name it as a freedom).

Examples (cardpack):

- Weak Ganjifa suits rank pips inverted (`A > 2 > … > 10`) → **essential**.
- Implementing that as a second rank ladder with inverted weight integers →
  **accident**.
- Card names localize into 5 locales with specific translated strings →
  **essential** (observable).
- The fluent-templates crate and `.ftl` file layout → **accident**.

**The coupled case:** some observable outputs are consequences of accidental
choices — e.g. the exact permutation from a seeded shuffle depends on which
RNG the original picked. Record a spec decision: **pin** (the vector is
normative; rebuilds are bit-compatible) or **relax** (the *property* —
"same seed ⇒ same permutation, uniform over seeds" — is normative and the
vector is informative). State which was chosen and why.

## Spec decision format

In the epic body, at the point of relevance:

> **Spec decision SD-NN:** <the question>. **Options:** <A> / <B>.
> **Chosen:** <one> — <one-line why>.

Number SD-NN globally across the pack; index every flag in the manifest.
A pack-level decision that belongs to no single epic (e.g. a
lens-normativity default) may live only in the manifest's index, with
`—` in its Epic column.

## Perspectives

The taxonomy has two kinds of entries. Both are rated in the manifest with
evidence; they differ in what an epic says about them.

**Actor perspectives** — who acts on the domain, behind what boundary
(extend with repo-specific actors as discovered):

- **God-mode** — central control over what the domain *is*: definitions,
  vocabularies, rank ladders.
- **Administrative** — operates and supports the domain without redefining
  it (registries, configuration, lifecycle).
- **User/client** — consumes functionality with bounded access, unable to
  corrupt the underlying domain.
- **Observer/operator** — read-only insight into domain activity (OTel-style
  telemetry: traces, metrics, logs) without the ability to affect it.

**Quality lenses** — measured characteristics of the code as built:

- **Performant** — how performant is it? Algorithmic complexity of core
  operations, allocation behavior, any benchmarks the source repo carries.
- **Flexibility** — how flexible is it in terms of where and how it can
  run? Runtime environments (OS-hosted, embedded/bare-metal, browser),
  optional-capability layering, configurability.

Rating rubric (manifest carries the ratings, with evidence):

- **Full** — an actor perspective has a complete, bounded interface with
  invariants holding everywhere; a quality lens is a demonstrated strength
  with cited evidence.
- **Partial** — some support exists; name the gaps concretely.
- **Absent** — no support; record it explicitly so a rebuilder can tell
  design from omission.

Phrase actor boundaries as **domain invariants**, never mechanisms: write
"consumers cannot alter the deck vocabulary", not "deck consts are
immutable"; write "observation must not mutate domain state", not "we log
via the log crate".

Phrase quality-lens findings as **characteristics**, in observable terms:
"builds a full deck in constant work per card; runs without an operating
system and in browsers" — not "uses const fn and no_std". Lens findings are
**informative by default** (they describe the original, they do not bind the
rebuild); binding one is a spec decision — raise an SD flag ("must the
rebuild match original performance? Chosen: …") rather than silently
promoting it.

## Vector conventions

- JSON, UTF-8, LF line endings, 2-space indent, trailing newline.
- Envelope: `{"epic": "DECON-NN", "behavior": "<slug>", "data": ...}`.
  The source commit is pinned once in MANIFEST.md, not per file.
- Deterministic: no timestamps, no unordered-map iteration, fixed seeds
  (list the seeds in the epic). Byte-identical across runs at one commit.
- Arrays appear in domain order (e.g. deck order), not alphabetical.
- One file per behavior cluster; typical clusters: `composition` (the full
  card list, in order), `ordering` (rank/suit precedence), `roundtrip`
  (parse/format pairs), `locales` (localized names), `seeded-shuffle`
  (seed → permutation).

## Dumper guidance

- Written in the source language, importing the code **as a consumer
  would** — public API only, no internal modules.
- Lives in the source repo (for Rust: an example, run via
  `cargo run --example <name>`), committed, so vectors regenerate when the
  source moves.
- Writes files under the pack's `vectors/` dir; prints one line per file
  written; exits nonzero on any failure.

## Numbering, naming, update mode

- `DECON-NN_Snake_Case.md`, zero-padded from `01`, ordered by build order
  (foundations first). Sub-letter `NNa` for a follow-on, as in /epic.
- Update mode: regenerate vectors at the current commit; if any file
  changes, add a Drift log row in the manifest (commit range → behavior
  change) and reconcile the affected epic text. Never renumber.
