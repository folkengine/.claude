# TypeScript / Next.js — stack file

Read together with `references/baseline.md`. This file is instructions for
you, the executing agent — carry out each section as a step, don't just
summarize it. Apply after the stack's native init has already run, following
baseline's layer order: baseline files → AI files → stack configs (this
file's Config files / Quality gate / CI sections) → `.okf/` seeding.

This stack is for **Next.js applications** — a project that ships its own
route tree, server rendering, and (usually) an HTTP surface, scaffolded by
`create-next-app`. A package meant to be imported by other TypeScript/
JavaScript code is `ts-lib.md`, not this file.

Unlike every other stack file, this one layers on top of a first-party
scaffolding tool that already makes most of the structural decisions (routing
convention, build tool, dev server, TypeScript template). The governing rule
for this whole file: **do not fight `create-next-app`.** Where the framework's
own generator already produces a reasonable, current default, keep it;
the playbook only adds what `create-next-app` doesn't provide on its own
(Vitest, the quality-gate wiring, CI, `.okf/`, the rest of baseline's files).

## Init

1. Interview the user for the **project name** (the directory
   `create-next-app` will create), then run:

   ```
   npx create-next-app@latest <name> --typescript --app --eslint --disable-git
   ```

   Deliberately stop there and let `create-next-app`'s **own interactive
   interview** run for everything else — Tailwind CSS, whether to use a
   `src/` directory, the import alias (default `@/*`), Turbopack vs. Webpack,
   React Compiler, whether to include `AGENTS.md`. Record the user's answers
   into `.okf/decisions/toolchain.md` during OKF seeding rather than
   re-deciding any of them here; this is the concrete form "don't fight the
   framework" takes for this stack — the four flags above pin only the
   choices this playbook actually cares about (TypeScript, App Router, ESLint
   as the linter, no auto `git init`), and nothing else.

   **`--disable-git` is the current, verified flag name.** Older tutorials
   and some cached memory reference `--skip-git` or `--no-git` — neither
   exists in current `create-next-app`. Confirmed two ways: (1) the current
   `create-next-app` CLI reference lists `--disable-git` — "Explicitly tell
   the CLI to disable git initialization" — with no `--skip-git`/`--no-git`
   alias; (2) a local smoke scaffold (`create-next-app@latest`, resolved to
   Next.js 16.2.12) run with this exact flag printed `Skipping git
   initialization.` and left no `.git` directory behind. Without this flag,
   `create-next-app` runs `git init` (and, per its own docs, an initial
   commit) unasked — that would both preempt the playbook's own file layers
   with a premature first commit and violate the "never run state-changing
   git commands" rule if the agent let it fire silently. Always pass it.

2. Resolve the **Node.js version** at scaffold time — never hardcode one
   from memory. Ask the user for a floor, otherwise use current stable
   (Next.js 16 requires Node.js 20.9+ at minimum — verified against the
   framework's own "Upgrading to Version 16" guide; treat that as the
   effective floor-of-the-floor, not just a suggestion). This value drives
   `.tool-versions`, the CI matrix, the devcontainer image tag, and (added by
   this stack, see `## Config files` — `create-next-app` does not write an
   `engines` field itself, unlike a hand-authored library `package.json`)
   `package.json`'s `engines.node` floor.

3. **tsconfig.json** — `create-next-app` writes this file itself as part of
   scaffolding (there is no separate `tsc --init` step to run, unlike
   `ts-lib.md`). Confirm `"strict": true` is already set rather than
   assuming — verified present by default in a local Next.js 16.2.12 /
   App Router / TypeScript smoke scaffold, but templates have changed
   defaults before and could again; if a future template regresses, set it
   explicitly. Do not otherwise restructure this file (no `rootDir`/`outDir`
   edits): unlike `ts-lib.md`'s tsup-only library setup, Next's own generated
   tsconfig has no `rootDir` constraint and already includes
   `.next/types/**/*.ts` / `.next/dev/types/**/*.ts` in its `include` — `tsc
   --noEmit` does not choke on `vitest.config.mts` or a colocated
   `*.test.tsx` the way `ts-lib.md`'s tsup+`rootDir` combination did. Verified
   locally: after adding the Vitest config and a colocated test file (step 5
   below), `npx tsc --noEmit` ran clean with zero errors, no `include` fix
   needed.

4. **next.config.ts** — untouched. Leave `create-next-app`'s generated file
   (current scaffolds emit `next.config.ts`, not `next.config.js`, when
   `--typescript` is chosen — verified locally) exactly as generated. This
   stack file adds no Next-specific config here.

5. **Testing setup** — install the test toolchain and add one colocated test
   per component so `make ayce` has something real to run from the first
   commit:

   ```
   npm install -D vitest @testing-library/react @testing-library/jest-dom @vitejs/plugin-react jsdom
   ```

   Write `vitest.config.mts` and `vitest.setup.ts` (see `## Config files` for
   exact contents — note the `.mts` extension, not `.ts`), then add a
   colocated `app/page.test.tsx` (or one per existing page/component)
   exercising it through Testing Library's `render`/`screen` — behavior
   assertions (`getByText`, `getByRole`), not snapshots. Verified locally: a
   test rendering the scaffold's own `app/page.tsx` and asserting on its
   "Get started" copy passed under `npx vitest run` (1/1), and `next build`
   afterward did not treat the colocated `.test.tsx` file as a route (Next
   only special-cases `page`/`layout`/`route`/etc. file names, so colocated
   tests are safe to leave inside `app/`).

6. **`AGENTS.md` / `CLAUDE.md` interaction — read before writing `CLAUDE.md`.**
   This is the one stack where the native scaffold writes its own AI-agent
   instructions file, and it is worth keeping. With `--agents-md` on by
   default (Next 16+), `create-next-app` writes:
   - `AGENTS.md` — a short framework notice: *"This is NOT the Next.js you
     know... Read the relevant guide in `node_modules/next/dist/docs/`
     before writing any code. Heed deprecation notices."* (verified locally,
     quoted from an actual scaffold's output).
   - `CLAUDE.md` — a one-line file containing only `@AGENTS.md`, Claude
     Code's own file-import directive.

   Baseline's CLAUDE.md-skeleton step (`baseline.md` § CLAUDE.md skeleton)
   runs *after* native init in the layer order and would otherwise overwrite
   this one-line file outright. Don't let it: keep `AGENTS.md` verbatim, and
   when generating the real `CLAUDE.md`, prepend `@AGENTS.md` as the file's
   very first line, before baseline's "Definition of done" line — so the
   framework's own version-drift warning is the first thing pulled in, and
   the rest of baseline's skeleton plus this file's `## CLAUDE.md addenda`
   follow it.

7. **`.gitignore`** — `create-next-app` already writes one covering
   `/node_modules`, `/coverage`, `/.next/`, `/out/`, `/build`,
   `*.tsbuildinfo`, `next-env.d.ts`, env files, and more (verified locally) —
   this already satisfies everything `ts-lib.md`'s TypeScript-ignores list
   calls for. Don't re-append duplicates. The one line worth adding is
   baseline's `.idea/` (`create-next-app` doesn't write it).

