# Canonical ruleset file schema

One file per source document. Verbatim. Never edited again except to correct a
transcription error or add a `note:`.

This is **File 1** in the `/conformance` pair. It carries no `applies`, no
`implemented`, no `evidence`, no `gap`, no `engine_note`. Those live in File 2,
which `/conformance` derives from this one and joins on rule id.

## Skeleton

```yaml
---
# <one-line description>
#
# Parsed from: docs/<original>.pdf
# <verbatim attribution line the publisher requires, if any>

meta:
  authority: <who publishes this ruleset>
  short_name: <how it is commonly cited>
  title: <official title, as printed>
  version: "1.0"                    # ALWAYS a string
  date: 2024-10-09                  # publication date, as printed
  form: longform                    # edition/variant, when the source has them
  includes:                         # the parts this document contains
    - Rules
    - Recommended Procedures
  website: https://<publisher>
  source_file: docs/<original>.pdf
  extraction: extract/<original>.txt
  copyright: >-
    <verbatim notice>
  preamble: >-
    <verbatim scope statement, if the document opens with one>
  rights:                           # from step 0 — see references/rights.md
    class: restricted               # open | restricted | unknown
    holder: <publisher>
    notice: >-
      <verbatim operative sentence>
    source_url: https://<where that notice appears>
    checked: 2026-08-25
    distribution: >-
      <what the default posture is and why>

sections:                           # preserve the source's own grouping
  - id: general-concepts
    name: General Concepts
    rules:
      - id: 1                       # `id`, not `number` — many specs use 4.2.1
        title: Floor Decisions
        text: |-
          <verbatim rule text>
        clauses:                    # only when the source subdivides
          - id: A
            text: |-
              <verbatim clause text>
        see_also: [2, 42]           # cross-references the rule itself makes
        note: >-                    # YOUR words — errata, extraction caveats
          <only when the source has a discrepancy worth recording>

skipped:                            # everything in the document that is not a rule
  - what: revision history table, pp. 3-5
    reason: change log, carries no normative content
  - what: rule 39
    reason: printed as "Deleted 2022"; id retained in sections for alignment
```

## Field rules

| Field | Rule |
|---|---|
| `version` | always quoted — `1.10` unquoted becomes the float `1.1` |
| `date` | as printed in the source, not today |
| `source_file` | required; the path to the original document |
| `extraction` | required; the path to the saved raw text |
| `id` | the source's own identifier, unmodified |
| `text` | verbatim; wrap freely, never reword. May be a **list** when the source states one item as several separate passages (prose plus its parameter table) — each element is verbatim on its own, the concatenation is not |
| `upstream` | list of ids in *other* documents that this item traces to, when the source prints them (AUTOSAR "Upstream requirements", ISO "derived from"). Source data, so it belongs here; unlike `see_also` it is not expected to resolve inside this file |
| `title` | as printed; omit if the source gives none — do not invent one |
| `note` | the only field that may contain your words |

Anything not on this list is not part of File 1. If you feel the need to add a
field, you have probably started scoping — that is `/conformance`.

## Multi-part documents

When one document contains several numbered series, each series gets its own
top-level block with its own id space:

```yaml
sections:                  # the main rule series, ids 1..71
  - ...

recommended_procedures:    # ids RP-1 .. RP-22
  meta:
    title: 2024 Recommended Procedures
    preamble: >-
      <verbatim>
  rules:
    - id: RP-1
      ...

illustration_addendum:     # worked examples keyed to specific rules
  examples:
    - id: IA-5
      applies_to: [42]
      text: |-
        <verbatim>
```

Flattening these collides ids (`1` from two series) and destroys the source's
own structure. Keep them apart.

Worked examples are worth extracting carefully: they carry concrete inputs and
concrete answers from an external authority, which is exactly what
`/conformance` turns into executable tests.

## Tables

A table in the source is structure, not prose. Extract it as structure:

```yaml
      - id: 4.2.1
        title: Timeout values
        text: |-
          <verbatim surrounding prose>
        table:
          columns: [parameter, min, max, unit]
          rows:
            - [T_wait, 10, 500, ms]
            - [T_retry, 1, 5, count]
```

Flattening a table into a sentence loses the values that make the rule testable.

## Identifiers, verbatim

Keep them exactly as printed, however awkward:

| Source style | Keep as |
|---|---|
| `Rule 42` | `42` |
| `4.2.1` | `"4.2.1"` (quoted — otherwise a float) |
| `RP-14` | `RP-14` |
| `§ 8(b)` | `"§ 8(b)"` |
| `[SWS_Can_00021]` | `SWS_Can_00021` |
| `MISRA C:2012 Rule 8.13` | `"8.13"` inside a document scoped to MISRA C:2012 |

Renumbering to make ids sort, or converting them to integers, breaks the join to
the source document and to any `/conformance` audit built on it.

## Editions and versions

Two editions are two files. They share ids, so they join:

```
tda_2022.yaml
tda_2024.yaml
```

Never merge them, and never overwrite an old edition with a new one. The diff
between editions is often the most valuable thing in the pair.

## Verification

Step 4 of the skill runs:

```bash
python3 ~/.claude/skills/codify/scripts/verify_ruleset.py <ruleset>.yaml \
  --extract extract/<source>.txt
```

Run it. Paste the output. It is the only evidence that "verbatim" is true.
