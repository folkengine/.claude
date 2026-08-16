# Conformance audit report template

Write into the repo's **existing** documentation folder — detect it, do not assume
`docs/`. If the repo already has a defect or audit convention (numbered
`DEFECT_NNN_*.md`, an `EPIC-NN` series, an `ADR/` directory), follow it and adapt
the headings below rather than importing this shape wholesale.

Default filename when the repo has no convention: `CONFORMANCE_AUDIT.md`.

Delete any section that genuinely does not apply, and say in one line why, rather
than leaving it empty.

---

```markdown
# Conformance: <target> against <ruleset>

**Ruleset:** <official title, version, date, publisher>
**Target:** <system>, <version>, commit `<sha>`, branch `<branch>`
**Audited:** <date>
**Method:** <source reading? tests executed? name exactly what was run>
**Status:** <Open / Partially remediated / Closed>

---

## Summary

Two or three paragraphs. Lead with the shape of the result, not a list. What
holds up, what does not, and the single most consequential gap.

State plainly what class of failure the ruleset's own structure implies — e.g.
whether any finding produces a wrong *result* versus a wrong *process*.

---

## Scorecard

| | yes | partial | no |
|---|---|---|---|
| **direct** (N) | | | |
| **adapted** (N) | | | |

Coverage: N audited + N excluded = N total rules.

---

## Findings at a glance

| # | Rule | Finding | Severity | Evidence |
|---|---|---|---|---|
| F-1 | <rule id> | <one line> | Major | `path:line` |

Findings are ordered by severity, not by rule number.

---

## F-N: <specific claim, not a topic>

**Severity:** <Critical / Major / Minor> — <one clause on why that severity>

### The rule

> <verbatim quote of the governing clause>

One or two sentences on what the rule is *for*. A reader who does not know the
domain should understand why the rule exists before seeing the code.

### Root cause

The code, quoted, with its citation. Point at the specific line that decides the
behaviour — not the whole function.

### Symptom

The divergence, using the **ruleset's own numbers** where it supplies them. A
table of expected-vs-actual is usually clearest. Mark measured values as measured.

### Fix sketch

Where the fix belongs and why there rather than somewhere else. Name what is out
of scope. If the fix changes stored data or recorded output, say so — that is a
decision that must precede the fix.

---

## Accepted divergences

Deliberate departures, so they are not re-reported as findings each run. Each
needs: what the rule requires, what the system does instead, and why that is
defensible. A divergence without a rationale is an unrecorded defect.

---

## Coverage analysis

**Usually the most valuable section.** For each finding, ask: could an existing
test have caught this? If a fix would make no current test fail, the suite is
pinned at the wrong altitude, and that is a larger finding than any single rule.

Name the specific reason each finding is invisible — absence cannot fail a test,
fixtures are too symmetric, the assertion is at the wrong layer, the failure mode
is silent.

---

## Prevention

Concrete and ordered by payoff. Typically:

- The conformance harness itself, and what it does and does not cover.
- Citing rule ids in the code, so the audit becomes greppable rather than
  one-off.
- Fixtures shaped to expose the conditions the findings need.
- Any decision that must be made before a fix can land.

---

## Affected code

| File | Role | Findings |
|---|---|---|
| `path:line` | what it does | F-1 |

Include an "absent — no implementation" row for findings that are absences.

---

## Out of scope

Findings belonging to a different component or repo. Pointers only — enough for
someone to pick them up, not a second report.

---

## Verification

Exact commands, and the **real observed output** pasted back. If the suite was
not run, say so explicitly rather than implying it was.

```bash
<command to reproduce each reproducible finding>
<command to confirm citations still resolve>
```

Then the observed result, verbatim.

---

## References

- The rule file and scoped audit this report draws from
- The ruleset's own worked examples, where they supplied expected values
- Prior related reports in this repo
```

---

## Notes on writing it

- **Severity is about consequence, not effort.** A one-chip payout error is
  Major; a missing predicate that blocks five other rules is Major-structural.
  Reserve Critical for wrong results at scale.
- **Quote the rule before the code.** Readers need the authority in view before
  the diff.
- **Measured beats derived.** Where you ran something, say "measured" and paste
  it. Where you reasoned, say so. Mixing the two silently is how a report ends up
  asserting a number nobody ever observed.
- **An absence gets the same treatment as a bug.** Root cause is "nothing
  implements this", evidence is the search that came back empty.
