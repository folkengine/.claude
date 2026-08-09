# Python — stack file

Read together with `references/baseline.md`. This file is instructions for
you, the executing agent — carry out each section as a step, don't just
summarize it. Apply after the stack's native init has already run, following
baseline's layer order: baseline files → AI files → stack configs (this
file's Config files / Quality gate / CI sections) → `.okf/` seeding.

## Init

1. Interview the user: **library or application?** — a repo may start as
   one and grow the other, but `uv init` needs to know which shape to lay
   down now.
   - Library: `uv init --lib --vcs none` — creates a `src/<package>/`
     layout with a build backend wired up in `pyproject.toml`, so
     `uv build` produces a real sdist + wheel. Which backend depends on
     the uv version and is not ours to choose: current uv writes its own
     in-process `uv_build`; older uv wrote hatchling. Keep whatever the
     native init produced — the playbook's layering rule is that the
     opinionated layer must not fight the stack's own init. Note the
     consequence when uv_build is used: `[build-system].requires` pins
     `uv_build>=<uv-minor>,<<next-uv-minor>`, coupling the build to uv's
     minor series, so that pin must be revisited whenever `.tool-versions`
     bumps uv's minor (see `## Update`).
   - Application: `uv init --app --vcs none` — creates a flat layout (`main.py` at the
     repo root, no build backend). If the app must itself be installable
     or distributed as a package (a CLI tool, a service published to an
     index, anything meant to be `pip install`-ed), ask a follow-up and use
     `uv init --app --package --vcs none` instead, which adds a `src/` layout and
     build-system table so `uv build` produces a real, worth-shipping
     sdist + wheel. If the app is a pure deployment artifact (e.g.
     containerized, never packaged), plain `uv init --app` is correct —
     but note that `uv build` will still *run* on a flat, backend-less
     project: PEP 517's setuptools legacy fallback kicks in and produces an
     actual wheel, it's just a low-value one (no declared build backend,
     packaging whatever happens to sit at the repo root). Don't rely on
     "there's nothing to build" here — see `## Quality gate` for how the
     `build` phase handles this case explicitly instead of silently
     accepting the legacy-fallback artifact.
   - This choice also decides the paths used in `## Quality gate`'s `lint`
     recipe below (`src/` vs flat) — keep the Makefile in sync with
     whichever layout `uv init` produced.
   - `--vcs none` is required on every variant: without it, `uv init`
     silently runs `git init` (and writes its own `.gitignore`) when not
     already inside a repo — the same implicit-VCS side effect
     `cargo init --vcs none` suppresses for Rust. Git state stays in the
     user's hands (this skill only *prints* the git block at the end),
     and baseline owns `.gitignore` generation.
