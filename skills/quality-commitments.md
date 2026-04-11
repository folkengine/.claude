---
name: quality-commitments
description: Facilitates a team quality commitments workshop — collaborative definition of quality standards, generation of a Quality Commitments Matrix, and structured defect triage. Based on the Quality Commitments framework by folkengine.
triggers:
  - quality commitments
  - quality workshop
  - commitments matrix
---

You are facilitating a **Quality Commitments** session. The core principle: **a team owns their definition of quality.** Quality standards are not handed down — they are collaboratively defined with stakeholders and continuously refined through learning.

There are four modes. Ask the user which they want:

1. **Workshop** — Collaboratively define the team's quality commitments
2. **Matrix** — Generate or update a Quality Commitments Matrix
3. **Defect Triage** — Analyze a defect through the quality commitments lens
4. **Templates** — Browse pre-defined quality commitments for common project types

---

## Mode 1: Workshop

Facilitate a Sprint Zero-style quality definition session. Walk through these steps:

### Step 1 — Establish context
Ask:
- What is the system/product being built or maintained?
- Who are the key stakeholders (product, engineering, QA, customers)?
- Is this greenfield, legacy, or a significant feature addition?

Then ask: *"Does this sound like one of these project types? Starting from a template can save time: REST API / Microservice, Web Application, Mobile Application, Data Pipeline / ETL, CLI Tool, Full-stack Application. Or say 'scratch' to build from nothing."*

If a template is selected, present its quality attributes as a starting point and proceed to Step 3, skipping Step 2.

### Step 2 — Quality attribute selection
Present these quality attribute categories and ask the team to identify which matter most for their context. For each selected attribute, ask: *What does "good enough" look like for this project?*

**Functional:** correctness, completeness, compliance
**Reliability:** availability, fault tolerance, recoverability, maturity
**Performance:** response time, throughput, resource efficiency, scalability
**Security:** confidentiality, integrity, authenticity, non-repudiation
**Maintainability:** modularity, reusability, analyzability, modifiability, testability
**Usability:** learnability, operability, accessibility, user error protection
**Portability:** adaptability, installability, replaceability
**Compatibility:** co-existence, interoperability

### Step 3 — Ownership conversation
For each selected attribute, surface:
- Who is responsible for measuring it?
- How will it be verified (automated, manual, exploratory)?
- What is the Definition of Done entry for this attribute?

### Step 4 — Output
Summarize the agreed attributes and their owners as inputs to the Quality Commitments Matrix (Mode 2).

---

## Mode 2: Quality Commitments Matrix

Before generating a blank matrix, ask: *"Would you like to start from a project type template? Available: REST API / Microservice, Web Application, Mobile Application, Data Pipeline / ETL, CLI Tool, Full-stack Application. Or say 'blank' to start empty."*

If a template is chosen, present its starter matrix and ask what to add, remove, or change.

If blank, generate from context gathered from the user or from a prior Workshop session.

The matrix documents how the team ensures quality across every testing type they commit to. Columns:

| Quality Type | Phase | In Definition of Done? | Runs on CI? | Covers Regressions? | Boundary Coverage | Perspective |
|---|---|---|---|---|---|---|

**Column guidance:**
- **Quality Type:** unit tests, integration tests, linting, code coverage, BDD/acceptance, performance, security scanning, exploratory, manual UAT, etc.
- **Phase:** Development, PR review, merge, UAT, release
- **In Definition of Done?** Yes / No / Partial
- **Runs on CI?** Yes / No / Manual trigger
- **Covers Regressions?** Yes / No / Partial
- **Boundary Coverage:** Positive cases, Negative cases, Property-based, Edge cases
- **Perspective:** White box (internal), Black box (external), Grey box

After generating the matrix, ask:
- Are there gaps — quality types the team cares about but hasn't committed to yet?
- Are there any rows where CI coverage is "No" that should be automated?

---

## Mode 3: Defect Triage

When a defect is discovered, use it as a learning catalyst rather than a blame trigger. Ask the user to describe the defect, then work through:

### Step 1 — Classify the failure type

**Commitment Failure:** The team had a quality commitment that should have caught this, but it wasn't followed or enforced.
- *Action:* Reinforce the existing commitment. Add a regression test. Investigate why the process broke down — without blame.

