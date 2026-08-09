# C++ — stack file

Read together with `references/baseline.md`. This file is instructions for
you, the executing agent — carry out each section as a step, don't just
summarize it. Apply after the stack's native init has already run, following
baseline's layer order: baseline files → AI files → stack configs (this
file's Config files / Quality gate / CI sections) → `.okf/` seeding.

This stack collapses five prior org template repos
(`cpp_cmake_gtest`, `cpp_bazel_gtest`, and their catch2/other variants) into
one parameterized flow. It is parameterized on two axes: **build system**
(CMake or Bazel, mutually exclusive per repo — a repo picks one and does not
mix them) and **test framework** (GoogleTest or Catch2 — but **Bazel supports
GoogleTest only**; Catch2 is a CMake-path-only option). Every section below
branches on the Init interview's two answers, and the `## Quality gate` table
always shows both build-system commands side by side, like `java.md`'s
Gradle/Maven table, so you can find the right one regardless of which was
chosen.

## Init

1. Interview the user: **CMake or Bazel?** Default to **CMake** if the user
   has no preference. This choice is permanent for the repo — do not mix
   build systems.
2. Interview the user: **GoogleTest (gtest) or Catch2?** Default to
   **GoogleTest** if the user has no preference. **If the user chose Bazel in
   step 1, GoogleTest is the only option — do not offer Catch2 on the Bazel
   path; if the user asks for Catch2 with Bazel, tell them plainly that this
   stack only wires up GoogleTest for Bazel and ask them to either switch to
   CMake or accept GoogleTest.**
