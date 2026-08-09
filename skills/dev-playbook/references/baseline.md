# Baseline — stack-agnostic playbook layer

Read this file on every `/dev-playbook` run, together with exactly one stack
file (`references/<stack>.md`). This file is instructions for you, the
executing agent — carry out each section as a step, in order, don't just
summarize it back.

Stack files supply the concrete values (tool names, versions, commands,
snippets) that plug into the skeletons below. They always use these section
headings, in this order: `## Init`, `## Toolchain`, `## Config files`,
`## Quality gate`, `## CI`, `## CLAUDE.md addenda`, `## Update`. Wherever a
stack file's Quality Gate section expands a phase, it must use exactly these
seven phase names and no others: `clean`, `fmt`, `build`, `test`, `lint`,
`security-scan`, `docs`.

**Version-consistency rule** (state this to the user verbatim whenever you
touch any version-declaring location, and re-verify the whole set every time):

> Every location that declares a runtime or tool version MUST agree. The
> baseline set is: `.tool-versions`, the CI matrix, the devcontainer
> toolchain pin (the image tag, where that image family's tag encodes the
> language version — otherwise a `postCreateCommand`/feature version pin
> instead; see § Devcontainer), and manifest pins (rust-version,
> requires-python, engines, java toolchain). **A stack may add more**, and
> the stack file names them — Python adds `.python-version`, which uv reads
> before anything else. Whenever any one of them changes, re-verify every
> location in this stack's set.

Never state this rule with a fixed count ("all four"). The set is
stack-dependent, and a count that is right for one stack silently undercounts
another — a rule that undercounts its own pins is worse than no rule, because
the location it omits is exactly the one nobody checks.

Apply layers in this order, after the stack's native init has already run:
baseline files (this document) → AI files (CLAUDE.md,
copilot-instructions.md, AI-BOM.md) → stack configs (stack file, Config files / Quality gate / CI sections) →
`.okf/` seeding (this document, § OKF seeding — always last).

Never hardcode an exact language or tool version anywhere you write from this
file. The only pins allowed are cron strings and `okf_version: "0.1"`. Every
runtime/tool version comes from the interview or from "current stable"
resolved at run time — and that **includes GitHub Actions `uses:` majors**,
which are resolved exactly like any other version (see § CI workflows, Action
version pins). Any `@v<N>` appearing in this document or in a stack file is
illustrative, never authoritative: treat every one as `@<resolved-major>`.

## § Files every scaffold gets

Write every row below into the target repo. "Substitute" means replace
`{{project}}` with the project name, `{{owner}}` with `git config user.name`
(ask the user if unset), and `{{year}}` with the current year — in every file
that contains those placeholders.

| File | Source | Action |
|---|---|---|
| `LICENSE-MIT`, `LICENSE-APACHE`, `LICENSE-GPLv3` | `assets/licenses/LICENSE-*` | Copy byte-stable, one file per license the user chose. Substitute `{{year}}`/`{{owner}}` where the license text has placeholders. |
| `CODE_OF_CONDUCT.md` | `assets/CODE_OF_CONDUCT.md` | Copy verbatim, no substitution. |
| `SECURITY.md` | `assets/SECURITY.md.tmpl` | Copy, substitute `{{project}}`. |
| `CONTRIBUTING.md` | `assets/CONTRIBUTING.md.tmpl` | Copy, substitute `{{project}}`. |
| `README.md` | generated | See § README shape below. |
| `.gitignore` | generated | Stack-appropriate ignores (stack file names the language-specific patterns) plus always `.idea/` on its own line. |
| `.editorconfig` | generated | Stack-appropriate indent/charset rules (stack file may add per-extension overrides); always include a `root = true` top block. |
| `.tool-versions` | generated | See § .tool-versions below. |
| `Makefile` | this file, § Makefile contract | Copy the skeleton verbatim; stack file fills phase bodies. |
| `bin/security-scan` | generated | See § bin/ scripts below; `chmod +x`. |
| `.github/workflows/ci.yaml` | generated | See § CI workflows below. |
| `.github/workflows/security.yaml` | this file, § CI workflows | Copy the skeleton verbatim; stack file supplies the toolchain setup step(s). |
| `.devcontainer/devcontainer.json` | generated | See § Devcontainer below. |
| `CLAUDE.md` | generated | See § CLAUDE.md skeleton below. |
| `.github/copilot-instructions.md` | generated | See § CLAUDE.md skeleton below (three lines). |
| `AI-BOM.md` | `assets/AI-BOM.md.tmpl` | Copy, substitute `{{project}}`; then replace the placeholder row in "AI tools in use" with the agent + model actually performing the scaffold, resolved at run time (e.g. `Claude Code` / the current model / role `scaffolding`) — never leave the placeholder comment row in the generated file. |
| `.okf/` | generated | See § OKF seeding below — apply this step LAST, after everything above exists. |

