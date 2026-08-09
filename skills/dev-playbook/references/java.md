# Java — stack file

Read together with `references/baseline.md`. This file is instructions for
you, the executing agent — carry out each section as a step, don't just
summarize it. Apply after the stack's native init has already run, following
baseline's layer order: baseline files → AI files → stack configs (this
file's Config files / Quality gate / CI sections) → `.okf/` seeding.

This stack collapses four prior org template repos (`java_gradle_junit5`,
`java21_maven_junit`, and their checkstyle/spotbugs variants) into one
parameterized flow. The two build tools it supports — Gradle and Maven — are
mutually exclusive per repo; every section below branches on the Init
interview's answer, and the `## Quality gate` table always shows both
commands side by side so you can find the right one regardless of which
tool was chosen.

## Init

1. Interview the user: **Gradle or Maven?** Default to **Gradle** if the
   user has no preference. This choice is permanent for the repo — do not
   mix build tools.
2. Interview the user: **JDK version?** Default to **21** (the current LTS
   at the time this playbook was written) if the user has no preference.
   Treat this default as an *interview default only* — never hardcode it
   into a generated file; the resolved answer (21, or whatever the user
   picks) is what gets written everywhere below.
3. Run the native init for the chosen tool:
   - **Gradle**:
     ```
     gradle init --type java-library --dsl kotlin --test-framework junit-jupiter \
       --project-name <project> --package <groupId>.<project>
     ```
     This generates `settings.gradle.kts`, `<module>/build.gradle.kts`
     (Kotlin DSL — never Groovy DSL for new scaffolds), a `gradle/
     libs.versions.toml` version catalog, and the wrapper. Confirm the
     generated `java { toolchain { languageVersion = ... } }` block in
     `build.gradle.kts` matches the resolved JDK version from step 2; `gradle
     init` writes whatever JDK it ran under, which may not be the one the
     user chose — correct it if it differs.
   - **Maven**: generate from the `maven-archetype-quickstart` archetype:
     ```
     mvn archetype:generate -DarchetypeGroupId=org.apache.maven.archetypes \
       -DarchetypeArtifactId=maven-archetype-quickstart \
       -DgroupId=<groupId> -DartifactId=<project> -Dversion=1.0-SNAPSHOT \
       -Dpackage=<groupId>.<project>
     ```
     Then **verify and upgrade the test framework to JUnit 5**: inspect the
     generated `pom.xml`'s `<dependencies>`. Recent archetype releases
     already emit a `junit-bom` import plus `junit-jupiter-api` and
     `junit-jupiter-params` (verified during this task's authoring — no
     `junit:junit:4.x` present); older cached archetype versions still emit
     JUnit 4. Either way, end up with exactly this test-scope dependency set
     (ported from `java21_maven_junit/pom.xml`): `junit-jupiter-api`,
     `junit-jupiter-engine`, `junit-jupiter-params`, all versions managed by
     a `junit-bom` import in `<dependencyManagement>` — this is explicit
     even though Maven Surefire 3.x can auto-resolve the platform launcher
     at runtime if it's missing; being explicit about the engine dependency
     avoids relying on that implicit behavior. Set `<maven.compiler.release>`
     (or `source`/`target`) to the resolved JDK version.
4. **Always commit the wrapper**, whichever tool was chosen:
   - Gradle: `gradlew`, `gradlew.bat`, `gradle/wrapper/gradle-wrapper.jar`,
     `gradle/wrapper/gradle-wrapper.properties` — `gradle init` writes these
     automatically.
   - Maven: run `mvn -N wrapper:wrapper` (the `maven-wrapper-plugin`) to
     generate `mvnw`, `mvnw.cmd`, `.mvn/wrapper/maven-wrapper.properties`.
     Commit all three.

   The wrapper is the **source of truth for the build tool's own version** —
   see `## Toolchain` below for how this interacts with `.tool-versions`.
5. Interview: **which OSS license(s)?** — feeds baseline's `LICENSE-*` copy
   step. No Java-specific license-scanning config depends on this choice (no
   `deny.toml` equivalent is in scope for this stack; OWASP dependency-check
   below is a vulnerability scanner, not a license-compliance tool).

