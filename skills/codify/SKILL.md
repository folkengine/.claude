---
name: codify
description: Turn externally-authored source documents — a standards-body spec, RFC, protocol PDF, regulation, house rules book, API contract, or a whole release bundle — into one canonical, verbatim, machine-readable ruleset file per document, with a saved raw extraction as proof and a checker that must pass before the job is called done. Use when the user types `/codify <documents>` or asks to "parse this spec into YAML", "extract the rules from these PDFs", "make a machine-readable version of this standard", "structure this rulebook", "build a ruleset file from these docs", "ingest this spec" — even if they never say codify. This is the mirror of `/conformance`: codify BUILDS the ruleset, conformance MEASURES a codebase against it. Do NOT trigger for scoping rules to a system, auditing code, or writing conformance tests (all `/conformance`), for summarizing or explaining a document (plain reading), or for standards the team authors itself (`/quality-commitments`).
---

# /codify

Turn documents **someone else wrote** into a canonical ruleset file. The document
is the authority; the YAML is a faithful mirror of it. Nothing else.

`/codify` is one half of a pair:

| Skill | Direction | Output |
|---|---|---|
| **`/codify`** | documents → rules | `<ruleset>.yaml`, verbatim |
| **`/conformance`** | rules → code verdict | audit + test harness |

Three guiding principles:

- **Transcription, not interpretation.** You are a scribe. Every judgement call
  you make is a place the ruleset stops being the authority. If a rule is vague,
  it stays vague in the YAML.
- **Machine extraction, not eyes.** Text comes out of the source with a tool, and
  the raw output is **kept on disk**. Verbatim you cannot check is verbatim you
  cannot claim.
- **Nothing disappears silently.** Every numbered item in the source is either in
  the file or in a `skipped:` ledger with a reason. A rule lost at this stage is
  invisible forever after, including to `/conformance`.

## What `/codify` does not do

It does **not** decide which rules apply to a system (`applies:`), whether code
implements them (`implemented:`), or what the code should do (`engine_note:`).
Those fields belong to `/conformance` and must not appear in a `/codify` output.
Adding them here means two skills own the same decision and can disagree.

If the user asks for both, run `/codify` first, then hand the file to
`/conformance`.

## Step 0 — Rights (before you extract anything)

Many specs are downloadable but not freely reusable. Parsing into YAML is both a
*modification* and a *derivative work*, so a licence that permits "unmodified,
informational use only" does not obviously cover it.

Do this before opening a single PDF. Full guidance: `references/rights.md`.

1. Find the publisher's notice — the PDF disclaimer page, the download page, the
   site imprint. Quote it, do not summarise it.
2. Classify the source: **open** (permissive/public domain), **restricted**
   (informational use only, no modification, no redistribution), or **unknown**.
3. Record the finding in `meta.rights` verbatim, with its URL.
4. Apply the default posture:

| Source class | Output default |
|---|---|
| open | normal repo file, committable |
| restricted or unknown | written to a **gitignored** path; local use only |

**Hard rule: never commit, push, or publish a ruleset derived from a `restricted`
or `unknown` source without the user explicitly saying to.** Say what the notice
says, say what the default is, and let them decide. Do not decide for them, and
do not quietly commit it because the repo already tracks the sources.

If the publisher also ships a machine-readable artefact (XML schema, meta-model,
JSON, an ABNF grammar), say so and offer it as the source instead of the PDF. It
is cleaner input and a smaller derivative footprint.

## Step 1 — Take stock

- List every document in scope. Count them. State the count.
- Detect where the output goes: beside existing ruleset YAMLs if the repo already
  has them, otherwise propose a location and ask once.
- Decide the file split. **Default: one YAML per source document.** Merge only
  when the user asks, and never merge across versions or editions — a 2022 and a
  2024 edition are two files that join on rule id.
- For large bundles (dozens of documents), work **one document at a time** and
  report progress per document. Never describe a set as codified when a sample
  was parsed.

## Step 2 — Extract, mechanically

Get the text out with a tool and **save the raw output**:

```bash
pdftotext -layout "docs/<source>.pdf" "extract/<source>.txt"
```

`extract/<source>.txt` is a required artefact, not a scratch file. Step 4 compares
every rule's `text` against it. No extraction, no verification, no completion.

Read the whole extraction before structuring anything. Multi-column layouts
interleave, tables collapse, and headers repeat on every page. Per-format tactics
and failure modes: `references/extraction.md`.

If a source is a scanned image with no text layer, stop and say so. Do not
transcribe it by eye.

## Step 3 — Structure

Build the canonical file. Schema, field by field, with a worked example:
`references/ruleset-schema.md`.

The rules that matter most:

- **`text` is verbatim.** Line-wrap freely; never reword, never tidy, never
  expand an abbreviation. Compare with `.split()` so wrapping is not drift.
- **Keep the source's own ids**, however ugly: `4.2.1`, `RP-14`, `§ 8(b)`,
  `[SWS_Can_00021]`. Renumbering destroys traceability to the document.
- **One block per part.** A document holding Rules + Recommended Procedures +
  Illustration Addendum becomes three top-level blocks, each with its own id
  space. Flattening them collides ids and loses the source's structure.
