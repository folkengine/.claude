# Notes for the skill — add-on: AI-assisted work

This is an **add-on**, not a stack. It layers three rows onto whatever matrix the team already has, for projects where agents write code, docs, or PRs.

It exists because of one asymmetry: an agent can produce a change far faster than a person can review it. On such a project "who read this, and how much of it" stops being implicit and has to be a commitment.

**Offer it; never add it silently.** The team owns its definition of quality. A team that does not use agents, or does not want these rows, skips it. As with any starter content, delete the rows you won't honor.

## When to offer

- **Workshop / Matrix** — ask once: *"Do agents write code, docs, or PRs on this project?"* If yes, present the rows below alongside the stack template.
- **Scan** — if the repo shows agent use (see **Evidence for Scan**) and the matrix has no review row for it, list the add-on under **Missing** in the gap analysis.
- **Scaffold** — if the team took the rows, append the DoD and PR-template sections below to the stack's files. Nothing else is written: the tooling lives in each developer's Claude configuration, not in the repo.
- **Triage** — a defect that shipped in a change nobody read is a **commitment failure** against row 1 if the row exists, and a **gap** if it does not.

## Matrix rows

| Quality Type | Phase | In Definition of Done? | Runs on CI? | Covers Regressions? | Documents Findings? | Boundary Coverage | Perspective |
|---|---|---|---|---|---|---|---|
| Human review of outgoing changes, scaled to stakes | PR review | Yes | No (local gate: `/slop-guard`) | No | Yes (reading order in the PR) | — | White box |
| AI-assistance disclosure in the PR body | PR review | Partial (optional section) | No | — | Yes (PR body) | — | — |
| Guardrail on the second occurrence of a mistake | Merge | Partial | Yes (the guardrail itself) | Yes | Yes (comment at the guardrail, commit message) | Negative | White box |

## What each row commits the team to

1. **Human review, scaled to stakes.** The team decides two things. First, a size threshold above which the whole diff is read by a person before it is pushed (the `/slop-guard` default is 400 changed lines, lockfiles not counted). Second, the paths that are always read whatever the size, such as auth, migrations, money, and public API. Below the threshold, the author reads the parts that carry risk.

   `/slop-guard` enforces the size threshold on each developer's machine. It knows nothing about the always-read paths: that half is an agreement kept by people. Say so when presenting the row.

2. **Disclosure.** A PR may carry an `## AI assistance` section saying what an agent wrote and what the author checked. It is optional by design, hence "Partial". `/slop-guard` prompts when the section is missing and never blocks. The hook checks that the heading is present, not that anything useful is written under it.

3. **Guardrail on the second occurrence.** The first time a mistake appears it is fixed. The second time, the team adds the most deterministic check that catches the class: a type, a lint, a test, a CI check. `/twice` builds it and proves it fails on the mistake. "Partial" in the DoD because it applies only when a mistake recurs.

## Definition of Done section

Append to the stack's `definition-of-done.md`:

```
## AI-assisted work

- [ ] A person has read the parts of this change that carry risk; all of it, if it is over the team's size threshold
- [ ] The author can say what the change does and why without asking the model
- [ ] If this is the second time this mistake has appeared, it has a guardrail, not only a second fix
```

## PR template sections

Add one line to the stack's **Quality commitments checklist**:

```
- [ ] **Human review** — I have read the parts of this change that carry risk (all of it if over the size threshold)
```

And append this section after **Exploratory pass**:

```
## AI assistance

<!-- Optional. What did an agent write, and what did you check yourself? Two or three lines. Delete this section if it does not apply. -->
```

## Evidence for Scan

- **Agent use:** `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.cursor/`, `.github/copilot-instructions.md`, or `Co-Authored-By:` trailers naming an agent in `git log`.
- **Row 1:** the PR template has the human-review line and the DoD has the section. The `/slop-guard` flag is deliberately kept out of commits, so its absence from the repo is not evidence either way. Ask.
- **Row 2:** the PR template has the `AI assistance` section, and recent PR bodies use it.
- **Row 3:** lint or check configuration with a comment saying which recurring mistake it catches. Sparse evidence is normal here. Ask before marking it missing.

## Things this add-on intentionally does *not* do

- No CI job. The review gate runs before a push, on the developer's machine. A CI check on PR size is possible, but add it deliberately: a required check binds every contributor.
- It neither requires nor forbids using an agent.
- It does not measure output. Lines of code, PRs merged, and tokens spent are not quality types. The commitment is about what a person understood before the change shipped.
