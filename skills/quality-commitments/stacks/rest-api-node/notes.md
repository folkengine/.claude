# Notes for the Scaffold skill — rest-api-node

Read this before copying assets into a target repo.

## Bundle contents

| File | Default destination | Purpose |
|---|---|---|
| `matrix.md` | `docs/quality-commitments-matrix.md` | The team's checked-in starter matrix |
| `github-workflows-ci.yml` | `.github/workflows/ci.yml` | CI: lint, typecheck, test, contract, openapi, vuln-scan, sast; optional load-test on workflow_dispatch |
| `eslint.config.js` | `eslint.config.js` (repo root) | Flat-config ESLint with TS type-checked rules |
| `pr-template.md` | `.github/pull_request_template.md` | PR checklist tied to the matrix |
| `definition-of-done.md` | `docs/definition-of-done.md` | DoD aligned with the starter matrix |
| `notes.md` | **not copied** — for the skill only | This file |

## Customization checkpoints

Before writing, ask the user (or infer and surface) the following:

1. **Node version** — default 20. Change in `github-workflows-ci.yml` if the project pins differently.
2. **Test runner** — defaults to Jest. If the project uses Vitest, the `npm test -- --coverage` line still works but the coverage path may differ.
3. **Contract tooling** — defaults to Pact (artifact path `pacts/`). If the team uses Schemathesis, Dredd, or postman-newman, swap the `contract-tests` job.
4. **OpenAPI lint tool** — defaults to `@redocly/cli`. Replace with `spectral` if the team prefers.
5. **Vuln scanner** — defaults to Trivy. Trivy needs no token for public repos; Snyk needs `SNYK_TOKEN`.
6. **SAST** — defaults to CodeQL (free for public, included for private GHA). Swap to Semgrep with `semgrep ci` if preferred.
7. **k6 smoke target** — the workflow assumes `load/smoke.js` exists. If not, flag this in the post-scaffold checklist.

## Required secrets

If the user wants the SAST and vuln-scan jobs to upload SARIF, the repo needs:

- For private repos: a GitHub Advanced Security license (CodeQL upload), OR the SARIF upload step removed
- No secrets needed for Trivy on public repos
- `SNYK_TOKEN` if Snyk is used instead

Surface these in the post-scaffold checklist.

## Things this template intentionally does *not* do

- It does not configure a deployment job — quality and shipping are separate concerns
- It does not include an exploratory testing automation job — exploratory testing is a human practice, the matrix and DoD reference it but CI does not gate on it
- It does not include performance regression gating — the load-test job runs on `workflow_dispatch` and uploads results; choosing thresholds is a team conversation
