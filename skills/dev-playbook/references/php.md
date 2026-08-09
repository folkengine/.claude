# PHP — stack file

Read together with `references/baseline.md`. This file is instructions for
you, the executing agent — carry out each section as a step, don't just
summarize it. Apply after the stack's native init has already run, following
baseline's layer order: baseline files → AI files → stack configs (this
file's Config files / Quality gate / CI sections) → `.okf/` seeding.

## Init

1. Interview the user: **library or application?** — Composer's `type`
   field wants to know (`library` vs `project`), and the choice decides
   whether `composer.json` ships install-worthy metadata or is a pure
   deployment manifest. Either way the layout is the same (`src/` +
   `tests/`); unlike Python there is no flat variant to choose.
2. Interview: **package name** — Composer requires `vendor/name`, all
   lowercase (e.g. `folkengine/mylib`), and **namespace root** — default
   to the PascalCase form of the package name (`Folkengine\Mylib`); ask
   only if the user wants something else.
3. **asdf/mise shim gotcha — handle before running anything.** On an
   asdf-managed machine, `php` and `composer` error with "No version is
   set for command php" until a version is in scope, and the native init
   below runs *before* baseline's layer writes `.tool-versions`. Resolve
   the **PHP version** now (current stable, or the user's pin — ask the
   toolchain, never guess from memory). Note that `asdf list all php`'s
   literal tail is usually alpha/beta/RC pre-releases — filter to final
   releases, e.g. `asdf list all php | grep -Ev 'alpha|beta|RC' | tail`,
   before taking the newest. Then put the resolved version in scope
   first:

   ```
   asdf set php <resolved-version>     # writes the .tool-versions php line
   ```

   (mise: `mise use php@<resolved-version>`.) This pre-writes the same
   `.tool-versions` line baseline's layer owns — that's fine; baseline's
   step then just confirms it rather than creating it. Composer needs no
   separate line or install: asdf-php builds bundle a `composer` binary
   per PHP version (verified locally — setting only the php version makes
   the `composer` shim work). Preflight also requires **Composer ≥ 2.4**
   (`composer --version`) — `composer audit`, the security scanner below,
   does not exist before that.
4. Run the native init — non-interactive, with the PSR-4 mapping declared
   up front:

   ```
   composer init --name <vendor/name> --type <library|project> \
     --description "<one-paragraph project description>" \
     --license "<SPDX-expression>" --autoload src/ --no-interaction
   ```

   `--description` is **not optional**: `composer validate --strict` (the
   `build` phase) fails on a manifest without one — "The property
   description is required" — so omitting it here means the scaffold's
   first `make ayce` is red on the playbook's own output (verified
   locally). Reuse the one-paragraph description baseline's README shape
   asks for; interview for it now if not already given.
   `--autoload src/` maps the namespace root to `src/` under
   `autoload.psr-4`. The `--license` value is an SPDX expression matching
   whatever the user chose in the licensing interview (multi-license
   scaffolds use `"MIT OR Apache-2.0 OR GPL-3.0-or-later"`) — baseline
   copies the `LICENSE-*` files; this field is what wires them into the
   package metadata, same job as Python's `license`/`license-files` keys.
5. Write the version pins into `composer.json`:

   ```json
   "require": {
     "php": ">=<resolved-minor>"
   },
   "config": {
     "platform": {
       "php": "<resolved-full-version>"
     },
     "sort-packages": true
   }
   ```

   Two pins with two jobs: `require.php` is the public **floor** (minor
   precision, `>=8.5` — consumers need "runs on 8.5+", not the scaffold
   machine's patch; same pattern as `requires-python` and
   `engines.node`), and `config.platform.php` is the **exact** version
   dependency resolution assumes, so `composer update` on a machine with
   a newer local PHP can't quietly lock packages the floor version can't
   run. Both are members of this stack's version-consistency set — see
   the enumeration in `## Update`.
6. Add the test autoload mapping and install the dev toolchain:

   ```json
   "autoload-dev": {
     "psr-4": {
       "<NamespaceRoot>\\Tests\\": "tests/"
     }
   }
   ```

   ```
   composer require --dev phpunit/phpunit phpstan/phpstan friendsofphp/php-cs-fixer
   ```

   All three are project dev-dependencies pinned by `composer.lock` —
   nothing on this stack is globally installed, and no separate phar is
   downloaded (see `## Toolchain`).
