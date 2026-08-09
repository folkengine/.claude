# C — stack file

Read together with `references/baseline.md`. This file is instructions for
you, the executing agent — carry out each section as a step, don't just
summarize it. Apply after the stack's native init has already run, following
baseline's layer order: baseline files → AI files → stack configs (this
file's Config files / Quality gate / CI sections) → `.okf/` seeding.

This is the plain-Make stack: no build-system generator (no CMake, no
Bazel, no Autotools). The Makefile you write in `## Quality gate` below IS
the build system — its `build`/`test` targets contain real compile and link
rules, not calls out to a separate configure/generate step. That is the one
structural way this stack differs from `cpp.md`: C++'s Makefile always
shells out to CMake/Bazel; C's Makefile compiles directly with `cc`.

## Init

1. Create the plain layout — `src/` (implementation), `include/` (public
   headers), `tests/` (Check test sources). No project-generator tool
   creates these; write the files directly.
2. Write a minimal hello-world split across a library file and an entry
   point, so there is something for both `build` and `test` to exercise:

   `include/greet.h`:
   ```c
   #ifndef GREET_H
   #define GREET_H

   const char *greet(void);

   #endif
   ```

   `src/greet.c`:
   ```c
   #include "greet.h"

   const char *greet(void) { return "Hello, World!"; }
   ```

   `src/main.c`:
   ```c
   #include <stdio.h>

   #include "greet.h"

   int main(void) {
     printf("%s\n", greet());
     return 0;
   }
   ```
3. Write exactly one Check test, `tests/test_greet.c` (full content and the
   reasoning behind its one non-obvious line — the `NOLINT` comment on the
   `START_TEST` line — are in `## Quality gate` below, since that line only
   makes sense once `lint` has been explained). This is the "one Check
   test" the brief calls for; do not scaffold a second one during Init —
   more arrive as the project grows real functions to cover (see
   `## CLAUDE.md addenda`).
4. Interview: **which OSS license(s)?** — feeds baseline's `LICENSE-*` copy
   step. No C-specific license-scanning config depends on this choice (see
   `## Quality gate`'s `security-scan` notes on why C has no dependency
   manifest to police).
5. No other native init step exists for this stack — there is no
   `cmake init`/`bazel mod init`/package-manager equivalent for plain
   Make + Check. The files above and the Makefile in `## Quality gate` are
   the entire scaffold.

## Toolchain

Unlike every other stack in this playbook, **no tool in the C stack gets a
`.tool-versions` line.** Walk through why, tool by tool, so this isn't a
silent omission:

| Tool | Role | Why no `.tool-versions` line |
|---|---|---|
| `cc` (clang or gcc) | compiler | The compiler is the OS/devcontainer's system toolchain, invoked via the `cc` alias (which resolves to whichever of clang/gcc the platform provides) — not a project-local, asdf/mise-managed install the way `rustup`-managed `rustc` or an asdf `cmake` plugin is. CI tracks `ubuntu-latest`'s own compiler version; see `## Update` for how that's bumped. |
| `make` | build driver | Always present as part of the base OS/devcontainer image; not independently versioned by any project. |
| Check (`libcheck`) | unit test framework (the org's chosen C test framework, same rationale as GoogleTest's default status in `cpp.md`: the framework other C templates already used) | Installed via the **system package manager** — `apt-get install libcheck-dev` on Ubuntu/devcontainer/CI, `brew install check` on macOS — not via asdf/mise. No asdf/mise plugin for Check has meaningful adoption; this is a system library with headers and a `.pc` file, not a standalone versioned CLI. Discovered at build time via **pkg-config**: `pkg-config --cflags check` / `pkg-config --libs check` (see `## Config files` and `## Quality gate` for the exact Makefile wiring — **verified** on this task's authoring machine: `pkg-config --cflags check` resolved to `-I/opt/homebrew/Cellar/check/0.15.2/include -D_THREAD_SAFE` and `--libs` to `-L/opt/homebrew/Cellar/check/0.15.2/lib -lcheck` against a Homebrew `check` 0.15.2 install). |
| `clang-format` | formatter | Same finding as `cpp.md`: no meaningful standalone asdf/mise plugin; ships as part of the LLVM/compiler toolchain. On Linux CI/devcontainer, comes from the distro's `clang-format` package (apt) or LLVM directly. On macOS it's present via Homebrew's `llvm` formula. **Verified**: `clang-format --style=file` (picking up `.clang-format` below) correctly reformatted this task's sample files, confirmed with `clang-format` 22.1.8 (Homebrew LLVM). |
| `clang-tidy` | linter | Same finding as `cpp.md`: **not included in Apple's Command Line Tools/Xcode clang on macOS** — confirmed during this task's authoring (`clang-tidy: command not found` against the system toolchain; `brew install llvm` then `$(brew --prefix llvm)/bin/clang-tidy` was needed, not symlinked onto `PATH` by default). On Linux CI/devcontainer, install via the distro's `clang-tidy` package. |
| osv-scanner | security scanner | Invoked by `bin/security-scan`; best-effort (see `## Quality gate`). Standalone static binary, not asdf/mise-managed, same as `cpp.md`. |

Because no tool here gets a `.tool-versions` line, baseline's
version-consistency rule (`.tool-versions` / CI matrix / devcontainer image
/ manifest pin must agree) has **no CI-matrix entry and no manifest pin to
check for this stack** — a plain Makefile project has no `Cargo.toml`-style
manifest. The **only** version-bearing artifact is the devcontainer image
tag (see below) and the implicit compiler version `ubuntu-latest` installs
via `apt-get` in CI. State this plainly to the user rather than silently
skipping the rule: this stack's version-consistency set has exactly one
member, the devcontainer tag, so there is nothing to cross-check against;
still re-verify it on every `/dev-playbook update` run (see `## Update`).
This is the low end of the same principle Python sits at the high end of —
the set is per-stack, which is why the rule is never stated as a count.

Record all of the above (tool → role → one-line why) in
`.okf/decisions/toolchain.md` during OKF seeding — do not restate this
prose in `CLAUDE.md` or the README.

For the devcontainer, use the `mcr.microsoft.com/devcontainers/cpp` image
family (there is no separate `.../c` image; the `cpp` image already ships
gcc, clang, make, and pkg-config, which cover this stack's whole toolchain).
Install Check via the devcontainer's `postCreateCommand` — append
`sudo apt-get update && sudo apt-get install -y libcheck-dev` — since it is
a project dependency the base image doesn't carry, and baseline's
devcontainer is image + `postCreateCommand` only (no Dockerfile, so there
is no `RUN` mechanism). Resolve the current image tag at scaffold time.

## Config files

**`.clang-format`** — write verbatim at the repo root, identical to the C++
stack's file (formatting is language-agnostic within the C-family LLVM
tooling):

```yaml
BasedOnStyle: LLVM
ColumnLimit: 100
```

**Verified during this task's authoring**: `clang-format -i` reformatted
`src/greet.c`/`src/main.c`/`tests/test_greet.c` to LLVM style (2-space
indent, 100-column limit) with `clang-format` 22.1.8 (Homebrew LLVM); the
whole tree re-formatted cleanly with no manual fixup needed.

**`.clang-tidy`** — write verbatim at the repo root. This is `cpp.md`'s list
with `modernize-*` dropped (those checks target C++-only features like
`auto`/`nullptr`/trailing-return-type and don't apply to C):

```yaml
Checks: >
  -*,
  bugprone-*,
  performance-*,
  readability-*
WarningsAsErrors: ''
```

Leave `WarningsAsErrors` empty in the file itself (same split as `cpp.md`:
interactive/IDE use shows warnings without hard-failing); the `lint` gate
phase elevates findings to errors on the command line via
`--warnings-as-errors='*'`.

**Verified finding unique to this stack — read before wiring `lint`.**
Check's own header (`check.h`, wherever pkg-config resolves it from) gets
linted right along with your own sources unless you scope diagnostics away
from it. This differs from `cpp.md`'s GoogleTest/Catch2 case: those are
pulled via CMake `FetchContent`, and GoogleTest's own CMake config marks its
include directory `SYSTEM`, so a CMake-generated `compile_commands.json`
naturally passes `-isystem` for it and clang-tidy's default header filter
(which only excludes *system* headers) skips it for free. `pkg-config
--cflags check` instead emits a plain `-I` flag — not `-isystem` — so
without extra scoping, `clang-tidy` reports ~50 findings **inside
`check.h` itself** (`readability-identifier-length` on parameters like
`Suite *s`, `bugprone-reserved-identifier` on Check's internal `_`-prefixed
macros, etc.) and fails `--warnings-as-errors='*'` on code you don't own and
can't fix. The fix, **verified working**: pass
`--header-filter='^(src|include|tests)/'` so only your own tree's headers
are reported on. With that filter, a real clang-tidy run against this
stack's sample `src/`+`include/`+`tests/` tree (Homebrew LLVM `clang-tidy`
22.1.8) dropped from ~740 warnings to a clean pass.

**A second, related verified finding**: Check's `START_TEST(name)` macro
expands to a function whose parameter is named `_i` — this trips
`readability-identifier-length` on the `START_TEST(...)` line itself, in
*your* test file, for every single test you write; it is not a false
positive from a header, it is baked into the macro every Check test
necessarily uses. **Verified fix**: a same-line suppression comment on the
`START_TEST` line (shown in the full `tests/test_greet.c` listing in
`## Quality gate` below, together with the `Suite`/`TCase`/`SRunner` runner
shape it needs to actually execute):

```c
START_TEST(test_greet_returns_hello_world) {  // NOLINT(readability-identifier-length)
  ck_assert_str_eq(greet(), "Hello, World!");
}
END_TEST
```

`// NOLINTNEXTLINE(...)` on the line *above* was tried first and did **not**
suppress the finding (the diagnostic's location survives macro expansion in
a way that only the same-line `NOLINT` catches) — use same-line `NOLINT`,
not `NOLINTNEXTLINE`, for this specific macro. This is the one line in every
Check test file that needs it; it is a documented, understood suppression
per the naming addenda's "suppress the specific diagnostic at the specific
line, with a comment explaining why it's a false positive" rule, not a
blanket pragma.

Add stack-appropriate ignores to the shared `.gitignore` (baseline writes
the file; these are the C-specific lines): `/build`, `*.o`, `*.obj`,
`*.exe`, `*.out`, `*.dSYM/`.

For `.editorconfig`, add a C override: 2-space indent for `*.c`, `*.h` —
matching what `clang-format`'s `BasedOnStyle: LLVM` above actually produces
(LLVM style's default indent width is 2; **verified** against this stack's
sample files), so the editor and the formatter never fight each other.

## Quality gate

Before the Makefile, write the complete `tests/test_greet.c` this stack's
`test` target builds and runs — the two-line `START_TEST`/`END_TEST`
snippet in `## Config files` above only showed the `NOLINT` line in
isolation; this is the full, working Check test-runner shape, **verified
end-to-end** (built via the Makefile below, `SRunner` executed,
`100%: Checks: 1, Failures: 0, Errors: 0`):

```c
#include <check.h>

#include "greet.h"

START_TEST(test_greet_returns_hello_world) {  // NOLINT(readability-identifier-length)
  ck_assert_str_eq(greet(), "Hello, World!");
}
END_TEST

static Suite *greet_suite(void) {
  Suite *suite = suite_create("Greet");
  TCase *tcase_core = tcase_create("Core");
  tcase_add_test(tcase_core, test_greet_returns_hello_world);
  suite_add_tcase(suite, tcase_core);
  return suite;
}

int main(void) {
  Suite *suite = greet_suite();
  SRunner *runner = srunner_create(suite);

  srunner_run_all(runner, CK_NORMAL);
  int number_failed = srunner_ntests_failed(runner);
  srunner_free(runner);
  return (number_failed == 0) ? 0 : 1;
}
```

Every Check test file needs this same shape: one `START_TEST`/`END_TEST`
pair per test case, a `Suite`-building function that creates a `TCase`,
adds each test to it via `tcase_add_test`, and adds the `TCase` to the
`Suite`; and a `main()` that creates an `SRunner` from the suite, calls
`srunner_run_all`, and — this is the part with no safe default, get it
wrong and CI reports a failing suite as a green build — **derives the
process exit code from `srunner_ntests_failed(runner)`**, not from
`srunner_run_all`'s (void) return value. `srunner_run_all` never signals
failure through its own return; only `srunner_ntests_failed` after the run
tells you whether any test failed.

The Makefile below fills baseline's skeleton with **real compile/link
recipes** — this is the centerpiece of this stack file; every other stack
either shells out to a package manager (`cargo`, `go`) or a build-system
generator (`cmake`/`bazel`). Shown complete, ready to write verbatim (adjust
only the source-file list if the project's `src/` layout grows beyond the
hello-world sample):

```makefile
CC       ?= cc
CFLAGS   = -std=c17 -Wall -Wextra -Werror -Iinclude
CHECK_CFLAGS := $(shell pkg-config --cflags check)
CHECK_LIBS   := $(shell pkg-config --libs check)

BUILD_DIR := build
LIB_SRCS  := $(filter-out src/main.c,$(wildcard src/*.c))
LIB_OBJS  := $(patsubst src/%.c,$(BUILD_DIR)/%.o,$(LIB_SRCS))

APP      := $(BUILD_DIR)/app
TEST_BIN := $(BUILD_DIR)/test_greet

.PHONY: default help clean fmt build test lint security-scan docs ayce
default: ayce

help:  ## self-documenting: every target has a '## comment' printed here
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-16s %s\n", $$1, $$2}'

clean: ## remove build artifacts
	rm -rf $(BUILD_DIR)

fmt: ## format all sources
	clang-format -i src/*.c include/*.h tests/*.c

$(BUILD_DIR)/%.o: src/%.c include/greet.h
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(APP): $(BUILD_DIR)/main.o $(LIB_OBJS)
	$(CC) $(CFLAGS) -o $@ $^

build: $(APP) ## compile/build

$(TEST_BIN): tests/test_greet.c $(LIB_OBJS)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(CHECK_CFLAGS) -o $@ $^ $(CHECK_LIBS)

test: build $(TEST_BIN) ## run all tests
	$(TEST_BIN)

lint: ## static analysis at the pedantic end
	clang-tidy --warnings-as-errors='*' --header-filter='^(src|include|tests)/' \
	  src/*.c include/*.h tests/*.c -- $(CFLAGS) $(CHECK_CFLAGS)

security-scan: ## dependency vulnerability scan
	./bin/security-scan

docs: ## build docs, fail on warnings
	@echo "No docs generator configured for this project (C stack has no default docs toolchain)."

ayce: clean fmt build test lint security-scan docs ## all-you-can-eat: full pre-push sweep

.PHONY: valgrind
valgrind: build $(TEST_BIN)  ## optional: run the test binary under valgrind (Linux only, not in ayce)
	valgrind --leak-check=full --error-exitcode=1 $(TEST_BIN)
```

**Verified end-to-end on this task's authoring machine** (macOS, Homebrew
`check` 0.15.2, Homebrew LLVM 22.1.8 for `clang-format`/`clang-tidy`,
Apple clang for `cc`): `make clean`, `make fmt`, `make build`, `make test`
(ran the Check suite, `100%: Checks: 1, Failures: 0, Errors: 0`), and
`make lint` (clean pass with `--header-filter` and the `NOLINT` line from
`## Config files` above) all ran green in sequence against the sample
`src/`/`include/`/`tests/` tree. `make docs` printed its no-op message and
exited 0.