3. Resolve the **current CMake minor version** at scaffold time (run
   `cmake --version` on the scaffolding machine, or check
   https://cmake.org/download/ for latest) — never hardcode one from memory.
   This only applies to the CMake path.
4. Run the native init for the chosen build system:
   - **CMake**:
     - Create `CMakeLists.txt` at the repo root:
       ```cmake
       cmake_minimum_required(VERSION <resolved-cmake-minor>)

       project(<project> VERSION 0.0.1 LANGUAGES CXX)

       set(CMAKE_CXX_STANDARD 20)
       set(CMAKE_CXX_STANDARD_REQUIRED ON)
       set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

       include(FetchContent)

       add_subdirectory(src)

       enable_testing()
       add_subdirectory(test)
       ```
       `<resolved-cmake-minor>` is a literal placeholder — replace it with the
       version resolved in step 3 (e.g. `3.28`), written as a bare
       `<major>.<minor>`, never the exact patch version of whatever CMake
       happens to be installed on the scaffolding machine. **Verified during
       this task's authoring**: this exact skeleton configures, builds, and
       links cleanly with CMake 4.4.2/AppleClang.
     - **Do not** put `-Wall -Wextra -Werror` in a top-level
       `add_compile_options()` call — see the warning callout in
       `## Config files` below for why (FetchContent'd third-party code will
       fail your own `-Werror`).
     - Layout: `include/` (public headers), `src/` (library sources, its own
       `CMakeLists.txt` building a `src` library target), `test/` (test
       sources, its own `CMakeLists.txt`, FetchContent-declares the chosen
       test framework). This mirrors both source templates' directory shape.
     - Create `CMakePresets.json` with a `default` and a `release` preset
       (see `## Config files`).
   - **Bazel**:
     - Create `MODULE.bazel` at the repo root (bzlmod — **do not** create a
       `WORKSPACE` file; both port-taste source repos still carried a stale
       `WORKSPACE` using the legacy `http_archive` pattern, which this
       playbook deliberately drops in favor of pure bzlmod):
       ```python
       module(name = "<project>", version = "0.0.1")

       bazel_dep(name = "rules_cc", version = "<resolved-rules_cc-version>")
       bazel_dep(name = "googletest", version = "<resolved-googletest-version>")
       ```
       Resolve both versions at scaffold time from the Bazel Central
       Registry (https://bcr.bazel.build/modules/rules_cc/metadata.json and
       .../modules/googletest/metadata.json) — **never pin an old cached
       version from memory**. **Verified during this task's authoring**: an
       older pin (`rules_cc 0.0.9` + `googletest 1.15.2`) failed to build
       under current Bazel (9.2.0) with `This rule has been removed from
       Bazel. Please add a load() statement for it` inside googletest's own
       BCR-published `BUILD.bazel` — a real incompatibility between a stale
       module release and a newer Bazel, not a config mistake. Bumping to
       the latest BCR releases (`rules_cc 0.2.22` + `googletest
       1.17.0.bcr.2`) built and passed `bazel test //...` cleanly. This is
       exactly why versions are resolved at scaffold time, never hardcoded.
     - Layout: `include/` (public headers, `BUILD.bazel` with
       `exports_files`), `src/` (`cc_library` target named `src`, `BUILD.bazel`
       loading `cc_library` from `@rules_cc//cc:defs.bzl`), `test/`
       (`cc_test` target depending on `//src` and `@googletest//:gtest_main`,
       loading `cc_test` from the same `rules_cc` module — Bazel 9+ removed
       the native/builtin `cc_library`/`cc_test` rules, so the explicit
       `load()` is required, not optional).
5. Interview: **which OSS license(s)?** — feeds baseline's `LICENSE-*` copy
   step. No C++-specific license-scanning config depends on this choice.

## Toolchain

Write `.tool-versions` with **one line for the chosen build system only**
(CMake and Bazel are mutually exclusive per repo, so never write both
lines):

| Tool | Role | Notes |
|---|---|---|
| `cmake` | build system (CMake path only) | asdf `cmake` plugin confirmed present (`asdf-community/asdf-cmake`); mise also has first-class `cmake` support. Resolve the version at scaffold time. |
| `bazel` | build system (Bazel path only) | asdf `bazel` plugin confirmed present (`rajatvig/asdf-bazel`); mise also has first-class `bazel` support. Resolve the version at scaffold time. Note the wrapper-script convention doesn't apply here the way it does for Gradle/Maven — teams that want hermetic per-repo pinning typically layer Bazelisk (`USE_BAZEL_VERSION` / `.bazelversion` file) on top; that is a good addition but out of scope for this stack's default `.tool-versions`-only story. |

**Do not add a `.tool-versions` line for `clang-format` or `clang-tidy`.**
Neither has meaningful standalone asdf/mise plugin support worth pinning:
both ship as part of the LLVM/compiler toolchain, not as an independently
versioned CLI tool a plugin manager tracks.
- On Linux CI/devcontainer, they come from the distro's `clang-format`/
  `clang-tidy` packages (apt) or from installing LLVM directly.
- On macOS, **clang-tidy is NOT included in Apple's Command Line
  Tools/Xcode clang** — confirmed during this task's authoring
  (`clang-tidy: command not found` against the system toolchain).
  `clang-format` IS present via Homebrew's `llvm` formula, but `clang-tidy`
  needed the same formula explicitly:
  `brew install llvm` then use `$(brew --prefix llvm)/bin/clang-tidy` (not
  symlinked onto `PATH` by default, to avoid clobbering Xcode's clang).
  Tell the user this plainly if they're on macOS and `clang-tidy` isn't
  found.
- State the resolved LLVM/compiler version the CI matrix and devcontainer
  use in `.okf/decisions/toolchain.md` instead of `.tool-versions`.

Other tools in play (not `.tool-versions` lines — see rationale below):

| Tool | Role | Notes |
|---|---|---|
| GoogleTest (gtest) | test framework, default | CMake: pulled via `FetchContent`. Bazel: pulled via bzlmod `bazel_dep`. Not a system tool. |
| Catch2 | test framework, CMake-path opt-in only | pulled via `FetchContent`; **not available on the Bazel path** (see `## Init`). |
| osv-scanner | security scanner | invoked by `bin/security-scan`; best-effort (see `## Quality gate`). |
| Doxygen | docs generator, **opt-in, OFF by default** | only added if the user opts in during Init (see `## Quality gate`, `docs` phase). |

Rationale notes (feed these one-line whys into
`.okf/decisions/toolchain.md` during OKF seeding, do not restate them in
`CLAUDE.md` or the README):

- **CMake default over Bazel** — CMake has the lower ramp-up cost for a
  single-library/binary C++ project and the wider tooling story (IDE
  integration, `FetchContent`, presets); Bazel is offered for teams that
  already standardize on it or need its hermetic multi-language build
  graph, but it's the non-default because most new C++ projects don't need
  that weight yet.
- **GoogleTest default over Catch2** — GoogleTest is the test framework
  both port-taste source repos already used, has first-class bzlmod support
  (making it the only framework that works identically on both build
  paths), and its `gtest_discover_tests`/`cc_test` integration is
  well-trodden on both CMake and Bazel.
- **Catch2 CMake-only** — Catch2's Bazel/bzlmod support is thin to
  nonexistent compared to GoogleTest's first-party BCR module; rather than
  scaffold a fragile Bazel+Catch2 combination, this stack simply doesn't
  offer it.
- **osv-scanner over a C++-specific SCA tool** — C++ has no single
  universal dependency manifest the way Cargo/npm/pip do, so there is no
  natural "one obvious scanner" for this ecosystem the way `cargo-audit` is
  for Rust. osv-scanner is free, supports the manifest formats C++ projects
  sometimes do have (Conan lockfiles, vcpkg manifests, SBOMs), and degrades
  gracefully to a no-op when none exist — see the `security-scan` phase
  below for exactly how.
- **Doxygen opt-in, not default** — meaningful Doxygen output requires
  actually-maintained Doxygen-comment blocks across the codebase; forcing
  it on for a fresh scaffold with no doc comments yet would just produce an
  empty or warning-spammed doc site. Ask during Init; if declined, `docs`
  is a no-op that says so (see `## Quality gate`).

For the devcontainer, use the `mcr.microsoft.com/devcontainers/cpp` image
family; resolve the current tag at scaffold time and keep it in agreement
with `.tool-versions`. **If Bazel was chosen**, install Bazelisk in the
devcontainer's `postCreateCommand` (baseline's devcontainer is image +
`postCreateCommand` only — no Dockerfile, so there is no `RUN` mechanism;
the `cpp` image bundles CMake/compilers/ninja but not Bazel) — resolve the
current Bazelisk release at scaffold time, never hardcode one from memory.

## Config files

**`.clang-format`** — write verbatim at the repo root, for both build
systems (formatting is build-system-agnostic):

```yaml
BasedOnStyle: LLVM
ColumnLimit: 100
```

**Verified during this task's authoring**: `clang-format --style=file` picks
this up and correctly reformats an intentionally mis-formatted sample file
(collapsed braces, ragged spacing) to LLVM style with a 100-column limit —
confirmed with `clang-format` 22.1.8 (Homebrew LLVM).

**`.clang-tidy`** — write verbatim at the repo root:

```yaml
Checks: >
  -*,
  bugprone-*,
  modernize-*,
  performance-*,
  readability-*
WarningsAsErrors: ''
```

Leave `WarningsAsErrors` empty in the config itself (so IDEs/editors that
read this file show warnings without hard-failing interactively); the
`lint` gate phase below elevates findings to errors on the command line via
`--warnings-as-errors='*'` instead, keeping the pedantic-vs-interactive
split explicit rather than baking severity into the shared config file.

**Verified during this task's authoring** (Homebrew LLVM `clang-tidy`
22.1.8, `-p build` pointed at a CMake-generated `compile_commands.json`):
the exact `Checks:` list above loads correctly and flags real findings
against a two-line sample function (`modernize-use-trailing-return-type`,
`readability-identifier-length` on single-letter parameter names); adding
`--warnings-as-errors='*'` on the CLI turns those findings into a nonzero
exit code as intended.