7. Write the hello-world so the gate has something real to chew on —
   `composer init` creates no source files:

   - `src/Greeter.php` — `declare(strict_types=1);` first statement, the
     namespace root from step 2, a `final` class with one typed public
     method, and docblocks meeting the `## CLAUDE.md addenda` bar (class
     docblock saying what it's for; method docblock only where the
     signature alone doesn't tell the whole story).
   - `tests/GreeterTest.php` — namespace `<NamespaceRoot>\Tests`, extends
     `PHPUnit\Framework\TestCase`, at least one real assertion against
     the hello-world. Same `declare(strict_types=1);` and docblock bar —
     PHPStan's `level: max` analyses `tests/` too (see `## Config
     files`), so test code meets the same standard from the first commit.

## Toolchain

Write one line per **asdf/mise-manageable** tool into `.tool-versions`
(version resolved at scaffold time, never hardcoded here):

| Tool | Role | Notes |
|---|---|---|
| `php` | interpreter + bundled Composer | the only line this stack needs — asdf-php builds ship a per-version `composer` binary, so there is no separate `composer` line to keep in sync |

Everything below is a project **dev-dependency**, installed and pinned via
Composer/`composer.lock`, not through asdf/mise, and gets no
`.tool-versions` line:

| Tool | Role | How it's installed / invoked |
|---|---|---|
| `phpunit/phpunit` | test runner | `composer require --dev phpunit/phpunit`; run via `vendor/bin/phpunit` |
| `phpstan/phpstan` | static analyser, run at `level: max` | `composer require --dev phpstan/phpstan`; run via `vendor/bin/phpstan analyse` |
| `friendsofphp/php-cs-fixer` | formatter (and format-conformance checker) | `composer require --dev friendsofphp/php-cs-fixer`; run via `vendor/bin/php-cs-fixer fix` / `check` |
| `composer audit` | dependency vulnerability scanner | built into Composer ≥ 2.4 — nothing to install; see `bin/security-scan` below |

Rationale notes (feed these one-line whys into
`.okf/decisions/toolchain.md` during OKF seeding, do not restate them in
`CLAUDE.md` or the README):

- **Composer-vendored tools, no phars, no global installs** — every tool
  rides `composer.lock`, so CI, the devcontainer, and every contributor
  run byte-identical tool versions; a `phive`/phar or global-install
  setup reintroduces exactly the per-machine drift the lockfile exists
  to kill.
- **PHPUnit** — the ecosystem's standard runner; data providers,
  attributes-based metadata, and first-class IDE/CI integration. Pest is
  a popular sugar layer *on top of* PHPUnit — a project that wants it
  can add it later without changing this gate's shape.
- **PHPStan at `level: max`** — the same "start maximal, carve out
  locally and visibly" stance as Python's `select = ["ALL"]` + `mypy
  --strict`: every property, parameter, and return is checked at the
  strictest level, and exceptions live in code as one-line `@phpstan-`
  annotations or a documented ignore entry, not as a lowered global
  level that silently regresses.
- **PHP-CS-Fixer with `@PER-CS`** — PER-CS is the PHP-FIG's current
  coding-style spec (successor to PSR-12); the fixer both applies it
  (`fix`, the `fmt` phase) and verifies it (`check`, part of the `lint`
  phase), so formatter and format-gate can never disagree about the
  rules.
- **`composer audit`** — first-party scanner against the packagist.org
  advisory database (and any additional configured repositories); run
  with `--locked` so the scan reflects `composer.lock` — what will
  actually ship — not whatever `vendor/` has drifted to locally, same
  reasoning as Python auditing `uv export`'s output.

## Config files

Write `.php-cs-fixer.dist.php` in the repo root (the `.dist` name is the
committed default; a developer can shadow it with an uncommitted local
`.php-cs-fixer.php` — same convention as the other two configs below):

```php
<?php

declare(strict_types=1);

$finder = PhpCsFixer\Finder::create()
    ->in([__DIR__ . '/src', __DIR__ . '/tests']);

return (new PhpCsFixer\Config())
    ->setRiskyAllowed(true)
    ->setRules([
        '@PER-CS' => true,
        '@PhpCsFixer' => true,
        'declare_strict_types' => true,
        // @PhpCsFixer would otherwise stamp @coversNothing onto every
        // test class — misleading here, since phpunit.xml.dist's
        // <source> block already defines coverage over src/.
        'php_unit_test_class_requires_covers' => false,
    ])
    ->setFinder($finder);
```

Notes:
- `@PER-CS` tracks the current PER Coding Style release; `@PhpCsFixer`
  layers the project's own stricter hygiene set on top. Together they
  are this stack's "pedantic end" formatting bar.
- Expect the first `make fmt` to rewrite the starter files — verified
  behaviors of `@PhpCsFixer` include adding an `@internal` annotation to
  test classes (correct: tests are not public API) and spacing tweaks in
  data providers. That is the ruleset doing its job, not a config error.
- `declare_strict_types` is a **risky** rule (it changes runtime
  behavior by inserting the declare where missing) — that is exactly why
  it's here, and why `setRiskyAllowed(true)` is set: strict types in
  every file is a project standard (`## CLAUDE.md addenda`), and the
  fixer enforcing it means a forgotten declare is a `make lint` failure,
  not a review nitpick.

Write `phpstan.dist.neon` in the repo root:

```neon
parameters:
    level: max
    paths:
        - src
        - tests
```

Keep it this small. `level: max` is the whole point; when a finding
genuinely can't be fixed, suppress it at the call site (inline
`@phpstan-ignore` with a reason) or as a documented `ignoreErrors` entry
here — never by lowering `level`.