## Toolchain

Write `.tool-versions` with **one line**, regardless of which build tool was
chosen:

| Tool | Role | Notes |
|---|---|---|
| `java` | JDK (Temurin distribution) | asdf/mise `java` plugin syntax is vendor-prefixed, e.g. `temurin-21.0.<x>+<build>` — resolve the exact Temurin build at scaffold time, never hardcode one from memory. |

**Do not add a `gradle` or `maven` line to `.tool-versions`.** Neither tool
has meaningful asdf/mise support worth pinning here: the wrapper (`gradlew`/
`mvnw`) already pins the exact Gradle/Maven distribution version and
downloads it on first run, on every machine and in CI alike, which is a
stronger guarantee than an asdf-managed global install could give (a stray
system-wide `gradle`/`mvn` on PATH is exactly what the wrapper exists to
route around). State this decision plainly if asked: **the wrapper file
(`gradle/wrapper/gradle-wrapper.properties`'s `distributionUrl`, or
`.mvn/wrapper/maven-wrapper.properties`'s `distributionUrl`) is the single
source of truth for the build-tool version** — it is an additional thing to
keep in sync only in the sense that its version should track the same
upgrade cadence as the rest; it is **not** a member of this stack's
version-consistency set, which covers the JDK version, not the build tool.

Other tools in play (not `.tool-versions` lines — see rationale below):

| Tool | Role | Notes |
|---|---|---|
| JUnit 5 (Jupiter) | test framework | pulled as a build dependency, not a system tool |
| Spotless (google-java-format) | formatter | pulled as a build plugin |
| Checkstyle | linter, **optional, OFF by default** | pulled as a build plugin only if the user opts in |
| OWASP dependency-check | security scanner | pulled as a build plugin, invoked via `bin/security-scan` |

Rationale notes (feed these one-line whys into
`.okf/decisions/toolchain.md` during OKF seeding, do not restate them in
`CLAUDE.md` or the README):

- **Temurin** — Eclipse Adoptium's Temurin builds are the most widely
  supported "no vendor lock-in" OpenJDK distribution across CI runners,
  devcontainer base images, and asdf/mise; `actions/setup-java@<resolved-major>` and the
  asdf `java` plugin both name it as a first-class `distribution`/vendor
  option.
- **Kotlin DSL over Groovy DSL** (Gradle only) — statically typed, IDE
  auto-complete works without a Gradle-specific plugin, and it's the
  direction `gradle init` itself defaults toward for new projects.
- **Spotless + google-java-format** — one plugin, both build tools have a
  matching artifact (`com.diffplug.spotless` Gradle plugin,
  `spotless-maven-plugin` for Maven), zero-config opinionated formatting —
  no house style-guide to bikeshed.
- **Checkstyle optional-off** — genuinely useful for teams that want a
  house style enforced beyond what a formatter checks (import order,
  Javadoc presence, cyclomatic complexity ceilings), but it duplicates a
  good chunk of what Spotless + `-Werror` javadoc already catch for a
  default scaffold; ask the user during Init whether they want it turned
  on, and if so add the plugin (config already ported from both source
  repos at `config/checkstyle/checkstyle.xml`) plus a `lint` invocation —
  otherwise leave it out entirely rather than scaffolding a disabled task.
- **OWASP dependency-check over an alternative SCA tool** — free, does not
  require a SaaS account, and both build ecosystems have a first-party
  plugin (`org.owasp.dependencycheck` for Gradle, `dependency-check-maven`
  for Maven) maintained by the same upstream project, so the underlying
  vulnerability database and CVE-matching logic is identical regardless of
  which build tool a given repo uses.
- **NVD API key reality** — dependency-check's data source (the NIST
  National Vulnerability Database) rate-limits unauthenticated API access
  hard enough that a cold first run without a key can take a very long time
  to populate the local CVE cache. Verified during this task's authoring:
  "slow" is optimistic — at the plugin's out-of-the-box request pacing, an
  unauthenticated run doesn't just take longer, it fails outright (repeated
  HTTP 429s exhaust the client's retry budget, which cascades into
  `DatabaseException`s and thousands of `NullPointerException`s while
  processing individual CVEs, and the whole analyze task exits non-zero).
  See `## Config files` below for the `nvd.delay`/`nvdApiDelay` back-off
  this scaffold now sets whenever `NVD_API_KEY` is absent — WITH that
  back-off in place, an unauthenticated first run genuinely does just run
  slower (confirmed: zero errors over an extended live run once the delay
  was applied) rather than failing, but "slower" here can still mean tens
  of minutes to a few hours for a fully cold cache; the local NVD data
  cache persists across runs (`~/.gradle/dependency-check-data/` for
  Gradle, `~/.m2/repository/org/owasp/dependency-check-data/` for Maven),
  so an interrupted or re-run scan resumes rather than restarting from
  scratch. Strongly recommend a free `NVD_API_KEY` for any real local use.