Notes:
- `build` depends only on `$(APP)`, not the test binary — `test`'s own
  prerequisite (`build`) plus its own `$(TEST_BIN)` rule builds the test
  binary separately, so `make build` alone never requires Check to be
  installed. This matters for a bare "can I compile the app" check on a
  machine without libcheck.
- `CFLAGS` intentionally has no version-hardcoded pieces beyond
  `-std=c17`, which is the language standard the brief mandates (a
  standard string, not a tool version, same category as Rust's `edition`
  string) — do not add a versioned optimization flag or similar here.
- `-Werror` here is **safe to apply at the top of the file**, unlike
  `cpp.md`'s per-target scoping requirement — there is no `FetchContent`/
  bzlmod third-party code being compiled by this Makefile's `build`/`test`
  rules to trip warnings you don't own. Check's headers are only ever
  `#include`d, never compiled as part of *this* project's own translation
  units, so `-Werror` never sees inside them.
- `valgrind` is deliberately **not** part of `ayce` — it's Linux-first
  tooling with weak/absent support on Apple Silicon macOS (not verified
  locally for that reason); wire it as an opt-in target developers and CI
  can call explicitly, per the brief's "note valgrind as optional target"
  instruction.

Write `bin/security-scan`'s body (baseline owns the shebang/`set -euo
pipefail` skeleton and the `chmod +x` step). **Same script as `cpp.md`,
same caveat wording** — C has no single universal dependency manifest
either, and this project in particular has zero third-party C
dependencies at scaffold time (Check is a system/dev dependency, not
something this project ships or vendors):

```bash
# C has no single universal dependency manifest (unlike Cargo.lock,
# package-lock.json, go.sum). osv-scanner best-effort scans whatever
# lockfiles/SBOMs actually exist in the tree (a vendored dependency's own
# manifest, a generated CycloneDX/SPDX SBOM). This project's only C
# dependency (Check) is a system/dev-time library discovered via
# pkg-config, not a vendored or manifest-tracked one, so there is nothing
# for osv-scanner to find until this project takes on real vendored
# dependencies. This is a genuine best-effort net, not a guarantee: treat
# a clean run as "nothing scannable found," not "confirmed
# vulnerability-free."
if ! command -v osv-scanner >/dev/null 2>&1; then
  echo "security-scan: osv-scanner not installed, skipping (see" \
       "https://github.com/google/osv-scanner for install instructions)" >&2
  exit 0
