# Definition of Done — Web Application (React)

A change is **done** when every applicable item below holds. Remove items the team decided are out of scope rather than skipping them silently per PR.

## Code

- [ ] Implementation complete and self-reviewed
- [ ] Lint and typecheck pass
- [ ] Components have clear prop types and no `any` in public interfaces

## Tests

- [ ] Component-level unit tests cover new behavior including negative cases
- [ ] E2E test covers any new critical-path user journey
- [ ] Visual regression baselines updated only when the visual change is intentional

## Accessibility

- [ ] Automated axe audit clean for the affected pages/components
- [ ] Keyboard navigation works end-to-end on new interactive elements
- [ ] ARIA roles/labels present where semantic HTML alone is insufficient
- [ ] Color contrast meets WCAG 2.1 AA

## Performance

- [ ] No new render-blocking script on the critical path
- [ ] Bundle size delta reviewed; large additions justified or lazy-loaded
- [ ] Core Web Vitals on the affected route not regressed (Lighthouse on workflow_dispatch)

## Cross-browser

- [ ] Tested in Chromium, Firefox, and WebKit (Playwright matrix or manual)

## Security

- [ ] Any raw-HTML rendering path is sanitized (DOMPurify or equivalent); prefer safe APIs
- [ ] No secrets in client-side code or repo
- [ ] Content Security Policy reviewed for new third-party origins

## Documentation

- [ ] Storybook stories updated for new/changed components
- [ ] `docs/quality-commitments-matrix.md` updated if a new quality type was introduced

## Exploratory

- [ ] At least one exploratory pass for user-visible changes; notes in the PR
