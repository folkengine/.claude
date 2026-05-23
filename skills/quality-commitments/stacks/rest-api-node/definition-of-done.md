# Definition of Done — REST API / Microservice

A change is **done** when every applicable item below holds. Items the team agreed are not in scope for this service should be removed from this document, not silently skipped per-PR.

## Code

- [ ] Implementation complete and self-reviewed
- [ ] Lint and typecheck pass locally and in CI
- [ ] No new `TODO` / `FIXME` without a linked issue

## Tests

- [ ] Unit tests cover new behavior, including at least one negative case
- [ ] Integration tests updated if HTTP routing, persistence, or external calls changed
- [ ] Contract tests (Pact) updated if consumer-facing shapes changed
- [ ] All test suites green in CI

## API surface

- [ ] OpenAPI/AsyncAPI spec reflects the change
- [ ] Breaking changes called out in the PR description and coordinated with consumers

## Security & dependencies

- [ ] No new vulns of severity High or Critical in dependency scan
- [ ] SAST clean (or false-positives documented inline)
- [ ] No secrets, tokens, or PII in code or fixtures

## Observability

- [ ] New failure modes are logged at the appropriate level
- [ ] Metrics emitted for any new latency-relevant code path
- [ ] Runbook updated if alerts can fire on the new code

## Documentation

- [ ] README updated for any user-facing change
- [ ] `docs/quality-commitments-matrix.md` updated if a new quality type was introduced or retired

## Exploratory

- [ ] At least one exploratory pass for changes that affect user-visible behavior (PR template documents what was tried)

## Release readiness

- [ ] Feature flag or migration path in place for risky changes
- [ ] Rollback plan exists or is trivially `git revert`