**Warning callout — do not apply `-Wall -Wextra -Werror` globally.**
Verified during this task's authoring: a top-level CMake
`add_compile_options(-Wall -Wextra -Werror)` broke the build the moment
GoogleTest was fetched and compiled, because GoogleTest's own headers trip
`-Wcharacter-conversion` under a recent AppleClang — a warning in
*third-party* code that isn't yours to fix. Scope warnings-as-errors to your
own targets only:

```cmake
target_compile_options(src PRIVATE -Wall -Wextra -Werror)
```

Apply the same per-target scoping to any other first-party target (e.g. a
`app`/binary target if one exists); never to the whole `CMakeLists.txt` tree
once `FetchContent`-fetched dependencies are being compiled alongside it.

**CMake path** — `CMakePresets.json` at the repo root, `default` +
`release` presets (**verified**: both configure correctly with CMake 4.4.2,
`release` resolving `CMAKE_BUILD_TYPE=Release` in `CMakeCache.txt` as
expected):

```json
{
  "version": 6,
  "configurePresets": [
    {
      "name": "default",
      "displayName": "Default",
      "binaryDir": "${sourceDir}/build",
      "cacheVariables": {
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON",
        "CMAKE_BUILD_TYPE": "Debug"
      }
    },
    {
      "name": "release",
      "displayName": "Release",
      "inherits": "default",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release"
      }
    }
  ]
}
```

