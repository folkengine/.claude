<!--
  PROGRESS / EVALUATION COMPANION TEMPLATE.
  Use for "progress report on X" / "evaluate the <branch> work". Emit as
  EPIC-NN_Name_Progress.md next to its parent EPIC (or standalone if none).
  This is an EVALUATION, not a plan: every claim is grounded in a check you
  actually ran (git log, cargo test, cargo clippy, build matrix). Report real
  numbers and real failures — the value is honesty, not optimism.
-->

# EPIC-NN <Name> — Progress Report & Quality Evaluation

**Date:** <YYYY-MM-DD>
**Evaluated at:** <commit sha + branch> (<one line on what that ref is>)
**Note:** <any branch drift / caveats about what was measured>

---

## Executive summary

<!-- Lead with the verdict. One paragraph: what state the work is in, what works,
     what doesn't, whether it meets its stated goal. -->

**Status:** <one-line state>.
**Overall grade:** <e.g. C+ — "solid skeleton, unfinished muscles.">

---

## Timeline & activity

<!-- When the work happened; commit cadence; authorship; dormancy. A small table
     of period → activity reads well. -->

| Period | Activity |
|---|---|
| <YYYY-MM> | <what landed> |

## Size & shape

<!-- Diffstat vs the base branch; module/file count; how it relates to the core
     (reuses vs forks). Cite the numbers you measured. -->

## Verification results

<!-- The checks you ACTUALLY ran and what they returned. -->

| Check | Result |
|---|---|
| `cargo test …` | ✅ N passed / ❌ … |
| `cargo clippy …` | ⚠️ N warnings |
| `cargo build --no-default-features` | ✅ / ❌ |
| CI coverage of this feature | ⚠️ <gap?> |

## What works today

<!-- Concretely, what a consumer can do right now. Cite path:line. -->

## Quality evaluation

**Strengths**

- <grounded, specific>

**Weaknesses**

- <runtime landmines, test gaps, WIP debris — each with path:line>

## Risk register

| Risk | Severity | Note |
|---|---|---|
| <risk> | High/Med/Low | <why> |

## Recommended next steps

<!-- Priority-ordered. The cheapest high-value fix first. -->

1. <action>

## Relationship to EPIC-NN / other work

<!-- How this connects to its parent EPIC and neighbours; cross-link with relative
     [text](EPIC-NN_Name.md) links. -->