- **Record errata, do not fix them.** Keep the text as printed and add a `note:`
  describing the discrepancy.
- **Keep deleted stubs.** A `D) Deleted 2022` clause keeps later clause ids
  aligned.
- **Anything not a rule goes in `skipped:`** — title pages, indexes, revision
  history, page furniture — each with a one-line reason.

## Step 4 — Verify (must run, must be green)

```bash
python3 ~/.claude/skills/codify/scripts/verify_ruleset.py <ruleset>.yaml --extract extract/<source>.txt
```

The checker asserts: the file parses; `meta` carries the required fields; ids are
unique and non-empty; numeric id runs have no undeclared holes; every rule's
`text` appears word-for-word in the raw extraction; `see_also` targets resolve;
no field landed as a YAML boolean by accident.

Add `--expect N` when the document states its own rule count; the checker then
reconciles the two for you.

**Paste the real output.** Not a summary of it. If it fails, fix the YAML — never
loosen the checker, and never edit the extraction to match the YAML.

### Cross-check the source against itself

When a document prints both **parameters** and **worked examples** — a
polynomial table plus the expected CRCs, a formula plus a sample calculation, a
rate plus a computed total — run the parameters through the examples. If they
reproduce, both extractions are provably right. If they do not, one of them was
extracted wrong, and you have found it before `/conformance` ever runs.

This costs a few minutes and is the strongest evidence available at this stage,
because it needs no code under test — the document is checking itself.

### Reading a verbatim failure

The checker prints how far the text matched before diverging:

```
FAIL  sections[7].rules[11].clauses[0]: text is not verbatim in the extraction
      — matched 20/21 words, then: ...Addendum.
```

Three causes, in order of likelihood:

1. **A silent tidy-up.** A period added, a source typo corrected, an abbreviation
   expanded. Restore the source's wording and add a `note:` recording the
   discrepancy. Do not "fix" the document.
2. **Reflow.** A bulleted list collapsed into a sentence, or two source
   paragraphs merged. Split it back.
3. **Page furniture the stripper missed.** Footers that vary per page, or a
   header appearing fewer than three times. Confirm by looking at the extraction
   around the divergence point; if that is the cause, say so in the report rather
   than editing either file.

A near-total mismatch (`matched 2/69 words`) usually means the text was assembled
from more than one place in the document.

## Step 5 — Wrap

- `README.md` naming the source document, its version and date, the publisher,
  and the verbatim copyright notice.
- The `skipped:` ledger, populated.
- A one-line statement of what was verified and how — the checker output, and the
  rule count reconciled against the source.

## Modes

Mode comes from the phrasing; there are no strict flags.

| Ask sounds like | Do | Output |
|---|---|---|
| `/codify <docs>` (default) | full pipeline | ruleset YAML + extraction + README |
| "just get the text out" | step 2 only | raw extractions |
| "add the 2025 edition" | new sibling file | second YAML, same schema, joins on id |
| "re-verify these" | step 4 only | checker output, drift report |
| "the source has errata" | targeted fix | corrected YAML + `note:` recording it |
| "can we publish this?" | step 0 only | rights finding, quoted, with the URL |

## Honesty rules

Each of these exists because the failure it names is easy and invisible.

1. **Never paraphrase rule text.** Not to shorten it, not to fix its grammar, not
   to make it parse nicely. A paraphrase read back later is indistinguishable
   from the source, and it silently becomes the authority.
2. **Never renumber.** Not to make ids sort, not to close a gap, not to make them
   integers. A gap in the source is a fact about the source; declare it in
   `skipped:`.
3. **Never invent structure the source lacks.** If the document does not group
   rules into sections, do not create sections.
4. **Never claim verbatim without the extraction on disk.** The checker's text
   comparison is the only thing that makes the claim true.
5. **Report counts as numbers, from the checker.** "All rules captured" is not a
   result. "71 of 71" is.
6. **State what you skipped and why**, in the file, not only in chat.
7. **Rights before content.** Do not commit or publish a derived ruleset from a
   restricted source on your own judgement.

## Common mistakes

- **Structuring before reading the whole extraction.** The first ten pages of a
  spec rarely show you the real shape; part 3 introduces the exception that
  breaks your schema.
- **Letting the target system leak in.** The moment you drop a rule because "our
  code could never do that", you have started scoping — that is `/conformance`,
  and a different file.
- **Merging editions into one file.** Diffing two editions is easy when they are
  two files with shared ids, and impossible once merged.
- **Reflowing text to look tidy.** Collapsing a bulleted list into a sentence
  changes meaning. Keep the list.
- **Treating a table as prose.** Tables carry the concrete values that make a
  rule testable downstream. Extract them as structure, not as a wall of words.
- **Calling a bundle done after a sample.** Say which documents were parsed and
  which were not.
- **Committing the output because the sources are already committed.** The
  sources' presence is not a licence finding.

## References

- `references/rights.md` — how to read a publisher's terms before extracting, and
  what each answer permits
- `references/ruleset-schema.md` — canonical file schema with a worked example
- `references/extraction.md` — per-format extraction tactics and failure modes
- `scripts/verify_ruleset.py` — the checker; step 4 must run it