`test/CMakeLists.txt` `FetchContent`-declares the chosen test framework.
Resolve `<resolved-gtest-version>`/`<resolved-catch2-version>` at scaffold
time (current release tag) — never hardcode a version from memory here
either, same rule as the toolchain versions above, even though this is a
library dependency pin rather than a system tool version:

```cmake
# GoogleTest (default):
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/v<resolved-gtest-version>.zip
)
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)
include(GoogleTest)

add_executable(example_test example_test.cpp)
target_link_libraries(example_test PRIVATE src GTest::gtest_main)
gtest_discover_tests(example_test)

# Catch2 (opt-in alternative):
FetchContent_Declare(
  Catch2
  GIT_TAG v<resolved-catch2-version>
  GIT_REPOSITORY https://github.com/catchorg/Catch2.git
)
FetchContent_MakeAvailable(Catch2)
include(CTest)
include(Catch)

add_executable(example_test example_test.cpp)
target_link_libraries(example_test PRIVATE src Catch2::Catch2WithMain)
catch_discover_tests(example_test)
```

**Verified during this task's authoring**: the GoogleTest branch above
(with a pinned `v1.15.2` URL) configures, builds (once `-Werror` is scoped
per-target as described above), and `ctest --test-dir build` passes the
sample test. The Catch2 branch was name-checked against Catch2's own CMake
integration docs, not built locally (no need — it follows the identical
`FetchContent` + `*_discover_tests` shape already verified for GoogleTest).

**Bazel path** — `MODULE.bazel` per `## Init` above. `src/BUILD.bazel`:

```python
load("@rules_cc//cc:defs.bzl", "cc_library")

cc_library(
    name = "src",
    srcs = ["example.cpp"],
    hdrs = ["//include:example.hpp"],
    includes = ["../include"],
    visibility = ["//visibility:public"],
)
```

`test/BUILD.bazel`:

```python
load("@rules_cc//cc:defs.bzl", "cc_test")

cc_test(
    name = "example_test",
    srcs = ["example_test.cpp"],
    deps = [
        "//src",
        "@googletest//:gtest_main",
    ],
)
```

**Verified during this task's authoring**: with current BCR versions
(`rules_cc 0.2.22`, `googletest 1.17.0.bcr.2`), `bazel test //test:...`
compiles GoogleTest from source via bzlmod and passes; `bazel build //...`
and `bazel clean` both work as expected.