## § README shape

Generate `README.md` with, in this order:

1. **Badge row** — one badge per line, in this order: CI workflow badge, then
   Contributor Covenant, then one license badge per license the user chose,
   then the AI-BOM badge last (always present — every scaffold ships an
   `AI-BOM.md`). Port the markdown shape verbatim from the badge row style below (this was
   ported read-only from `rs_blank/README.md` lines 1-7 — adapt only the repo
   path, org, and license set to the new project; keep the same badge
   services and image styles):

   ```markdown
   [![Build and Test](https://github.com/<org>/<repo>/actions/workflows/ci.yaml/badge.svg)](https://github.com/<org>/<repo>/actions/workflows/ci.yaml)
   [![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg)](CODE_OF_CONDUCT.md)
   [![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE-MIT)
   [![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue?style=flat-square)](LICENSE-APACHE)
   [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)
   [![AI-BOM](https://img.shields.io/badge/AI--BOM-declared-8A2BE2?style=flat-square)](AI-BOM.md)
   ```

   The Contributor Covenant badge's version number MUST match the version
   named inside `assets/CODE_OF_CONDUCT.md` (currently 2.0) — if that asset is
   ever upgraded to a newer Contributor Covenant release, update this badge to
   match; never let the badge and the document it links to disagree.

   Include only the license badges for licenses actually chosen; drop the
   rest. A trailing `---` line after the badge row is optional but matches
   house style.
2. **One-paragraph description** — what the project is, in plain language;
   ask the user for this if not already given during the interview.
3. **"How to use"** — a short section: clone/install steps plus the one
   command to run everything: `make ayce`. Mention `make help` for the full
   target list.
4. **"What's in the box"** — a bullet list of the tooling choices (formatter,
   linter, test framework, security scanner, etc.). Each bullet states WHAT
   was chosen, and links its WHY into `.okf/decisions/toolchain.md` (e.g.
   `- **Linting:** ruff — see [toolchain decisions](.okf/decisions/toolchain.md)`)
   rather than duplicating the rationale prose in the README. Do not restate
   the reasoning here even briefly — one sentence of "what", then the link.

## § No YAML linter

Scaffolds do **not** ship `.yamllint` or `.yamlignore`, and no stack installs
or runs yamllint. Earlier versions of this playbook wrote a `.yamllint`; it was
dropped deliberately, so do not reintroduce it.

The reason is the playbook's own arbiter rule: `make ayce` decides whether the
repo is correct. No stack's `lint` phase or CI job ever invoked yamllint, and
no `## Toolchain` section installed it, so the config was inert — it sat in
every scaffold looking like an enforced standard while enforcing nothing. It
had in fact been broken the whole time (`ignore-from-file` named a
`.yamlignore` that no step created, so yamllint aborted with
`FileNotFoundError` rather than linting), and nothing surfaced that, because
nothing ran it. A config outside the gate has no mechanism keeping it honest.

If a project later wants its workflows checked, add a real tool to the `lint`
phase so the gate enforces it — `actionlint` is the better fit for GitHub
Actions than a generic YAML linter, since it understands workflow schema,
expression syntax, and `runs-on` labels. Adding an unenforced config file back
is not the answer.