## Toolchain

Write one line per **asdf/mise-manageable** tool into `.tool-versions`
(version resolved at scaffold time, never hardcoded here):

| Tool | Role | Notes |
|---|---|---|
| `nodejs` | runtime | the only line this stack needs in `.tool-versions` — same as `ts-lib.md`: real asdf/mise plugin support exists for `nodejs`; nothing else below does |

Everything below is a project **dev-dependency**, installed and pinned via
`npm`/`package-lock.json` (`next`/`react`/`react-dom`/`eslint`/
`eslint-config-next` are installed by `create-next-app` itself; the Vitest
stack is installed by this playbook in `## Init` step 5), not through
asdf/mise, and gets no `.tool-versions` line:

| Tool | Role | Installed by |
|---|---|---|
| `next`, `react`, `react-dom` | the framework | `create-next-app` |
| `typescript` | type-checking only (`tsc --noEmit`) | `create-next-app` |
| `eslint` + `eslint-config-next` | linting **and** (this stack's `fmt` convention) formatting-via-autofix | `create-next-app` |
| `vitest` | test runner | this playbook |
| `@testing-library/react` + `@testing-library/jest-dom` | component tests: render + behavior-focused matchers | this playbook |
| `@vitejs/plugin-react` | JSX transform for Vitest (Vitest's own default transform has no React JSX runtime) | this playbook |
| `jsdom` | DOM environment for Vitest | this playbook |

Rationale notes (feed these one-line whys into
`.okf/decisions/toolchain.md` during OKF seeding, do not restate them in
`CLAUDE.md` or the README):

- **Keep ESLint, don't switch to Biome.** `ts-lib.md` prefers Biome as one
  binary replacing Prettier + ESLint — this stack deliberately does **not**
  port that choice. `create-next-app`'s own generated `eslint.config.mjs`
  wires `eslint-config-next/core-web-vitals` plus `eslint-config-next/
  typescript`, which encode Next-specific rules with no Biome equivalent
  (`@next/next/no-img-element`, `no-html-link-for-pages`,
  `no-async-client-component`, and friends — several of them exist
  specifically to catch Server/Client Component mistakes). Replacing this
  with Biome would mean losing framework-specific lint coverage that only
  `eslint-config-next` provides. (`create-next-app` 16.x *can* scaffold with
  `--biome` instead of `--eslint` — the playbook's `## Init` deliberately
  pins `--eslint`, per the brief this stack file implements.)
- **No Prettier — state the trade-off honestly.** `eslint-config-next`'s
  flat config includes no Prettier-equivalent formatting ruleset. Accepting
  a narrower `fmt` phase (see `## Quality gate`) avoids introducing a second
  tool whose stylistic opinions could disagree with ESLint's own (the
  classic conflict `eslint-config-prettier` exists purely to paper over).
  This is a deliberate scope trade-off, not an oversight — document it in
  the project's own `.okf/decisions/toolchain.md`, not just here.
- **Vitest over the framework-default Jest.** `create-next-app` can wire
  Jest via `next/jest` (a config-wrapper plus `moduleNameMapper` and a
  jsdom environment setting), but that is more moving parts than Vitest's
  native ESM/TypeScript support needs, and it matches `ts-lib.md`'s test
  runner choice — the same mental model carries across both stacks.
  Verified locally: `@vitejs/plugin-react` is required in
  `vitest.config.mts` for JSX transform — omitting it fails rendering a
  `.tsx` component under test.
- **`@testing-library/jest-dom/vitest`, not the bare package import.**
  `@testing-library/jest-dom` ships both a Jest-flavored and a
  Vitest-flavored setup entrypoint; this stack's `vitest.setup.ts` imports
  the Vitest one.

## Config files

**tsconfig.json** — confirm `"strict": true` (see `## Init` step 3); no
other edits.

Write **`vitest.config.mts`** in the repo root — the `.mts` extension is
deliberate, not `.ts` (see the note below):

```typescript
import react from "@vitejs/plugin-react";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./vitest.setup.ts"],
  },
});
```

Write **`vitest.setup.ts`**:

```typescript
import "@testing-library/jest-dom/vitest";
```

Why `.mts` and not `.ts`: unlike `ts-lib.md`'s hand-authored `package.json`
(which sets `"type": "module"`), `create-next-app`'s generated `package.json`
does **not** set `"type": "module"` — Next's own build tooling doesn't need
it, and this stack does not add it just to satisfy Vitest. A plain
`vitest.config.ts` still works, but Vite's config loader prints a "features
unsupported by `configLoader: 'native'`" warning when it has to load ESM
config syntax from a file the surrounding `package.json` marks as CommonJS.
Verified locally: `vitest.config.ts` → benign warning, tests still pass;
renaming to `vitest.config.mts` → clean run, identical test outcome. Do not
"fix" this by adding `"type": "module"` to `package.json` instead — that is
a wider change than the warning warrants and is not something
`create-next-app` opts into on its own.

**next.config.ts** — untouched (see `## Init` step 4).

**eslint.config.mjs** — untouched. `create-next-app`'s own generated flat
config (`eslint-config-next/core-web-vitals` + `eslint-config-next/
typescript`) is the entirety of this stack's lint configuration. Do not add
a second config file, and do not add a legacy `.eslintrc.json` alongside it.

**`.gitignore`** — confirm `create-next-app`'s generated file already covers
`/node_modules`, `/coverage`, `/.next/`, `/out/`, `*.tsbuildinfo` (verified
locally); add baseline's `.idea/` line, which `create-next-app` doesn't
write.

For **`.editorconfig`**, add a TypeScript/TSX override: 2-space indent for
`*.ts`/`*.tsx`/`*.json` (same convention as `ts-lib.md`). This carries more
practical weight in this stack than in a Biome- or Prettier-formatted one:
since `fmt` here is ESLint autofix only (see `## Quality gate`), the editor's
own `.editorconfig` — not a project-wide formatter — is what actually keeps
indentation consistent between saves.

For the devcontainer, use the
`mcr.microsoft.com/devcontainers/typescript-node` image family; resolve the
current tag at scaffold time and keep it in agreement with `.tool-versions`.

**`package.json`'s `engines.node` floor** — `create-next-app` does not write
an `engines` field at all (verified: a fresh scaffold's `package.json` has
no `engines` key). Baseline's version-consistency rule still requires a
manifest pin here, same as every other stack, so add it by hand after
scaffolding:

```json
"engines": {
  "node": ">=<resolved-node-major>"
}
```

## Quality gate

Fill the baseline Makefile skeleton's phase bodies exactly as follows.
Never rename these seven targets, never change what `ayce` depends on:

```makefile
clean: ## remove build artifacts
	rm -rf .next out

fmt: ## format all sources
	npx eslint --fix .

build: ## compile/build
	npx next build

test: ## run all tests
	npx vitest run

lint: ## static analysis at the pedantic end
	npx eslint .
	npx tsc --noEmit

security-scan: ## dependency vulnerability scan
	./bin/security-scan

docs: ## build docs, fail on warnings
	@echo "docs: no-op — this project does not publish generated docs." \
	      "TSDoc comments on exported symbols satisfy the documentation" \
	      "bar (see CLAUDE.md addenda); there is no typedoc/similar step" \
	      "wired into this stack's default gate."
```

**Deviation from the brief, documented (same pattern as `go.md`'s `go doc`
note) — read this before assuming the brief's literal commands are current.**
The brief this stack file implements specifies `fmt = npx next lint --fix`
and `lint = npx next lint && npx tsc --noEmit`. `next lint` does not exist to
run anymore: it was deprecated with a warning in Next.js 15.5 and fully
**removed** in Next.js 16. Confirmed three ways: (1) Next's own "Upgrading to
Version 16" guide, under Removals: *"The `next lint` command has been
removed. Use Biome or ESLint directly. `next build` no longer runs
linting."*; (2) the ESLint Plugin reference page's changelog: *"`next lint`
and the `eslint` next.config.js option were removed in favor of the ESLint
CLI"*; (3) a local `create-next-app@latest` smoke scaffold resolving to Next
16.2.12 — the generated `package.json` ships `"lint": "eslint"`, not
`"lint": "next lint"`, and there is no `next lint` binary left to invoke.
This stack file follows the brief's **intent** — a framework-native,
lint-tool-driven `fmt`/`lint` convention, no Biome, no Prettier — using the
commands current `create-next-app` itself actually generates:
`npx eslint --fix .` for `fmt`, `npx eslint .` (plus `npx tsc --noEmit`) for
`lint`. Verified locally against the smoke scaffold: both commands ran clean
on the untouched scaffold, and a deliberately introduced `x: any` parameter
was caught by `npx eslint .` as a hard **error** (not a warning) via
`@typescript-eslint/no-explicit-any` from `eslint-config-next/typescript`,
exiting non-zero — confirming `lint` actually fails the gate on a real `any`,
not just on a lint warning that would be silently tolerated. If a project is
ever scaffolded against a pre-16 Next version where `next lint` still exists
(deprecated-but-present in 15.5.x), prefer `npx eslint` anyway — the
deprecation warning is the framework's own migration signal — and use
`npx @next/codemod@canary next-lint-to-eslint-cli .` to migrate an existing
project's scripts and generate `eslint.config.mjs` (see `## Update`).

**Honest scope of `fmt` in this stack — say plainly what it does and doesn't
cover.** `npx eslint --fix .` only applies ESLint's own autofixable rules
(unused-import removal, and whichever stylistic rules the config happens to
enable with an autofixer) — it is **not** a full-file formatter. Unlike
`ts-lib.md`'s Biome or other stacks' dedicated formatters, this stack's `fmt`
phase does **not** normalize whitespace, line-wrapping, quote style, or
trailing commas project-wide the way Prettier or Biome's formatter would.
The brief mandates no Prettier for this stack — accept this as the
deliberate trade-off it is (`eslint-config-next` handles style only
incidentally, as a side effect of a few autofixable rules, not as its
purpose), not as an oversight. If a project later wants real full-file
reformatting, adding Prettier or Biome is a deliberate, separate decision
outside this playbook's default — record it in `.okf/decisions/toolchain.md`
if taken, rather than letting `make fmt`'s name imply coverage it doesn't
have.

Notes on the rest of the gate:
- `build` runs `next build` directly — Turbopack is the default build engine
  as of Next.js 16 (no `--turbopack` flag needed any more); this stack
  doesn't override that default (see `## Init`'s "don't fight the framework"
  framing).