Write `phpunit.xml.dist` in the repo root. Resolve the schema version
from the *installed* PHPUnit (`vendor/bin/phpunit --version`, take
major.minor) — never copy one from this document:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/<resolved-major.minor>/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         cacheDirectory=".phpunit.cache"
         colors="true"
         failOnWarning="true"
         failOnNotice="true">
  <testsuites>
    <testsuite name="default">
      <directory>tests</directory>
    </testsuite>
  </testsuites>
  <source>
    <include>
      <directory>src</directory>
    </include>
  </source>
</phpunit>
```

`failOnWarning`/`failOnNotice` make the `test` phase hold the same "a
warning is a failure" line the rest of the playbook holds for docs and
lint. The schema URL is version-coupled by design — `## Update` names it
as this stack's drift probe (`--migrate-configuration` regenerates it).

Add PHP-specific ignores to the shared `.gitignore` (baseline writes the
file; these are the PHP-specific lines):

```
/vendor/
.phpunit.cache/
.php-cs-fixer.cache
```

Do **not** ignore `composer.lock` — commit it for libraries and
applications alike. Consumers of a published library ignore it anyway
(Composer resolves from `composer.json` for dependencies), but *this
repo's* CI, devcontainer, and contributors all install from it, which is
what makes tool and dependency versions reproducible — same rule and
same reasoning as `uv.lock` and `package-lock.json`.

For `.editorconfig`, add a PHP override: 4-space indent for `*.php`
(PER-CS inherits PSR-12's four-space rule; the fixer would fight
anything else).

For the devcontainer, use the `mcr.microsoft.com/devcontainers/php`
image family. Its tags **do** encode the PHP minor version (`8.4`,
`8.5`, `8.5-trixie` — verified against the MCR tag list 2026-08-09), so
the image tag itself is the devcontainer's member of the
version-consistency set: resolve the tag matching the Init PHP version
at scaffold time and keep the two in agreement. The tag carries minor
precision only; `config.platform.php` (Init, step 5) holds the exact
patch.

## Quality gate

Fill the baseline Makefile skeleton's phase bodies exactly as follows.
Never rename these seven targets, never change what `ayce` depends on:

```makefile
clean: ## remove build artifacts
	rm -rf .phpunit.cache .php-cs-fixer.cache

fmt: ## format all sources
	@[ -d vendor ] || composer install
	vendor/bin/php-cs-fixer fix

build: ## compile/build
	composer validate --strict
	composer install
	composer dump-autoload --optimize --strict-psr

test: ## run all tests
	@[ -d vendor ] || composer install
	vendor/bin/phpunit

lint: ## static analysis at the pedantic end
	@[ -d vendor ] || composer install
	vendor/bin/php-cs-fixer check
	vendor/bin/phpstan analyse

security-scan: ## dependency vulnerability scan
	./bin/security-scan

docs: ## build docs, fail on warnings
	@echo "docs: no-op — this project does not publish generated docs." \
	      "Opt into phpDocumentor at scaffold time to enable this phase;" \
	      "until then, per-symbol docblocks satisfy the documentation bar" \
	      "(CLAUDE.md addenda)."
```

Notes:
- **`clean` must not remove `vendor/`.** Every later phase's tools live
  there, and `ayce` runs `clean` first — deleting `vendor/` would make
  `ayce` reinstall the toolchain on every sweep. `vendor/` is this
  stack's `.venv`/`node_modules`, not a build artifact.
- The `@[ -d vendor ] || composer install` guard on `fmt`, `test`, and
  `lint` makes each phase self-sufficient on a fresh clone (`make test`
  straight after checkout works). `build`'s unconditional
  `composer install` remains the authoritative sync with
  `composer.lock`.