2. Resolve the **Python version** at scaffold time — never hardcode one
   from memory. Ask the user for a floor (e.g. "must run on the LTS distro
   Python", "needs 3.12+ for X") otherwise use current stable. Pin it:

   ```
   uv python pin <resolved-version>
   ```

   This writes `.python-version` — uv's own resolution file, which uv reads
   *before* `.tool-versions` or anything else. **It is a member of this
   stack's version-consistency set**, the one Python adds beyond baseline's
   four, bringing this stack's total to five. Because uv consults it first,
   a `.python-version` that disagrees with the rest doesn't merely sit
   there being wrong — it silently wins, and every `uv run` in the repo
   uses an interpreter neither CI nor the devcontainer does.
3. Write the floor into `pyproject.toml`:

   ```toml
   requires-python = ">=<resolved-minor>"
   ```

   `.python-version`, `.tool-versions`' `python` line, the CI matrix, the
   devcontainer image tag, and this `requires-python` value must all agree
   — the version-consistency rule from baseline applies here from the
   first commit onward.
4. **Make what `uv init` generated actually pass the gate — it does not
   out of the box.** This is not optional polish: skip either part below
   and the scaffold's first `make ayce` is red on code the playbook
   itself produced.

   **(a) Add docstrings to the generated hello-world.** `uv init --lib`
   writes exactly this, with no module docstring and no function
   docstring:

   ```python
   def hello() -> str:
       return "Hello from <package>!"
   ```

   Under `select = ["ALL"]` that is two immediate lint errors — `D104`
   (missing docstring in public package) and `D103` (missing docstring
   in public function). Rewrite it to satisfy the documentation bar the
   `## CLAUDE.md addenda` section imposes: a module docstring saying what
   the package is for, and a function docstring with a summary line, a
   `Returns:` section, and a usage example, in whichever convention
   `[tool.ruff.lint.pydocstyle]` declares.

   **(b) Create `tests/` yourself — `uv init` does not.** Every variant
   (`--lib`, `--app`, `--app --package`) writes only `src/<pkg>/` (or a
   flat `main.py`), `pyproject.toml`, `README.md`, and `.python-version`.
   There is no `tests/` directory. This matters because the `lint` phase
   and the CI `lint` job both run `uv run mypy src tests`, which fails
   outright on a missing path. Write:

   - `tests/test_<package>.py` — at least one real test against the
     hello-world, so `test` and `lint` both exercise actual code from the
     first commit. Test modules need docstrings too, for the same `D`
     rules.
   - **No `tests/__init__.py`.** With the `src/` layout, tests import the
     package from the installed distribution rather than from the source
     tree, which is exactly what makes this layout catch packaging
     mistakes (a module missing from the wheel fails the test run instead
     of passing on an accidental source-tree import). Adding an
     `__init__.py` would silence ruff's `INP001` but forfeit that
     property; the `## Config files` section ignores the rule under
     `tests/` instead.
5. Declare the license in `pyproject.toml`. Baseline copies the
   `LICENSE-*` files to the repo root, but nothing wires them into the
   package metadata, so `uv build` would otherwise produce a
   distribution with no license declared. Add, matching whatever the user
   chose:

   ```toml
   license = "MIT"
   license-files = ["LICENSE-MIT"]
   ```

   For a multi-license scaffold use an SPDX expression and list every
   file (e.g. `license = "MIT OR Apache-2.0"` with
   `license-files = ["LICENSE-MIT", "LICENSE-APACHE"]`).
6. No license-driven *config* file is needed at Init for Python the way
   `deny.toml`'s allow-list is for Rust — this stack's security scanner
   (pip-audit, below) checks for known *vulnerabilities*, not license
   compliance. The `LICENSE-*` files come from baseline and the manifest
   metadata from step 5; there's no third file to keep in sync.

## Toolchain

Write one line per **asdf/mise-manageable** tool into `.tool-versions`
(version resolved at scaffold time, never hardcoded here):

| Tool | Role | Notes |
|---|---|---|
| `python` | interpreter | resolved version from Init, step 2 |
| `uv` | env + dependency + lock manager, task runner, build frontend | replaces pip, venv, pip-tools, pipx, and (for this playbook) the build step too |

Everything below the line is installed *through* uv, not through
asdf/mise, and gets no `.tool-versions` line:

| Tool | Role | How it's installed / invoked |
|---|---|---|
| `ruff` (format + check) | formatter and linter, replaces Black + Flake8 + isort + a long tail of flake8 plugins | project dev-dependency: `uv add --dev ruff`; run via `uv run ruff format .` / `uv run ruff check .` |
| `pytest` | test runner | project dev-dependency: `uv add --dev pytest`; run via `uv run pytest` |
| `mypy` | static type checker, run `--strict` | project dev-dependency: `uv add --dev mypy`; run via `uv run mypy` |
| `pip-audit` | dependency vulnerability scanner | NOT a project dependency — invoked ephemerally via `uvx pip-audit`, see `bin/security-scan` below |

Rationale notes (feed these one-line whys into
`.okf/decisions/toolchain.md` during OKF seeding, do not restate them in
`CLAUDE.md` or the README):

- **uv** — one fast Rust-implemented tool replaces the pip + venv +
  pip-tools (or Poetry) + pipx stack: it resolves and locks
  (`uv.lock`), creates and manages the project's `.venv` transparently,
  installs and pins the Python interpreter itself, and runs ad hoc tools
  via `uvx` without polluting the project environment.
- **ruff format + ruff check** — a single Rust binary subsumes Black
  (formatting), Flake8 plus its plugin ecosystem, and isort (import
  sorting); one dependency, one config block, and lint runs are
  10-100x faster than the tools it replaces, which matters once `select
  = ["ALL"]` is turned on (see `## Config files`).
- **pytest** — the de facto standard runner: fixtures, parametrization,
  and a plugin ecosystem (coverage, mock, asyncio, etc.) that
  `unittest` alone doesn't offer.
- **mypy --strict** — `--strict` bundles the individual strictness flags
  (`disallow_untyped_defs`, `no_implicit_optional`,
  `warn_return_any`, etc.) so type coverage can't quietly regress one
  flag at a time; it is the highest-signal way to catch a whole class of
  runtime `AttributeError`/`TypeError` bugs before they ship.
- **pip-audit** — the PyPA-maintained scanner; run against the *locked*
  dependency set (`uv export`'s output), not against whatever happens to
  be installed, so the scan reflects what will actually ship.

## Config files

Add to `pyproject.toml` (ported/modernized from the brief's toolchain
choices — write these tables under the project's existing
`[project]`/`[build-system]` tables that `uv init` already created):

```toml
[tool.ruff]
line-length = 100

[tool.ruff.lint]
select = ["ALL"]
ignore = [
    "D203",   # "blank line before class docstring" — conflicts with D211;
              # we keep D211 (no blank line) active, so D203 is ignored.
    "D213",   # "multi-line summary on second line" — conflicts with D212;
              # we keep D212 (summary on first line) active.
    "COM812", # trailing-comma placement — fights ruff's own formatter.
    "ISC001", # implicit string concatenation — also fights the formatter;
              # ruff's own docs recommend disabling both when using
              # `ruff format`.
    "CPY001", # per-file copyright headers — the LICENSE-* files at the
              # repo root are the authoritative grant; duplicating one
              # atop every source file adds churn without legal effect.
]

[tool.ruff.lint.pydocstyle]
# CLAUDE.md requires one docstring style project-wide; declaring it here is
# what makes ruff's D rules enforce that choice instead of accepting either.
convention = "google"   # or "numpy" — pick one at scaffold time

[tool.ruff.lint.per-file-ignores]
# S101: bare `assert` is the idiomatic pytest form. Still forbidden in src/.
# INP001: tests/ deliberately has no __init__.py — see `## Init`, step 4.
"tests/*" = ["S101", "INP001"]

[tool.mypy]
strict = true

[tool.pytest.ini_options]
addopts = "-q"
```

`select = ["ALL"]` is deliberately maximal — it turns on every rule
category ruff ships, including ones that will need per-project
`# noqa: <CODE>` escapes at specific call sites. That's intended: start
from "everything is a lint" and carve out exceptions locally and visibly,
rather than starting from a curated subset and hoping nothing important
was left off. Keep the `ignore` list above short and *documented* — every
entry has a one-line reason in the comment next to it; if the project
needs more (e.g. `ANN401` for a spot that genuinely needs `Any`), add it
with the same comment discipline, at the top-level list or as a per-file
`[tool.ruff.lint.per-file-ignores]` entry.

The carve-outs beyond the formatter-conflict pairs — `CPY001`, `S101`,
`INP001`, and the `pydocstyle` convention — are seeded above rather than
discovered later because **every one of them fires on the scaffold's own
hello-world output**. Without them, `## Quality gate`'s first `make ayce`
is guaranteed red on code the playbook itself generated, and step 6 of
the skill burns iterations rediscovering the same set every run.

Note what is deliberately *not* on that list: `D103`/`D104`, the missing
docstrings on `uv init`'s generated `hello()`. Those are fixed at the
source (`## Init`, step 4a) rather than ignored, because the
documentation bar in `## CLAUDE.md addenda` is a real project standard —
silencing the rule to make the scaffold green would mean the very first
commit violates the standard the repo claims to hold.

Add Python-specific ignores to the shared `.gitignore` (baseline writes
the file; these are the Python-specific lines — trimmed from
`py_blank/.gitignore`'s larger stock list to what an ordinary uv project
actually generates):

```
__pycache__/
*.py[cod]
.venv/
build/
dist/
*.egg-info/
.pytest_cache/
.mypy_cache/
.ruff_cache/
.coverage
htmlcov/
```

Do **not** ignore `uv.lock` — commit it for both libraries and
applications (unlike Cargo's binary/library split, uv's lockfile is
always meant to be committed for reproducible installs and CI).

For `.editorconfig`, add a Python override: 4-space indent for `*.py`
(PEP 8).

For the devcontainer, use the `mcr.microsoft.com/devcontainers/python`
image family; resolve the current tag at scaffold time and keep it in
agreement with `.tool-versions` and `.python-version`.

## Quality gate

Fill the baseline Makefile skeleton's phase bodies exactly as follows.
Never rename these seven targets, never change what `ayce` depends on:

```makefile
clean: ## remove build artifacts
	rm -rf dist *.egg-info .pytest_cache .mypy_cache .ruff_cache

fmt: ## format all sources
	uv run ruff format .

build: ## compile/build
	uv build

test: ## run all tests
	uv run pytest

lint: ## static analysis at the pedantic end
	uv run ruff check .
	uv run mypy src tests

security-scan: ## dependency vulnerability scan
	./bin/security-scan

docs: ## build docs, fail on warnings
	@echo "docs: no-op — this project does not publish generated docs." \
	      "Opt into mkdocs at scaffold time to enable this phase" \
	      "(see below); until then, per-function docstrings satisfy" \
	      "the documentation bar (CLAUDE.md addenda)."
```

If the user opts into mkdocs during Init or a later `/dev-playbook update`,
replace the `docs` body with:

```makefile
docs: ## build docs, fail on warnings
	uv run mkdocs build --strict
```

...and add `mkdocs`/`mkdocs-material` (or the user's preferred theme) as a
dev-dependency via `uv add --dev mkdocs`.

Notes:
- `lint`'s second line assumes the `src/` layout from `uv init --lib` (or
  `--app --package`) **plus the `tests/` directory that `## Init` step 4
  tells you to create** — `uv init` does not create `tests/` itself, and
  `mypy src tests` fails outright on the missing path. If Init chose the
  flat `uv init --app` layout instead, change it to `uv run mypy .` (mypy
  respects `pyproject.toml`'s config either way) and keep this in sync with
  whichever layout Init actually wrote.
- `test` does not run doctest examples by default. The `## CLAUDE.md
  addenda` below requires every public function's docstring to include a
  usage example, but pytest only executes those as tests if `addopts`
  gains `--doctest-modules` (and the example is written as a `>>>` REPL
  block) — treat that as an opt-in enhancement, not a default, since it
  changes what counts as a test failure across the whole codebase.
- `build` on an unpackaged, flat `uv init --app` scaffold (see `## Init`,
  step 1) does NOT simply report "nothing to build" — PEP 517's setuptools
  legacy fallback still runs and produces a real wheel, packaging whatever
  sits at the repo root with no declared build backend. That artifact is
  low-value (nothing controls what goes in it) and its own
  `<name>.egg-info/` build directory is easy to forget to clean up. Rather
  than let that legacy-fallback wheel pass silently as if it were a
  deliberate release artifact, make `build` a no-op for this layout too,
  matching the `docs` phase's pattern:

  ```makefile
  build: ## compile/build
  	@echo "build: no-op — this app has no declared build backend" \
  	      "(uv init --app without --package). Re-run uv init --app" \
  	      "--package if this project needs to ship as an installable" \
  	      "package; until then, 'uv build' would only invoke" \
  	      "setuptools' legacy fallback and produce a low-value wheel."
  ```

  Use plain `uv build` (as shown above) only when Init chose a packaged
  layout (`uv init --lib`, or `uv init --app --package`) — there it
  produces a real, intentional sdist + wheel. Keep this choice in sync with
  whichever layout Init actually wrote, same as the `lint` note above.

Write `bin/security-scan`'s body (baseline owns the shebang/`set -euo
pipefail` skeleton and the `chmod +x` step):

```bash
# --no-emit-project: without this, `uv export` includes the project itself
# as an editable self-reference (`-e .`) alongside its hash; pip-audit
# refuses to process editable requirements when hashes are present, and
# exits 1. The project's own code isn't a third-party dependency anyway —
# only its dependencies need scanning.
uv export --format requirements-txt --no-emit-project | uvx pip-audit -r /dev/stdin
```

This is the single definition of Python's security checks — the
Makefile's `security-scan` target and the CI `security.yaml` workflow
both call this script; do not duplicate the `pip-audit` invocation
anywhere else. Scanning `uv export`'s output (the resolved, locked
dependency set) rather than running `pip-audit` against whatever is
currently installed in `.venv` means the scan reflects exactly what will
ship, including transitive pins — not whatever a developer's local
environment happens to have drifted to.

## CI

Generate `.github/workflows/ci.yaml` from baseline's triggers block (push,
pull_request, monthly cron) with these jobs. Use `astral-sh/setup-uv@<resolved-major>`
for toolchain setup in every job. Resolve every `@<resolved-major>` below at
scaffold time — see baseline.md, § CI workflows → Action version pins, for
the procedure and the offline fallback table. Never write a major copied from
this file:

```yaml
name: CI

on:
  push:
  pull_request:
  schedule:
    - cron: "40 1 1 * *"   # monthly — toolchain freshness check

permissions:
  contents: read

jobs:
  test:
    name: Python ${{ matrix.python-version }}
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        # resolved supported version(s) from Init — add more entries here
        # only if the project explicitly commits to supporting them.
        python-version: ["<resolved-python-version>"]
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@<resolved-major>
      - uses: astral-sh/setup-uv@<resolved-major>
        with:
          python-version: ${{ matrix.python-version }}
      - run: uv run pytest

  lint:
    name: Lint
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@<resolved-major>
      - uses: astral-sh/setup-uv@<resolved-major>
      - run: uv run ruff check .
      # src/tests matches the src-layout from `uv init --lib` /
      # `--app --package`. For the flat `uv init --app` layout use
      # `uv run mypy .` instead — same rule as the Makefile's `lint`
      # phase (see `## Quality gate` notes); keep the two in sync.
      - run: uv run mypy src tests

  fmt-check:
    name: Format check
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@<resolved-major>
      - uses: astral-sh/setup-uv@<resolved-major>
      - run: uv run ruff format --check .
```

Replace `"<resolved-python-version>"` in the matrix with the actual
version string resolved during Init (the same one written to
`.python-version` and `requires-python`) — do not leave the placeholder
literal in the generated file. If the project wants to test against
multiple supported minor versions, list them all here and make sure the
oldest one matches `requires-python`'s floor.

Generate `.github/workflows/security.yaml` per baseline's exact verbatim
shape, inserting this stack's toolchain setup step (daily cron, unchanged
from baseline). The snippet below starts *after* baseline's own
`actions/checkout` step — do not repeat that step here, baseline's
skeleton already has it:

```yaml
      - uses: astral-sh/setup-uv@<resolved-major>
      - run: ./bin/security-scan
```

## CLAUDE.md addenda

Copy this section verbatim into the target repo's `CLAUDE.md`, after the
baseline's "Definition of done" and "Knowledge bundle pointer" sections:

---

### Python: Typing Requirements

- Every function and method signature must be fully typed (parameters and
  return type) — no bare `def f(x):`. `mypy --strict` enforces this in CI
  and locally via `make lint`; a signature that needs `Any` should say so
  explicitly (`x: Any`) rather than omitting the annotation.
- Prefer precise types (`list[int]`, `Mapping[str, int]`, a `TypedDict`,
  or a `dataclass`) over `dict`/`Any` when the shape is known ahead of
  time.
- Use `Protocol` for structural typing instead of inheritance when only
  behavior (not identity) matters.

### Python: Documentation Requirements

- Every public function, method, and class must have a docstring: a
  single-sentence summary line, then (if non-trivial) an explanation of
  behavior, parameters, return value, and exceptions raised, plus a
  short usage example.
- Docstring format is consistent across the project (pick one of
  Google-style or NumPy-style at project start and stick to it — ruff's
  `D` rules under `select = ["ALL"]` will flag inconsistent sections
  either way).
- Modules with non-obvious purpose get a module-level docstring at the
  top of the file explaining what the module is for and how it fits with
  its neighbors.

### Python: Testing Requirements

- Every public function must have pytest coverage for: the happy path,
  at least one edge case (empty input, boundary value, etc.), and at
  least one error case (the input that should raise).
- Name tests descriptively: `test_<function_or_scenario>`.
- Use `pytest.raises` to assert on expected exceptions — don't just
  assert the function "doesn't crash".
- Prefer fixtures and `pytest.mark.parametrize` over copy-pasted test
  bodies when the same logic is exercised with different inputs.

### Python: Error Handling

- Never use a bare `except:` — always name the exception type(s) being
  caught. A bare `except` (or `except Exception:` used as a catch-all)
  swallows `KeyboardInterrupt`/`SystemExit` and hides bugs; ruff's `BLE`
  and `E722` rules (both included under `select = ["ALL"]`) enforce this.
- Raise specific, ideally custom, exception types for domain errors
  rather than reusing `ValueError`/`Exception` generically across
  unrelated failure modes.
- Let `mypy --strict` and ruff's `select = ["ALL"]` both pass before
  considering a change done — a green `make lint` is the gate, not a
  human skim of the diff.

### Python: Naming

- `snake_case` for functions, variables, and modules; `PascalCase` for
  classes; `UPPER_SNAKE_CASE` for module-level constants.
- Avoid single-letter names except loop indices (`i`, `j`, `k`); prefer
  full words matching the domain (`cards` not `c`, `rank` not `r`).

---

## Update

On `/dev-playbook update` for a Python repo:

1. `uv lock --upgrade` (bump the lockfile's dependency versions within
   their declared constraints).
2. Re-resolve the Python version if the user wants to raise the floor
   (e.g. to pick up a new language feature); if so, `uv python pin
   <new-version>` (updates `.python-version`), otherwise leave it as-is.
3. Propagate any version change across all locations the
   version-consistency rule covers:
   - `pyproject.toml`'s `requires-python`
   - `.tool-versions`' `python` line
   - `.python-version` (uv's own pin file)
   - `ci.yaml`'s `test` job matrix `python-version` entries
   - `.devcontainer/devcontainer.json`'s image tag
4. Run `make security-scan` after any dependency-version change — catches
   newly introduced advisories in the upgraded lockfile before they land.
   (This is the same `bin/security-scan` script from `## Quality gate` —
   don't invoke `pip-audit` directly here either.)
5. Run `make ayce` and confirm it is green before considering the update
   done.
