# Definition of Done — Data Pipeline / ETL (Python)

A change is **done** when every applicable item below holds.

## Code

- [ ] Implementation complete and self-reviewed
- [ ] Ruff, ruff-format, and mypy pass
- [ ] No `print()` debugging left in pipeline code; use the logger

## Tests

- [ ] Unit tests cover transformations with positive, negative, and edge cases
- [ ] Integration tests cover the source-sink boundaries that changed
- [ ] Data quality expectations updated for any new field or invariant
- [ ] Idempotency test still passes — same input twice produces same output
- [ ] Coverage threshold (fail_under) holds

## Data contracts

- [ ] Input and output schemas declared (pydantic / jsonschema / Avro)
- [ ] Breaking schema changes coordinated with upstream/downstream owners
- [ ] Backwards compatibility documented or migration path provided

## Reliability

- [ ] Retries and timeouts configured for external calls
- [ ] Partial-failure behavior is explicit (skip, dead-letter, halt)
- [ ] Pipeline can resume from checkpoint or is fully idempotent

## Security

- [ ] No credentials in code; secrets via environment or secret manager
- [ ] PII handling reviewed for any new field touched
- [ ] Data at rest and in transit encryption preserved

## Observability

- [ ] Structured logs at decision points and error paths
- [ ] Row counts / duration / failure rate emitted as metrics
- [ ] Alerts updated if SLOs changed

## Documentation

- [ ] Runbook updated for new failure modes
- [ ] `docs/quality-commitments-matrix.md` updated if a new quality type was introduced

## Exploratory

- [ ] At least one exploratory pass against a realistic sample (malformed rows, late data, duplicates)
