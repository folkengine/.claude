# Notes for the Scaffold skill — data-pipeline-python

## Bundle contents

| File | Default destination | Purpose |
|---|---|---|
| `matrix.md` | `docs/quality-commitments-matrix.md` | Starter matrix |
| `github-workflows-ci.yml` | `.github/workflows/ci.yml` | CI: lint+types, unit, integration (Postgres service), data-quality, idempotency, vuln-scan; optional perf |
| `pyproject-snippet.toml` | merge into existing `pyproject.toml` | Ruff, mypy, pytest, coverage config |
| `pr-template.md` | `.github/pull_request_template.md` | PR checklist |
| `definition-of-done.md` | `docs/definition-of-done.md` | DoD |

## Customization checkpoints

1. **Python version** — defaults to 3.12 in workflow and pyproject. Adjust to match the project.
2. **`pyproject-snippet.toml`** — this is a **merge** target, not a write. Open the existing `pyproject.toml` and merge sections without clobbering project-specific config. If no pyproject exists, write it whole.
3. **Database service** — workflow uses Postgres 16 for integration. Swap for the project's actual datastore (MySQL, ClickHouse, DuckDB local, etc.) or remove the service block if integration tests use in-memory doubles only.
4. **Data quality tool** — workflow runs `pytest tests/data_quality`. If the team uses Great Expectations or Soda Core directly, replace with the respective CLI invocation.
5. **Coverage threshold** — `fail_under = 80` is opinionated. Confirm with the team.
6. **Pipeline orchestration** — this template does NOT include Airflow/Dagster/Prefect config. That belongs in the project, not the quality scaffold.

## Required secrets

- None for the default workflow
- Add scanner tokens (`SNYK_TOKEN`, etc.) if swapping `pip-audit`

## Things this template intentionally does *not* do

- No DAG/orchestration definitions
- No data source connection config — that lives in the project's settings module
- No data lineage tooling (DataHub, OpenLineage) — flag in post-scaffold checklist if relevant