- `lint` runs two tools in sequence, same two-tool shape as `ts-lib.md`:
  `eslint` (Next-aware linting, including the Server/Client Component rules
  noted in `## Toolchain`) and `tsc --noEmit` (type-checking only — no emit;
  `next build` owns actual output). Both must pass for `lint` to succeed.
- `test` does not require a separate typecheck step for test files — Vitest
  transpiles `.test.tsx` the same as app code; type errors in test files
  still surface via `lint`'s `tsc --noEmit` pass.

Write `bin/security-scan`'s body (baseline owns the shebang/`set -euo
pipefail` skeleton and the `chmod +x` step):

```bash
npm audit --audit-level=high
```

This is the single definition of this stack's security checks — the
Makefile's `security-scan` target and the CI `security.yaml` workflow both
call this script. Unlike `ts-lib.md`'s belt-and-suspenders `npm audit` plus
optional `osv-scanner`, the brief for this stack pins `security-scan` to
exactly this one command — keep it to that; adding `osv-scanner` on top is a
deliberate addition beyond this stack's default, not part of it. Verified
locally: run against a fresh Next.js 16.2.12 scaffold's own dependency tree,
`npm audit --audit-level=high` exited non-zero (exit code 1) against two
real high-severity advisories already present in that tree (a `postcss`
XSS/path-traversal chain and a `sharp`→libvips CVE set) — confirming the
`--audit-level=high` floor actually fires on genuine high-severity findings
rather than passing silently.

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
      - uses: actions/cache@<resolved-major>
        with:
          path: |
            ~/.npm
            ${{ github.workspace }}/.next/cache
          key: ${{ runner.os }}-nextjs-${{ hashFiles('**/package-lock.json') }}-${{ hashFiles('**/*.js', '**/*.jsx', '**/*.ts', '**/*.tsx') }}
          restore-keys: |
            ${{ runner.os }}-nextjs-${{ hashFiles('**/package-lock.json') }}-
      - run: npm ci
      - run: npx next build
      - run: npx vitest run
      - run: npx eslint .
      - run: npx tsc --noEmit
```