fi

set +e
output=$(osv-scanner scan source . 2>&1)
status=$?
set -e
echo "$output"

if [ "$status" -eq 0 ]; then
  exit 0
fi
if echo "$output" | grep -qi "no package sources found"; then
  echo "security-scan: no scannable manifests found, treating as pass" >&2
  exit 0
fi
exit "$status"
```

**Not verified locally** — `osv-scanner` was not installed in this task's
verification environment (confirmed via `which osv-scanner` returning
nothing), so this script is name-checked against osv-scanner's documented
CLI behavior only, identical caveat to `cpp.md`'s. If your osv-scanner
version's "nothing found" wording differs, adjust the `grep` pattern.

## CI

Generate `.github/workflows/ci.yaml` from baseline's triggers block (push,
pull_request, monthly cron). Matrix over compiler (gcc, clang) on
`ubuntu-latest`, mirroring `cpp.md`'s compiler matrix since the same
`CC ?= cc` override in the Makefile makes this trivial to drive from CI.

Resolve every `@<resolved-major>` below at scaffold time — see baseline.md,
§ CI workflows → Action version pins, for the procedure and the offline
fallback table. Never write a major copied from this file.

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
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        compiler: [gcc, clang]
    timeout-minutes: 45
    env:
      CC: ${{ matrix.compiler }}
    steps:
      - uses: actions/checkout@<resolved-major>
      - run: sudo apt-get update && sudo apt-get install -y libcheck-dev clang-format clang-tidy pkg-config
      - run: make build
      - run: make test
      - run: clang-format --dry-run --Werror src/*.c include/*.h tests/*.c
      - run: make lint
```