## § .tool-versions

Write `.tool-versions` in asdf syntax (mise-compatible: `mise install` reads
the same file). One line per runtime/tool the stack file names in its
`## Toolchain` section, format `<tool> <version>`. Resolve each version at
scaffold time (current stable, or the user's explicit pin) — never write a
version from memory.

State the version-consistency rule in `CLAUDE.md` (§ CLAUDE.md skeleton
handles the placement) and re-verify it on every `/dev-playbook update` run.
In the generated `CLAUDE.md`, do not paste the generic wording — **enumerate
the concrete locations this repo actually has**, by path, resolved from the
stack file. The generic rule teaches an agent what kind of thing to look for;
a concrete list tells it exactly which files to open. For a Python library
that list is:

> `.tool-versions`, `.python-version`, `pyproject.toml`'s `requires-python`,
> `.github/workflows/ci.yaml`'s matrix, and
> `.devcontainer/devcontainer.json`'s image tag MUST agree; whenever any one
> changes, verify all of them.

Substitute the equivalent paths for other stacks (`Cargo.toml`'s
`rust-version`, `go.mod`'s `go` directive, `package.json`'s `engines`, the
Java toolchain block, …). Count the locations for the stack you are actually
scaffolding; never copy a count from this document.

## § Makefile contract

Write `Makefile` starting from this exact skeleton. Never rename, remove, or
reorder the `PHONY` targets, never change what `default` points to, and never
change `ayce`'s prerequisite list. The stack file fills in the recipe body
under each phase target (the lines currently empty below); it may add extra
targets after `docs` but must not touch anything above. One documented
exception: for the **c** stack, Make *is* the build system, so `c.md`'s
Makefile adds variables above `.PHONY` and pattern rules between the phase
targets — the invariants that still bind it are `default: ayce`, the seven
phase names, and `ayce`'s prerequisite list.

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

Rule: `ayce` is ALWAYS `default`; the seven phase names (`clean`, `fmt`,
`build`, `test`, `lint`, `security-scan`, `docs`) never vary and never get
renamed; stacks may add extra targets but never rename these.

## § bin/ scripts

Write `bin/security-scan` as an executable shell script:

```bash
#!/usr/bin/env bash
set -euo pipefail

# <stack file supplies the scanner commands here, e.g.:
#    cargo audit
#    cargo deny check advisories
#  or: pip-audit / govulncheck / npm audit + osv-scanner / etc. >
```

Run `chmod +x bin/security-scan` after writing it. No check logic may live in
the Makefile or in any CI workflow — both call this one script. If a future
stack needs more than one scanner script, they all still live under `bin/`
and are all called from here, not inlined elsewhere.

## § CI workflows

**`.github/workflows/ci.yaml`** — generate from the stack file's `## CI`
section (jobs, matrix). Triggers:

```yaml
on:
  push:
  pull_request:
  schedule:
    - cron: "40 1 1 * *"   # monthly — toolchain freshness check
```

Every job must pin tool versions consistent with `.tool-versions` (same
version-consistency rule as above). Job bodies (checkout, toolchain setup,
build/test/lint invocation) come entirely from the stack file.

**`.github/workflows/security.yaml`** — write this exact shape, inserting only
the stack's toolchain setup step(s) where marked. "Exact shape" governs the
name, triggers, cron, job structure, and step order — it does **not** freeze
the `uses:` major, which is resolved like every other version (below):

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
      - uses: actions/checkout@<resolved-major>
      # <stack toolchain setup steps here>
      - run: ./bin/security-scan
```

The security workflow's cron is always daily; the ci.yaml cron is always
monthly. Do not swap these or make either configurable.

### Action version pins

Resolve the major of every version-pinned `uses:` at scaffold time, the same
way you resolve a language version — never copy a literal out of this document
or a stack file. Stack files write these as `@<resolved-major>` precisely so a
stale literal cannot be copied by accident.

```
gh api repos/<owner>/<repo>/releases/latest --jq .tag_name
```

or, without `gh`:

```
curl -s https://api.github.com/repos/<owner>/<repo>/releases/latest \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])'
```

Take the major from the returned tag (`v7.0.1` → pin `@v7`; some repos
tag without the `v` prefix — `2.37.2` → pin `@v2` all the same). Pin the major
only, never the full patch tag: majors are the moving refs GitHub maintains
for exactly this purpose, and a patch pin turns every action release into
manual maintenance.

**Not every `@ref` is a version. These are refs by name and must be copied
verbatim — resolving them breaks the action:**

| Ref | What it actually selects |
|---|---|
| `dtolnay/rust-toolchain@stable` / `@master` / `@miri` | Rust toolchain *channel*. This action is versioned by branch, not by release tag; there is no `@v1`. |
| `taiki-e/install-action@cargo-deny` / `@cargo-audit` | Which *tool* to install. The ref is a tool name, not a version. |

Before resolving any `@ref`, ask whether it names a version or a thing. If it
names a thing, leave it alone.

**Offline / registry unreachable.** Fall back to the last-known-good majors
below, and say plainly in the handoff which pins were not verified. This table
is the single place in the playbook allowed to carry a stale action version —
it exists so that eight stack files do not each carry their own.

| Action | Last-known-good major | Verified |
|---|---|---|
| `actions/checkout` | `v7` | 2026-08-09 |
| `actions/setup-go` | `v7` | 2026-08-09 |
| `actions/setup-node` | `v7` | 2026-08-09 |
| `actions/setup-java` | `v5` | 2026-08-09 |
| `actions/cache` | `v6` | 2026-08-09 |
| `astral-sh/setup-uv` | `v9` | 2026-08-09 |
| `golangci/golangci-lint-action` | `v9` | 2026-08-09 |
| `gradle/actions/setup-gradle` | `v6` | 2026-08-09 |
| `shivammathur/setup-php` | `v2` | 2026-08-09 |
| `EmbarkStudios/cargo-deny-action` | `v2` | 2026-08-09 |
| `bazel-contrib/setup-bazel` | `0.19` | 2026-08-09 |

Refresh this table's values and its Verified date whenever a `/dev-playbook
update` run resolves something newer.

## § Devcontainer

Write `.devcontainer/devcontainer.json` using the current Microsoft
dev-container image for the stack (the stack file names which image family,
e.g. `mcr.microsoft.com/devcontainers/rust`, `.../python`, `.../go`,
`.../java`, `.../cpp`, `.../typescript-node`). Resolve the current tag at
scaffold time; never hardcode one from memory.

Not every `devcontainers/<stack>` image tags itself by the *language*
version — check before assuming. Some families (e.g. `.../rust`) tag by the
devcontainer image's own release/OS-codename (`2.0.9-bookworm`, `bookworm`,
`latest`) with no runtime-version segment at all; others may tag by
language version directly. When the tag can't encode the runtime version,
version-consistency still applies, just via a different lever: pick a
stable/current tag for the base image, and pin the exact runtime version
some other way inside the container (a devcontainer feature's `version`
option, or a `postCreateCommand`) — the stack file says which. Never claim
an image tag agrees with `.tool-versions` when the tag scheme can't actually
express that version.

## § CLAUDE.md skeleton

Generate `CLAUDE.md` containing, in this order:

1. **Definition of done**: "`make ayce` passes. Run it before claiming any
   work complete."
2. **Knowledge bundle pointer**: "Consult `.okf/` for context; write durable
   learnings back to it (concepts need `type` frontmatter; append to
   `.okf/log.md`)."
3. **Stack-specific addenda** — copy the stack file's `## CLAUDE.md addenda`
   section verbatim (testing standards + documentation standards for that
   stack).

Generate `.github/copilot-instructions.md` as exactly three lines: it must
point to `CLAUDE.md` as the single source of standards, and it must name
`make ayce` as the gate. Do not duplicate any prose from `CLAUDE.md` here —
this file only points, it never repeats.

## § OKF seeding

Run this section LAST, after every file above already exists — toolchain
decisions must exist before you write rationale about them.

1. Locate the OKF plugin's init script — discover it at run time, never
   assume a user or version:
   ```
   OKF_INIT=$(ls -d "$HOME"/.claude/plugins/cache/scaccogatto/okf/*/skills/okf/scripts/okf_init.py 2>/dev/null | sort -V | tail -1)
   ```
   (`sort -V | tail -1` picks the newest installed plugin version if
   several are cached.)
   - If `$OKF_INIT` is non-empty, run:
     ```
     uv run "$OKF_INIT" .okf --title "<project>"
     ```
   - If it does not exist, hand-write the fallback bundle yourself:
     - `.okf/index.md` — frontmatter `okf_version: "0.1"` only, plus a
       listing of the concept files below.
     - `.okf/log.md` — one dated entry: "Repository scaffolded by
       dev-playbook (<stack>)".
     - `.okf/getting-started.md` — frontmatter `type: guide`.
2. Always write these two files, regardless of which path Step 1 took. Give
   both the full recommended frontmatter set the OKF validator checks for
   (`type`, `title`, `description`, `tags`, `timestamp` — an ISO-8601
   instant, written as `timestamp: '<resolved-utc-instant>'`; resolve the
   actual current UTC time at scaffold time, e.g. via
   `date -u +%Y-%m-%dT%H:%M:%SZ` — never hardcode or copy-paste a literal
   instant from this document or from any prior run), not just `type` —
   `--strict` validation (step 3 below) fails on any of these being absent,
   not only on missing `type`:
   - `.okf/decisions/toolchain.md` — frontmatter `type: decision`; a table of
     tool → version → one-line why, sourced from the stack file's
     `## Toolchain` section.
   - `.okf/processes/quality-gate.md` — frontmatter `type: process`;
     describes what each `ayce` phase runs, what "green" means, that
     `make security-scan` exists standalone, and that `security.yaml` runs it
     daily.
   Update `index.md`'s concept listing to include both new files (whichever
   path created `index.md`).
