## What

<!-- One or two sentences. What does this PR do and why? -->

## Quality commitments checklist

Tick the rows of `docs/quality-commitments-matrix.md` this change touches. Explain unchecked items in **Why not** below.

- [ ] **Unit tests (transformations)** — added or updated, negative cases included
- [ ] **Integration tests** — covered if source/sink contracts changed
- [ ] **Schema / contract validation** — updated for input/output shape changes
- [ ] **Data quality checks** — expectations updated for new fields or invariants
- [ ] **Idempotency** — running this pipeline twice on the same input yields the same output
- [ ] **Ruff + mypy** — clean
- [ ] **Vuln scan** — no new high-severity findings
- [ ] **Reconciliation** — row counts / checksums match expected for the test fixture
- [ ] **Definition of Done** — see `docs/definition-of-done.md`

### Why not

<!-- Be specific about omissions. -->

## Sample data tested

<!-- Which fixtures or real samples did you run this against? Any anomalies? -->

## Exploratory pass

<!-- Did you try malformed input, partial failures, late-arriving data, schema drift? -->

## How to verify

<!-- Steps a reviewer can run locally or in staging. -->
