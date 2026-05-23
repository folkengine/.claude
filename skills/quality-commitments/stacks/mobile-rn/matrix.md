# Quality Commitments Matrix — Mobile Application (React Native)

> Starter matrix. Customize rows, owners, and DoD entries. Delete rows you won't honor.

## Prioritized quality attributes

- **Functional:** correctness, completeness
- **Usability:** accessibility, operability, user error protection
- **Performance:** response time (constrained hardware), resource efficiency (battery, memory)
- **Reliability:** availability, recoverability, fault tolerance (offline behavior)
- **Portability:** adaptability (OS versions), replaceability (app store compliance)
- **Security:** confidentiality (local data), integrity

## Matrix

| Quality Type | Phase | In Definition of Done? | Runs on CI? | Covers Regressions? | Documents Findings? | Boundary Coverage | Perspective |
|---|---|---|---|---|---|---|---|
| Jest unit / component tests | Development | Yes | Yes | Yes | Partial | Positive, Negative | White box |
| Integration tests (React Testing Library) | Development / PR | Yes | Yes | Yes | Partial | Positive, Negative | Grey box |
| Detox E2E (iOS sim + Android emulator) | PR / Merge | Yes | Yes | Partial | Yes (screenshots/videos on failure) | Positive | Black box |
| ESLint + TypeScript `--noEmit` | Development | Yes | Yes | Partial | No | — | White box |
| Accessibility audit (React Native a11y testing) | PR | Partial | Yes | Partial | Yes (report artifact) | Positive, Negative | Black box |
| Bundle size analysis | PR | Partial | Yes | Yes | Yes (size diff comment) | — | White box |
| Device matrix smoke (multiple OS versions) | UAT / Release | Partial | Manual trigger | Partial | Yes (matrix report) | Edge | Black box |
| Offline behavior testing | UAT | Yes | No | Partial | Yes (test scenarios) | Edge | Grey box |
| Performance profiling (memory/battery) | Release | Partial | No | No | Yes (profiler exports) | Edge | White box |
| App store compliance review | Release | Yes | No | No | Yes (store submission notes) | — | Black box |
| Exploratory testing on real devices | UAT | No | No | No | Yes (session notes) | Edge | Black box |