The `actions/cache` step is ported verbatim (path list and key/restore-keys
expressions) from Next.js's own official GitHub Actions guidance in its
CI-build-caching guide — do not hand-roll a different key scheme; this one
is what the framework's own docs recommend for `.next/cache` specifically.

Replace `"<resolved-node-version>"` in the matrix with the actual version
string resolved during Init (the same one written to `.tool-versions` and
`engines.node`'s floor) — do not leave the placeholder literal in the
generated file. Use `npm ci`, not `npm install`, in CI.

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
      - run: ./bin/security-scan
```

## CLAUDE.md addenda

Copy this section verbatim into the target repo's `CLAUDE.md`, after the
baseline's "Definition of done" and "Knowledge bundle pointer" sections —
and after the `@AGENTS.md` import line noted in `## Init` step 6:

---

### Next.js: Testing Requirements

- Components, hooks, and exported utilities are tested via **Testing
  Library** (`@testing-library/react`), asserting on rendered *behavior*
  (what a user sees/can do) — `getByRole`/`getByText`/user-event
  interactions — never on a serialized snapshot of markup. A snapshot test
  passes when the DOM changes in any way, intentional or not; a
  behavior-focused query only fails when the thing the user actually cares
  about breaks.
- Colocate each test as `<file>.test.tsx` next to the component/module it
  tests, same convention as `ts-lib.md`.
- Cover loading, error, and empty states for components that have them, not
  just the populated happy path.
- Prefer `@testing-library/jest-dom` matchers (`toBeInTheDocument`,
  `toHaveTextContent`, etc.) over manual DOM assertions — they produce
  clearer failure messages and read closer to the behavior being verified.

### Next.js: Server/Client Component Boundary

- Every component file's Server-vs-Client status must be **documented, not
  just implied by the presence or absence of `"use client"`.** A component
  that opts into Client rendering gets a one-line comment above the
  directive stating *why* (state, effects, event handlers, a browser-only
  API, a third-party library that requires the client) — the directive
  alone tells a reader *that* it's a Client Component, not *why* it had to
  be.
- Push the `"use client"` boundary as far down the tree as possible (leaf
  components that actually need interactivity), not up at a layout or page
  root — hoisting it unnecessarily drags everything beneath it into the
  client bundle and gives up Server Component rendering for the whole
  subtree.
- When a Server Component passes data to a Client Component, keep the props
  crossing that boundary serializable (no functions, no class instances,
  no `Date`-as-object assumptions) — this is a real runtime failure mode,
  not just a style preference.

### Next.js: Type Safety

- Never use `any` to silence a type error. `eslint-config-next/typescript`
  enables `@typescript-eslint/no-explicit-any` as a hard **error**, not a
  warning — verified locally: a deliberately introduced `any` parameter
  failed `npx eslint .` with a non-zero exit, no `--max-warnings` flag
  needed to make it fail the gate. If a value genuinely can't be typed
  precisely yet, use `unknown` and narrow it, or silence the specific line
  with a targeted `// eslint-disable-next-line
  @typescript-eslint/no-explicit-any -- <reason>` comment, never a blanket
  config-level suppression.
- Prefer the typed helpers Next.js generates for dynamic route props
  (`PageProps<'/route/[slug]'>`, `LayoutProps`, `RouteContext` — available
  via `npx next typegen`) over hand-writing `params`/`searchParams` types,
  so async-params changes across Next versions type-check instead of
  silently returning `any`-shaped data.

### Next.js: Code Organization

- Keep functions and components focused and single-purpose.
- Extract complex logic into well-named helper functions or custom hooks
  rather than growing a single component.
- Group related types and functions into modules; only export from a
  route's `page.tsx`/`layout.tsx`/`route.tsx` what Next's own file
  conventions require (default export, named `generateMetadata`, etc.) —
  everything else stays a module-private implementation detail.
- Colocate a component's test file (and, where used, its styles/types)
  next to it rather than mirroring the structure in a parallel `__tests__`
  tree.
- Avoid deep relative import chains (`../../../lib/foo`) — use the
  project's `@/*` import alias (`create-next-app`'s own default, chosen
  during `## Init`'s interview) instead of adding more path segments.

---

## Update

On `/dev-playbook update` for a Next.js repo:

1. `npx npm-check-updates -u && npm install` — bump `package.json`'s
   dependency ranges to their latest versions and refresh
   `package-lock.json` to match (same first step as `ts-lib.md`).
2. **For a Next.js major version bump specifically, don't rely on step 1
   alone** — run the framework's own migration tool instead:

   ```
   npx @next/codemod@latest upgrade major
   ```

   (`upgrade` accepts `patch`/`minor`/`major`, an npm dist-tag such as
   `latest`/`canary`, or an exact version like `16.0.0` — defaults to
   `minor` if omitted; verified against Next's own Codemods reference.) This
   both bumps `next`/`react`/`react-dom` together — avoiding the classic
   "React version drifts out of sync with Next" foot-gun a generic
   `npm-check-updates` run can't prevent — and runs whichever codemods that
   version actually needs (e.g. the 16.0 `middleware`→`proxy` rename, the
   `next lint`→ESLint-CLI migration if a project somehow still had the old
   form). Re-run `make lint` and `make build` afterward — a Next major is
   exactly the kind of change that can introduce new ESLint findings or type
   errors the codemod didn't catch.
3. If `eslint`'s own major version moves independently of Next (`
   eslint-config-next` pins compatible ranges, but a standalone `eslint`
   bump can still drift ahead of what it expects), re-verify
   `eslint.config.mjs`'s flat-config shape still loads cleanly. Next 16
   already moved `@next/eslint-plugin-next` to flat-config-by-default
   (verified in Next's own v16 upgrade notes, "ESLint Flat Config" section),
   so this is a settled format for the resolvable future — but treat an
   ESLint major bump as a real compatibility axis to re-check regardless,
   same spirit as `ts-lib.md`'s `typescript`/`tsup` pairing.
4. Re-resolve the Node.js version if the user wants to raise the floor
   (Next.js itself may raise its own minimum — Next 16 requires Node 20.9+
   — so check the target Next version's own requirement isn't already ahead
   of the project's current floor); otherwise leave it as-is.
5. Propagate any version change across all of this stack's version-consistency-rule
   locations, per baseline's propagation table:
   - `package.json`'s `engines.node` floor (this stack adds this field by
     hand — see `## Config files` — `create-next-app` doesn't write it)
   - `.tool-versions`' `nodejs` line
   - `ci.yaml`'s `build` job matrix `node-version` entries
   - `.devcontainer/devcontainer.json`'s image tag
6. Run `make security-scan` after any dependency-version change — catches
   newly introduced advisories in the updated lockfile before they land.
   (This is the same `bin/security-scan` script from `## Quality gate` —
   don't invoke `npm audit` directly here either.)
7. Run `make ayce` and confirm it is green before considering the update
   done.
