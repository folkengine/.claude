# Notes for the Scaffold skill — fullstack

The fullstack template is a **composition**, not a standalone bundle. It pulls assets from `rest-api-node` and `web-react` and adds one full-stack-specific addition.

## How to scaffold

When the user picks `fullstack`, ask:

1. *"Single repo (monorepo) or two repos?"*
2. If monorepo: *"What are the directory names for the API and the web client?"* (defaults: `apps/api`, `apps/web`)
3. If two repos: scaffold each side into the respective repo and stop — the integration row below applies in only one of them, the user chooses which.

## Asset selection

### Always include (in the API-side directory or repo)

- `rest-api-node/matrix.md` → merge with web matrix below
- `rest-api-node/github-workflows-ci.yml` → see workflow composition note
- `rest-api-node/eslint.config.js` → API directory's `eslint.config.js`
- `rest-api-node/pr-template.md` → if monorepo, see PR template note
- `rest-api-node/definition-of-done.md` → if monorepo, see DoD note

### Always include (in the web-side directory or repo)

- `web-react/matrix.md` → merge with API matrix above
- `web-react/github-workflows-ci.yml` → see workflow composition note
- `web-react/eslint.config.js` → web directory's `eslint.config.js`
- `web-react/playwright.config.ts` → web directory
- `web-react/pr-template.md` → if monorepo, see PR template note
- `web-react/definition-of-done.md` → if monorepo, see DoD note

## Merged matrix — one extra row

Drop this into the merged `docs/quality-commitments-matrix.md`:

| Quality Type | Phase | In Definition of Done? | Runs on CI? | Covers Regressions? | Documents Findings? | Boundary Coverage | Perspective |
|---|---|---|---|---|---|---|---|
| Full-stack E2E (UI → API → DB) | Merge / UAT | Yes | Yes | Yes | Yes (Playwright traces, DB snapshot of seed data) | Positive, Edge | Black box |

This row is the most commonly **missing** quality commitment on full-stack projects — prioritize getting it green in CI even before the unit suites are exhaustive. It catches integration drift that neither side's suite alone can.

## Workflow composition (monorepo)

For a monorepo, prefer **one** `.github/workflows/ci.yml` rather than two. Combine by:

- Putting the API jobs under one job with a working-directory step (`defaults: run: working-directory: apps/api`)
- Putting the web jobs under another job with `working-directory: apps/web`
- Adding a single `fullstack-e2e` job at the end that boots the API, points Playwright at it, and runs the integration E2E suite

## PR template composition

Use the API template as the base. Append the web template's accessibility, performance, and cross-browser sections under their own headings. Add a final section:

```
## Full-stack integration

- [ ] **Full-stack E2E** — at least one test exercises the UI → API → DB path for changed flows
```

## DoD composition

Merge the two DoDs section by section, removing duplicates. The merged DoD should have a top-level **Full-stack integration** section with the single bullet above.

## Customization checkpoints

In addition to the per-stack checkpoints in each bundle's `notes.md`:

1. **Database for full-stack E2E** — what database does the team use? Postgres service in workflow? Or test container?
2. **Seed data strategy** — fixtures, factories, or migrations replayed?
3. **API contract authority** — is OpenAPI the source of truth, or does the web client define its own types? Either is fine, but pick one.
4. **Auth in E2E** — bypass token, test user, or full OAuth flow? Document and stick with it.

## Things this template intentionally does *not* do

- Choose your monorepo tool — Nx, Turborepo, pnpm workspaces, plain workspaces all work
- Wire deployment of either side
- Decide where the matrix lives in a monorepo (recommend `docs/quality-commitments-matrix.md` at the repo root, with per-app sections)
