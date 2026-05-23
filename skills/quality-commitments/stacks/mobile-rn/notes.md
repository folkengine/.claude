# Notes for the Scaffold skill — mobile-rn

## Bundle contents

| File | Default destination | Purpose |
|---|---|---|
| `matrix.md` | `docs/quality-commitments-matrix.md` | Starter matrix |
| `github-workflows-ci.yml` | `.github/workflows/ci.yml` | CI: lint, typecheck, unit, bundle-size, a11y; Detox iOS on PR; Detox Android on workflow_dispatch |
| `pr-template.md` | `.github/pull_request_template.md` | PR checklist |
| `definition-of-done.md` | `docs/definition-of-done.md` | DoD |

No ESLint config is shipped — React Native projects usually inherit from `@react-native/eslint-config` via the template. If the target repo lacks one, surface that in the post-scaffold checklist.

## Customization checkpoints

1. **Detox scripts** — workflow assumes `detox:build:ios`, `detox:test:ios`, `detox:test:android` exist in package.json. Add these or adjust the workflow.
2. **macOS runner cost** — `macos-14` for Detox iOS is expensive (~10× Linux minutes). For private repos with budget constraints, consider gating Detox iOS on `workflow_dispatch` too.
3. **Xcode version** — pinning to `latest-stable` reduces breakage but can shift unexpectedly. Pin a specific version for reproducibility once the project settles.
4. **Bundle-size baseline** — the workflow uploads bundles but doesn't compare to main. Add `actions/cache` and a comparison step for a real size-diff comment.
5. **a11y test runner** — workflow assumes `npm run test:a11y` exists. RN doesn't have a single canonical a11y test tool; common options are `@testing-library/react-native` queries plus accessibility role assertions.
6. **Expo vs. bare workflow** — these scripts assume bare React Native. Expo managed workflow uses `expo prebuild` + EAS Build for E2E; replace Detox jobs with EAS Build / Maestro if so.

## Required secrets

- None for the default workflow
- If integrating EAS Build: `EXPO_TOKEN`
- If publishing to App Store Connect / Play Store: store-specific service-account credentials

## Things this template intentionally does *not* do

- No App Store / Play Store deploy job
- No code-push / OTA-update wiring
- No native build job — RN's native modules are tested via Detox, not separately compiled in CI for every PR
- No real-device cloud testing (BrowserStack, Sauce Labs, AWS Device Farm) — flag as a paid-tier consideration in post-scaffold checklist