Add stack-appropriate ignores to the shared `.gitignore` (baseline writes
the file; these are the C++-specific lines): CMake path —
`/build`, `/cmake-build-*`, `compile_commands.json`; Bazel path —
`/bazel-*` (the build-system symlinks Bazel creates in the repo root).
Both paths: `*.o`, `*.obj`, `*.so`, `*.dylib`, `*.a`, `*.exe`.

For `.editorconfig`, add a C++ override: 4-space indent for `*.cpp`,
`*.hpp`, `*.cc`, `*.h`.

## Quality gate

Fill the baseline Makefile skeleton's phase bodies using the row for
whichever build system the Init interview selected. Both commands are
shown for every phase so you can find the right one regardless of choice —
never put both commands in the same generated Makefile recipe, only the row
matching the repo's chosen build system:

| Phase | CMake | Bazel |
|---|---|---|
| `clean` | `rm -rf build` | `bazel clean` |
| `fmt` | `clang-format -i $$(find src include test -name '*.cpp' -o -name '*.hpp')` | `clang-format -i $$(find src include test -name '*.cpp' -o -name '*.hpp')` |
| `build` | `cmake --preset default && cmake --build build` | `bazel build //...` |
| `test` | `ctest --test-dir build` | `bazel test //...` |
| `lint` | `clang-tidy -p build --warnings-as-errors='*' $$(find src include test -name '*.cpp' -o -name '*.hpp')` | `bazel run @hedron_compile_commands//:refresh_all && clang-tidy -p . --warnings-as-errors='*' $$(find src include test -name '*.cpp' -o -name '*.hpp')` (opt-in, see caveat below) |
| `security-scan` | `./bin/security-scan` | `./bin/security-scan` |
| `docs` | opt-in Doxygen, else no-op (see below) | opt-in Doxygen, else no-op (see below) |

Notes:
- `fmt` is identical on both build systems — `clang-format` operates on
  source files directly and doesn't care which build system compiles them.
  **Verified**: the command above reformats the whole tree in place.
- `build` on CMake configures against the `default` preset then builds
  (the `release` preset exists for an explicit optimized build, invoked
  manually via `cmake --build --preset release` when needed — `ayce`'s
  `build` phase always uses `default`). **Verified** end-to-end (configure
  → build → link) with the sample project above.
- `test` on CMake requires `enable_testing()` in the root `CMakeLists.txt`
  (already in the `## Init` skeleton) and relies on `gtest_discover_tests`/
  `catch_discover_tests` having registered the test binary with CTest.
  **Verified**: `ctest --test-dir build` found and ran the sample test.