For the devcontainer, use the `mcr.microsoft.com/devcontainers/java` image
family. Unlike `.../rust` (see baseline.md § Devcontainer), this family's
tags DO encode the JDK version directly (confirmed against the live MCR tag
list during this task's authoring: `21`, `21-bookworm`, `21-bullseye`,
`1-21-bookworm` are all valid tags, matching the pattern the org's own prior
`java_gradle_junit5`/`java21_maven_junit` templates already used, e.g.
`mcr.microsoft.com/devcontainers/java:1-21-bullseye`) — so the image tag
itself is the version-consistency-rule pin for this stack; no separate
`postCreateCommand`/feature version override is needed. Resolve the current
tag at scaffold time and keep its JDK segment in agreement with
`.tool-versions`' `java` line.

## Config files

**Gradle** — in `<module>/build.gradle.kts`:

```kotlin
plugins {
    `java-library`
    id("com.diffplug.spotless") version "<resolved>"
    id("org.owasp.dependencycheck") version "<resolved>"
    // checkstyle           // only if the user opted in during Init
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(<resolved-jdk>)
    }
}

spotless {
    java {
        googleJavaFormat()
    }
}

dependencyCheck {
    // Reads the NVD API key from the environment if present. Never hardcode
    // a key here — CI injects it via a repo secret.
    nvd.apiKey = System.getenv("NVD_API_KEY")
    // Without a key, NVD's public rate limit is 5 requests per rolling 30s
    // window; the plugin's default delay is tuned for the keyed (50/30s)
    // limit and floods the endpoint with 429s when unauthenticated. Verified
    // during this task's authoring: at the plugin default delay, an
    // unauthenticated first run does NOT just run slower — the retry-exhausted
    // 429s cascade into `DatabaseException: Unable to retrieve id for new
    // vulnerability` and thousands of `NullPointerException`s while processing
    // individual CVEs, and the whole `dependencyCheckAnalyze` task fails
    // (confirmed: ~3000 such failures, non-zero exit). Backing off to a safe
    // delay is not optional when no key is present — it is the difference
    // between "slow" and "broken":
    if (System.getenv("NVD_API_KEY").isNullOrEmpty()) {
        nvd.delay = 6500
    }
}

