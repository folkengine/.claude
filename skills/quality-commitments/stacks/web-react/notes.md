# Notes for the Scaffold skill — web-react

## Bundle contents

| File | Default destination | Purpose |
|---|---|---|
| `matrix.md` | `docs/quality-commitments-matrix.md` | Team's starter matrix |
| `github-workflows-ci.yml` | `.github/workflows/ci.yml` | CI: lint, typecheck, unit, e2e (3 browsers), a11y; optional Lighthouse on workflow_dispatch |
| `eslint.config.js` | `eslint.config.js` | Flat-config ESLint with React + jsx-a11y |
| `playwright.config.ts` | `playwright.config.ts` | Playwright with chromium/firefox/webkit projects, traces on retry |
| `pr-template.md` | `.github/pull_request_template.md` | PR checklist |
| `definition-of-done.md` | `docs/definition-of-done.md` | DoD |

## Customization checkpoints

1. **Dev server URL** — `playwright.config.ts` defaults to `http://localhost:5173` (Vite). Change for Next.js (`3000`), CRA (`3000`), etc.
2. **Vitest vs. Jest** — workflow assumes `npm run test` invokes Vitest with `--coverage`. Adjust if Jest.
3. **a11y test runner** — workflow assumes `npm run test:a11y` exists (`@axe-core/playwright`). If using `jest-axe`, fold into the unit job and remove the standalone job.
4. **Visual regression** — not wired in CI by default. If using Chromatic, add the publish step with `CHROMATIC_PROJECT_TOKEN`.
5. **Lighthouse budgets** — `lighthouserc.json` is not provided; on first scaffold, surface a note that a `lighthouserc.json` with budgets must be added before the `lighthouse` job is meaningful.
6. **Storybook** — referenced in DoD but no Storybook config is shipped. Note this in post-scaffold checklist if the project doesn't already have one.

## Required secrets

- `CHROMATIC_PROJECT_TOKEN` if Chromatic is added
- No secrets needed for the default workflow

## Things this template intentionally does *not* do

- No production deployment job
- No CDN purge or cache invalidation
- No Sentry/Datadog wiring — observability for a SPA needs runtime config the matrix should reference but the scaffold doesn't blindly add
