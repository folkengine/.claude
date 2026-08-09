# TypeScript library — stack file

Read together with `references/baseline.md`. This file is instructions for
you, the executing agent — carry out each section as a step, don't just
summarize it. Apply after the stack's native init has already run, following
baseline's layer order: baseline files → AI files → stack configs (this
file's Config files / Quality gate / CI sections) → `.okf/` seeding.

This stack is for **libraries** — a package meant to be imported by other
TypeScript/JavaScript code (published to a registry or consumed as a
workspace dependency). An app that ships its own HTTP surface or UI is
`ts-next.md`, not this file.

## Init

1. Interview the user: **package name** (scoped, e.g. `@org/name`, or
   unscoped) and **entry point** (default: a single `src/index.ts`; ask if
   the library needs multiple public entry points, e.g. `src/index.ts` plus
   `src/testing.ts` for a test-utilities subpath — each becomes its own
   `exports` subpath and its own `tsup` entry, see `## Config files`).
2. Resolve the **Node.js version** at scaffold time — never hardcode one
   from memory. Ask the user for a floor, otherwise use current stable.
   This value drives `.tool-versions`, the CI matrix, the devcontainer image
   tag, and `package.json`'s `engines.node` — the version-consistency rule
   from baseline applies here from the first commit onward.
3. Write `package.json` **directly** (there is no native `npm init`
   scaffold worth running first — its interactive prompts don't know about
   `exports`, `type`, or `engines`, so hand-authoring the whole file is
   faster than running `npm init` and then rewriting most of it):

   ```json
   {
     "name": "<package-name>",
     "version": "0.0.1",
     "type": "module",
     "engines": {
       "node": ">=<resolved-node-major>"
     },
     "exports": {
       ".": {
         "types": "./dist/index.d.ts",
         "import": "./dist/index.js",
         "require": "./dist/index.cjs"
       }
     },
     "main": "./dist/index.cjs",
     "module": "./dist/index.js",
     "types": "./dist/index.d.ts",
     "files": ["dist"]
   }
   ```

   `engines.node` states a **floor** (major version only, `">=<major>"`),
   not the exact patch `.tool-versions` pins — Node's own semver compatibility
   promise operates at major-version boundaries, and consumers of the
   published package need "will this run on Node 22+", not the scaffold
   machine's exact patch. `.tool-versions`, the CI matrix, and the
   devcontainer image tag still pin the exact resolved version for
   reproducibility; only this floor is deliberately looser (same pattern as
   `python.md`'s `requires-python = ">=<resolved-minor>"`).

   The `main`/`module`/`types`/`exports.import`/`exports.require` filenames
   above (`index.js` for ESM, `index.cjs` for CJS) are not arbitrary — they
   are what `tsup` actually emits for a package whose `type` is `"module"`
   (verified locally, see `## Toolchain`'s tsup note). If a future version of
   tsup changes its default output-extension mapping, resolve the mismatch
   here rather than leaving `exports` pointing at files that don't exist in
   `dist/`.

   `exports` is the single map: only what appears under it (or under
   `files: ["dist"]`, which restricts what gets published at all) is public.
   State this in `CLAUDE.md` too — see `## CLAUDE.md addenda`.
4. Install the dev-dependency toolchain:

   ```
   npm install -D typescript tsup vitest @biomejs/biome
   ```

   **Resolve "current stable" `typescript` carefully.** At scaffold time,
   verify that the version `npm install` picks up actually works with
   `tsup`'s `.d.ts`-bundling step before moving on — a genuine incompatibility
   was found while authoring this file: TypeScript 7.0.2 crashes tsup
   8.5.1's `dts` build (`rollup-plugin-dts` throws `Cannot read properties
   of undefined (reading 'useCaseSensitiveFileNames')`); TypeScript 5.9.3
   against the same tsup build works cleanly. If "current stable"
   `typescript` resolves to a new major that breaks the `build` phase this
   way, pin to the newest working `5.x` instead, note the pin and the reason
   in `.okf/decisions/toolchain.md`, and revisit the pin next
   `/dev-playbook update` once tsup (or its dts backend) catches up.
5. Initialize the TypeScript config, then tighten it:

   ```
   npx tsc --init
   ```

   Current `tsc --init` output already defaults to `"strict": true` and
   `"module": "nodenext"` (which implies `"moduleResolution": "nodenext"`) —
   confirm both are present rather than assuming; older `tsc --init`
   templates did not default this way, and a future one could drift again.
   Then edit the generated file:
   - Set (or confirm) `"strict": true`, `"module": "nodenext"`.
   - Set `"rootDir": "./src"`, `"outDir": "./dist"`.
   - Add `"include": ["src"]` at the top level (outside
     `compilerOptions`). Without it, `tsc` (invoked with `--noEmit` in the
     `lint` phase, see `## Quality gate`) picks up `tsup.config.ts` and
     `vitest.config.ts` by its default include pattern and then fails with
     `TS6059: File '.../tsup.config.ts' is not under 'rootDir'` — verified
     locally. Scoping `include` to `src` is what fixes it; `tsup` and
     `vitest` each read their own config file directly and don't need `tsc`
     to type-check them as part of this project's own program.
   - Leave `"declaration": true` set (tsc's default template already sets
     it) — even though `tsup` is what actually emits the shipped `.d.ts`
     (see `## Toolchain`), `declaration: true` is harmless for `tsc
     --noEmit`'s type-checking pass and keeps the config honest about the
     project's intent if anything ever invokes `tsc` for emit directly.
6. Add a `src/index.ts` (or one file per interviewed entry point) and a
   colocated `src/index.test.ts` using Vitest's `test`/`expect` imports, so
   `make ayce` has something real to build and run from the first commit.

## Toolchain

Write one line per **asdf/mise-manageable** tool into `.tool-versions`
(version resolved at scaffold time, never hardcoded here):

| Tool | Role | Notes |
|---|---|---|
| `nodejs` | runtime | the only line this stack needs in `.tool-versions` — real asdf/mise plugin support exists for `nodejs`; nothing else in this table does |

Everything below is a project **dev-dependency**, installed and pinned via
`npm`/`package-lock.json`, not through asdf/mise, and gets no
`.tool-versions` line:

| Tool | Role | How it's installed / invoked |
|---|---|---|
| `typescript` | compiler, used here for type-checking only (`tsc --noEmit`) | `npm install -D typescript`; run via `npx tsc --noEmit` |
| `tsup` | bundler: esbuild-based JS build plus rolled-up `.d.ts` | `npm install -D tsup`; run via `npx tsup` |
| `vitest` | test runner | `npm install -D vitest`; run via `npx vitest run` |
| `@biomejs/biome` | formatter + linter, one binary replaces Prettier + ESLint | `npm install -D @biomejs/biome`; run via `npx biome format` / `npx biome check` |

Rationale notes (feed these one-line whys into
`.okf/decisions/toolchain.md` during OKF seeding, do not restate them in
`CLAUDE.md` or the README):

- **tsup** — wraps esbuild for the JS build (fast, zero-config ESM+CJS dual
  output) and bundles `.d.ts` declarations into a single rolled-up file per
  entry point, so consumers get one clean type-definitions file instead of
  a mirrored `dist/` tree of per-module `.d.ts` files. This is why
  `tsconfig.json`'s own `declaration` setting doesn't drive what ships —
  `tsup`'s `dts: true` does (see `## Config files`).
- **tsup's dts step depends on the installed `typescript` version** — it
  shells out to the TypeScript compiler API (via `rollup-plugin-dts`)
  to generate declarations. Verified during authoring: TypeScript 7.0.2
  crashes this step against tsup 8.5.1; TypeScript 5.9.3 does not. Treat
  this pairing as a real compatibility axis, not a hypothetical — re-verify
  it (`make build`) after any `typescript` or `tsup` bump, not just after a
  `typescript` bump.
- **vitest** — Vite's test runner without requiring an actual Vite app;
  it reads its config from `vitest.config.ts` using
  `defineConfig` from `vitest/config` (not from a separate `vite.config.ts`
  — this project has no bundled frontend, so there is no reason to run two
  overlapping config files). Jest-compatible API (`test`, `expect`,
  `describe`), but written in TypeScript/ESM natively with no transform
  step or `ts-jest` needed.
- **Biome (`@biomejs/biome`)** — one Rust binary replaces both Prettier
  (formatting) and ESLint plus its plugin ecosystem (linting): one
  dependency, one config file, and an order of magnitude faster than the
  tools it replaces. `biome check` runs formatting-conformance and linting
  in a single pass; `biome format --write` applies formatting fixes.

## Config files

Write `tsup.config.ts` in the repo root (entry, dts, dual-format output —
verified locally, produces `dist/index.js` + `.d.ts` for ESM and
`dist/index.cjs` + `.d.cts` for CJS given `"type": "module"` in
`package.json`):

```typescript
import { defineConfig } from "tsup";

export default defineConfig({
  entry: ["src/index.ts"],
  format: ["esm", "cjs"],
  dts: true,
  clean: true,
  sourcemap: true,
});
```

If Init interviewed multiple entry points, list them all in `entry` (tsup
emits one output pair per entry) and add matching subpaths to `package.json`'s
`exports` map.

Write `biome.json` in the repo root (recommended rule set, line width 100
per the brief):

```json
{
  "$schema": "https://biomejs.dev/schemas/<resolved-biome-version>/schema.json",
  "vcs": { "enabled": true, "clientKind": "git", "useIgnoreFile": true },
  "files": { "ignoreUnknown": false },
  "formatter": { "enabled": true, "lineWidth": 100 },
  "linter": {
    "enabled": true,
    "rules": { "preset": "recommended" }
  }
}
```

Resolve the `$schema` version tag to whatever `@biomejs/biome` actually
installed (`npx biome --version`) — don't leave a stale schema version
behind after an `## Update` bump. Use `"rules": { "preset": "recommended" }`,
**not** the older `"rules": { "recommended": true }` boolean form — the
boolean form still works but is deprecated in Biome 2.x and prints a
migration warning on every run; `preset: "recommended"` is the current
schema and was verified locally to catch real lint violations (e.g.
`noExplicitAny` fired on a deliberately introduced `x: any` parameter, `var`
usage flagged too) with no deprecation noise. `vcs.useIgnoreFile: true`
means Biome expects a `.gitignore` to exist in the repo root — baseline
already writes one, so this is satisfied by scaffold order, not an extra
step.

Write `vitest.config.ts` in the repo root — no separate `vite.config.ts`,
Vitest's own config carries the `test` block:

```typescript
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
  },
});
```

Add TypeScript-specific ignores to the shared `.gitignore` (baseline writes
the file; these are the lines this stack needs):

```
node_modules/
dist/
*.tsbuildinfo
coverage/
```

For `.editorconfig`, add a TypeScript override: 2-space indent for
`*.ts`/`*.tsx`/`*.json` (Biome's own formatter default, so the editor and
the formatter never fight over whitespace between saves).

For the devcontainer, use the `mcr.microsoft.com/devcontainers/typescript-node`
image family; resolve the current tag at scaffold time and keep it in
agreement with `.tool-versions`.

## Quality gate

Fill the baseline Makefile skeleton's phase bodies exactly as follows.
Never rename these seven targets, never change what `ayce` depends on:

```makefile
clean: ## remove build artifacts
	rm -rf dist

fmt: ## format all sources
	npx biome format --write .

build: ## compile/build
	npx tsup

test: ## run all tests
	npx vitest run

lint: ## static analysis at the pedantic end
	npx biome check .
	npx tsc --noEmit

security-scan: ## dependency vulnerability scan
	./bin/security-scan

docs: ## build docs, fail on warnings
	@echo "docs: no-op — this project does not publish generated docs." \
	      "Opt into typedoc at scaffold time to enable this phase" \
	      "(add \`npm install -D typedoc\` and replace this recipe with" \
	      "\`npx typedoc --treatWarningsAsErrors\`); until then, per-symbol" \
	      "doc comments satisfy the documentation bar (CLAUDE.md addenda)."
```

Notes:
- `lint` runs two tools in sequence: `biome check` (formatting-conformance
  plus linting) and `tsc --noEmit` (type-checking only — no emit, `tsup`
  owns actual output). Both must pass for `lint` to succeed. This mirrors
  Python's `ruff check` + `mypy` two-tool `lint` phase.
- `build` runs `tsup` directly, not `tsc` — `tsc --noEmit` in `lint` is the
  type-checker; `tsup` (via esbuild) is the actual bundler/emitter.
  `tsup.config.ts`'s `clean: true` already removes stale `dist/` output
  before each build, so the Makefile's `clean` target (`rm -rf dist`) and
  `build` don't fight; `clean` exists as its own phase so `make clean` alone
  is a meaningful, ayce-independent action.
- `test` does not require a separate typecheck step for test files — Vitest
  transpiles `.test.ts` through esbuild same as the app code; type errors in
  test files still surface via `lint`'s `tsc --noEmit` pass (which
  type-checks everything under `src/`, tests included).

If the user opts into typedoc during Init or a later `/dev-playbook update`,
replace the `docs` body with:

```makefile
docs: ## build docs, fail on warnings
	npx typedoc --treatWarningsAsErrors
```

...and add `typedoc` as a dev-dependency via `npm install -D typedoc`.

Write `bin/security-scan`'s body (baseline owns the shebang/`set -euo
pipefail` skeleton and the `chmod +x` step). Unlike the C/C++ stacks,
this project always has a real, universal dependency manifest
(`package-lock.json`), so `osv-scanner` here is a genuine best-effort
*addition* on top of `npm audit`, not the primary check papering over a
missing manifest:

```bash
npm audit --audit-level=high

if ! command -v osv-scanner >/dev/null 2>&1; then
  echo "security-scan: osv-scanner not installed, skipping the OSV-format" \
       "scan (see https://github.com/google/osv-scanner for install" \
       "instructions); npm audit above already covers the npm advisory" \
       "database." >&2
  exit 0
fi

osv-scanner scan source .
```

This is the single definition of this stack's security checks — the
Makefile's `security-scan` target and the CI `security.yaml` workflow both
call this script; do not duplicate `npm audit` or `osv-scanner` anywhere
else. `npm audit --audit-level=high` was verified locally: it exits 0 when
only low/moderate advisories are present and would exit non-zero on a
high/critical one — a stray low-severity `esbuild` advisory in the smoke
test did not fail the gate, confirming the `--audit-level=high` floor
behaves as documented.

## CI

Generate `.github/workflows/ci.yaml` from baseline's triggers block (push,
pull_request, monthly cron) with this job. Use `actions/setup-node@<resolved-major>` for
toolchain setup, with a version consistent with `.tool-versions`. Resolve
every `@<resolved-major>` below at scaffold time — see baseline.md, § CI
workflows → Action version pins, for the procedure and the offline fallback
table. Never write a major copied from this file:

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
  build:
    name: Node ${{ matrix.node-version }}
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        # resolved Node version from Init — add more entries here only if
        # the project explicitly commits to supporting them.
        node-version: ["<resolved-node-version>"]
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@<resolved-major>
      - uses: actions/setup-node@<resolved-major>
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm ci
      - run: npx tsup
      - run: npx vitest run
      - run: npx biome check .
      - run: npx tsc --noEmit
```

Replace `"<resolved-node-version>"` in the matrix with the actual version
string resolved during Init (the same one written to `.tool-versions` and
`engines.node`'s floor) — do not leave the placeholder literal in the
generated file. Use `npm ci`, not `npm install`, in CI — it installs
exactly what `package-lock.json` pins and fails instead of silently
re-resolving if the lockfile and manifest disagree.

Generate `.github/workflows/security.yaml` per baseline's exact verbatim
shape, inserting this stack's toolchain setup step (daily cron, unchanged
from baseline). The snippet below starts *after* baseline's own
`actions/checkout@<resolved-major>` step — do not repeat that step here, baseline's
skeleton already has it:

```yaml
      - uses: actions/setup-node@<resolved-major>
        with:
          node-version-file: .tool-versions
      - run: npm ci
      - run: |
          curl -sSfL https://github.com/google/osv-scanner/releases/latest/download/osv-scanner_linux_amd64 \
            -o /usr/local/bin/osv-scanner
          chmod +x /usr/local/bin/osv-scanner
      - run: ./bin/security-scan
```

`actions/setup-node@<resolved-major>`'s `node-version-file` input accepts a `.tool-versions`
file directly (it looks for the `nodejs` line) — this is what keeps CI's
Node version from drifting out of the version-consistency rule without a
second hardcoded value in the workflow.

## CLAUDE.md addenda

Copy this section verbatim into the target repo's `CLAUDE.md`, after the
baseline's "Definition of done" and "Knowledge bundle pointer" sections:

---

### TypeScript: Testing Requirements

- Every exported symbol (function, class, const) must have at least one
  Vitest test covering its happy path, colocated as `<file>.test.ts` next
  to the file it tests.
- Name tests descriptively: a `test("<function> <scenario>", ...)` or
  `describe("<symbol>", () => { test("<scenario>", ...) })` block, not a
  bare `test("works", ...)`.
- Cover edge cases and error conditions, not just the happy path — an
  exported function that can throw or return an error variant needs a test
  exercising that path too.
- Prefer `expect(...).toThrow(...)` (or the async equivalent) over
  asserting a function merely "doesn't crash".

### TypeScript: Documentation Requirements

- Every exported symbol gets a `/** ... */` TSDoc comment: a single-sentence
  summary line, then (if non-trivial) `@param`, `@returns`, and `@throws`
  tags, plus a short usage example for anything whose call shape isn't
  obvious from its signature.
- The `exports` map in `package.json` (see `## Config files`) is the
  project's actual public API surface — anything not re-exported from an
  entry point listed there is a private implementation detail and does not
  need the same documentation bar, even if it happens to use the `export`
  keyword internally within `src/`.
- Modules with non-obvious purpose get a file-level comment at the top
  explaining what the module is for and how it fits with its neighbors.

### TypeScript: Error Handling

- Never use `any` to silence a type error — Biome's `noExplicitAny`
  (part of the `recommended` preset, see `## Config files`) flags it in
  `make lint`; if a value genuinely can't be typed precisely yet, use
  `unknown` and narrow it, or document why with a targeted
  `// biome-ignore lint/suspicious/noExplicitAny: <reason>` comment at the
  call site, not a blanket config-level suppression.
- Throw `Error` subclasses (custom error classes for domain-specific
  failures), never bare strings or plain objects — callers doing
  `catch (e)` need `e instanceof MyError` to work.
- Prefer a typed `Result`-like return (a discriminated union) over throwing
  when a failure is an expected, common outcome the caller must branch on;
  reserve `throw` for truly exceptional/programmer-error conditions.

### TypeScript: Naming

- `camelCase` for functions, variables, and methods; `PascalCase` for
  types, interfaces, classes, and enums; `UPPER_SNAKE_CASE` for
  module-level constants.
- Prefer named exports over a default export — named exports are
  grep-able, survive renames/refactors better under Biome's tooling, and
  keep the `exports` map (the real public surface) as the one place that
  decides what's public, rather than a file's default-export identity.
- Avoid single-letter names except loop indices (`i`, `j`, `k`); prefer
  full words matching the domain.

### TypeScript: Code Organization

- Keep functions focused and single-purpose.
- Extract complex logic into well-named helper functions.
- Group related types and functions into modules under `src/`; only
  re-export from an entry point (`src/index.ts`) what's meant to be public
  — the `exports` map, not file structure, is what makes something part of
  the package's API.
- Avoid deep relative import chains (`../../../foo`) — prefer restructuring
  modules over adding path aliases to route around them, since path aliases
  need to be re-declared in both `tsconfig.json` and any bundler config,
  another place for drift.

---

## Update

On `/dev-playbook update` for a TypeScript library repo:

1. `npx npm-check-updates -u && npm install` — bump `package.json`'s
   dependency ranges to their latest versions and refresh
   `package-lock.json` to match.
2. Re-verify the TypeScript/tsup compatibility pairing noted in `## Init`
   step 4 and `## Toolchain` — run `make build` after the bump and confirm
   `tsup`'s `dts` step still succeeds before considering the upgrade clean;
   a `typescript` major bump is exactly the kind of change that can
   silently break `.d.ts` bundling again.
3. Re-resolve the Node.js version if the user wants to raise the floor;
   otherwise leave it as-is.
4. Propagate any version change across all locations the
   version-consistency rule covers:
   - `package.json`'s `engines.node` floor
   - `.tool-versions`' `nodejs` line
   - `ci.yaml`'s `build` job matrix `node-version` entries
   - `.devcontainer/devcontainer.json`'s image tag
5. Run `make security-scan` after any dependency-version change — catches
   newly introduced advisories in the updated lockfile before they land.
   (This is the same `bin/security-scan` script from `## Quality gate` —
   don't invoke `npm audit` or `osv-scanner` directly here either.)
6. Run `make ayce` and confirm it is green before considering the update
   done.
