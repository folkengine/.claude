---
name: dev-playbook
description: Use when the user types /dev-playbook, asks to start, scaffold, bootstrap, or init a new project/repo/library in rust, python, go, java, cpp, c, ts-lib, or ts-next, or asks to bump/update an existing playbook repo's toolchain, dependencies, or language version. Replaces forking the devplaybooks GitHub org templates.
---

# Dev Playbook

Scaffold repos the devplaybooks way: opinionated supporting files layered on top
of the stack's native init — quality gates, CI, security scanning, CLAUDE.md,
and an OKF knowledge bundle — no application code beyond hello-world, and a
quality gate that is green before the first commit. Also updates an existing
playbook repo's toolchain and dependencies to latest or to pinned versions.
"Cruel to be kind in the right measure."

## How to read this skill

Always read `references/baseline.md` plus exactly ONE stack file from the
roster. Never read more than one stack file per run.

## Stack roster

| Key | Reference | Stack-specific questions |
|---|---|---|
| rust | references/rust.md | lib vs bin; edition/MSRV; miri opt-in |
| python | references/python.md | lib vs app |
| go | references/go.md | module path |
| java | references/java.md | maven vs gradle; JDK version (default 21) |
| cpp | references/cpp.md | cmake vs bazel; gtest vs catch2 (bazel→gtest only) |
| c | references/c.md | — |
| ts-lib | references/ts-lib.md | package scope; entry points |
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
   Makefile-with-cc-rules + Check-based tests/ for c, package.json). Read the matching stack file. On a repo
   that only partially matches playbook conventions, list what was and wasn't
   recognized and touch only the recognized parts.
2. **Dirty-tree check** — `git status --porcelain`; if dirty, warn and get
   explicit go-ahead before touching files (reading git state is allowed;
   changing it is not).
3. **Resolve targets** — latest stable per tool, overridden by explicit pins.
4. **Propagate versions** to all four locations: `.tool-versions`, CI matrix,
   devcontainer toolchain pin (image tag where the family encodes the
   language version; otherwise the postCreateCommand/feature pin — see
   baseline.md § Devcontainer), manifest pins. Bump GitHub Actions `uses:`
   versions too.
5. **Update dependencies** — run the stack file's Update-section commands.
6. **Drift check** — for each generated file the stack file defines a
   drift probe for (its Update section names them), regenerate what the
   current toolchain would produce and diff against the repo's file.
   REPORT divergence with the actual diff; never silently rewrite — after
   the first commit these files belong to the user. Offer to apply the
   fresh output only if the user asks.
7. **Verify** — `make ayce` to green, security-scan included. If an upgrade
   breaks the build, report the offender and offer to hold it back pinned so
   the rest lands.
8. **Record** — append dated `.okf/log.md` entry; update
   `.okf/decisions/toolchain.md` if a tool (not just a version) changed.
9. **Hand off** — report what changed and why; print git commands, never run.

## Hard rules

- Never run state-changing git commands. Print them for the user.
- `make ayce` is always the default Makefile target; its meaning never varies.
- One security-scan definition (`bin/security-scan`); Makefile and CI call it.
- The four version-declaring locations always agree.
- Report failures plainly; never claim a green gate that isn't.
- Offline or registry unreachable: do what is possible, then list exactly which
  steps (version resolution, dependency fetch, advisory databases) need
  connectivity to finish.
