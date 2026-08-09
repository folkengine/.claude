# Go — stack file

Read together with `references/baseline.md`. This file is instructions for
you, the executing agent — carry out each section as a step, don't just
summarize it. Apply after the stack's native init has already run, following
baseline's layer order: baseline files → AI files → stack configs (this
file's Config files / Quality gate / CI sections) → `.okf/` seeding.

## Init

1. Interview the user for the **module path** — the import path other code
   will use, e.g. `github.com/<owner>/<repo>` (or the equivalent path for
   whatever host/org actually hosts the repo; it does not have to be
   GitHub). Run:

   ```
   go mod init <module path>
   ```

   This also stamps a `go` directive in `go.mod` at whatever toolchain
   version is installed locally — confirm it matches the resolved current
   stable version from step 2 below rather than leaving a stale local one.
2. Interview: **library or command?** (a repo may be both — ask which
   shape applies now; add the other later as needed).
   - Library: keep the package at the repo root. Write a starter file
     (e.g. `<name>.go`) with a package-level doc comment and one exported
     function, so `## Quality gate`'s `docs`/`test` phases have something
     real to exercise.
   - Command (binary): write `main.go` at the repo root for a single
     binary. If the project anticipates **multiple** binaries, ask and use
     `cmd/<name>/main.go` per binary instead (the standard multi-command
     layout) — keep the repo root free of `main.go` in that case.
3. Resolve the **Go version** at scaffold time — never hardcode one from
   memory. Ask the user if they have a floor, otherwise use current
   stable. Make sure `go.mod`'s `go` directive reflects it; this value
   must agree with `.tool-versions`, the CI matrix, and the devcontainer
   image tag — the version-consistency rule from baseline applies here
   from the first commit onward.
