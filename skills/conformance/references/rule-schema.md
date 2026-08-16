# Canonical rule file schema

Two artefacts, kept separate so scoping decisions stay reviewable:

1. **`<ruleset>.yaml`** — the full ruleset, verbatim, unfiltered. Never edited
   again except to fix a transcription error.
2. **`<ruleset>_<target>.yaml`** — the scoped subset carrying `applies`,
   `implemented`, `evidence`, `gap`. Joins to the first on rule id.

Keeping them apart means you can re-scope for a second target without re-parsing,
and a reviewer can diff your filter against the source.

## File 1 — the full ruleset

```yaml
meta:
  authority: <who publishes this ruleset>
  title: <official title>
  version: "1.0"                 # always a string
  date: 2024-10-09
  source_file: docs/<original>.pdf
  copyright: <verbatim notice, if the source carries one>
  preamble: <verbatim scope statement, if present>

sections:                        # preserve the source's own grouping
  - id: general-concepts
    name: General Concepts
    rules:
      - id: 1                    # `id`, not `number` — many specs use 4.2.1
        title: Floor Decisions
        text: |-
          <verbatim rule text>
        clauses:                 # only when the source subdivides
          - id: A
            text: |-
              <verbatim clause text>
        see_also: [2, 42]        # cross-references the rule itself makes
```

**Rules for this file**

- `text` is **verbatim**. No paraphrase, no reflow of meaning. Line-wrap freely;
  compare with `.split()` when verifying, so wrapping never registers as drift.
- Preserve the source's own ids even when they are ugly (`4.2.1`, `RP-14`,
  `§ 8(b)`). Renumbering destroys traceability.
- Record source errata rather than silently fixing them: keep the text as printed
  and add a `note:` explaining the discrepancy.
- Clause ids stay as printed, including ones the source has deleted — a `D)
  Deleted 2022` stub keeps later clause ids aligned.

## File 2 — the scoped audit

Same rule ids, plus the audit fields. Rules that do not apply move to `excluded`.

```yaml
meta:
  title: <ruleset> — <target> conformance audit
  derived_from: <ruleset>.yaml
  target: <system under audit>
  target_profile: >-
    <what this system is, in the terms the ruleset cares about — this is what
    makes a scoping decision defensible later>
  inclusion_criteria: >-
    <the one-sentence test you applied to keep or drop a rule>
  audited: 2026-08-16
  against: <repo paths and commit>
  method: >-
    <source reading? tests executed? say exactly which>

sections:
  - id: general-concepts
    name: General Concepts
    rules:
      - id: 1
        title: Floor Decisions
        applies: direct                 # direct | adapted
        implemented: "partial"          # "yes" | "partial" | "no" — ALWAYS quoted
        evidence:
          - "src/foo.rs:94 — min_raise returns the last increment"
        gap: >-
          <what is missing or divergent; omit entirely when implemented is "yes">
        engine_note: >-
          <what the implementation must actually do about this rule>
        text: |-
          <verbatim, unchanged from file 1>

excluded:
  - id: 4
    title: Player Identity
    reason: physical appearance; no analogue in an automated system
```

## Field reference

| Field | Values | Meaning |
|---|---|---|
| `applies` | `direct` | mechanically checkable against this system |
| | `adapted` | literal mechanism absent, but the rule raises a real design question here |
| `implemented` | `"yes"` | behaviour is present; `method` says whether that was verified by test or by reading |
| | `"partial"` | some clauses or some cases handled; `gap` says which are not |
| | `"no"` | absent; `gap` says how the absence was established |
| `evidence` | list of `path:line — what` | omit when there is genuinely nothing to cite |
| `gap` | prose | omit only when `implemented` is `"yes"` |
| `engine_note` | prose | what the code must do — the actionable half |

### Why `implemented` must be quoted

YAML 1.1 parses bare `yes`, `no`, `on`, `off`, `y`, `n` as booleans. Written
unquoted, `implemented: yes` becomes `True`, the field turns mixed-type, and any
tally over it silently reports zero for both `yes` and `no`. Always quote.

### Why `adapted` is a separate value, not an exclusion

A rule can be unimplementable as written and still binding in substance. A
requirement that a participant be physically present has no literal meaning in a
networked system — but it maps onto connection state, and the consequences it
attaches (forfeit, timeout, resource release) port exactly. Excluding it loses a
real design question. `adapted` keeps it visible while signalling that the fix is
a decision, not a transcription.

## Verification snippets

Run these; do not eyeball them.

```python
import yaml, collections

full  = yaml.safe_load(open("<ruleset>.yaml"))
audit = yaml.safe_load(open("<ruleset>_<target>.yaml"))

all_ids  = {r["id"] for s in full["sections"]  for r in s["rules"]}
kept     = {r["id"] for s in audit["sections"] for r in s["rules"]}
excluded = {e["id"] for e in audit.get("excluded", [])}

assert not (kept & excluded),        f"in both: {kept & excluded}"
assert kept | excluded == all_ids,   f"unaccounted: {all_ids - kept - excluded}"

rules = [r for s in audit["sections"] for r in s["rules"]]
assert all(isinstance(r["implemented"], str) for r in rules), "unquoted yes/no"
assert all(r.get("gap") for r in rules if r["implemented"] != "yes"), "missing gap"

# Rule text must still match the source, ignoring line wrapping.
src = {r["id"]: r for s in full["sections"] for r in s["rules"]}
for r in rules:
    if "text" in r:
        assert r["text"].split() == src[r["id"]]["text"].split(), f"drift: {r['id']}"

print(collections.Counter((r["applies"], r["implemented"]) for r in rules))
```

Then confirm every citation resolves:

```bash
grep -oE '[a-zA-Z0-9_./-]+\.[a-z]+:[0-9]+' <ruleset>_<target>.yaml | sort -u |
while IFS=: read -r f l; do
  printf '%-50s %s\n' "$f:$l" "$(sed -n "${l}p" "$f" | cut -c1-60)"
done
```

Anything printing blank is a citation that no longer points where it claims.
