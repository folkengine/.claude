# Quality Commitments Matrix — Web Application (React + Vite)

> Starter matrix. Customize rows, owners, and DoD entries for your context. Delete rows you won't honor.

## Prioritized quality attributes

- **Functional:** correctness, completeness
- **Usability:** accessibility (WCAG 2.1 AA), learnability, user error protection
- **Performance:** response time (Core Web Vitals), resource efficiency
- **Reliability:** availability, recoverability
- **Compatibility:** co-existence (browser matrix), interoperability
- **Security:** integrity, authenticity (CSP, XSS prevention)

## Matrix

| Quality Type | Phase | In Definition of Done? | Runs on CI? | Covers Regressions? | Documents Findings? | Boundary Coverage | Perspective |
|---|---|---|---|---|---|---|---|
| Vitest unit/component tests | Development | Yes | Yes | Yes | Partial (CI logs) | Positive, Negative | White box |
| Playwright E2E (critical paths) | PR / Merge | Yes | Yes | Yes | Yes (traces, videos on failure) | Positive | Black box |
| axe accessibility audit (automated) | PR | Yes | Yes | Partial | Yes (axe report artifact) | Positive, Negative | Black box |
| Visual regression (Chromatic or Percy) | PR | Partial | Yes | Yes | Yes (diffs in service) | Positive | Black box |
| ESLint + TypeScript `--noEmit` | Development | Yes | Yes | Partial | No | — | White box |
| Lighthouse Core Web Vitals | Release | Yes | Manual trigger | No | Yes (HTML report artifact) | — | Black box |
| Cross-browser smoke (Playwright matrix) | UAT | Partial | Yes | Partial | Partial | Edge | Black box |
| Manual accessibility review | UAT | No | No | No | Yes (review notes) | Edge | Black box |
| Exploratory testing pass | UAT | No | No | No | Yes (charters / notes) | Edge | Black box |