tasks.named<Javadoc>("javadoc") {
    (options as StandardJavadocDocletOptions).addBooleanOption("Werror", true)
}
```

Verified during this task's authoring: `id("com.diffplug.spotless")`
registers `spotlessApply`/`spotlessCheck`/`spotlessJava*` tasks;
`id("org.owasp.dependencycheck")` registers `dependencyCheckAnalyze`
(the task the brief and `bin/security-scan` call — not
`dependencyCheckUpdate` or `dependencyCheckAggregate`, which are related but
different tasks); the `addBooleanOption("Werror", true)` javadoc pattern
does fail the build on any javadoc warning (confirmed: an undocumented
public class/method produces `error: warnings found and -Werror specified`).

**Maven** — in `pom.xml`, add to `<build><plugins>`:

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-enforcer-plugin</artifactId>
  <version><!-- resolved --></version>
  <executions>
    <execution>
      <id>enforce-java-version</id>
      <goals><goal>enforce</goal></goals>
      <configuration>
        <rules>
          <requireJavaVersion><version>[<resolved-jdk>,)</version></requireJavaVersion>
        </rules>
      </configuration>
    </execution>
  </executions>
</plugin>
<plugin>
  <groupId>com.diffplug.spotless</groupId>
  <artifactId>spotless-maven-plugin</artifactId>
  <version><!-- resolved --></version>
  <configuration>
    <java><googleJavaFormat/></java>
  </configuration>
</plugin>
<plugin>
  <groupId>org.owasp</groupId>
  <artifactId>dependency-check-maven</artifactId>
  <version><!-- resolved --></version>
  <configuration>
    <!-- Recommended way to pass the key: never let it land in Maven debug
         logs the way a literal <nvdApiKey> property expansion could. -->
    <nvdApiKeyEnvironmentVariable>NVD_API_KEY</nvdApiKeyEnvironmentVariable>
    <!-- See the Gradle block above for why this delay is not optional
         without a key — same rate-limit-cascade failure mode applies to
         the Maven plugin (it shares the same underlying engine). Ported
         by analogy from the Gradle-side fix verified during this task's
         authoring; the `nvdApiDelay` parameter name itself is confirmed
         against the plugin's own configuration reference (dependency-check-
         maven's configuration.html lists `nvdApiDelay` alongside `nvdApiKey`)
         but the conditional wiring below was not re-run end-to-end in a
         Maven scaffold this task. `<configuration>` values cannot contain
         inline conditional expressions (POM interpolation is not a
         scripting language) — resolve the "no key" branch via a profile
         instead, activated on the env var's absence: -->
    <nvdApiDelay>${nvd.delay}</nvdApiDelay>
  </configuration>
</plugin>
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-javadoc-plugin</artifactId>
  <version><!-- resolved --></version>
  <configuration>
    <additionalOptions>
      <additionalOption>-Werror</additionalOption>
    </additionalOptions>
    <failOnWarnings>true</failOnWarnings>
  </configuration>
</plugin>
<!-- maven-checkstyle-plugin: only if the user opted in during Init -->
```

Also add, at the top level of `pom.xml` (sibling of `<build>`), the default
delay plus the profile that raises it when no key is present — this pairs
with the `${nvd.delay}` reference in the plugin `<configuration>` above:

```xml
<properties>
  <nvd.delay>0</nvd.delay>
</properties>

<profiles>
  <profile>
    <id>nvd-no-api-key</id>
    <activation>
      <property><name>!env.NVD_API_KEY</name></property>
    </activation>
    <properties>
      <nvd.delay>6500</nvd.delay>
    </properties>
  </profile>
</profiles>
```

Verified during this task's authoring: `maven-enforcer-plugin`'s
`requireJavaVersion` rule passes/fails correctly against the running JDK;
`spotless-maven-plugin`'s `spotless:check`/`spotless:apply` goals both run
and correctly detect/fix an unformatted file; the OWASP goal is
`org.owasp:dependency-check-maven:check` — confirmed via
`maven-help-plugin:describe` (`Mojo: 'dependency-check:check'`), and its
recommended env-var property is exactly `nvdApiKeyEnvironmentVariable` per
the plugin's own parameter documentation. The `!env.VARNAME` profile
activation-by-absent-property syntax is standard Maven (`env.*` exposes
environment variables as properties); NOT re-run end-to-end in a Maven
scaffold this task — only the Gradle side's equivalent delay fix was
verified live (see `## Toolchain` and `## Config files` Gradle block
above), so treat the Maven wiring as ported-by-analogy until a future
Maven-branch acceptance run confirms it.

Add stack-appropriate ignores to the shared `.gitignore` (baseline writes
the file; these are the Java-specific lines): `build/`, `target/`, `.gradle/`,
`*.class`, `.mvn/wrapper/maven-wrapper.jar` (the wrapper *script* is
committed; the wrapper *jar*, when the wrapper plugin still emits one
instead of the download-only variant, is not — the `only-script` wrapper
distribution used above has no jar to ignore, but keep this line for
compatibility with older-generated wrappers).

For `.editorconfig`, add a Java override: 4-space indent for `*.java`.

## Quality gate

Fill the baseline Makefile skeleton's phase bodies using the row for
whichever build tool the Init interview selected. Both commands are shown
for every phase so you can find the right one regardless of choice — never
put both commands in the same generated Makefile recipe, only the row
matching the repo's chosen tool:

| Phase | Gradle | Maven |
|---|---|---|
| `clean` | `./gradlew clean` | `./mvnw clean` |
| `fmt` | `./gradlew spotlessApply` | `./mvnw spotless:apply` |
| `build` | `./gradlew assemble` | `./mvnw package -DskipTests` |
| `test` | `./gradlew test` | `./mvnw test` |
| `lint` | `./gradlew spotlessCheck` (+ `checkstyleMain checkstyleTest` if opted in) | `./mvnw spotless:check` (+ `checkstyle:check` if opted in) |
| `security-scan` | `./bin/security-scan` | `./bin/security-scan` |
| `docs` | `./gradlew javadoc` | `./mvnw javadoc:javadoc` |

Notes:
- `build` intentionally skips tests (`assemble` never runs tests in Gradle's
  Java plugin; `-DskipTests` makes Maven's `package` match that) — `test` is
  its own gate phase, so `build` shouldn't re-run it.
- `lint` here is Spotless running in check-only mode (no changes made,
  fails on drift) — this is a different invocation from `fmt`'s
  apply-in-place mode, not a duplicate.
- `docs` fails the build on any javadoc warning via the `-Werror`
  configuration written into `build.gradle.kts`/`pom.xml` in
  `## Config files` above — the Makefile recipe itself is just
  `javadoc`/`javadoc:javadoc`; the `-Werror` behavior lives in the build
  file, not the Makefile line, so both build tools' plain doc-generation
  command is enough here.

Write `bin/security-scan`'s body (baseline owns the shebang/`set -euo
pipefail` skeleton and the `chmod +x` step) — branch on the repo's chosen
build tool, only one of these two lines is present in a given repo:

```bash
# Gradle:
./gradlew dependencyCheckAnalyze

# Maven:
./mvnw org.owasp:dependency-check-maven:check
```

This is the single definition of Java's security check — the Makefile's
`security-scan` target and the CI `security.yaml` workflow both call this
script; do not duplicate the dependency-check invocation anywhere else.
`NVD_API_KEY` is read from the environment by the plugin configuration
written in `## Config files`, not passed on this command line — locally,
an unset key means a slow first run (NVD's public rate limit); the
`nvd.delay`/`nvdApiDelay` back-off configured there is what keeps that
"slow" from becoming "broken" (see `## Toolchain`'s NVD API key reality
note for what happens without the back-off). In CI, the workflow below
injects the key from a repository secret when available.

## CI

Generate `.github/workflows/ci.yaml` from baseline's triggers block (push,
pull_request, monthly cron). One job, using `actions/setup-java@<resolved-major>` with
`distribution: temurin` and the resolved JDK, ported from both source
repos' CI shape and modernized (source repos used branch-list triggers and
no matrix; this collapses to baseline's push/PR/cron shape with a JDK
matrix for headroom on future multi-version testing even though today it's
a single entry).

Resolve every `@<resolved-major>` below at scaffold time — see baseline.md,
§ CI workflows → Action version pins, for the procedure and the offline
fallback table. Never write a major copied from this file. Note that
`gradle/actions/setup-gradle` is versioned by the `gradle/actions`
repository, so resolve it against that repo, not against a per-action one.

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
        java: ["<resolved-jdk>"]
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@<resolved-major>
      - uses: actions/setup-java@<resolved-major>
        with:
          distribution: temurin
          java-version: ${{ matrix.java }}
          # Gradle:
          cache: gradle
          # Maven:
          # cache: maven
      # Gradle:
      - uses: gradle/actions/setup-gradle@<resolved-major>
      - run: ./gradlew build
      - run: ./gradlew spotlessCheck
      - run: ./gradlew javadoc
      # Maven:
      # - run: ./mvnw -B verify
      # - run: ./mvnw -B spotless:check
      # - run: ./mvnw -B javadoc:javadoc