3. Validate the bundle: locate the validator the same way as step 1:
   ```
   OKF_VALIDATE=$(ls -d "$HOME"/.claude/plugins/cache/scaccogatto/okf/*/skills/validate/scripts/okf_validate.py 2>/dev/null | sort -V | tail -1)
   ```
   - If `$OKF_VALIDATE` is non-empty, run:
     ```
     uv run "$OKF_VALIDATE" .okf --strict
     ```
     (equivalently, invoke the `/okf:validate` skill).
   - If it does not exist, state plainly in your output that OKF validation
     was skipped — never claim validation passed without having run it.

## § Update-flow propagation table

On `/dev-playbook update`, a version bump must land in **every** location the
stack declares — the baseline set below, plus any the stack file adds. Use
this table to find where each lives per file type:

| Location | Where the version lives | Who writes it |
|---|---|---|
| `.tool-versions` | one `<tool> <version>` line per runtime/tool | baseline layer (this file) |
| CI matrix | `ci.yaml` job matrix / setup-action `version:` inputs | stack file, `## CI` section |
| Devcontainer toolchain pin | `.devcontainer/devcontainer.json` — `image` field tag IF that family's tags encode the language version; otherwise the `postCreateCommand`/feature `version` option (image tag itself then just tracks a stable base, not the pinned language version) | baseline layer, § Devcontainer |
| Manifest pins | `rust-version` (Cargo.toml), `requires-python` (pyproject.toml), `engines` (package.json), Java toolchain version (pom.xml/build.gradle*), go.mod `go` directive, etc. | stack file, `## Update` section |
| *(stack additions)* | e.g. Python's `.python-version` — read by uv before anything else | stack file, `## Init` / `## Update` sections |

Before declaring the update done, enumerate this stack's full set and re-check
every entry for agreement — the version-consistency rule applied
mechanically. Build that list from the stack file, not from a count carried
over from another stack.