- `lint` on CMake depends on `build/compile_commands.json`, which
  `CMakePresets.json` above already turns on via
  `CMAKE_EXPORT_COMPILE_COMMANDS`. Run `build` (or at least `cmake
  --preset default`) before `lint` — the Makefile's `ayce` target already
  orders `build` before `lint`, so this is automatic under `make ayce`.
  **Bazel caveat**: Bazel does not emit a `compile_commands.json` on its
  own. `clang-tidy` needs one to know each file's include paths and
  defines. The opt-in fix is the community
  [`hedron_compile_commands`](https://github.com/hedronvision/bazel-compile-commands-extractor)
  extension: add it as a `bazel_dep` and run
  `bazel run @hedron_compile_commands//:refresh_all` to generate
  `compile_commands.json` at the repo root, then run the same
  `clang-tidy -p . --warnings-as-errors='*' ...` command as the CMake path.
  This extension was **not verified locally** (it requires an extra bzlmod
  dependency and a refresh step out of scope for this task's quick smoke
  test) — treat it as name-checked against its own documentation. Until a
  repo opts in, the Bazel `lint` target should print a message explaining
  this and exit `0` (a documented no-op, not a silent skip):
  ```makefile
  lint: ## static analysis at the pedantic end
  	@echo "clang-tidy needs compile_commands.json; Bazel doesn't emit one natively."
  	@echo "Opt in: add hedron_compile_commands to MODULE.bazel, then"
  	@echo "  bazel run @hedron_compile_commands//:refresh_all"
  	@echo "  clang-tidy -p . --warnings-as-errors='*' \$$(find src include test -name '*.cpp' -o -name '*.hpp')"
  ```
  If the user opts into `hedron_compile_commands` during Init or later,
  replace this no-op with the two real commands (refresh, then lint) and
  say so in `.okf/decisions/toolchain.md`.
- `docs`: if the user opted into Doxygen during Init, the phase runs
  `doxygen Doxyfile` against a `Doxyfile` configured with `WARN_AS_ERROR =
  YES` (fail the build on any missing/malformed doc comment, same
  "warning-free docs" philosophy as `rust.md`'s `RUSTDOCFLAGS="-D
  warnings"`). **Verified during this task's authoring**: a Doxyfile with
  `WARN_AS_ERROR = YES` aborts immediately on a config/input problem
  (confirming the flag's fail-fast behavior), and a corrected run against
  the sample `include/`+`src/` tree generated a complete HTML doc site with
  exit code 0 and no warnings. If the user does **not** opt in, write the
  no-op `docs` target with a comment, never silently drop the target:
  ```makefile
  docs: ## build docs, fail on warnings
  	@echo "Doxygen not enabled for this project (declined during dev-playbook Init)."
  	@echo "To enable: add a Doxyfile (WARN_AS_ERROR = YES) and replace this no-op."
  ```

Write `bin/security-scan`'s body (baseline owns the shebang/`set -euo
pipefail` skeleton and the `chmod +x` step). **Same script for both build
systems** — osv-scanner doesn't care which build system produced the
sources it's scanning:

```bash
# C++ has no single universal dependency manifest (unlike Cargo.lock,
# package-lock.json, go.sum). osv-scanner best-effort scans whatever
# lockfiles/SBOMs actually exist in the tree (a Conan lockfile, a vcpkg
# manifest, a generated CycloneDX/SPDX SBOM). FetchContent-pinned or
# bzlmod-pinned test-framework dependencies are NOT covered by either --
# neither produces a manifest osv-scanner understands. This is a genuine
# best-effort net, not a guarantee: if this project takes on real
# third-party dependencies via Conan or vcpkg, add the matching lockfile
# and this scan starts covering it for free; until then, treat a clean run
# as "nothing scannable found," not "confirmed vulnerability-free."
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

**Not verified locally** — `osv-scanner` is not installed in this task's
verification environment, so the exact wording of its "nothing found"
message could not be confirmed byte-for-byte against a live run; the script
above is name-checked against osv-scanner's documented CLI behavior (exit
`0` = clean, non-zero = findings or scan failure) and defensively greps for
the documented "no sources found" phrasing rather than trusting a specific
non-zero code to always mean "no manifests." If your osv-scanner version's
wording differs, adjust the `grep` pattern — this is the one part of this
stack file's shipped script that should be spot-checked against your actual
installed version.

## CI

Generate `.github/workflows/ci.yaml` from baseline's triggers block (push,
pull_request, monthly cron). Matrix over compiler (gcc, clang) on
`ubuntu-latest` — both build systems get their own job body; keep only the
block matching the repo's chosen build system, drop the other entirely
rather than leaving it commented out in the generated file (shown side by
side here only so this reference covers both).

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
      CC: ${{ matrix.compiler == 'gcc' && 'gcc' || 'clang' }}
      CXX: ${{ matrix.compiler == 'gcc' && 'g++' || 'clang++' }}
    steps:
      - uses: actions/checkout@<resolved-major>

      # CMake:
      - run: sudo apt-get update && sudo apt-get install -y cmake ninja-build clang-tidy clang-format
      - run: cmake --preset default
      - run: cmake --build build
      - run: ctest --test-dir build --output-on-failure
      - run: clang-format --dry-run --Werror $(find src include test -name '*.cpp' -o -name '*.hpp')
      - run: clang-tidy -p build --warnings-as-errors='*' $(find src include test -name '*.cpp' -o -name '*.hpp')

      # Bazel (compiler matrix still applies via CC/CXX env above):
      # - uses: bazel-contrib/setup-bazel@<resolved-setup-bazel-version>
      #   with:
      #     bazelisk-cache: true
      # - run: bazel build //...
      # - run: bazel test //...
      # - run: clang-format --dry-run --Werror $(find src include test -name '*.cpp' -o -name '*.hpp')
```

`bazel-contrib/setup-bazel` does not publish a floating major-version tag
the way `actions/checkout@<resolved-major>` does — as of this task's authoring its
releases are all full `0.x.y` semver tags (`0.19.0` newest, confirmed via
`gh api repos/bazel-contrib/setup-bazel/tags`), so there is no `@v0`/`@v1`
to pin to. Resolve the current release tag at scaffold time (same
never-hardcode rule as the `rules_cc`/`googletest` bzlmod versions above)
and write it in place of `<resolved-setup-bazel-version>` — never carry a
literal patch-level pin from this reference file into a generated
`ci.yaml`.

Every job must pin tool versions consistent with `.tool-versions` (same
version-consistency rule as baseline). Notes:
- `-Werror` on `clang-format --dry-run` turns formatting drift into a CI
  failure, matching the `fmt`-then-`lint`-checks-formatting-too split seen
  in `rust.md`'s `fmt`/`clippy` and `java.md`'s Spotless apply/check split.
- The Bazel job's `lint` step is intentionally the same `clang-format`-only
  check shown here — per the `## Quality gate` caveat above, a Bazel
  `clang-tidy` CI step additionally requires the opt-in
  `hedron_compile_commands` refresh step; add it only if the repo opted in.

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

osv-scanner ships as a standalone static binary — no Go toolchain or
package-manager install step needed, just fetch and `chmod +x` the release
asset as shown.

## CLAUDE.md addenda

Copy this section verbatim into the target repo's `CLAUDE.md`, after the
baseline's "Definition of done" and "Knowledge bundle pointer" sections:

---

### C++: Testing Requirements

- Every public function/method must have at least one unit test covering
  the happy path, plus tests for documented error/edge conditions.
- Name tests descriptively: GoogleTest `TEST(Suite, Scenario)` or Catch2
  `TEST_CASE("scenario")` — the name should read as a sentence describing
  the behavior under test, not just the function name.
- Place tests under `test/`, one test file per source file being tested
  (`example.cpp` → `example_test.cpp`).
- Cover edge cases, error conditions (exceptions thrown, error codes
  returned), and boundary conditions explicitly — don't rely on the happy
  path alone.

### C++: Documentation Requirements

- Every public class, function, and non-trivial member needs a doc comment
  (Doxygen-style `///` or `/** */`) — required if Doxygen is enabled for
  this repo (`docs` fails the build on missing/malformed comments in that
  case); still expected as house style even when Doxygen is declined.
- First sentence is a single-sentence summary (Doxygen treats it as the
  brief description).
- Document parameters, return values, and thrown exceptions for any
  function whose behavior isn't obvious from its name and signature.
- Header files (`include/`) are the primary audience for doc comments —
  that's what downstream consumers of the library actually read.

### C++: Resource Management

- **RAII everywhere.** Every resource (memory, file handle, mutex, socket)
  is owned by an object whose destructor releases it. Manual
  acquire/release pairs (`new`/`delete`, `fopen`/`fclose`, `lock`/`unlock`)
  outside of a RAII wrapper are a defect, not a style preference.
- **No raw owning pointers.** A raw pointer (`T*`) may only ever be a
  non-owning observer/view. Ownership is expressed with `std::unique_ptr<T>`
  (single owner), `std::shared_ptr<T>` (shared ownership, used sparingly
  and only when lifetime genuinely can't be expressed with a single owner),
  or by-value/RAII container types. `new`/`delete` should not appear
  directly in application code outside of a smart-pointer factory call
  (`std::make_unique`/`std::make_shared`).
- Prefer `std::string_view`/`std::span` for non-owning views over
  strings/contiguous ranges instead of raw pointer+length pairs.
- Use standard containers (`std::vector`, `std::array`, `std::string`) over
  hand-rolled buffer management.

### C++: Compiler Warnings

- Warnings-as-errors (`-Wall -Wextra -Werror`) is mandatory for first-party
  targets — see the `## Config files` warning callout above for why this
  must be scoped per-target (`target_compile_options`) rather than applied
  globally: a global flag will break the moment a `FetchContent`/bzlmod
  dependency with its own (out-of-your-control) warnings gets compiled.
- Never silence a warning with a blanket `#pragma` disabling a whole
  category across a file; suppress the specific diagnostic at the specific
  line, with a comment explaining why it's a false positive.

### C++: Naming

- `snake_case` for functions, variables, and namespaces; `PascalCase` for
  types (classes, structs, enums).
- Avoid single-letter names except loop indices (`i`, `j`, `k`); this is
  also mechanically enforced by `.clang-tidy`'s `readability-identifier-length`
  check (part of the `readability-*` group enabled above) — expect it to
  flag short parameter/variable names during `lint`.

### C++: Code Organization

- Keep functions focused and single-purpose.
- Extract complex logic into well-named helper functions.
- Group related functions and types in logical namespaces/files, not one
  giant translation unit.
- Use the narrowest access level that works (`private`/anonymous-namespace
  internal linkage over exposing implementation details in `include/`).
- Separate interface (`include/`) from implementation (`src/`) — public
  headers should be stable and minimal; implementation details stay out of
  them.

---

## Update

On `/dev-playbook update` for a C++ repo:

1. Bump the pinned test-framework version:
   - **CMake path**: update the `FetchContent_Declare` URL/tag for
     GoogleTest or Catch2 in `test/CMakeLists.txt` to the current release.
   - **Bazel path**: update the `googletest` (and `rules_cc`) `bazel_dep`
     version(s) in `MODULE.bazel` to the current Bazel Central Registry
     release. Re-run `bazel build //...` immediately after — as verified
     during this task's authoring, a stale module version can fail outright
     under a newer Bazel release (removed native rules), so this bump is
     not purely cosmetic.
2. Bump the compiler images: the CI matrix's implicit `ubuntu-latest`
   compiler versions (gcc/clang installed via `apt-get`) track Ubuntu's own
   release cadence — if pinning a specific `ubuntu-XX.04` runner instead of
   `ubuntu-latest`, bump that pin here. Bump the devcontainer image tag in
   lockstep (version-consistency rule).
3. Propagate any build-system-tool version change across all of this stack's
   version-consistency-rule locations, per baseline's propagation table:
   - `.tool-versions`' `cmake` or `bazel` line (whichever this repo uses)
   - `ci.yaml`'s toolchain install step
   - `.devcontainer/devcontainer.json`'s image tag
   - Manifest pin: `cmake_minimum_required(VERSION ...)` in
     `CMakeLists.txt`, or the `bazel_dep` versions in `MODULE.bazel`
4. If `clang-format`/`clang-tidy` behavior changed because the underlying
   LLVM/compiler version moved (new checks added, new formatting
   defaults), re-run `make fmt` and `make lint` and review the diff/findings
   before considering the bump complete — these tools have no independent
   version pin to bump, but their *behavior* still moves with the compiler
   toolchain.
5. Run `make ayce` and confirm it is green before considering the update
   done.
