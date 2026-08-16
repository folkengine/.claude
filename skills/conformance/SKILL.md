---
name: conformance
description: Measure a codebase against an externally-authored ruleset — a standards-body spec, RFC, protocol document, regulation, house rules PDF, or API contract — producing a canonical rule file, a standardized re-runnable audit in the repo's docs folder (CONFORMANCE_AUDIT.md) with per-rule verdicts and file:line evidence, and an executable test harness for those rules the source states concretely enough to assert. Use when the user types `/conformance <ruleset>` or asks "are we compliant with X", "audit this against the spec", "which parts of <standard> do we actually implement", "does our engine follow <rules>", "turn this spec into tests", or hands over a spec and a codebase and asks how far apart they are — even if they never say conformance. Do NOT trigger for standards the team authors itself (that is /quality-commitments), dependency entanglement (/untangle), API design quality (/reusability or /muratori), or a plain security scan.
---

# /conformance

Measure a codebase against rules **someone else wrote**. The ruleset is the
authority; the code is the thing under test. Your job is to say — rule by rule,
with evidence — which rules are met, which are half-met, which are absent, and
which never applied in the first place.

Three guiding principles:

- **The ruleset is external and fixed.** You do not get to reinterpret a rule
  because the code is inconvenient. If the code diverges deliberately, that is a
  recorded *divergence with a rationale*, not a redefinition of the rule.
- **Evidence or silence.** Every verdict cites `path/file.ext:line`. A claim you
  cannot cite is a claim you do not make.
- **Coverage of the ruleset must be total.** Every rule is either audited or
  explicitly excluded with a reason. Silent drops are the failure mode that makes
  an audit worthless.

## The two tiers

This is the load-bearing distinction. Get it wrong and the skill produces
fiction.

| Tier | Produces | Applies to |
|---|---|---|
| **1 — Audit** | per-rule verdict + `file:line` evidence + gap | **every** ruleset, always |
| **2 — Executable** | a real, running test per rule | **only** rules the source states concretely enough to assert |

Tier 1 always runs. Tier 2 runs **only** where the ruleset supplies a concrete
expected value or an unambiguous mechanical predicate.

A rule is tier-2 eligible when the source gives you a number, a required
ordering, a state transition, or a yes/no predicate you can evaluate. Specs with
worked examples — "in this situation the answer is 700" — are gold: they are an
external authority that cannot drift with your code.

A rule is **tier 1 only** when it reads like *"ensure appropriate access
controls"* or *"the operator should act reasonably"*. There is nothing to
assert. Say so and move on.

> **Never invent an expected value.** If the ruleset does not state the answer,
> the rule is tier 1. Fabricating an expected value produces a test that asserts
> your guess and calls it compliance.

## Modes

Mode comes from the phrasing; there are no strict flags.

| Ask sounds like | Do | Output |
|---|---|---|
| `/conformance <spec>` (default) | full pipeline | rule file + audit + harness |
| "parse/ingest this spec" | ingest only | canonical rule file |
| "which of these apply to us" | ingest + scope | rule file with `applies` set |
| "audit us against <rules>" | scope + audit | `CONFORMANCE_AUDIT.md` |
| "turn the spec's examples into tests" | harness only | test module |
| "re-run the conformance audit" | re-audit | updated audit; verdict deltas called out |
| "write up the failures" | defect report | repo's defect/docs convention |

## Workflow

### 1. Ingest — source material to canonical rules

Convert whatever you were handed (PDF, HTML spec, markdown, RFC text, an
existing YAML) into one canonical rule file. Schema and worked example:
`references/rule-schema.md`.

Extract text mechanically rather than transcribing by eye (`pdftotext -layout`
for PDFs). Multi-column layouts interleave — read the whole extraction before
structuring it.

Preserve rule text **verbatim**. The rule text is quoted authority; your commentary
belongs in separate fields. Record the source file, version, and date.

**Verify coverage before moving on:** parse the file and assert the rule count and
numbering match the source. A rule silently lost at ingest is invisible forever
after.

### 2. Scope — which rules bind this system

Not every rule in a ruleset binds every implementation. Tag each rule:

- **`direct`** — the rule is mechanically checkable against this system.
- **`adapted`** — the rule solves a problem that exists here in a *different*
  form. It does not port verbatim, but the design question it raises is real and
  must be answered.
- **excluded** — the rule genuinely does not apply. Goes in an `excluded:` list
  with a one-line reason.