```

Keep only the block matching the repo's chosen build tool — drop the other
tool's steps/comment entirely rather than leaving them commented out in the
generated file (they're shown side by side here only so this reference
covers both).

Generate `.github/workflows/security.yaml` per baseline's exact verbatim
shape (daily cron, unchanged from baseline), inserting this stack's
toolchain setup step **after** the checkout step baseline already writes —
do not repeat `actions/checkout@<resolved-major>` here:

```yaml
      - uses: actions/setup-java@<resolved-major>
        with:
          distribution: temurin
          java-version: "<resolved-jdk>"
      - run: ./bin/security-scan
        env:
          NVD_API_KEY: ${{ secrets.NVD_API_KEY }}
```

Note the `env:` block on the scan step — this is the one place the
workflow explicitly wires the secret in; if the repository has no
`NVD_API_KEY` secret configured, this expression simply evaluates to an
empty string and dependency-check falls back to its slower unauthenticated
path rather than failing. Tell the user during CI setup that adding an
`NVD_API_KEY` repository secret (a free key from the NVD API) is strongly
recommended but not required for the workflow to succeed.

## CLAUDE.md addenda

Copy this section verbatim into the target repo's `CLAUDE.md`, after the
baseline's "Definition of done" and "Knowledge bundle pointer" sections:

---

### Java: Testing Requirements

- Test framework is JUnit 5 (Jupiter) — do not add JUnit 4 or TestNG.
- Name test methods `<methodUnderTest>_<scenario>_<expectedOutcome>`, e.g.
  `withdraw_insufficientBalance_throwsIllegalStateException`.
- AssertJ is allowed (and preferred over raw JUnit `assertEquals` chains)
  for fluent, readable assertions — add it as a test-scope dependency if
  not already present.
- Every public method must have at least one test covering the happy path,
  plus tests for documented error/edge conditions.
- Use `@ParameterizedTest` (JUnit Jupiter Params) instead of hand-rolled
  loops over test cases.

### Java: Documentation Requirements

- Every public class, interface, and method needs a Javadoc comment —
  `docs`/`-Werror` fails the build on any missing/malformed Javadoc, so
  this is enforced, not aspirational.
- First sentence is a single-sentence summary (Javadoc treats it as the
  short description everywhere else in the generated docs).
- Document `@param`, `@return`, and `@throws` for every public method that
  has them.

### Java: Dependency Injection

- No field injection (`@Autowired` or equivalent directly on a field).
  Use constructor injection — it makes dependencies explicit, immutable,
  and testable without a DI container in unit tests.

### Java: Code Organization

- Keep methods focused and single-purpose; extract complex logic into
  well-named private helper methods.
- Group related classes into packages by feature/domain, not by technical
  layer (avoid `controllers`/`services`/`models` package-per-layer sprawl
  for anything beyond a trivial app).
- Use the narrowest access modifier that works (`private` > package-private
  > `protected` > `public`); public API surface is what Javadoc and
  semantic-versioning compatibility both hold you to, so keep it small.
- Prefer immutable objects (`final` fields, no setters) where the domain
  allows it.

---

## Update

On `/dev-playbook update` for a Java repo:

1. Bump dependencies:
   - **Gradle**: apply the `nl.littlerobots.version-catalog-update` plugin
     if not already present, then run `./gradlew versionCatalogUpdate` to
     bump the `gradle/libs.versions.toml` catalog to latest releases.
   - **Maven**: `./mvnw versions:use-latest-releases versions:update-properties`
     (both goals from `org.codehaus.mojo:versions-maven-plugin`, confirmed
     present in that plugin's goal list during this task's authoring).
2. If bumping the JDK, propagate the new version across all of this stack's
   version-consistency-rule locations, per baseline's propagation table
   (the toolchain/compiler block in the build file *is* this stack's
   manifest-pin location):
   - `.tool-versions`' `java` line
   - `ci.yaml`'s `java-version` matrix entry
   - `.devcontainer/devcontainer.json`'s image tag
   - Manifest pin: Gradle's `java.toolchain.languageVersion` in
     `build.gradle.kts`, or Maven's `maven.compiler.release` property (and
     the `maven-enforcer-plugin` `requireJavaVersion` range) in `pom.xml`
3. Re-run `make ayce` and confirm it is green before considering the
   update done — `lint` will catch any Spotless drift the version bump's
   auto-formatting introduced, and `security-scan` will catch any newly
   disclosed CVE in a bumped dependency.