The apt package for Check's headers is `libcheck-dev` (it also pulls in the
runtime `libcheck0`) — **not verified against a live Ubuntu apt run in this
task's authoring** (only Homebrew's `check` formula was verified locally);
if a given Ubuntu release resolves the package differently, adjust the
package name here and note it in `.okf/decisions/toolchain.md`.

Every job must stay consistent with the (empty, for this stack — see
`## Toolchain`) `.tool-versions`. There is no MSRV-style matrix entry to
resolve here; the `[gcc, clang]` matrix values are literal compiler names,
not versions.

Generate `.github/workflows/security.yaml` per baseline's exact verbatim
shape (daily cron, unchanged from baseline), inserting this stack's
toolchain setup step **after** the checkout step baseline already writes —
do not repeat `actions/checkout@<resolved-major>` here:

```yaml
      - run: |
          curl -sSfL https://github.com/google/osv-scanner/releases/latest/download/osv-scanner_linux_amd64 \
            -o /usr/local/bin/osv-scanner
          chmod +x /usr/local/bin/osv-scanner
      - run: ./bin/security-scan
```

## CLAUDE.md addenda

Copy this section verbatim into the target repo's `CLAUDE.md`, after the
baseline's "Definition of done" and "Knowledge bundle pointer" sections:

---

### C: Testing Requirements

- Every function — C has no `public`/`private` access modifiers, so this
  means every function, not just ones at a module boundary — must have at
  least one Check test covering its happy path, plus tests for documented
  error/edge conditions.
- Use Check's `START_TEST`/`END_TEST` macros for each test case; group
  related cases into a `TCase`, add the `TCase` to a `Suite`, and run the
  suite through an `SRunner` in the test file's own `main()` — see
  `tests/test_greet.c` from `## Init`/`## Quality gate` for the working
  shape.
- Name tests descriptively: `test_<function>_<scenario>` — the name should
  read as a sentence describing the behavior under test.
- Every `START_TEST(...)` line needs the `// NOLINT(readability-identifier-length)`
  comment described in `## Config files` — Check's own macro, not your
  code, introduces the short identifier that trips this check.
- Place one test file per source file under test (`greet.c` →
  `test_greet.c`), mirroring `src/`'s layout under `tests/`.

### C: Memory Management

- Every heap allocation (`malloc`/`calloc`/`realloc`) is paired with a
  matching `free`; document who owns a pointer (and therefore who must
  free it) at the point of allocation or in the function's header comment.
