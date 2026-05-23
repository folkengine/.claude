---
name: quality-commitments
description: Facilitates Quality Commitments work — collaborative definition of quality standards, generation of a Quality Commitments Matrix, evidence-based audit of an existing repo, scaffolding of stack-specific quality tooling into new repos, and blame-free defect triage. Use for project kickoff, definition-of-done conversations, QA workshops, quality audits, CI/lint/test scaffolding, and defect retrospectives. Based on the Quality Commitments framework by folkengine.
triggers:
  - quality commitments
  - quality workshop
  - commitments matrix
  - definition of done
  - quality audit
  - quality matrix scan
  - scaffold quality
  - QA workshop
  - defect retrospective
---

You are facilitating **Quality Commitments** work. The core principle: **a team owns their definition of quality.** Standards are not imposed — they are collaboratively defined with stakeholders, made operational through tooling and CI, and continuously refined through learning.

## Preconditions (read these before doing anything)

Every mode below assumes the team is operating under these non-negotiables. Surface them explicitly if a session feels off-track.

1. **Team ownership.** The team — not management, not a separate QA org — defines, maintains, and revises its quality commitments collaboratively with stakeholders.
2. **Blame-free posture.** Defects are systemic learning opportunities, not career events. If a session starts hunting for individuals to blame, pause and reset.
3. **QA as exploratory expert.** QA professionals are a critical line of defense providing exploratory, boundary-pushing, and expert testing value. They are not scripted-regression machines. Integrate them as part of the broader team, not siloed.
4. **Shared language.** The Quality Commitments Matrix exists to prevent confusion about what "tested" actually means. When in doubt, write it down in the matrix.

## When NOT to use this skill

- Single-file bugfixes, hotfixes, or one-off patches — invoke `systematic-debugging` instead
- Drive-by refactors with no kickoff or retrospective need
- Tasks where the user wants implementation help, not a quality conversation

Use this skill when the work is **kickoff, audit, scaffold, or retrospective** in nature.

## Modes

Ask the user which mode they want. Cross-links between modes are noted — chain them when it helps.

1. **Workshop** — collaboratively define what quality means for this project → typically followed by **Matrix**
2. **Matrix** — generate or update the Quality Commitments Matrix → typically follows Workshop or Scan
3. **Scan** — evidence-based audit of an existing repo → typically followed by Workshop (close gaps) or Scaffold (fill missing tooling)
4. **Scaffold** — apply a stack template to a target repo, writing real CI/lint/test/DoD files
5. **Triage** — classify a defect (commitment failure vs. gap) and produce a learning summary → may update the Matrix
6. **Templates** — browse stack starter content without committing to Scan or Scaffold

---

## Mode 1 — Workshop

Facilitate a Sprint-Zero quality definition session.

### Step 1 — Establish context
Ask:
- What system/product is being built or maintained?
- Who are the key stakeholders (product, engineering, QA, customers, ops)?
- Is this greenfield, legacy, or a significant feature addition?
- Which stack template fits? *(REST API / Microservice — Node, Web App — React, Data Pipeline — Python, CLI — Rust, Mobile — React Native, Full-stack, or "scratch" to build from nothing)*

If a template is chosen, present its prioritized attributes from **Mode 6 Templates** as a starting point, then jump to Step 3.

### Step 2 — Quality attribute selection (skip if a template was chosen)
Walk through these categories. For each one the team selects, ask: *What does "good enough" look like for this project?*

- **Functional:** correctness, completeness, compliance
- **Reliability:** availability, fault tolerance, recoverability, maturity
- **Performance:** response time, throughput, resource efficiency, scalability
- **Security:** confidentiality, integrity, authenticity, non-repudiation
- **Maintainability:** modularity, reusability, analyzability, modifiability, testability
- **Usability:** learnability, operability, accessibility, user error protection
- **Portability:** adaptability, installability, replaceability
- **Compatibility:** co-existence, interoperability

### Step 3 — Ownership conversation
For each selected attribute, surface:
- Who is responsible for measuring it?
- How will it be verified (automated, manual, exploratory)? Name the QA contribution explicitly — exploratory testing is a distinct, valuable column, not a fallback for "we didn't automate it."
- What is the Definition of Done entry for this attribute?

### Step 4 — Output
Produce a markdown summary: agreed attributes, owners, DoD entries. Offer to continue into **Mode 2 (Matrix)** to formalize these as commitments.

---

## Mode 2 — Quality Commitments Matrix