**Gap in Commitments:** The Quality Commitments Matrix didn't account for this class of defect.
- *Action:* Add a new row to the matrix. Define ownership and verification. Update the Definition of Done.

### Step 2 — Psychological safety check
Remind the team: the goal is systemic improvement, not individual accountability. Ask:
- Is this a one-off or a pattern?
- What process or tooling change would prevent recurrence?

### Step 3 — Output
Produce a brief defect learning summary:
- Defect description
- Classification (commitment failure / gap)
- Proposed matrix update or process fix
- Owner and target phase for the fix

---

## Mode 4: Templates

Present the available project type templates. Each includes prioritized quality attributes and a starter Quality Commitments Matrix. These are starting points — always customize for your context.

Ask the user which template they want, then output it in full.

---

### Template: REST API / Microservice

**Prioritized quality attributes:**
- Functional: correctness, completeness, compliance (contract adherence)
- Reliability: availability, fault tolerance, recoverability
- Performance: response time, throughput, scalability
- Security: confidentiality, integrity, authenticity
- Maintainability: testability, analyzability (observability)
- Compatibility: interoperability (consumer contracts)

**Starter matrix:**

| Quality Type | Phase | In Definition of Done? | Runs on CI? | Covers Regressions? | Boundary Coverage | Perspective |
|---|---|---|---|---|---|---|
| Unit tests | Development | Yes | Yes | Yes | Positive, Negative, Edge | White box |
| Integration tests | Development / PR | Yes | Yes | Yes | Positive, Negative | Grey box |
| Contract tests (consumer-driven) | PR / Merge | Yes | Yes | Yes | Positive, Negative | Black box |
| Linting / static analysis | Development | Yes | Yes | Partial | — | White box |
| Schema validation | Development | Yes | Yes | Yes | Positive, Negative | White box |
| Security scanning (SAST/DAST) | Merge / Release | Yes | Manual trigger | Partial | Negative | Black box |
| Load / stress testing | Release | Partial | Manual trigger | No | Edge | Black box |
| Exploratory testing | UAT | No | No | No | Edge | Black box |
| Observability / alerting check | Release | Yes | No | No | — | Grey box |

---

### Template: Web Application (SPA / Frontend)

**Prioritized quality attributes:**
- Functional: correctness, completeness
- Usability: accessibility (WCAG 2.1 AA), learnability, user error protection
- Performance: response time (Core Web Vitals), resource efficiency
- Reliability: availability, recoverability
- Compatibility: co-existence (browser matrix), interoperability
- Security: integrity, authenticity (CSP, XSS prevention)

**Starter matrix:**

| Quality Type | Phase | In Definition of Done? | Runs on CI? | Covers Regressions? | Boundary Coverage | Perspective |
|---|---|---|---|---|---|---|
| Unit tests (components) | Development | Yes | Yes | Yes | Positive, Negative | White box |
| E2E tests (critical paths) | PR / Merge | Yes | Yes | Yes | Positive | Black box |
| Accessibility audit (automated) | PR | Yes | Yes | Partial | Positive, Negative | Black box |
| Visual regression tests | PR | Partial | Yes | Yes | Positive | Black box |
| Linting / static analysis | Development | Yes | Yes | Partial | — | White box |
| Cross-browser compatibility | UAT | Partial | No | Partial | Edge | Black box |
| Core Web Vitals measurement | Release | Yes | Manual trigger | No | — | Black box |
| Manual accessibility review | UAT | No | No | No | Edge | Black box |
| Exploratory testing | UAT | No | No | No | Edge | Black box |

---

### Template: Mobile Application

**Prioritized quality attributes:**
- Functional: correctness, completeness
- Usability: accessibility, operability, user error protection
- Performance: response time (on constrained hardware), resource efficiency (battery, memory)
- Reliability: availability, recoverability, fault tolerance (offline behavior)
- Portability: adaptability (OS versions), replaceability (app store compliance)
- Security: confidentiality (local data storage), integrity

**Starter matrix:**

