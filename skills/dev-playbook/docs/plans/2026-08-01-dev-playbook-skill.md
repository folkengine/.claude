# dev-playbook Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the global `/dev-playbook` skill that scaffolds production-quality repos per stack and updates existing ones, per the approved spec at `~/.claude/skills/dev-playbook/docs/2026-08-01-dev-playbook-skill-design.md`.

**Architecture:** A skill directory: `SKILL.md` orchestrates two flows (scaffold, update); `references/baseline.md` holds all stack-agnostic content; eight `references/<stack>.md` files each follow an identical 7-section template; `assets/` holds byte-stable files (licenses, CoC, templates). A run reads baseline + exactly one stack file.

**Tech Stack:** Markdown skill files; source material ported from `/Users/christoph/src/github.com/devplaybooks/*` (esp. `rs_blank`); OKF plugin scripts at `/Users/christoph/.claude/plugins/cache/scaccogatto/okf/0.4.0/skills/`.

## Global Constraints

- **Never run state-changing git commands** (user's global CLAUDE.md). No commit steps in this plan; `~/.claude/skills/dev-playbook/` is not a git repo. Each task ends with a verification step instead of a commit.
- Every scaffold's Makefile MUST have `ayce` (clean → format → build → test → lint → security-scan → docs) as the `default` target, plus `help` and `security-scan` targets.
- `bin/security-scan` is the single definition of security checks; Makefile and CI workflows are thin callers.
- CI cron: monthly for `ci.yaml`, **daily** for `security.yaml`.
- Version-consistency rule: `.tool-versions`, CI matrix, devcontainer image, and manifest pins must agree; both flows enforce it.
- Stack keys are exactly: `rust`, `python`, `go`, `java`, `cpp`, `c`, `ts-lib`, `ts-next`.
- OKF: every concept file has non-empty `type` frontmatter; root `index.md` carries `okf_version: "0.1"`; validate with the okf plugin's checker when present.
- Exact tool/language versions are NEVER hardcoded in skill files — resolved at run time ("current stable" or user pin). Allowed exceptions: `@vN` GitHub Action major pins, cron strings, `okf_version: "0.1"`, JDK 21 as interview *default*, C/C++ language-standard literals (`-std=c17`, `CMAKE_CXX_STANDARD 20` — standards, not tool versions), and versions inside narrative "verified with X" evidence notes (never inside generated-file snippets).
- All test scaffolds go in the session scratchpad, never in real project dirs.
- Skill authoring follows superpowers:writing-skills conventions (frontmatter with `name` + trigger-rich third-person `description`; concise imperative voice).

---

### Task 1: SKILL.md — the orchestrator

**Files:**
- Create: `~/.claude/skills/dev-playbook/SKILL.md`

**Interfaces:**
- Produces: the flow contract every later reference file plugs into: scaffold flow reads `references/baseline.md` + `references/<stack>.md`; update flow reads the same pair after stack detection. Stack keys as in Global Constraints.

- [ ] **Step 1: Invoke superpowers:writing-skills** to load current authoring conventions before writing.

- [ ] **Step 2: Write SKILL.md** with this content (adjust wording to writing-skills conventions, keep all structure):

````markdown
---
name: dev-playbook
description: Scaffold a production-quality repository for a chosen language and toolchain (rust, python, go, java, cpp, c, ts-lib, ts-next) directly in the target directory — native init plus opinionated quality gates, CI, security scanning, CLAUDE.md, and an OKF knowledge bundle. Also updates an existing playbook repo's toolchain and dependencies to latest or to pinned versions. Use when the user types /dev-playbook, asks to start or scaffold a new project/repo/library in one of these stacks, or asks to bump/update a playbook repo's dependencies or language version. Replaces forking the devplaybooks GitHub org templates.
---

# Dev Playbook

Scaffold repos the devplaybooks way: opinionated supporting files layered on top
of the stack's native init, no application code beyond hello-world, and a quality
gate that is green before the first commit. "Cruel to be kind in the right
measure."

## How to read this skill

Always read `references/baseline.md` plus exactly ONE stack file from the
roster. Never read more than one stack file per run.

## Stack roster

| Key | Reference | Stack-specific questions |
|---|---|---|
| rust | references/rust.md | lib vs bin |
| python | references/python.md | lib vs app |
| go | references/go.md | module path |
| java | references/java.md | maven vs gradle; JDK version (default 21) |
| cpp | references/cpp.md | cmake vs bazel; gtest vs catch2 (bazel→gtest only) |
| c | references/c.md | — |
| ts-lib | references/ts-lib.md | — |
| ts-next | references/ts-next.md | — (create-next-app runs its own) |

## Flow 1: Scaffold

`/dev-playbook [stack] [name] [--<tool> <version> ...]`

1. **Interview** — ask only what wasn't given, one question at a time:
   stack → project name → stack-specific questions (roster) → license(s)
   (default: all three of MIT, Apache-2.0, GPLv3) → target directory
   (default `./<name>`) → version targeting (default: current stable;
   accept pins like `--python 3.11`).
2. **Preflight** — target dir must not exist or be empty, else STOP and ask.
   Native tool must be installed, else STOP and report the install command
   (prefer `mise install`). Resolve every version now (ask the toolchain,
   e.g. `rustup check`, `uv python list`; never guess from memory).
3. **Native init** — run the stack's init command (stack file, section Init).
4. **Layer** — apply baseline layers (baseline.md) then stack layer
   (stack file, sections Config/Gate/CI). Order: baseline files → AI files →
   stack configs.
5. **Knowledge** — seed `.okf/` last (baseline.md, OKF section), so toolchain
   decisions exist to record.
6. **Verify** — run `make ayce`; iterate on failures until green. If still red
   after ~3 distinct fix attempts, deliver anyway and state plainly which
   target fails and why. Never claim green that isn't.
7. **Validate OKF** — run the okf validator (baseline.md, OKF section). If the
   plugin is absent, say validation was skipped.
8. **Hand off** — print, never run:

   ```
   git init && git add -A && git commit -m "chore: scaffold <name> via dev-playbook (<stack>)"
   gh repo create <name> --public --source=. --push   # optional
   ```

## Flow 2: Update

`/dev-playbook update [--<tool> <version> ...]` inside an existing repo.

1. **Detect** stack from `.tool-versions` + manifests (Cargo.toml,
   pyproject.toml, go.mod, pom.xml/build.gradle*, CMakeLists.txt/MODULE.bazel,
   Makefile+configure, package.json). Read the matching stack file. On a repo
   that only partially matches playbook conventions, list what was and wasn't
   recognized and touch only the recognized parts.
2. **Dirty-tree check** — `git status --porcelain`; if dirty, warn and get
   explicit go-ahead before touching files (reading git state is allowed;
   changing it is not).
3. **Resolve targets** — latest stable per tool, overridden by explicit pins.
4. **Propagate versions** to all four locations: `.tool-versions`, CI matrix,
   devcontainer image, manifest pins. Bump GitHub Actions `uses:` versions too.
5. **Update dependencies** — run the stack file's Update-section commands.
6. **Verify** — `make ayce` to green, security-scan included. If an upgrade
   breaks the build, report the offender and offer to hold it back pinned so
   the rest lands.
7. **Record** — append dated `.okf/log.md` entry; update
   `.okf/decisions/toolchain.md` if a tool (not just a version) changed.
8. **Hand off** — report what changed and why; print git commands, never run.

## Hard rules

- Never run state-changing git commands. Print them for the user.
- `make ayce` is always the default Makefile target; its meaning never varies.
- One security-scan definition (`bin/security-scan`); Makefile and CI call it.
- The four version-declaring locations always agree.
- Report failures plainly; never claim a green gate that isn't.
- Offline or registry unreachable: do what is possible, then list exactly which
  steps (version resolution, dependency fetch, advisory databases) need
  connectivity to finish.
````

- [ ] **Step 3: Verify** — `wc -l ~/.claude/skills/dev-playbook/SKILL.md` (expect < 200) and confirm frontmatter parses: first line `---`, has `name:` and `description:`.

---

### Task 2: assets/ — byte-stable files

**Files:**
- Create: `~/.claude/skills/dev-playbook/assets/licenses/LICENSE-MIT`
- Create: `~/.claude/skills/dev-playbook/assets/licenses/LICENSE-APACHE`
- Create: `~/.claude/skills/dev-playbook/assets/licenses/LICENSE-GPLv3`
- Create: `~/.claude/skills/dev-playbook/assets/CODE_OF_CONDUCT.md`
- Create: `~/.claude/skills/dev-playbook/assets/SECURITY.md.tmpl`
- Create: `~/.claude/skills/dev-playbook/assets/CONTRIBUTING.md.tmpl`

**Interfaces:**
- Produces: template placeholders used by baseline.md: `{{project}}`, `{{year}}`, `{{owner}}`. Scaffold copies licenses verbatim except placeholder lines.

- [ ] **Step 1: Copy license and CoC sources**

```bash
mkdir -p ~/.claude/skills/dev-playbook/assets/licenses
cp /Users/christoph/src/github.com/devplaybooks/rs_blank/LICENSE-MIT ~/.claude/skills/dev-playbook/assets/licenses/LICENSE-MIT
cp /Users/christoph/src/github.com/devplaybooks/rs_blank/LICENSE-APACHE ~/.claude/skills/dev-playbook/assets/licenses/LICENSE-APACHE
cp /Users/christoph/src/github.com/devplaybooks/rs_blank/LICENSE-GPL3.0 ~/.claude/skills/dev-playbook/assets/licenses/LICENSE-GPLv3
cp /Users/christoph/src/github.com/devplaybooks/rs_blank/CODE_OF_CONDUCT.md ~/.claude/skills/dev-playbook/assets/CODE_OF_CONDUCT.md
```

- [ ] **Step 2: Parameterize copyright lines** — in `LICENSE-MIT`, replace the `Copyright (c) ...` line with `Copyright (c) {{year}} {{owner}}`. In `LICENSE-APACHE`, if it contains a filled-in copyright boilerplate line, parameterize the same way; the GPL text has no per-owner line — leave byte-identical.

- [ ] **Step 3: Write SECURITY.md.tmpl** — base on `/Users/christoph/src/github.com/devplaybooks/rs_blank/SECURITY.md`; replace the project name with `{{project}}` and any contact/repo URLs with `{{owner}}`/`{{project}}` forms. Keep it short: supported-versions table (single row: latest), and "report via GitHub security advisories".

- [ ] **Step 4: Write CONTRIBUTING.md.tmpl** — base on `/Users/christoph/src/github.com/devplaybooks/rs_blank/CONTRIBUTING.md`; substitute `{{project}}`; state the one non-negotiable: "run `make ayce` before opening a PR — CI runs the same checks."

- [ ] **Step 5: Verify** — `grep -rl '{{' ~/.claude/skills/dev-playbook/assets/` lists MIT (and APACHE if parameterized) + both `.tmpl` files; `grep -c '{{' assets/licenses/LICENSE-GPLv3` is 0.

---

### Task 3: references/baseline.md — the stack-agnostic playbook

**Files:**
- Create: `~/.claude/skills/dev-playbook/references/baseline.md`

**Interfaces:**
- Consumes: `assets/` paths and placeholders from Task 2.
- Produces: the layer procedure and the Makefile/bin/CI/OKF/CLAUDE.md skeletons that every stack file's sections 3–5 plug concrete values into. Stack files refer to phases by these exact names: `clean`, `fmt`, `build`, `test`, `lint`, `security-scan`, `docs`.

- [ ] **Step 1: Write baseline.md** with these sections and content:

**§ Files every scaffold gets** — checklist table: licenses (per choice, from `assets/licenses/`, substitute `{{year}}`=current year, `{{owner}}`=git config user.name or asked), CODE_OF_CONDUCT.md (verbatim), SECURITY.md + CONTRIBUTING.md (from `.tmpl`, substitute), README.md, .gitignore (stack-appropriate + always `.idea/`), .editorconfig, .yamllint (port `/Users/christoph/src/github.com/devplaybooks/.baseline/.yamllint`), .tool-versions, Makefile, bin/security-scan, .github/workflows/ci.yaml, .github/workflows/security.yaml, .devcontainer/devcontainer.json, CLAUDE.md, .github/copilot-instructions.md, .okf/.

**§ README shape** — badge row (CI workflow badge, Contributor Covenant, one badge per chosen license — port badge markdown from `/Users/christoph/src/github.com/devplaybooks/rs_blank/README.md` lines 1–7), one-paragraph description, "How to use", "What's in the box" as a bullet list where each rationale links into `.okf/decisions/toolchain.md` instead of duplicating prose, `make help` mention.

**§ .tool-versions** — asdf syntax (mise-compatible). One line per runtime/tool the stack file names. State the **version-consistency rule** verbatim: ".tool-versions, the CI matrix, the devcontainer image, and manifest pins (rust-version, requires-python, engines, java toolchain) MUST agree; verify all four whenever any changes."

**§ Makefile contract** — include this skeleton (stack files fill the phase bodies):

```makefile
.PHONY: default help clean fmt build test lint security-scan docs ayce
default: ayce

help:  ## self-documenting: every target has a '## comment' printed here
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-16s %s\n", $$1, $$2}'

clean: ## remove build artifacts
fmt: ## format all sources
build: ## compile/build
test: ## run all tests
lint: ## static analysis at the pedantic end
security-scan: ## dependency vulnerability scan
	./bin/security-scan
docs: ## build docs, fail on warnings
ayce: clean fmt build test lint security-scan docs ## all-you-can-eat: full pre-push sweep
```

Rule: `ayce` is ALWAYS `default`; phase names never vary; stacks may add extra targets but never rename these.

**§ bin/ scripts** — `bin/security-scan`: `#!/usr/bin/env bash`, `set -euo pipefail`, stack file supplies the scanner commands; `chmod +x`. No check logic in Makefile or workflows — both call the script.

**§ CI workflows** — `ci.yaml`: triggers push/PR + monthly cron (`40 1 1 * *`); jobs from stack file section 5; every job pins tool versions consistent with `.tool-versions`. `security.yaml`: this exact shape (runner setup step comes from the stack file):

```yaml
name: Security
on:
  push:
  schedule:
    - cron: "17 4 * * *"   # daily — new advisories appear every day
jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # <stack toolchain setup steps here>
      - run: ./bin/security-scan
```

**§ Devcontainer** — `.devcontainer/devcontainer.json` using the current Microsoft image for the stack (stack file names it); image tag must agree with `.tool-versions`.

**§ CLAUDE.md skeleton** — generated file contains: (1) "Definition of done: `make ayce` passes. Run it before claiming any work complete."; (2) "Knowledge bundle: consult `.okf/` for context; write durable learnings back to it (concepts need `type` frontmatter; append to `.okf/log.md`)."; (3) stack file section 6 addenda (testing + documentation standards). `.github/copilot-instructions.md` is three lines: point to CLAUDE.md as the standards source, name `make ayce` as the gate.

**§ OKF seeding** — run last. If `/Users/christoph/.claude/plugins/cache/scaccogatto/okf/0.4.0/skills/okf/scripts/okf_init.py` exists: `uv run <that path> .okf --title "<project>"`. Fallback: hand-write `.okf/index.md` (frontmatter `okf_version: "0.1"` only), `.okf/log.md` (dated entry "Repository scaffolded by dev-playbook (<stack>)"), `.okf/getting-started.md` (frontmatter `type: guide`). Then always write: `.okf/decisions/toolchain.md` (`type: decision`; table of tool → version → one-line why, from stack file section 2) and `.okf/processes/quality-gate.md` (`type: process`; what each ayce phase runs, what green means, `make security-scan` + daily CI schedule). Update both `index.md` listings. Validate: `uv run /Users/christoph/.claude/plugins/cache/scaccogatto/okf/0.4.0/skills/validate/scripts/okf_validate.py .okf --strict` (or `/okf:validate`); if absent, state validation was skipped.

**§ Update-flow propagation table** — the four locations and where each lives per file type, so the update flow is mechanical.

- [ ] **Step 2: Verify** — grep baseline.md for each required section: `grep -c '^## '` ≥ 9; `grep -q 'ayce' && grep -q 'security-scan' && grep -q 'okf_version'`.

---

### Task 4: references/rust.md

**Files:**
- Create: `~/.claude/skills/dev-playbook/references/rust.md`
- Read (sources to port): `/Users/christoph/src/github.com/devplaybooks/rs_blank/{.rustfmt.toml,deny.toml,Makefile,CLAUDE.md,.github/workflows/,.devcontainer/}`

**Interfaces:**
- Consumes: baseline phase names and skeletons (Task 3).
- Produces: n/a (leaf). All stack files use the same 7 section headings: `## Init`, `## Toolchain`, `## Config files`, `## Quality gate`, `## CI`, `## CLAUDE.md addenda`, `## Update`.

- [ ] **Step 1: Write rust.md** with the 7 sections:
  1. **Init:** `cargo init` / `cargo init --lib` (interview: lib vs bin). Set `rust-version` (MSRV) in Cargo.toml to the resolved version.
  2. **Toolchain:** rustfmt; clippy pedantic (rationale: "dialed up to 11"); cargo-deny (licenses/bans/advisories/sources); cargo-audit (security-scan); miri OPTIONAL (off by default — heavy); docs via `cargo doc --no-deps` warning-free.
  3. **Config files:** `.rustfmt.toml` — port from rs_blank (keep `max_width = 100`). `deny.toml` — port from rs_blank; set the license allow-list to the licenses chosen in the interview. Modernization: pedantic via `[lints.clippy] pedantic = { level = "warn", priority = -1 }` in Cargo.toml instead of a `#![warn]` attribute (works since Rust 1.74; survives file renames).
  4. **Quality gate phase mapping:** clean=`cargo clean`; fmt=`cargo fmt`; build=`cargo build`; test=`cargo test` (includes doc-tests); lint=`cargo clippy --all-targets -- -D warnings` + `cargo deny check`; security-scan=`./bin/security-scan`; docs=`RUSTDOCFLAGS="-D warnings" cargo doc --no-deps`. `bin/security-scan` = `cargo audit` + `cargo deny check advisories`. Extra targets allowed: `watch`, `install-tools` (port from rs_blank Makefile).
  5. **CI:** jobs test (matrix: stable, beta, MSRV — drop nightly; port structure from rs_blank CI.yaml using `dtolnay/rust-toolchain`), clippy, fmt, doc. Drop `outdated` (broken on edition 2024). Miri only if user opted in.
  6. **CLAUDE.md addenda:** port rs_blank `CLAUDE.md` (testing requirements, doc-test requirements, error-handling rules — no unwrap/expect/panic in lib code, naming, trait guidance) trimmed to standards only (drop the command-list section; the Makefile is the command source).
  7. **Update:** `rustup update && cargo update`; bump `rust-version`, `.tool-versions` (`rust <ver>`), CI MSRV entry, devcontainer image tag; `cargo deny check` after.

- [ ] **Step 2: Verify** — `grep -c '^## ' references/rust.md` = 7; section names match the canonical list exactly.

---

### Task 5: references/python.md

**Files:**
- Create: `~/.claude/skills/dev-playbook/references/python.md`
- Read: `/Users/christoph/src/github.com/devplaybooks/py_blank/{.tool-versions,bin/,.github/,.devcontainer/}`

Same 7-section shape. Content:
  1. **Init:** `uv init --lib` or `uv init --app` (interview: lib vs app); `uv python pin <resolved version>`; `requires-python = ">=<resolved minor>"`.
  2. **Toolchain:** uv (env+lock, rationale: single fast tool replaces pip/venv/pip-tools); ruff format + ruff check (replaces black+flake8+isort); pytest; mypy `--strict`; pip-audit.
  3. **Config files:** in `pyproject.toml`: `[tool.ruff] line-length = 100`, `[tool.ruff.lint] select = ["ALL"]` with a short documented `ignore` list (D203/D213 conflict pair and similar formatter conflicts); `[tool.mypy] strict = true`; `[tool.pytest.ini_options] addopts = "-q"`.
  4. **Gate:** clean=`rm -rf dist .pytest_cache .mypy_cache .ruff_cache`; fmt=`uv run ruff format .`; build=`uv build`; test=`uv run pytest`; lint=`uv run ruff check . && uv run mypy src tests`; security-scan=`./bin/security-scan` (= `uvx pip-audit` against the locked env: `uv export --format requirements-txt | uvx pip-audit -r /dev/stdin`); docs=`uv run python -m pydoc -w` is NOT used — docs phase = `uv run mkdocs build --strict` only if user opts into mkdocs, else phase is a no-op with an explanatory comment.
  5. **CI:** `astral-sh/setup-uv@v5`; test job matrix over resolved python version(s); lint job; fmt-check job (`ruff format --check`). security.yaml setup = same setup-uv step.
  6. **CLAUDE.md addenda:** every public function typed + docstring with example; pytest tests per public function (happy + edge + error); no bare `except:`; mypy strict must pass.
  7. **Update:** `uv lock --upgrade`; `uv python pin <new>`; bump `requires-python`, `.tool-versions`, CI matrix, devcontainer.

- [ ] **Verify:** 7 sections, canonical names.

---

### Task 6: references/go.md

**Files:**
- Create: `~/.claude/skills/dev-playbook/references/go.md`

Content: Init `go mod init <module path>` (interview: module path, e.g. `github.com/<owner>/<name>`) + hello-world `main.go` or lib file. Toolchain: go, golangci-lint (rationale: one runner for vet+staticcheck+lint family), govulncheck. Config: `.golangci.yaml` enabling `govet, staticcheck, errcheck, revive, gofumpt` formatters section. Gate: clean=`go clean ./... && rm -rf bin/out`; fmt=`gofumpt -w .` (via golangci-lint fmt); build=`go build ./...`; test=`go test ./...`; lint=`golangci-lint run`; security-scan=`./bin/security-scan` (= `govulncheck ./...`); docs=`go doc ./... > /dev/null` (smoke) — note `pkgsite` for browsing. CI: `actions/setup-go@v5` with version from go.mod; test+lint jobs. CLAUDE.md addenda: table-driven tests; errors wrapped with `%w`; exported identifiers documented. Update: `go get -u ./... && go mod tidy`; bump `go` directive in go.mod, `.tool-versions`, CI, devcontainer.

- [ ] **Verify:** 7 sections, canonical names.

---

### Task 7: references/java.md

**Files:**
- Create: `~/.claude/skills/dev-playbook/references/java.md`
- Read: `/Users/christoph/src/github.com/devplaybooks/java_gradle_junit5/` and `/Users/christoph/src/github.com/devplaybooks/java21_maven_junit/` (port taste: wrapper usage, plugin choices, CI shape)

Content: Init — interview build tool (gradle default | maven) + JDK version (default 21); `gradle init --type java-library --dsl kotlin --test-framework junit-jupiter` or Maven archetype `maven-archetype-quickstart` then upgrade JUnit to 5; always commit the wrapper (`gradlew`/`mvnw`). Toolchain: JDK (Temurin), JUnit 5, Spotless (google-java-format), Checkstyle optional-off, OWASP dependency-check (security). Config: toolchain block pinning JDK (`java.toolchain.languageVersion` / maven-enforcer `requireJavaVersion`); Spotless plugin config; dependency-check plugin. Gate: clean=`./gradlew clean`|`./mvnw clean`; fmt=`spotlessApply`; build=`assemble`|`package -DskipTests`; test=`test`; lint=`spotlessCheck`; security-scan=`./bin/security-scan` (= `./gradlew dependencyCheckAnalyze` | `./mvnw org.owasp:dependency-check-maven:check`); docs=`javadoc` with `-Werror`. CI: `actions/setup-java@v4` distribution temurin, matrix on the resolved JDK; cache gradle/maven. CLAUDE.md addenda: JUnit 5 naming `method_scenario_expected`, AssertJ allowed, no field injection, javadoc on public API. Update: gradle `versionCatalogUpdate` or `./mvnw versions:use-latest-releases versions:update-properties`; bump JDK across the four locations + toolchain block.

- [ ] **Verify:** 7 sections; both maven and gradle commands present for every gate phase.

---

### Task 8: references/cpp.md

**Files:**
- Create: `~/.claude/skills/dev-playbook/references/cpp.md`
- Read: `/Users/christoph/src/github.com/devplaybooks/cpp_cmake_gtest/`, `/Users/christoph/src/github.com/devplaybooks/cpp_bazel_gtest/` (port taste)

Content: Init — interview build system (cmake default | bazel) + test framework (gtest default | catch2; bazel→gtest only). CMake path: `cmake_minimum_required` current, `FetchContent` for the test framework, `CMakePresets.json` with `default` + `release` presets. Bazel path: bzlmod `MODULE.bazel`, `rules_cc`, `googletest` dep. Toolchain: clang-format, clang-tidy, chosen test framework. Config: `.clang-format` (LLVM base, `ColumnLimit: 100`), `.clang-tidy` (bugprone-*, modernize-*, performance-*, readability-*). Gate: clean=`rm -rf build`|`bazel clean`; fmt=`clang-format -i` over `src include tests`; build=`cmake --preset default && cmake --build build`|`bazel build //...`; test=`ctest --test-dir build`|`bazel test //...`; lint=`clang-tidy` over sources (compile_commands.json from CMake; note bazel caveat + `bazel run @hedron_compile_commands` as opt-in); security-scan=`./bin/security-scan` (= `osv-scanner scan source .` — best-effort, documented: C++ has no universal manifest; scans what lockfiles/SBOMs exist, exits 0 on "no packages found"); docs=doxygen only if user opts in, else no-op with comment. CI: matrix gcc+clang on ubuntu; steps mirror gate. CLAUDE.md addenda: every public function tested; RAII; no raw owning pointers; warnings-as-errors (`-Wall -Wextra -Werror`). Update: bump FetchContent tags / MODULE.bazel versions; compiler images in CI/devcontainer; `.tool-versions` (cmake, bazel via mise where plugins exist).

- [ ] **Verify:** 7 sections; both cmake and bazel commands present for every gate phase.

---

### Task 9: references/c.md

**Files:**
- Create: `~/.claude/skills/dev-playbook/references/c.md`
- Read: `/Users/christoph/src/github.com/devplaybooks/c_make_check/` (port taste)

Content: Init — plain Make project layout (`src/`, `include/`, `tests/`), hello-world + one Check test; no generator. Toolchain: cc (clang/gcc), Check (unit tests, rationale: the org's chosen C framework), clang-format, clang-tidy. Config: `.clang-format` as cpp; Makefile IS the build system here — gate targets contain real build rules (`CFLAGS = -std=c17 -Wall -Wextra -Werror`), pkg-config for check. Gate: clean=`rm -rf build`; fmt=`clang-format -i src/*.c include/*.h tests/*.c`; build=compile rule; test=build+run check binary; lint=`clang-tidy`; security-scan=`./bin/security-scan` (= `osv-scanner scan source .` best-effort, same caveat as cpp); docs=no-op with comment. CI: ubuntu, `apt-get install check`, run make targets. CLAUDE.md addenda: every function has a Check test; all allocations paired with frees (note valgrind as optional target); no implicit declarations. Update: mostly toolchain image bumps; document that C deps are vendored/system and updates are manual review.

- [ ] **Verify:** 7 sections, canonical names.

---

### Task 10: references/ts-lib.md

**Files:**
- Create: `~/.claude/skills/dev-playbook/references/ts-lib.md`
- Read: `/Users/christoph/src/github.com/devplaybooks/ts_lib_tsup_vitest/` (port taste)

Content: Init — write `package.json` directly (name, `type: module`, `exports` map, `engines.node` = resolved version); `npm install -D typescript tsup vitest @biomejs/biome`; `npx tsc --init` then set `strict: true`, `module/moduleResolution: NodeNext`, `declaration` handled by tsup. Toolchain: tsup (bundling d.ts + esm/cjs, rationale), vitest, biome (fmt+lint, single fast tool replaces eslint+prettier). Config: `biome.json` (recommended rules, line width 100), `tsup.config.ts` (entry, dts, formats), `vitest` config inline in `vite`-less mode. Gate: clean=`rm -rf dist`; fmt=`npx biome format --write .`; build=`npx tsup`; test=`npx vitest run`; lint=`npx biome check . && npx tsc --noEmit`; security-scan=`./bin/security-scan` (= `npm audit --audit-level=high` + `osv-scanner scan source .` if installed); docs=no-op comment (typedoc opt-in). CI: `actions/setup-node@v4` with `.tool-versions`-consistent version, `npm ci`, gate steps. CLAUDE.md addenda: vitest per exported symbol; no `any` (biome rule); exports map is the public API. Update: `npx npm-check-updates -u && npm install`; bump `engines.node`, `.tool-versions` (`nodejs <ver>`), CI, devcontainer.

- [ ] **Verify:** 7 sections, canonical names.

---

### Task 11: references/ts-next.md

**Files:**
- Create: `~/.claude/skills/dev-playbook/references/ts-next.md`

Content: Init — `npx create-next-app@latest <name> --typescript --app --eslint` (let its own interview run for the rest; record answers). Playbook layers on top only — do not fight the framework: keep eslint (create-next-app native) rather than biome; add prettier NOT added (eslint-config-next handles style minimally; note this decision). Toolchain: next, react, typescript strict, vitest + @testing-library/react (rationale: framework-default jest is heavier; vitest matches ts-lib), npm audit. Config: enable `"strict": true` in tsconfig if not already; vitest + jsdom setup file; `next.config` untouched. Gate: clean=`rm -rf .next out`; fmt=`npx next lint --fix` (note: lint-as-fmt is the Next convention); build=`npx next build`; test=`npx vitest run`; lint=`npx next lint && npx tsc --noEmit`; security-scan=`./bin/security-scan` (= `npm audit --audit-level=high`); docs=no-op comment. CI: setup-node, `npm ci`, gate steps; build job caches `.next/cache`. CLAUDE.md addenda: components tested via testing-library (behavior, not snapshots); server/client component boundary documented per component; no `any`. Update: `npx npm-check-updates -u && npm install` + `npx @next/codemod@latest upgrade` for major Next bumps; four-location version bump for node.

- [ ] **Verify:** 7 sections, canonical names.

---

### Task 12: Acceptance test — rust scaffold end-to-end

**Files:**
- Create (scratch): `<scratchpad>/accept-rust/` — a full scaffold

- [ ] **Step 1:** Follow SKILL.md Flow 1 exactly as written (interview answers: stack=rust, name=accept-rust, bin, licenses=all three, defaults elsewhere) targeting `<scratchpad>/accept-rust`. Read only baseline.md + rust.md, as the skill instructs.
- [ ] **Step 2:** Run `make ayce` in the scaffold. Expected: green. Iterate fixes; any fix that reveals a wrong instruction in SKILL.md/baseline.md/rust.md gets fixed IN THE SKILL FILES, not just the scaffold (the scaffold is disposable; the skill is the deliverable).
- [ ] **Step 3:** Run `./bin/security-scan` directly. Expected: exit 0.
- [ ] **Step 4:** Validate OKF: `uv run /Users/christoph/.claude/plugins/cache/scaccogatto/okf/0.4.0/skills/validate/scripts/okf_validate.py <scratchpad>/accept-rust/.okf --strict`. Expected: 0 errors.
- [ ] **Step 5:** Structural audit — confirm present: `.tool-versions`, `Makefile` (default=ayce), `bin/security-scan` (executable), both workflows (security cron daily), `CLAUDE.md`, `.github/copilot-instructions.md`, chosen licenses, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CONTRIBUTING.md`, `.okf/decisions/toolchain.md`, `.okf/processes/quality-gate.md`, `.gitignore` containing `.idea/`. Confirm the four version locations agree.
- [ ] **Step 6:** Confirm the run's final output printed (not ran) the git command block.

---

### Task 13: Acceptance test — java scaffold (interview branching)

- [ ] **Step 1:** Follow Flow 1 with stack=java, name=accept-java, gradle, JDK 21, MIT only, target `<scratchpad>/accept-java`.
- [ ] **Step 2:** `make ayce` to green (needs a local JDK — if none installed, record the preflight STOP message verbatim as the test result and verify it names the install command; that IS the designed behavior).
- [ ] **Step 3:** Verify single-license case: only LICENSE-MIT present; README badge row has exactly one license badge.
- [ ] **Step 4:** Verify gradle-specific: wrapper committed, `java.toolchain` pins 21, dependency-check wired into `bin/security-scan`.

---

### Task 14: Acceptance test — pin + update round-trip (python)

- [ ] **Step 1:** Scaffold with a pin: Flow 1, stack=python, name=accept-pin, `--python <previous stable minor, e.g. 3.12 if 3.13 is current>`, target `<scratchpad>/accept-pin`.
- [ ] **Step 2:** Verify all four version locations state the pinned minor (`.tool-versions`, CI matrix, devcontainer image tag, `requires-python`). `make ayce` green.
- [ ] **Step 3:** Run Flow 2 (`/dev-playbook update`, no pins) in the scaffold. Expected: python bumped to current stable in all four locations, `uv lock --upgrade` ran, `make ayce` green.
- [ ] **Step 4:** Verify `.okf/log.md` gained a dated update entry, and the final output printed git commands without running them.

---

### Task 15: Skill self-review & spec coverage

- [ ] **Step 1:** Re-read the spec (`docs/2026-08-01-dev-playbook-skill-design.md`) section by section; for each requirement point to the skill file/line that implements it. Fix any gap in the skill files.
- [ ] **Step 2:** Run the superpowers:writing-skills verification guidance against SKILL.md (frontmatter, description triggers, imperative voice, file sizes; every reference file reachable from SKILL.md).
- [ ] **Step 3:** Confirm no skill file hardcodes a language/tool version (grep for version-looking literals; allowed: action pins like `@v4`, cron strings, `okf_version`, JDK default 21 as an interview default).
- [ ] **Step 4:** Delete scratch scaffolds. Report completion to the user with: what was built, test results, and suggested next steps (e.g. optionally `git init` the skill dir themselves for version control).
