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
touch any of these four locations, and verify all four agree, every time):

> `.tool-versions`, the CI matrix, the devcontainer toolchain pin (the image
> tag, where that image family's tag encodes the language version —
> otherwise a `postCreateCommand`/feature version pin instead; see §
> Devcontainer), and manifest pins (rust-version, requires-python, engines,
> java toolchain) MUST agree; verify all four whenever any changes.

Apply layers in this order, after the stack's native init has already run:
baseline files (this document) → AI files (CLAUDE.md,
copilot-instructions.md, AI-BOM.md) → stack configs (stack file, Config files / Quality gate / CI sections) →
`.okf/` seeding (this document, § OKF seeding — always last).

Never hardcode an exact language or tool version anywhere you write from this
file. The only pins allowed are: GitHub Actions `uses:` pins (e.g. `@v4`),
cron strings, and `okf_version: "0.1"`. Every runtime/tool version comes from
the interview or from "current stable" resolved at run time.

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
| `.yamllint` | this file, § .yamllint | Copy the block below verbatim. |
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

## § .yamllint

Write this file verbatim as `.yamllint` in the repo root (ported unmodified
from the org's `.baseline/.yamllint`):

```yaml
extends: default

ignore-from-file: [.gitignore, .yamlignore]

rules:
  document-start: disable
  octal-values: enable
  truthy:
    allowed-values: ['true', 'false', 'on']  # 'on' for GH action trigger
  line-length:
    max: 200
  indentation:
    check-multi-line-strings: false
    indent-sequences: consistent
  brackets:
    max-spaces-inside: 1
    max-spaces-inside-empty: 0
  braces:
    max-spaces-inside: 1
    max-spaces-inside-empty: 0
```

## § .tool-versions

Write `.tool-versions` in asdf syntax (mise-compatible: `mise install` reads
the same file). One line per runtime/tool the stack file names in its
`## Toolchain` section, format `<tool> <version>`. Resolve each version at
scaffold time (current stable, or the user's explicit pin) — never write a
version from memory.

State this rule verbatim in `CLAUDE.md` (§ CLAUDE.md skeleton handles the
placement) and re-verify it on every `/dev-playbook update` run:

> `.tool-versions`, the CI matrix, the devcontainer toolchain pin (the image
> tag, where that image family's tag encodes the language version —
> otherwise a `postCreateCommand`/feature version pin instead; see §
> Devcontainer), and manifest pins (rust-version, requires-python, engines,
> java toolchain) MUST agree; verify all four whenever any changes.

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

**`.github/workflows/security.yaml`** — write this exact shape verbatim,
inserting only the stack's toolchain setup step(s) where marked:

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

The security workflow's cron is always daily; the ci.yaml cron is always
monthly. Do not swap these or make either configurable.

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

On `/dev-playbook update`, any version bump must land in all four locations.
Use this table to find where each lives per file type:

| Location | Where the version lives | Who writes it |
|---|---|---|
| `.tool-versions` | one `<tool> <version>` line per runtime/tool | baseline layer (this file) |
| CI matrix | `ci.yaml` job matrix / setup-action `version:` inputs | stack file, `## CI` section |
| Devcontainer toolchain pin | `.devcontainer/devcontainer.json` — `image` field tag IF that family's tags encode the language version; otherwise the `postCreateCommand`/feature `version` option (image tag itself then just tracks a stable base, not the pinned language version) | baseline layer, § Devcontainer |
| Manifest pins | `rust-version` (Cargo.toml), `requires-python` (pyproject.toml), `engines` (package.json), Java toolchain version (pom.xml/build.gradle*), go.mod `go` directive, etc. | stack file, `## Update` section |

Whenever any one of these four changes, re-check all four for agreement
before declaring the update done — this is the version-consistency rule
applied mechanically.
