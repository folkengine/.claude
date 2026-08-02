# dev-playbook Skill — Design

**Date:** 2026-08-01
**Status:** Approved design, pre-implementation
**Replaces:** The [devplaybooks](https://github.com/devplaybooks) GitHub org's fork-a-template workflow

## Purpose

A global `/dev-playbook` skill that scaffolds a production-quality repository for a
chosen language + toolchain directly in place — no fork, no GitHub org dependency.
It preserves the devplaybooks philosophy (opinionated quality gates, no application
code beyond native init, "cruel to be kind in the right measure") while modernizing
tooling and adding what the pre-LLM templates couldn't have: an AI-assistant layer
and a seeded knowledge bundle.

The skill embeds the playbook knowledge as a layered model — a stack-agnostic
baseline plus per-stack overlays — applied at generation time. This eliminates the
drift problem of maintaining ~20 template repos as copies. The org repos become
optional showcases.

## Decisions (from design interview)

| Decision | Choice |
|---|---|
| Output model | Scaffold in place in the current/target directory |
| Stack coverage v1 | All current org stacks (collapsed, see roster) |
| Tooling | Modernize per stack; concrete choices live in stack references |
| Run UX | Short interview, then native init + playbook layers, ending green |
| Git handling | Skill never runs state-changing git; prints exact commands for the user |
| Architecture | Hybrid: byte-stable `assets/` + generative `references/<stack>.md` specs |
| Task runner | GNU Make (universally preinstalled); `make help` self-documenting |
| JetBrains `.idea/` | Dropped; added to `.gitignore`; rely on `.editorconfig` |
| Knowledge layer | `.okf/` bundle seeded in every scaffold |
| Version pinning | `.tool-versions` (asdf syntax, mise-compatible) in every scaffold |
| Universal gate | `make ayce` — all-you-can-eat sweep, always the default target |
| Security | `bin/security-scan` script; `make security-scan` and CI call the same script; daily scheduled CI run |
| Design doc home | Inside the skill (`~/.claude/skills/dev-playbook/docs/`) |
| Flows | Two verbs: `scaffold` (default) and `update` (bump an existing repo) |
| Version targeting | Default = current stable; any language/tool version can be pinned explicitly, at scaffold or update time |

## Invocation & interview

Two flows share one skill:

- `/dev-playbook` — scaffold; menu of stacks
- `/dev-playbook <stack>` — scaffold; skips the stack question
- `/dev-playbook <stack> <name>` — scaffold; skips stack + name questions
- `/dev-playbook update` — update flow, run inside an existing repo (see below)

Scaffold interview (only what's not already given):

1. Stack (from roster)
2. Project name
3. Library vs. binary (where the stack distinguishes; e.g. `cargo init --lib`)
4. License(s) — default: all three (MIT, Apache-2.0, GPLv3), matching current templates
5. Target directory — default `./<name>`
6. **Version targeting** — default: current stable for language and tools; the
   user may pin any of them instead (e.g. Python 3.11 because production runs
   3.11, JDK 17 for an LTS mandate, Rust 1.85 for MSRV policy). Pins are
   first-class, not an afterthought: whatever is chosen lands consistently in
   `.tool-versions`, the CI matrix, the devcontainer image, and manifest pins.
   Inline shorthand is accepted: `/dev-playbook python api --python 3.11`.
7. Stack-specific questions defined in that stack's reference (e.g. Java: Maven vs.
   Gradle, JDK version; C++: CMake vs. Bazel, GoogleTest vs. Catch2)

## Update flow

`/dev-playbook update [targets]`, run in an existing repository. Two modes,
mirroring the scaffold-time choice:

- **Latest and greatest** (default): bump language, tools, and dependencies to
  current stable.
- **Targeted**: pin specific versions where you don't have a choice
  (`/dev-playbook update --java 17`, `--rust 1.85`, or stated conversationally).
  Everything not pinned goes to latest.

Steps:

1. **Detect** the stack and current state from `.tool-versions` and manifests.
   Designed for playbook-scaffolded repos; degrades to best-effort on any repo
   that follows similar conventions (states clearly what it could not handle).
2. **Resolve targets** — latest stable per tool, overridden by explicit pins.
3. **Propagate versions** to all four version-declaring locations
   (`.tool-versions`, CI matrix, devcontainer image, manifest pins) — the
   version-consistency rule is what makes this a mechanical, safe edit.
4. **Update dependencies** via the stack's native commands (defined in each
   stack reference's Update section): `cargo update`, `uv lock --upgrade`,
   `./gradlew versionCatalogUpdate` / Maven versions plugin, `npm update`, etc.
   GitHub Actions versions in workflows are bumped too.
5. **Verify**: `make ayce` until green, including `security-scan` — an update
   that compiles but fails audit is not done.
6. **Record**: append a dated `.okf/log.md` entry; update
   `decisions/toolchain.md` if a tool choice (not just a version) changed.
7. **Report** what changed and why; print the git commands for the user to run.

The update flow never runs state-changing git. If `git status` shows a dirty
working tree, it warns and asks before touching files, so playbook changes are
not entangled with unrelated edits.

## Stack roster

| Stack key | Replaces org repos | Modernized toolchain (headline) |
|---|---|---|
| `rust` | rs_blank | cargo, rustfmt, clippy (pedantic), cargo-deny, cargo-audit; miri optional |
| `python` | py_blank, python | uv, ruff (fmt + lint), pytest, mypy (strict), pip-audit |
| `go` | go_blank | go toolchain, golangci-lint, govulncheck |
| `java` | java17/19/21_maven_junit5, java_gradle_junit5 | one stack; interview picks Maven/Gradle + JDK (default 21); JUnit 5 |
| `cpp` | cpp_cmake_gtest, cpp_cmake_catch2, cpp_cmake_cpm, cpp_bazel_gtest, cpp_baseline | one stack; interview picks CMake/Bazel + GoogleTest/Catch2 |
| `c` | c_make_check | make, check |
| `ts-lib` | ts_lib_tsup_vitest | tsup, vitest, biome (fmt + lint) |
| `ts-next` | ts-react-next | current create-next-app + playbook layer |

Out of scope: forks, katas, and examples (`led-driver-kata`, `MDK`,
`rust-tui-template`, `rs_blank_example`, `rust_blank_example`, `spark4`, `pg_rs`,
`mongodb-jdk17`, `CMake-codecov`, `codespaces-base`, `ES2020`, `fawkes_umbrella`) —
they are not blank playbooks.

Exact tool versions are resolved at scaffold time (current stable for the chosen
stack), never hardcoded in the skill, so the skill does not rot.

## The layers

Every scaffold is built from four layers applied in order after native init.

### 1. Baseline layer (stack-agnostic)

- **Licenses** per interview choice — copied byte-stable from `assets/licenses/`
- **CODE_OF_CONDUCT.md** (Contributor Covenant 2.0 — deliberately kept
  byte-identical to the org's rs_blank copy rather than retyped as 2.1;
  the README badge is pinned to whatever version the asset actually is,
  see baseline.md § README badges), **SECURITY.md**,
  **CONTRIBUTING.md** — from `assets/`, `{{project}}`-substituted
- **README.md** — generated: badge row (CI, CoC, licenses), project description,
  "What's in the box" section that *links to* the `.okf/` rationale concepts
  instead of duplicating prose
- **.gitignore** — stack-appropriate; includes `.idea/`
- **.github/workflows/ci.yaml** — per stack spec; keeps the monthly cron
  (toolchain freshness) from today's templates
- **.github/workflows/security.yaml** — runs `bin/security-scan` on push and on a
  **daily** schedule (new advisories appear daily; monthly is too slow)
- **.devcontainer/** — current Microsoft dev container image for the stack
- **.editorconfig**, **.yamllint**
- **.tool-versions** — asdf syntax (mise-compatible); runtime(s) + tools with
  asdf/mise plugins
- **Makefile** — the universal contract (below)
- **bin/** — executable scripts shared by Makefile and CI (below)

**Version-consistency rule:** `.tool-versions`, the CI matrix, the devcontainer
image, and manifest pins (`rust-version`, `requires-python`, `engines`, …) must
agree. Stack references state this explicitly; the skill verifies it at scaffold
time.

### 2. AI layer

- **CLAUDE.md** — modernized from rs_blank's: per-stack testing and documentation
  standards, plus the quality-gate contract — *definition of done is `make ayce`
  passing* — and a pointer to `.okf/` (consult for context; write durable
  learnings back).
- **.github/copilot-instructions.md** — thin pointer to the same standards; no
  duplicated prose, single source of truth.

### 3. Per-stack layer

From `references/<stack>.md`: native init invocation, toolchain configs as
canonical snippets (`.rustfmt.toml`, `deny.toml`, ruff config in `pyproject.toml`,
`.golangci.yaml`, …) — ported from the org templates where they encode taste,
modernized where stale — CI job matrix, gate-phase expansions, CLAUDE.md addenda.

### 4. Knowledge layer (OKF) — applied last, so toolchain decisions are known

`.okf/` bundle at repo root, seeded at scaffold time:

- `index.md` (root, with `okf_version: "0.1"`), `log.md` (first dated entry:
  scaffolded by dev-playbook), `getting-started.md` — via the OKF plugin's
  `okf_init.py` fast-path when installed; hand-written conformantly otherwise
  (hard rule: every concept file has non-empty `type` frontmatter)
- `decisions/toolchain.md` — why each tool was chosen (rationale that previously
  lived only in template READMEs becomes queryable knowledge)
- `processes/quality-gate.md` — what `make ayce` and `make security-scan` run,
  what green means, definition of done
- Validated with `/okf:validate --strict` before the run is declared done; if the
  plugin is absent, note in output that validation was skipped

## Universal Makefile contract

Every scaffold, every stack:

- **`make ayce`** ("all you can eat") — the complete start-to-finish sweep:
  clean → format → build → test → lint → security-scan → docs. Validates the repo
  is ready to push to GitHub and pass CI/CD. Always present, always the `default`
  target (bare `make` = ayce). Per-stack references define what each phase expands
  to; the name and meaning never vary. (Codifies rs_blank's existing
  `default: ayce` practice.)
- **`make help`** — self-documenting target list
- **`make security-scan`** — thin delegation to `bin/security-scan`
- Individual targets (`fmt`, `build`, `test`, `lint`, `docs`, …) for fast
  iteration

## Security scanning

- **`bin/security-scan`** — stack-appropriate executable script:
  - Rust: `cargo audit` + `cargo deny check advisories`
  - Python: `pip-audit` (uv-compatible invocation)
  - Go: `govulncheck`
  - TS: `npm audit` + `osv-scanner`
  - Java: OWASP dependency-check or `osv-scanner` on the lockfile
  - C/C++: `osv-scanner` where a lockfile/manifest exists; otherwise documented
    as best-effort
- **One definition, two callers:** `make security-scan` and
  `.github/workflows/security.yaml` both execute `bin/security-scan`. No check
  logic lives in the Makefile or the workflow. This prevents local/CI gate drift.
- Security workflow schedule: daily + on push.

## Skill file structure

```
~/.claude/skills/dev-playbook/
├── SKILL.md                  # process, philosophy, interview, stack table
├── docs/                     # this design doc, future plans
├── assets/
│   ├── licenses/             # LICENSE-MIT, LICENSE-APACHE, LICENSE-GPLv3
│   ├── CODE_OF_CONDUCT.md
│   ├── SECURITY.md.tmpl
│   └── CONTRIBUTING.md.tmpl
└── references/
    ├── baseline.md           # stack-agnostic: README shape, badges, CI cron
    │                         #   policy, devcontainer rules, .tool-versions
    │                         #   consistency rule, Makefile/ayce contract,
    │                         #   bin/ + security-scan pattern, CLAUDE.md
    │                         #   skeleton, .okf/ seeding
    ├── rust.md
    ├── python.md
    ├── go.md
    ├── java.md
    ├── cpp.md
    ├── c.md
    ├── ts-lib.md
    └── ts-next.md
```

**Context economics:** `SKILL.md` orchestrates; a run reads `baseline.md` plus
exactly one stack file. Adding stacks never increases per-run context.

**Per-stack reference template** — every stack file has the same six sections, so
adding a stack is filling in a form:

1. **Init** — native command + stack-specific interview questions
2. **Toolchain** — modernized tools, one-line rationale each (feeds
   `.okf/decisions/toolchain.md`)
3. **Config files** — canonical snippets
4. **Quality gate** — ordered phase expansion for `ayce` + individual targets
5. **CI** — jobs and matrix for `ci.yaml`; anything stack-specific for
   `security.yaml`
6. **CLAUDE.md addenda** — stack-specific testing/doc standards
7. **Update** — native commands for bumping dependencies and toolchain in this
   stack, and any stack-specific propagation quirks (e.g. Maven enforcer plugin,
   Cargo `rust-version` vs. toolchain file)

## Data flow of a run

Scaffold:

```
interview → native init → baseline layer → AI layer → per-stack layer
  → .okf/ seed → make ayce (iterate until green) → okf validate
  → print git commands
```

Update:

```
detect stack/state → resolve targets (latest or pinned) → propagate versions
  → native dependency updates → make ayce (iterate until green)
  → .okf/ log entry → report + print git commands
```

Because native init provides hello-world code, the first `make ayce` passes — the
old templates' deliberate "red badge until you add code" quirk is retired.

**Git ending:** the skill never runs state-changing git (global rule). It ends by
printing exactly:

```
git init && git add -A && git commit -m "<scaffold message>"
gh repo create <name> --public --source=. --push   # optional
```

## Error handling

- **Target directory exists and is non-empty** → stop and ask; never overlay
  silently.
- **Missing native tool** (no `cargo`, no `uv`, …) → report what is missing with
  the install command (prefer `mise install` since `.tool-versions` is present);
  do not half-scaffold.
- **`make ayce` won't go green** after a few fix iterations → deliver the
  scaffold anyway, stating plainly which target fails and why. Never claim green
  that isn't.
- **OKF plugin absent** → hand-write a conformant bundle; state that
  `/okf:validate` was not run.
- **Offline / registry unreachable** → scaffold what's possible; list which
  steps (tool resolution, audit databases) need connectivity to finish.
- **Update on an unrecognized repo** → identify what was detected, what wasn't,
  and proceed only on the parts that were positively identified.
- **Update leaves ayce red** (e.g. a breaking dependency major) → report the
  failing target and the offending upgrade; offer to hold that dependency back
  (pin it) so the rest of the update can land green.

## Verification

- The skill's own acceptance test: scaffold the `rust` stack end-to-end in a
  scratch directory and run `make ayce` to green, plus `bin/security-scan`, plus
  OKF validation. Repeat for at least one interview-branching stack (`java` or
  `cpp`) to exercise the sub-choices.
- Version-pinning test: scaffold once with a deliberately non-latest pin (e.g.
  Python 3.11) and confirm all four version-declaring locations agree.
- Update test: take the pinned scaffold and run `/dev-playbook update` to
  latest; confirm propagation, green ayce, and the `.okf/log.md` entry.
- Skill authoring follows superpowers:writing-skills conventions (frontmatter,
  description with triggers, testing before deployment).

## Out of scope (v1)

- Regenerating/updating the GitHub org template repos
- Katas, examples, and fork-based repos from the org
- A `spark`, `pg_rs` (Rust+PostgreSQL), or MongoDB stack — add later via the
  per-stack template if wanted
- Running any state-changing git or `gh repo create` on the user's behalf