- For functions with multiple resources to release on an error path,
  prefer a single `cleanup:` label reached via `goto` over duplicating
  free/close calls at every early return — the common, accepted C idiom
  for this, not a code smell in this language.
- Never free a pointer twice, and set a pointer to `NULL` immediately after
  freeing it if it could otherwise be inspected or freed again later in
  the same scope.
- Run `make valgrind` (Linux; see `## Quality gate` — an opt-in target, not
  part of `ayce`) whenever a change touches allocation/ownership logic, to
  catch leaks and use-after-free bugs Check's own test run won't surface on
  its own.

### C: Declarations and Warnings

- **No implicit declarations.** Every function must be declared (via its
  header) before it is called — `-std=c17 -Wall -Wextra -Werror` already
  turns a missing declaration into a hard compile error (**verified**: an
  undeclared-function call fails with `error: call to undeclared function
  ...; ISO C99 and later do not support implicit function declarations
  [-Wimplicit-function-declaration]` under this exact `CFLAGS`), so this is
  mechanically enforced, not just a style rule — but write code that never
  needs to lean on that safety net: `#include` the right header instead of
  relying on the compiler to catch a missing one.
- Never silence a warning with a blanket `#pragma` disabling a whole
  category across a file; suppress the specific diagnostic at the specific
  line, with a comment explaining why it's a false positive (see the
  `NOLINT` example in `## Config files`).

### C: Naming

- `snake_case` for functions, variables, and file names; `PascalCase`/
  `UpperCamelCase` only for `typedef`'d struct/enum names if the project
  uses them, otherwise `struct foo`/`enum bar` with a `_t`-suffixed
  `typedef` when a bare type name reads better at call sites.
- Avoid single-letter names except loop indices (`i`, `j`, `k`); this is
  also mechanically enforced by `.clang-tidy`'s
  `readability-identifier-length` check (part of the `readability-*` group
  enabled above) — expect it to flag short parameter/variable names during
  `lint`, same as `cpp.md`'s naming addenda.

### C: Code Organization

- Keep functions focused and single-purpose.
- Extract complex logic into well-named helper functions.
- Group related functions in one `.c` file per logical concern; keep
  translation units small rather than growing one giant `src/main.c`.
- Use `static` for any function or file-scope variable not needed outside
  its own `.c` file — the narrowest linkage that works, mirroring `cpp.md`'s
  "narrowest access level" guidance in C's terms.
- Separate interface (`include/`) from implementation (`src/`) — public
  headers should be minimal and stable; never put function bodies or
  file-private helpers in a header.

---

## Update

On `/dev-playbook update` for a C repo:

1. Bump the devcontainer image tag (`mcr.microsoft.com/devcontainers/cpp`)
   to the current release. This is the **only** version-bearing location
   this stack has — see `## Toolchain` for why there is no `.tool-versions`
   line, CI-matrix version, or manifest pin to cross-check against it here;
   still state baseline's version-consistency rule verbatim to the user and
   confirm there is nothing else to reconcile it against for this stack.
2. The CI compiler versions (gcc/clang installed via `apt-get`) track
   Ubuntu's own release cadence on `ubuntu-latest`, same as `cpp.md`'s
   Update section — if pinning a specific `ubuntu-XX.04` runner instead of
   `ubuntu-latest`, bump that pin here and keep the devcontainer image tag
   in lockstep.
3. **C dependencies are vendored or system, and updates are a manual
   review, documented honestly** — there is no `Cargo.lock`/`go.sum`-style
   lockfile in this stack to bump mechanically. If this project later
   vendors third-party C source (a single-header library dropped into
   `src/` or `include/`, a git submodule) or takes on a new system library
   discovered via `pkg-config` (the way Check already is), each such
   dependency's version is a manual decision: record the exact
   version/commit vendored (or the system package version resolved) in
   `.okf/decisions/toolchain.md`, and re-run the full gate after any bump —
   there is no automated diff/audit tool doing this for you the way
   `cargo deny`/`govulncheck` do for other stacks.
4. If `clang-format`/`clang-tidy` behavior changed because the underlying
   LLVM/compiler version moved (new checks added, new formatting
   defaults), re-run `make fmt` and `make lint` and review the diff/
   findings before considering the bump complete — same note as `cpp.md`:
   these tools have no independent version pin to bump, but their
   *behavior* still moves with the compiler toolchain.
5. Run `make ayce` and confirm it is green before considering the update
   done.
