# Quality Commitments Matrix — Data Pipeline / ETL (Python)

> Starter matrix. Customize rows, owners, and DoD entries. Delete rows you won't honor.

## Prioritized quality attributes

- **Functional:** correctness, completeness, compliance (data contracts)
- **Data quality:** accuracy, timeliness, uniqueness, completeness of records
- **Reliability:** fault tolerance, recoverability, maturity (idempotency)
- **Security:** confidentiality, integrity (data at rest and in transit)
- **Maintainability:** testability, analyzability
- **Performance:** throughput, resource efficiency

## Matrix

| Quality Type | Phase | In Definition of Done? | Runs on CI? | Covers Regressions? | Documents Findings? | Boundary Coverage | Perspective |
|---|---|---|---|---|---|---|---|
| pytest unit tests (transformations) | Development | Yes | Yes | Yes | Partial | Positive, Negative, Edge | White box |
| Integration tests (source/sink with test doubles) | Development / PR | Yes | Yes | Yes | Partial | Positive, Negative | Grey box |
| Schema / contract validation (pydantic, jsonschema) | PR / Merge | Yes | Yes | Yes | Yes (schema files) | Positive, Negative | White box |
| Data quality checks (Great Expectations / Soda) | Merge / Release | Yes | Yes | Partial | Yes (DQ reports) | Positive, Negative | Grey box |
| Idempotency test (rerun the pipeline twice on same input) | PR | Yes | Yes | Yes | Partial | Positive, Edge | Grey box |
| Reconciliation / audit (row counts, checksums) | UAT / Release | Yes | No | Partial | Yes (audit log) | Positive, Negative | Black box |
| Ruff + mypy | Development | Yes | Yes | Partial | No | — | White box |
| Volume / performance test | Release | Partial | Manual trigger | No | Yes (benchmark artifact) | Edge | Black box |
| Dependency vuln scan (pip-audit) | Merge | Yes | Yes | Partial | Yes (SARIF) | Negative | Black box |
| Exploratory / anomaly testing on real samples | UAT | No | No | No | Yes (anomaly notes) | Edge | Black box |