Before generating, ask: *"Start from a stack template, or blank?"* If a template is chosen, read its `matrix.md` from `skills/quality-commitments/stacks/<stack>/matrix.md` (relative to this skill's directory) and present it.

The matrix documents how the team ensures quality across every testing type they commit to. Columns:

| Quality Type | Phase | In Definition of Done? | Runs on CI? | Covers Regressions? | Documents Findings? | Boundary Coverage | Perspective |
|---|---|---|---|---|---|---|---|

**Column guidance:**

- **Quality Type:** unit tests, integration tests, contract tests, linting, code coverage, BDD/acceptance, performance, security scanning, accessibility, exploratory, manual UAT, observability/alerting, etc.
- **Phase:** Development, PR review, Merge, UAT, Release
- **In Definition of Done?** Yes / No / Partial
- **Runs on CI?** Yes / No / Manual trigger
- **Covers Regressions?** Yes / No / Partial
- **Documents Findings?** Yes / No / Partial — does this practice produce a written artifact (test report, audit log, scan output, retro note) that the team revisits?
- **Boundary Coverage:** Positive cases, Negative cases, Property-based, Edge cases
- **Perspective:** White box (internal), Black box (external), Grey box

After generating the matrix, ask:
- Are there gaps — quality types the team cares about but hasn't committed to yet?
- Any rows where **Runs on CI?** is "No" that should be automated?
- Any rows where **Documents Findings?** is "No" — quietly running tools whose output nobody reads?

Offer to continue into **Mode 4 (Scaffold)** to write the tooling, or **Mode 3 (Scan)** to compare against what is actually in the repo today.

---

## Mode 3 — Scan (evidence-based repo audit)

Inspect an existing repository and produce a Quality Commitments Matrix reflecting **what is actually present**, not what the team wishes were present. Gaps are called out explicitly.

### Step 1 — Identify project type
Ask: *"Which stack does this repo most resemble? (REST API/Microservice, Web App, Data Pipeline, CLI, Mobile, Full-stack, or Other)"* — used as the gap baseline. Infer from findings if unsure.

### Step 2 — Discover

Work through every category. Record evidence (file paths) for what you find.

**2a. Project structure & language** — read `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`, `build.gradle`, `*.csproj`, `Gemfile`. Identify primary language(s), framework(s), and test directory naming convention.

**2b. Unit & integration tests** — `jest.config.*`, `pytest.ini`, `vitest.config.*`, `mocha.*`, `phpunit.xml`, `rspec` in Gemfile, `xunit.*`. Sample test files to infer unit vs. integration style. Coverage config: `.nycrc`, `codecov.yml`, `jacoco`, `coverageThreshold`.

**2c. Linting & static analysis** — `.eslintrc*`, `eslint.config.*`, `.rubocop.yml`, `pylintrc`, `.flake8`, `mypy.ini`, `pyproject.toml [tool.ruff]`, `.golangci.yml`, `clippy.toml`, `sonar-project.properties`, `biome.json`, `.stylelintrc*`.

**2d. CI/CD** — `.github/workflows/*.yml`, `.circleci/config.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, `Makefile` test/lint targets, `.travis.yml`, `azure-pipelines.yml`, `buildkite.yml`. For each, record jobs, triggers, and which checks they include.

**2e. Security scanning** — workflow files referencing `trivy`, `snyk`, `semgrep`, `codeql`, `dependabot`, `gitleaks`, `checkov`, `bandit`, `brakeman`, `gosec`. Also `.snyk`, `semgrep.yml`, `.gitleaks.toml`, `dependabot.yml`.

**2f. Contract & API testing** — `pact/`, `*.pact.json`, OpenAPI/Swagger specs, Postman collections, REST-assured/Karate/Dredd references.

**2g. E2E & acceptance** — `cypress/`, `playwright/`, `e2e/`, `features/`, BDD frameworks (`behave`, rspec feature specs, SpecFlow), `.feature` files.

**2h. Performance & load** — `k6/`, `locust/`, `gatling/`, `jmeter/`, `lighthouserc.*`, `artillery.yml`, `wrk` scripts in CI.

**2i. Accessibility** — `axe-core`, `@axe-core/playwright`, `jest-axe`, `pa11y` dependencies; search test files for `axe`, `a11y`, `wcag`; Lighthouse a11y audits in CI.

**2j. Visual regression** — `percy/`, `chromatic`, `backstop.json`, `reg-cli`, Storybook test-runner.

**2k. Type checking** — `tsconfig.json` strict, `mypy`/`pyright`, `tsc --noEmit` in CI, type coverage thresholds.

### Step 3 — Build the matrix from evidence

| Column | How to determine |
|---|---|
| **Quality Type** | Name the specific tool/practice (e.g., "Jest unit tests", "Cypress E2E") |
| **Phase** | Infer from CI trigger: PR jobs → "PR review"; merge → "Merge"; scheduled → "Release"; no CI → "Development (manual)" |
| **In Definition of Done?** | Check `CONTRIBUTING.md`, `docs/definition-of-done.md`, PR templates. If absent, mark "Unknown" |
| **Runs on CI?** | Yes if in a CI workflow; No if only local; "Manual trigger" if under `workflow_dispatch` |
| **Covers Regressions?** | Yes if test files exist alongside source and look maintained; Partial if sparse; infer from coverage thresholds |
| **Documents Findings?** | Yes if the tool emits an artifact the repo retains (uploaded coverage report, retained test logs, audit YAML); No if output is ephemeral CI logs only |
| **Boundary Coverage** | Sample tests for negative patterns (`throws`, `rejects`, names containing "invalid", "error", "edge") |
| **Perspective** | Unit → White; E2E/contract/Postman → Black; Integration → Grey |

Output as a markdown table. Never infer a practice from a dependency alone — a `jest` entry in `devDependencies` is weaker evidence than actual `*.test.js` files.

### Step 4 — Gap analysis

Compare findings to the stack template's `matrix.md`. Format:

```
### Gaps vs. <stack> template

**Missing:**
- <practice> — not found

**Partial:**
- <practice> — <reason, e.g., "ESLint config exists but not in CI">

**Present:**
- <practice> ✓
```

### Step 5 — Output & next steps

Deliver:
1. The completed Matrix (evidence-based)
2. The gap analysis
3. A prioritized recommendations list (3–5 items, ordered by impact). **Call out exploratory-testing gaps explicitly** — they hide easily because they have no config file to find.

Then offer:
- **Mode 4 (Scaffold)** to fill missing tooling from the stack template
- **Mode 1 (Workshop)** to turn the gaps into team commitments

### Notes on uncertainty
- Config present but no tests found → "Runs on CI? Yes" with a note "*config present, no test files found*"
- No CI files at all → all "Runs on CI?" cells are "No"; flag this prominently at the top of the matrix

---

## Mode 4 — Scaffold

Apply a stack template to a target repository by writing concrete artifacts. This is the operational counterpart to Mode 2: it produces files, not just a matrix.

### Step 1 — Inputs

Ask:
- *"Which stack? (rest-api-node, web-react, data-pipeline-python, cli-rust, mobile-rn, fullstack)"*
- *"What is the absolute path of the target repo?"*
- *"Should I overwrite existing files, skip them, or stop on conflict?"* (default: stop on conflict, report each one)

### Step 2 — Read the stack assets

The stack templates live alongside this skill at `skills/quality-commitments/stacks/<stack>/`. For the chosen stack, list its files and read `notes.md` first — it tells you what each artifact is for and what to customize.

### Step 3 — Plan the writes

Present the user with a write plan before touching the target repo:
- List each source asset and its destination path inside the target repo
- For each existing file at the destination, flag the conflict and ask
- For artifacts requiring substitution (project name, owner, language version), surface the variables and ask for values

### Step 4 — Write artifacts

Copy each file. Standard mappings per stack:

| Asset | Default destination in target repo |
|---|---|
| `github-workflows-ci.yml` | `.github/workflows/ci.yml` |
| `eslint.config.js` / `clippy.toml` / `pyproject-snippet.toml` | repo root |
| `playwright.config.ts` | repo root |
| `pr-template.md` | `.github/pull_request_template.md` |
| `definition-of-done.md` | `docs/definition-of-done.md` |
| `matrix.md` | `docs/quality-commitments-matrix.md` |

`matrix.md` is always copied so the team has a checked-in record of their committed standards. `notes.md` is **not** copied — it's guidance for this skill, not for the team.

### Step 5 — Post-scaffold checklist

Produce a checklist of human follow-ups the skill cannot do alone:

- [ ] Edit `docs/quality-commitments-matrix.md` to reflect the team's actual commitments (not just the template defaults)
- [ ] Wire any required secrets into GitHub Actions (security scanners, deploy tokens)
- [ ] Run the new CI workflow once and resolve any environment-specific failures
- [ ] Schedule the kickoff: invoke **Mode 1 (Workshop)** so the team commits to the matrix you just dropped in
- [ ] Identify the QA contributor(s) who will own the exploratory column — this rarely lives in CI

Offer to chain into **Mode 1** for the workshop.

---

## Mode 5 — Defect Triage

When a defect is discovered, use it as a learning catalyst. Ask the user to describe the defect, then work through:

### Step 1 — Classify

**Commitment Failure:** the team had a commitment that should have caught this, but it wasn't followed or enforced.
- *Action:* Reinforce the existing commitment. Add a regression test. Investigate the process gap **without blame**.

**Gap in Commitments:** the matrix didn't account for this class of defect.
- *Action:* Add a row to the matrix. Define ownership and verification. Update Definition of Done. Optionally chain into **Mode 4 (Scaffold)** if the gap implies missing tooling.

### Step 2 — Pattern check
- Is this a one-off or a pattern?
- What process or tooling change would prevent recurrence?
- Was an exploratory testing pass earlier in the cycle likely to have caught it? (If yes, the gap may be about *time* given to exploratory testing, not about the test types in the matrix.)

### Step 3 — Output

A short defect learning summary:
- Defect description
- Classification (commitment failure / gap)
- Proposed matrix update or process fix
- Owner and target phase for the fix

---

## Mode 6 — Templates

Browse a stack's starter content without committing to Scan or Scaffold. Read and present:

- `skills/quality-commitments/stacks/<stack>/matrix.md` — the starter Quality Commitments Matrix
- `skills/quality-commitments/stacks/<stack>/notes.md` — what's in the bundle, what to customize

Use this mode to compare stacks before choosing, or to crib individual rows into an existing matrix.

Available stacks: **rest-api-node**, **web-react**, **data-pipeline-python**, **cli-rust**, **mobile-rn**, **fullstack**.

Stacks are starting points — always customize for your context. If your project doesn't match a stack, build from the closest one or run **Mode 1 (Workshop)** from scratch.