**Do not collapse `adapted` into excluded.** It is where the interesting work
lives — the rule whose literal mechanism is gone but whose intent still demands a
decision. Dropping those turns an audit into a checklist.

Record the inclusion criteria in the file so the filter is reviewable.

### 3. Audit — verdict plus evidence

For each in-scope rule, search the codebase and record:

- `implemented:` — `"yes"` / `"partial"` / `"no"` (**quoted** — see honesty rules)
- `evidence:` — `path:line — what is there`, omitted only when there is nothing
  to cite
- `gap:` — what is missing or divergent, omitted only when the verdict is `"yes"`

Search by **mechanism, not vocabulary**. The code will not use the ruleset's
words. Search for the behaviour: the arithmetic, the state transition, the
ordering, the guard.

An absence is a finding. If nothing implements a rule, say so and record how you
established the absence (the search that returned nothing).

### 4. Report

Write the audit into the repo's existing documentation folder — detect it, do not
assume `docs/`. Follow the repo's own conventions if it has a defect or audit
format already. Template: `references/report-template.md`.

The most valuable section is usually **not** the individual findings. It is the
coverage analysis: *would a fix for any of these make an existing test fail?* If
the answer is no, the suite is pinned at the wrong altitude, and that is a bigger
result than any single rule.

### 5. Harness — tier 2

Where rules are tier-2 eligible, write a conformance test module:

- **Conformant rules get passing tests** that pin correct behaviour against the
  external authority.
- **Violated rules get tests asserting the ruleset's answer**, marked skipped /
  `#[ignore]` / `xfail` **with the finding id in the reason string**. They fail
  by design; CI stays green; un-skip each as it is fixed.
- **Run both ways and record the real output.** Default run must be green. The
  include-skipped run must show exactly the predicted failures.

If a predicted failure *passes*, your finding was wrong. Fix the finding, not the
test.

## Honesty rules

These are non-negotiable, and each exists because it was violated in real use.

1. **Never state a computed value you have not executed.** Reading the formula is
   not running it. If the audit claims "this yields 400", run it and paste what
   came back. Reading produced 400; the machine produced 600.
2. **Trace the ruleset's own worked examples through the code before naming a
   root cause.** A plausible root cause derived from reading is frequently the
   wrong one — often adjacent to the real defect, which makes it convincing.
3. **Quote the verdict strings.** In YAML 1.1 bare `yes` and `no` parse as
   booleans, so `implemented: yes` silently becomes `True` and any tally over the
   field returns zero. Write `implemented: "yes"`.
4. **Verify every citation resolves.** Print each cited line mechanically and
   confirm it says what you claim. Line numbers drift by one or two constantly.
5. **Sanity-check your search tool before trusting its output.** A misread flag
   can rewrite matches silently (`rg -ril PATTERN` parses as `--replace=il`). Run
   a control with known content first.
6. **State what `"yes"` means.** Present in source, or covered by a test you ran?
   Say which. If you did not execute the suite, write that in the report.
7. **Account for every rule.** `audited + excluded == total`. Assert it in code,
   not by eye.

## What makes a good conformance finding

- It names the rule, quotes the relevant clause, and cites the code.
- It shows the divergence with the ruleset's **own numbers**, not invented ones.
- It separates "wrong" from "deliberately different" — a divergence with a stated
  rationale is a decision, not a defect, but it must be *recorded* as one.
- It says whether existing tests could have caught it.

## Common mistakes

- **Promising tier 2 for a prose ruleset.** Most regulatory and policy text has
  nothing assertable. Producing tests anyway means asserting your interpretation.
- **Auditing by vocabulary.** Grepping the ruleset's terms finds nothing, because
  implementations name things differently. Search for mechanism.
- **Treating absence as out of scope.** "There is no code for this" is a finding,
  frequently the most important one.
- **Letting the code redefine the rule.** If the implementation is more permissive
  than the ruleset, that is a divergence to record — not a reason to soften the
  rule's wording.
- **Reporting findings without the coverage analysis.** A list of bugs is worth
  less than the observation that none of them could fail a test.
- **One giant rule file per project.** Keep the raw ruleset and the scoped subset
  as separate artefacts, so the scoping decisions stay reviewable.

## References

- `references/rule-schema.md` — canonical rule file schema, field by field, with
  a worked example
- `references/report-template.md` — audit document skeleton
