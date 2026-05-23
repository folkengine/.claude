# Quality Commitments Matrix — REST API / Microservice (Node/TypeScript)

> Starter matrix. Customize the rows, owners, and DoD columns to match your team's actual commitments. Delete rows you won't honor — an aspirational row is worse than no row.

## Prioritized quality attributes

- **Functional:** correctness, completeness, compliance (contract adherence)
- **Reliability:** availability, fault tolerance, recoverability
- **Performance:** response time, throughput, scalability
- **Security:** confidentiality, integrity, authenticity
- **Maintainability:** testability, analyzability (observability)
- **Compatibility:** interoperability (consumer contracts)

## Matrix

| Quality Type | Phase | In Definition of Done? | Runs on CI? | Covers Regressions? | Documents Findings? | Boundary Coverage | Perspective |
|---|---|---|---|---|---|---|---|
| Jest unit tests | Development | Yes | Yes | Yes | Partial (CI logs only) | Positive, Negative, Edge | White box |
| Integration tests (HTTP layer) | Development / PR | Yes | Yes | Yes | Partial | Positive, Negative | Grey box |
| Consumer-driven contract tests (Pact) | PR / Merge | Yes | Yes | Yes | Yes (Pact broker) | Positive, Negative | Black box |
| ESLint + TypeScript `--noEmit` | Development | Yes | Yes | Partial | No | — | White box |
| OpenAPI schema validation | Development | Yes | Yes | Yes | Yes (spec file) | Positive, Negative | White box |
| Dependency vuln scan (Trivy/Snyk) | Merge / Release | Yes | Yes | Partial | Yes (SARIF upload) | Negative | Black box |
| SAST (Semgrep or CodeQL) | Merge | Yes | Yes | Partial | Yes (SARIF upload) | Negative | White box |
| Load / stress test (k6) | Release | Partial | Manual trigger | No | Yes (k6 summary artifact) | Edge | Black box |
| Observability check (logs/metrics/traces present) | Release | Yes | No | No | Yes (runbook) | — | Grey box |
| Exploratory testing pass | UAT | No | No | No | Yes (test charters / notes) | Edge | Black box |

## Notes

- The exploratory row has **No** for CI and Regressions but **Yes** for Documents Findings — the artifact is the tester's session notes / charters, which feed back into the matrix as new rows when a class of issue recurs.
- "Documents Findings? Partial (CI logs only)" means the output exists but is ephemeral — promote to **Yes** by uploading reports as workflow artifacts or to a coverage service.