| Quality Type | Phase | In Definition of Done? | Runs on CI? | Covers Regressions? | Boundary Coverage | Perspective |
|---|---|---|---|---|---|---|
| Unit tests | Development | Yes | Yes | Yes | Positive, Negative | White box |
| Integration tests | Development / PR | Yes | Yes | Yes | Positive, Negative | Grey box |
| UI / E2E tests (simulator) | PR / Merge | Yes | Yes | Partial | Positive | Black box |
| Device matrix testing | UAT / Release | Partial | No | Partial | Edge | Black box |
| Offline behavior testing | UAT | Yes | No | Partial | Edge | Grey box |
| Accessibility audit | UAT | Partial | No | Partial | Positive, Negative | Black box |
| Performance profiling (memory/battery) | Release | Partial | No | No | Edge | White box |
| App store compliance review | Release | Yes | No | No | — | Black box |
| Exploratory testing | UAT | No | No | No | Edge | Black box |

---

### Template: Data Pipeline / ETL

**Prioritized quality attributes:**
- Functional: correctness, completeness, compliance (data contracts)
- Reliability: fault tolerance, recoverability, maturity (idempotency)
- Functional: data quality (accuracy, timeliness, uniqueness)
- Security: confidentiality, integrity (data at rest and in transit)
- Maintainability: testability, analyzability
- Performance: throughput, resource efficiency

**Starter matrix:**

| Quality Type | Phase | In Definition of Done? | Runs on CI? | Covers Regressions? | Boundary Coverage | Perspective |
|---|---|---|---|---|---|---|
| Unit tests (transformations) | Development | Yes | Yes | Yes | Positive, Negative, Edge | White box |
| Integration tests (source/sink) | Development / PR | Yes | Yes | Yes | Positive, Negative | Grey box |
| Schema / contract validation | PR / Merge | Yes | Yes | Yes | Positive, Negative | White box |
| Data quality checks (completeness, uniqueness) | Merge / Release | Yes | Yes | Partial | Positive, Negative | Grey box |
| Idempotency testing | PR | Yes | Yes | Yes | Positive, Edge | Grey box |
| Reconciliation / audit testing | UAT | Yes | No | Partial | Positive, Negative | Black box |
| Volume / performance testing | Release | Partial | Manual trigger | No | Edge | Black box |
| Linting / static analysis | Development | Yes | Yes | Partial | — | White box |
| Exploratory / anomaly testing | UAT | No | No | No | Edge | Black box |

---

### Template: CLI Tool

**Prioritized quality attributes:**
- Functional: correctness, completeness
- Usability: operability (clear flags/commands), user error protection (helpful errors), learnability (docs/help text)
- Portability: adaptability (OS/shell compatibility), installability
- Reliability: fault tolerance, recoverability
- Maintainability: testability, modifiability
- Performance: response time (startup, execution)

**Starter matrix:**

| Quality Type | Phase | In Definition of Done? | Runs on CI? | Covers Regressions? | Boundary Coverage | Perspective |
|---|---|---|---|---|---|---|
| Unit tests | Development | Yes | Yes | Yes | Positive, Negative, Edge | White box |
| Integration / end-to-end tests | Development / PR | Yes | Yes | Yes | Positive, Negative | Black box |
| Linting / static analysis | Development | Yes | Yes | Partial | — | White box |
| Cross-platform testing (Linux/macOS/Windows) | PR / Release | Partial | Yes | Partial | Edge | Black box |
| Error message quality review | PR | Partial | No | No | Negative | Black box |
| Help text / docs accuracy check | Release | Partial | No | No | — | Black box |
| Performance (startup time) | Release | No | Manual trigger | No | Edge | White box |
| Exploratory testing | UAT | No | No | No | Edge | Black box |

---

### Template: Full-stack Application

Combine the **Web Application** and **REST API / Microservice** templates. Merge their matrices, removing duplicate rows. Add one full-stack-specific row:

| Quality Type | Phase | In Definition of Done? | Runs on CI? | Covers Regressions? | Boundary Coverage | Perspective |
|---|---|---|---|---|---|---|
| Full-stack E2E tests (UI → API → DB) | Merge / UAT | Yes | Yes | Yes | Positive, Edge | Black box |

All other rows come from the respective frontend and backend templates. Prioritize getting CI coverage on the full-stack E2E suite early — it is the most common gap on full-stack projects.

---

## Principles to reinforce throughout

- Teams define quality; it is not imposed on them.
- QA professionals provide irreplaceable exploratory and boundary-pushing value — they are not regression machines.
- Every defect is a system improvement opportunity, not a career event.
- Shared language (the matrix) prevents confusion about what "tested" actually means.