4. Interview: **which OSS license(s)?** — feeds baseline's `LICENSE-*`
   copy step. Unlike Rust's `deny.toml` allow-list, Go's security scanner
   (`govulncheck`, below) checks for known *vulnerabilities*, not license
   compliance, so there is no second config file that needs to stay in
   sync with this choice (same situation as Python's `pip-audit`).

## Toolchain

Write one line per **asdf/mise-manageable** tool into `.tool-versions`
(version resolved at scaffold time, never hardcoded here):

| Tool | Role | Notes |
|---|---|---|
| `golang` | compiler/toolchain (`go build`/`test`/`vet`, module tooling) | `go.mod`'s `go` directive tracks this; asdf's plugin name is `golang`, the binary is still `go` |
| `golangci-lint` | one runner for `go vet` + staticcheck + errcheck + revive (linting) *and* gofumpt (formatting) | this file's `.golangci.yaml` targets the **v2** config schema — run `golangci-lint version` and confirm the installed major is 2.x before trusting this config; v1 uses a different schema (see `## Config files`) |

Everything below the line is installed *through* `go install`/`go run`, not
through asdf/mise, and gets no `.tool-versions` line:

| Tool | Role | How it's installed / invoked |
|---|---|---|
| `govulncheck` | dependency + standard-library vulnerability scanner | not installed persistently; invoked ephemerally via `go run golang.org/x/vuln/cmd/govulncheck@latest ./...`, see `bin/security-scan` below |
| `pkgsite` | local doc-browsing server (interactive `godoc`-style UI) | optional, not part of the gate; run on demand via `go run golang.org/x/pkgsite/cmd/pkgsite@latest` |

Rationale notes (feed these one-line whys into
`.okf/decisions/toolchain.md` during OKF seeding, do not restate them in
`CLAUDE.md` or the README):

- **golangci-lint as the one runner** — bundles `go vet`, staticcheck,
  errcheck, and revive as linters, and gofumpt as a formatter, behind one
  binary and one config file; avoids hand-assembling five separate tools
  with five separate invocations and five separate version drifts.
- **gofumpt via golangci-lint's `formatters` section, not a standalone
  binary** — v2's `golangci-lint fmt` subcommand runs the configured
  formatters directly, so there is no separate gofumpt install or version
  to track; `fmt` and `lint` share one dependency.
- **govulncheck** — the Go team's own scanner; it distinguishes
  vulnerable symbols the code actually *calls* from vulnerabilities in
  code merely *imported but unreachable*, which is lower-noise than a
  plain "is this module version on an advisory list" check. It ships as
  an `x/` tool, not part of the standard toolchain, so it is invoked
  ephemerally via `go run ...@latest` rather than kept as a persistent
  dependency or asdf-managed tool.
- **pkgsite noted, not gated** — `## Quality gate`'s `docs` phase is a
  compile/render *smoke check* only (see below), not full site
  generation; `pkgsite` is how a developer actually browses rendered
  docs locally, but it is not part of `ayce`.

## Config files

Write `.golangci.yaml` in the repo root, **v2 schema** (the `version: "2"`
key at top is what selects this schema — golangci-lint v1 uses a flat
`linters:`/`linters-settings:` layout with no `formatters:` section and no
top-level `version` key; if the installed major is 1.x, do not use this
file verbatim, consult that version's migration docs or run `golangci-lint
migrate` instead):

```yaml
version: "2"

linters:
  enable:
    - errcheck
    - govet
    - staticcheck
    - revive

formatters:
  enable:
    - gofumpt
```

Notes:
- `errcheck`, `govet`, and `staticcheck` are already on by default under
  golangci-lint v2's standard linter set (along with `ineffassign` and
  `unused`, which stay enabled too); listing them explicitly here is
  intentional self-documentation, not redundant — it makes the pedantic
  intent visible in the config file itself rather than relying on
  whatever golangci-lint's shipped defaults happen to be this release.
  `enable:` *adds* to the standard set; it does not replace it.
- `revive` is the one addition beyond golangci-lint v2's defaults — it is
  what catches undocumented exported identifiers (see `## CLAUDE.md
  addenda` below) and a broader style-lint set than `go vet` alone.

Add Go-specific ignores to the shared `.gitignore` (baseline writes the
file; these are the Go-specific lines):

```
/out/
*.test
*.out
```

(`out/` matches this file's `clean`/`build` recipes below — see
`## Quality gate`. Never ignore `bin/`: it holds the **tracked**
`bin/security-scan` script, and ignoring it would keep the script out of
the repo and break CI's `./bin/security-scan` step on a fresh clone.)

For `.editorconfig`, add a Go override: tabs (not spaces) for `*.go` —
gofmt/gofumpt both indent with tabs and will fight a spaces override.

For the devcontainer, use the `mcr.microsoft.com/devcontainers/go` image
family; resolve the current tag at scaffold time and keep it in agreement
with `.tool-versions`.

## Quality gate

Fill the baseline Makefile skeleton's phase bodies exactly as follows.
Never rename these seven targets, never change what `ayce` depends on:

```makefile
clean: ## remove build artifacts
	go clean ./...
	rm -rf out

fmt: ## format all sources
	golangci-lint fmt

build: ## compile/build
	go build -o out/ ./...

test: ## run all tests
	go test ./...

lint: ## static analysis at the pedantic end
	golangci-lint run

security-scan: ## dependency vulnerability scan
	./bin/security-scan

docs: ## build docs, fail on warnings
	go list ./... | xargs -n1 go doc > /dev/null
```

Notes:
- `fmt` runs `golangci-lint fmt`, not a bare `gofumpt -w .` — v2's `fmt`
  subcommand reads the `formatters:` section of `.golangci.yaml` and
  applies exactly what's configured there (gofumpt), so the formatter
  list stays defined in one place instead of split between the Makefile
  and the config file.
- `build` writes binaries to `out/` (`go build -o out/ ./...`) so `clean`
  has something concrete to remove; for a library-only repo with no
  `main` package, `go build ./...` alone still compiles and type-checks
  everything without producing a binary — `-o out/` is a no-op path in
  that case and is safe to leave in place. Build output must **never**
  target `bin/`: that directory belongs to the repo's tracked scripts
  (`bin/security-scan`), and pointing `build`/`clean` at it would make
  the first `make ayce` delete the very script its `security-scan` phase
  runs next.
- `docs` is a **smoke check**, not full documentation generation: `go
  doc` does not accept the `./...` wildcard directly (it errors with "too
  many periods in symbol specification" if you try `go doc ./...`) —
  `go list ./...` enumerates the module's packages and `go doc` is run
  once per package instead, failing the phase if any package fails to
  resolve/render. This is intentionally the same "does it compile
  cleanly enough to document" bar as Rust's warning-free `cargo doc`,
  scaled to what `go doc` actually supports. For interactively *browsing*
  rendered docs, use `pkgsite` (`## Toolchain`), which is not part of
  this gate.

Write `bin/security-scan`'s body (baseline owns the shebang/`set -euo
pipefail` skeleton and the `chmod +x` step):

```bash
go run golang.org/x/vuln/cmd/govulncheck@latest ./...
```

This is the single definition of Go's security checks — the Makefile's
`security-scan` target and the CI `security.yaml` workflow both call this
script; do not duplicate the `govulncheck` invocation anywhere else.

## CI

Generate `.github/workflows/ci.yaml` from baseline's triggers block (push,
pull_request, monthly cron) with these jobs. Use `actions/setup-go@<resolved-major>` for
toolchain setup, reading the version from `go.mod` (`go-version-file:
go.mod`) so the CI toolchain can never drift from the manifest pin. Resolve
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
  test:
    name: Test
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@<resolved-major>
      - uses: actions/setup-go@<resolved-major>
        with:
          go-version-file: go.mod
      - run: go build -o out/ ./...
      - run: go test ./...

  lint:
    name: Lint
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@<resolved-major>
      - uses: actions/setup-go@<resolved-major>
        with:
          go-version-file: go.mod
      - uses: golangci/golangci-lint-action@<resolved-major>
        with:
          version: latest
```

`golangci-lint-action` from v7 onward supports the v2 config schema only
(v6 and earlier assumed v1) — confirm whichever major you pin here still
matches the `version: "2"` schema in `.golangci.yaml`; if a future major
drops v2 support or a project pins an older golangci-lint intentionally,
adjust both together.

Generate `.github/workflows/security.yaml` per baseline's exact verbatim
shape, inserting this stack's toolchain setup step (daily cron, unchanged
from baseline). The snippet below starts *after* baseline's own
`actions/checkout@<resolved-major>` step — do not repeat that step here, baseline's
skeleton already has it:

```yaml
      - uses: actions/setup-go@<resolved-major>
        with:
          go-version-file: go.mod
      - run: ./bin/security-scan
```

## CLAUDE.md addenda

Copy this section verbatim into the target repo's `CLAUDE.md`, after the
baseline's "Definition of done" and "Knowledge bundle pointer" sections:

---

### Go: Testing Requirements

- Every public function must have at least one test covering the happy
  path, plus edge cases and error conditions.
- Prefer **table-driven tests**: a slice of struct cases (`name`, inputs,
  expected output/error) run through one `t.Run(tt.name, func(t
  *testing.T) {...})` loop, rather than one hand-written test function
  per case. This is the idiomatic Go pattern and keeps new cases a
  one-line addition.
- Name tests `Test<FunctionOrType>_<scenario>`; name table-driven
  sub-tests (the `tt.name` field) as short scenario descriptions, not
  restatements of the input.
- Use `t.Parallel()` for independent test cases where safe, to keep the
  suite fast as it grows.

### Go: Documentation Requirements

- Every exported identifier (function, type, method, constant, package)
  must have a doc comment starting with the identifier's own name, per Go
  convention (`// Foo does X.`, not `// This function does X.`).
  `golangci-lint run`'s `revive` linter enforces this — an undocumented
  exported identifier is a lint failure, not a style suggestion.
- Package-level doc comments (`// Package <name> ...`, placed directly
  above the `package` clause, in a `doc.go` file for larger packages) must
  explain the package's purpose and, for non-trivial packages, basic
  usage.
- Prefer runnable `Example` functions (`func ExampleFoo() { ... // Output:
  ... }`) for non-trivial public APIs — they double as documentation
  rendered by `go doc`/`pkgsite` and as tests `go test` actually executes.

### Go: Error Handling

- Wrap errors with context using `%w`, never `%v` or string
  concatenation, when propagating an error up the call stack:
  `fmt.Errorf("reading config: %w", err)`. This preserves the original
  error for `errors.Is`/`errors.As` callers.
- Never discard an error with `_` unless the reason is genuinely safe and
  said so in a comment at the call site; `errcheck` (enabled in
  `.golangci.yaml`) fails the build on silently dropped errors.
- Define sentinel errors (`var ErrNotFound = errors.New(...)`) for
  conditions callers need to check programmatically; use `errors.Is`/
  `errors.As` to check, never string-compare `err.Error()`.
- Return errors, don't panic, from library code; reserve `panic` for
  truly unrecoverable programmer errors, and never let one cross a
  package boundary uncaught.

### Go: Naming

- `camelCase` for unexported identifiers, `PascalCase` for exported ones;
  package names are short, lowercase, and not `snake_case` or
  `mixedCaps`.
- Avoid stutter: a type `Client` in package `http` is `http.Client`, not
  `http.HTTPClient` — the package name is the namespace.
- Avoid single-letter names except loop indices (`i`, `j`, `k`) and
  well-known short-lived receivers (`c *Client`); prefer full words for
  anything with meaningful scope.

### Go: Code Organization

- Keep functions focused and single-purpose.
- Extract complex logic into well-named helper functions.
- Group related types and functions into logical packages — a package
  should have one clear responsibility, not be a catch-all `utils`.
- Export deliberately: keep a type, function, or field unexported unless
  something outside the package genuinely needs it; a smaller exported
  surface is easier to keep backward-compatible.

---

## Update

On `/dev-playbook update` for a Go repo:

1. `go get -u ./...` (bump direct and indirect dependencies to their
   latest compatible versions), then `go mod tidy` (prune unused
   requires, add anything newly needed, resync `go.sum`).
2. Re-resolve the Go version if the user wants to raise the floor (e.g.
   to pick up a new language feature); otherwise leave `go.mod`'s `go`
   directive untouched.
3. Propagate any version change across all of this stack's
   version-consistency-rule locations, per baseline's propagation table:
   - `go.mod`'s `go` directive
   - `.tool-versions`' `golang` line
   - `ci.yaml`'s `actions/setup-go` step (already reads `go-version-file:
     go.mod`, so this one updates itself — just confirm it still points
     at `go.mod` and hasn't drifted to a hardcoded `go-version:`)
   - `.devcontainer/devcontainer.json`'s image tag
4. Run `make security-scan` after any dependency-version change — catches
   newly introduced advisories in the updated module graph before they
   land. (This is the same `bin/security-scan` script from `## Quality
   gate` — don't invoke `govulncheck` directly here either.)
5. Run `make ayce` and confirm it is green before considering the update
   done.