- PHP has no compile step, so `build` asserts the things that *can*
  break at "build time" here: `composer validate --strict` (manifest
  well-formed and warning-free), `composer install` (lockfile and
  manifest agree — install fails if they've drifted), and
  `composer dump-autoload --optimize --strict-psr`, which turns any
  class whose namespace/path disagrees with the PSR-4 mapping into a
  hard failure instead of a silent autoload miss. This mirrors Python's
  "does `uv build` produce a real artifact" bar, scaled to what PHP
  actually ships.
- `lint` runs two tools in sequence — `php-cs-fixer check`
  (format-conformance, no writes) then `phpstan analyse` — mirroring
  Python's `ruff check` + `mypy` and ts-lib's `biome check` + `tsc
  --noEmit` two-tool phases. `fmt` writes; `lint` only verifies.
- Until the user runs the printed `git init && git commit`, nearly every
  composer command prints `Composer could not detect the root package
  (<vendor/name>) version, defaulting to '1.0.0'` — expected during
  scaffolding (the skill never runs git itself), harmless (a warning,
  not a failure), and it disappears after the first commit. Don't burn a
  fix iteration on it.

If the user opts into phpDocumentor during Init or a later
`/dev-playbook update`, replace the `docs` body with an invocation of the
phpDocumentor phar or Docker image (it is not Composer-installable into
an ordinary project without dependency conflicts — that is why the
default is the no-op, not a half-wired doc build).

Write `bin/security-scan`'s body (baseline owns the shebang/`set -euo
pipefail` skeleton and the `chmod +x` step):

```bash
composer audit --locked --abandoned=report
```

This is the single definition of PHP's security checks — the Makefile's
`security-scan` target and the CI `security.yaml` workflow both call
this script; do not duplicate the `composer audit` invocation anywhere
else. `--locked` audits `composer.lock` directly, so the scan needs no
installed `vendor/` (the security workflow exploits this — see `## CI`)
and reflects exactly what ships. `--abandoned=report` prints abandoned
packages without failing the gate: abandonment is a maintenance signal,
not a vulnerability, and a daily cron that goes red the day a maintainer
archives a repo trains people to ignore red. Advisories still fail the
scan.

## CI

Generate `.github/workflows/ci.yaml` from baseline's triggers block
(push, pull_request, monthly cron) with these jobs. Use
`shivammathur/setup-php@<resolved-major>` for toolchain setup — the de
facto standard PHP setup action (its releases are version tags; current
major verified v2, see baseline's fallback table). Resolve every
`@<resolved-major>` below at scaffold time — see baseline.md, § CI
workflows → Action version pins. Never write a major copied from this
file:

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
    name: PHP ${{ matrix.php-version }}
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        # resolved supported version(s) from Init — add more entries here
        # only if the project explicitly commits to supporting them.
        php-version: ["<resolved-minor>"]
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@<resolved-major>
      - uses: shivammathur/setup-php@<resolved-major>
        with:
          php-version: ${{ matrix.php-version }}
          coverage: none
      - run: composer validate --strict
      - run: composer install --prefer-dist --no-progress
      - run: vendor/bin/phpunit

  lint:
    name: Lint
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@<resolved-major>
      - uses: shivammathur/setup-php@<resolved-major>
        with:
          php-version: "<resolved-minor>"
          coverage: none
      - run: composer install --prefer-dist --no-progress
      - run: vendor/bin/php-cs-fixer check
      - run: vendor/bin/phpstan analyse
```

Replace `"<resolved-minor>"` (both jobs) with the actual minor resolved
during Init — the same value as `require.php`'s floor — and do not leave
the placeholder literal in the generated file. `coverage: none` skips
Xdebug/PCOV setup the gate doesn't use, which measurably speeds up every
run. `composer install` in CI is already lockfile-strict — it fails if
`composer.lock` and `composer.json` disagree, so it is this stack's
`npm ci` with no extra flag needed. Note that `setup-php` reads neither
`.tool-versions` nor `composer.json`, so both workflows carry explicit
`php-version` values — that is why they appear in this stack's
version-consistency set (`## Update`).

Generate `.github/workflows/security.yaml` per baseline's exact verbatim
shape, inserting this stack's toolchain setup step (daily cron, unchanged
from baseline). The snippet below starts *after* baseline's own
`actions/checkout@<resolved-major>` step — do not repeat that step here,
baseline's skeleton already has it. No `composer install` step:
`--locked` audits the lockfile directly (see `## Quality gate`):

```yaml
      - uses: shivammathur/setup-php@<resolved-major>
        with:
          php-version: "<resolved-minor>"
          coverage: none
      - run: ./bin/security-scan
```

## CLAUDE.md addenda

Copy this section verbatim into the target repo's `CLAUDE.md`, after the
baseline's "Definition of done" and "Knowledge bundle pointer" sections:

---

### PHP: Strictness Requirements

- Every PHP file starts with `declare(strict_types=1);` — the
  `declare_strict_types` fixer rule inserts it, and `make lint` fails
  without it. Never remove or work around it with loose comparisons.
- Every property, parameter, and return type is declared — PHPStan at
  `level: max` treats a missing type as an error, not a suggestion. A
  value that genuinely can't be typed precisely gets a `@phpstan-`
  docblock type (e.g. generics via `@template`, array shapes via
  `array{...}`), not a bare `mixed` shrug.
- Suppress a PHPStan finding only at the call site with an inline
  `@phpstan-ignore` carrying a reason, or as a documented `ignoreErrors`
  entry — never by lowering `level` in `phpstan.dist.neon`.

### PHP: Testing Requirements

- Every public method must have PHPUnit coverage for: the happy path, at
  least one edge case (empty input, boundary value), and at least one
  error case (the input that should throw).
- Name test methods descriptively: `test<Scenario>` or attribute-based
  with a readable method name — not `testWorks`.
- Use data providers (`#[DataProvider]`) instead of copy-pasted test
  bodies when the same logic is exercised with different inputs.
- Use `$this->expectException(...)` to assert on expected exceptions —
  don't just assert the call "doesn't crash".

### PHP: Documentation Requirements

- Every public class and method gets a docblock: a single-sentence
  summary line, plus `@param`/`@return`/`@throws` tags **only where they
  add information the native type declarations don't already carry**
  (array shapes, generics, thrown exception types). A docblock that
  restates `int $x` as `@param int $x` is noise, not documentation.
- Files or classes with non-obvious purpose get a docblock explaining
  what they are for and how they fit with their neighbors.

### PHP: Error Handling

- Throw specific, ideally custom, exception types for domain errors —
  never generic `\Exception`, and never a string-y error return where an
  exception is warranted.
- Never use the `@` error-suppression operator — handle the condition or
  let it surface.
- Catch exceptions only where something meaningful can be done; a
  `catch` that swallows and continues hides bugs.

### PHP: Naming and Organization

- PSR conventions: `PascalCase` classes/interfaces/traits/enums,
  `camelCase` methods and properties, `UPPER_SNAKE_CASE` class
  constants; one class per file, filename matches the class name, path
  matches the namespace (PSR-4 — `composer dump-autoload --strict-psr`
  in `make build` fails on violations).
- Declare classes `final` unless the class is explicitly designed as an
  extension point — inheritance is an API commitment, not a default.
- Keep classes and methods focused and single-purpose; extract complex
  logic into well-named private methods or collaborating classes rather
  than growing god-objects.

---

## Update

On `/dev-playbook update` for a PHP repo:

1. `composer update` (bump `composer.lock` within `composer.json`'s
   declared constraints). For moves *outside* the constraints, run
   `composer outdated --direct` to see what's being held back by a major
   pin, raise the constraint in `composer.json` deliberately, and
   `composer update` again.
2. Re-resolve the PHP version if the user wants to raise the floor;
   otherwise leave it as-is.
3. Propagate any PHP version change across all locations the
   version-consistency rule covers — this stack's full set:
   - `.tool-versions`' `php` line
   - `composer.json`'s `require.php` floor
   - `composer.json`'s `config.platform.php` exact pin
   - `ci.yaml`'s `test` job matrix `php-version` entries **and** the
     `lint` job's `php-version` (setup-php reads no version file — both
     are hand-maintained, see `## CI`)
   - `security.yaml`'s `setup-php` step `php-version`
   - `.devcontainer/devcontainer.json`'s image tag (minor-precision)
4. **Drift probe:** after any PHPUnit **major** bump, `phpunit.xml.dist`'s
   schema URL points at the old major.minor. Run
   `vendor/bin/phpunit --migrate-configuration` to regenerate, then diff
   against the repo's file and REPORT per baseline's drift-check rule —
   never silently rewrite; the file belongs to the user after the first
   commit.
5. Run `make security-scan` after any dependency-version change — catches
   newly introduced advisories in the updated lockfile before they land.
   (This is the same `bin/security-scan` script from `## Quality gate` —
   don't invoke `composer audit` directly here either.)
6. Run `make ayce` and confirm it is green before considering the update
   done.
