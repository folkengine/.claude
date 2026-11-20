# EPIC: Skill Artifact Integrity — Folding NVIDIA's Checks into Vitale's Spec (SEAL)

> **One-line:** Bring the two integrity ideas from NVIDIA's Agent Package
> Specification — safe extraction and a per-file inventory — into Thomas
> Vitale's Agent Skills OCI Artifacts Specification without breaking a single
> skill already published under it. Prove the approach with a small Rust
> reference implementation whose core is a pure kernel, and only then propose
> it upstream.

> **Provenance.** Drafted 2026-11-19 from Vitale's spec v0.1.0 (draft dated
> 2026-04-01, `README.md` on `main` as read 2026-11-19) and NVIDIA's
> `agent-package-spec` initial draft (`spec/agent-package.md` on `main` as read
> 2026-11-19). Both were read through a summarizing fetch, not line by line.
> Anything marked *(verify)* has not been checked against the source text.
> The implementation survey (Context, "Who implements what") was added later
> the same day from package docs and READMEs. Nothing here has been built.

The kata: the **Thing** is **a skill on disk that an agent will trust**. The
**Business Requirement** is that a consumer can show the files in
`.agents/skills/<name>/` are exactly the files the publisher signed, safely
unpacked, and can show it again tomorrow. The **Business Logic** is a pure
admission-and-drift kernel. It decides from archive headers, digests and a
policy, and never touches the network or the filesystem itself.

---

## Status

*As of 2026-11-19. Nothing has landed. Every row is honest aspiration.*

| Component | Status | Where |
|---|---|---|
| Confirm how Vitale's spec and Arconia treat unknown config and lock fields | Planned (Phase 0) | reading |
| Prior-art check: ToolHive's `LabelSkillFiles` and its build-time path and symlink checks | Planned (Phase 0) | reading |
| `seal-kernel`: admission policy, inventory, drift check, content digest | Planned (Phase 1) | reference repo |
| Hostile-archive texture corpus | Planned (Phase 1) | reference repo |
| `seal` CLI: install / verify against an OCI registry | Planned (Phase 2) | reference repo |
| Install-time content digest recorded per skill (no format change) | Planned (Phase 2) | reference repo |
| Publisher side: `files` written into the skill config at push | Planned (Phase 3) | reference repo |
| **Backward-compatibility test: does Arconia still install a skill whose config has `files`?** | Planned (Phase 3) — **decides Phase 4's shape** | experiment |
| Upstream issue, then PR, to Vitale's spec | Planned (Phase 4) | upstream |
| DK skills published with inventories; `verify --against` for git checkouts | Planned (Phase 5) | dkskills |
| Inventory as a referrer artifact (Option B) | 🔒 Gated (Phase 6) — only if upstream rejects Option A | reference repo |

---

## Context

### The idea in four sentences

Vitale's spec has the better consumer workflow: collections, a lock file, an
install layout and working tools. NVIDIA's has the better artifact integrity:
every file listed with its digest, and strict rules for unpacking. In Vitale's
spec the layer digest proves the download arrived intact, but nothing proves
what ended up on disk, and nothing stops a hostile archive from writing outside
the skill directory. This EPIC adds both without changing the artifact format
existing consumers depend on, wherever that can be done.

### What Vitale's spec has (v0.1.0)

- **One manifest, one layer.** Artifact type `application/vnd.agentskills.skill.v1`.
  Content layer `application/vnd.agentskills.skill.content.v1.tar+gzip`, a
  single archive rooted at `<skill-name>/` with `SKILL.md` required.
- **Config** `application/vnd.agentskills.skill.config.v1+json`, holding
  `schemaVersion` (must be `"1"`), `name`, `version`, `description`,
  `license`, `compatibility`, `allowedTools` and `metadata`. **Clients MUST
  reject an unrecognized `schemaVersion`.**
- **POSIX permissions MUST be preserved.** Deterministic archive creation is
  SHOULD only.
- **Signing.** Cosign SHOULD be used, signatures are stored as referrers, and
  consumers SHOULD verify before extraction. A `sha256-<digest>` fallback tag
  serves registries without the Referrers API.
- **Project files.** `skills.json` (edited by people) and `skills.lock.json`
  (machine-written; `lockfileVersion: 1`, which **clients MUST reject if
  unknown**). Each lock entry records `registry`, `repository`, `tag`,
  `digest` and `ref`.
- **Install layout.** Skills go to `.agents/skills/<name>/`, with file-system
  copies in every `additionalBasePaths` entry (e.g. `.claude/skills/`).
- **Update workflow** (§7.4 *(verify section number)*): resolve the tag,
  compare digests, pull, extract, replace and relock.

### What it lacks

- **No per-file digests or file inventory.** Once a skill is unpacked, nothing
  shows whether the directory still matches the artifact.
- **No extraction rules.** It says nothing about absolute paths, `..`,
  symlinks, hard links, devices, duplicate entries or case collisions.
- **A permission rule that conflicts with safe extraction.** "Preserve POSIX
  permissions" includes setuid and setgid bits.
- **No way to identify a skill's content apart from its packaging.** Two
  builds of the same files can have different layer digests, because
  determinism is only SHOULD.

### What NVIDIA's spec contributes

- **A `files` array in the config.** Each entry has `path`, `digest`
  (`sha256:` plus 64 lowercase hex characters) and an optional `executable`
  flag. It covers every regular file in the layer.
- **Two levels of checking.** The layer digest verifies the archive as
  transported. Each file digest verifies the bytes after unpacking. File
  digests ignore archive metadata, so they don't change between builds.
- **Coverage by the existing signature.** A signature over the manifest digest
  also covers the config, and so the inventory, with no extra signing step.
- **Extraction rules.**
  - Paths must be relative, use `/`, and have no empty, `.` or `..`
    components, backslashes, NUL or drive prefixes.
  - Duplicates, file/directory conflicts and case or normalization collisions
    are rejected.
  - Devices, sockets, FIFOs, hard links and symlinks are prohibited.
  - The `executable` flag must match the archive mode bit, and setuid and
    setgid bits are never restored.
  - Extraction happens in an isolated staging root with resource limits, and
    no package code is executed.
  - Validators are never fetched from URIs supplied by the package.

### Who implements what (as of 2026-11-19)

| Tool | Language | Format | Notes |
|---|---|---|---|
| Arconia CLI | Java (ORAS Java SDK) | Vitale | Reference implementation: publish, install, collections, lock. Its skills commands are marked experimental. |
| salaboy `skills-oci` | Go | Vitale, except grouping | Skill, config and layer types match. Groups use `application/vnd.agentskills.catalog.v1`, not the spec's `collection.v1`. |
| ORAS CLI | Go | either | Moves bytes only. No skill validation. |
| `agent-package-cli` | — | NVIDIA | Proposed only. No implementation exists. |
| ToolHive `thv skill` + `toolhive-core/oci/skills` | Go | own: `dev.toolhive.skills.v1` | Most complete tool. Its build step already rejects symlinks and path traversal. Its config labels include `LabelSkillFiles` *(verify: is this a file inventory?)*. Plugins are a separate type, `dev.toolhive.plugins.v1`. |
| RamaLama PR #2909 | Python | own: `application/vnd.cncf.skill.manifest.v1+json` | Skills, agents and plugins. Open, not merged *(verify)*. |
| Red Hat ET `skillimage` / `skillctl` | Go | plain OCI image (`FROM scratch`) | Deliberately not an ORAS artifact, so podman and Kubernetes ImageVolumes can use it. |
| stax (Stakpak) | TypeScript | own: `application/vnd.stax.*` | Whole agent bundles, not single skills. |

**Rust:** no crate implements either spec. `oci-client`
(oras-project/rust-oci-client, formerly `oci-distribution`) implements the
OCI Distribution protocol. `oci-wasm` is a thin wrapper over it that
implements the OCI Wasm artifact spec, which is exactly the shape of the
`seal` shell. The `oras` crate on crates.io (0.0.1) is an unaffiliated stub.

**Spelling hazard:** Vitale's blog post writes the type as
`application/vnd.agent-skills.skill.v1`, with a hyphen. The spec, Arconia and
`skills-oci` all use `agentskills`. `seal` follows the spec.

### What this EPIC explicitly does NOT do

- **Merge the two specs.** Vendor trees (`agentskills` vs `agentpackage`),
  archive roots (`<skill-name>/` vs `payload/`) and plugin support stay as
  they are. This EPIC borrows from NVIDIA; it doesn't converge on it.
- **Define what a skill may do at runtime.** `allowedTools` remains advisory.
  Permissions are a harness concern.
- **Establish trust.** An inventory proves consistency with what was signed.
  Who signed it, and whether to trust them, is cosign identity policy, which
  is unchanged.
- **Replace Arconia.** The reference implementation exists to find holes in
  the contract before proposing it upstream, not to compete with Vitale's
  tooling.

---

## Goals

- A consumer can show that **every installed copy** of a skill matches the
  artifact it came from, and can name the file that drifted when one doesn't.
- A consumer can show that a skill **obtained another way** (for example a git
  checkout) matches a signed published artifact.
- A consumer **cannot be made to write** outside the skill directory, create a
  special file, or restore a setuid bit by any archive.
- Every existing skill published under Vitale v0.1.0 **still installs** with
  every existing client after the change.
- The integrity rules are a **pure kernel** with a texture corpus, assessable
  the same way as any other DK kernel.

---

## Decisions

1. **Least format change first.** The order is: client-only (Phases 1–2),
   then an additive optional field (Phases 3–4), then a separate referrer
   artifact (Phase 6, gated). Each step ships value on its own.
2. **Extraction rules are client behavior, so they need no format change.**
   They go into Vitale's spec as a new normative "Extraction" section.
   Existing artifacts are unaffected unless they contain something the rules
   reject, and Phase 5 measures that against real published skills.
3. **Permissions: preserve the bits a skill needs, drop the rest.** The
   amendment replaces "POSIX permissions MUST be preserved" with "permission
   bits MUST be preserved except setuid, setgid and sticky, which MUST NOT be
   restored."
4. **How strict the symlink rule is depends on whether the artifact has an
   inventory.** Artifacts without `files` get the soft rule: reject absolute
   symlinks and any that resolve outside the skill root, and warn on the rest.
   Artifacts that declare `files` get NVIDIA's rule: no symlinks at all.
   Publishers who choose the stronger guarantee accept the stronger rule, and
   nothing already published breaks.
5. **Hard links, devices, FIFOs and sockets are always rejected.** No
   legitimate skill needs them.
6. **Use NVIDIA's inventory field shape verbatim:** `files[]` with `path`,
   `digest` and `executable`. Keeping the field names identical makes a later
   convergence mechanical.
7. **Inventory paths are relative to the skill root,** written `SKILL.md`, not
   `<skill-name>/SKILL.md` or NVIDIA's `payload/SKILL.md`. The same inventory
   then checks `.agents/skills/<name>/` and every `additionalBasePaths` copy
   without rewriting.
8. **An inventory is a closed list.** When `files` is present, an archive
   entry that isn't listed is a rejection, and so is a listed file that's
   missing. Otherwise an attacker could append a file the inventory doesn't
   mention.
9. **Content digest: one hash that identifies a skill's content regardless of
   packaging.** It is SHA-256 over the inventory in a fixed text form: one
   line per regular file, `<path>\t<hex digest>\t<x or ->\n`, sorted by the
   path's UTF-8 bytes. This is this EPIC's proposal, not NVIDIA's (which
   doesn't require canonical JSON). It gives the lock file one short value per
   skill and lets two rebuilds be compared without diffing tarballs.
10. **The lock file stores the content digest; per-file detail is re-derived.**
    The locked artifact digest is immutable, so when `verify` finds drift it
    can re-pull that exact artifact and diff file by file. The lock never
    carries a file list.
11. **Where the content digest is stored depends on Phase 0.** If lockfile v1
    tolerates unknown entry fields, store it as `contentDigest` on the lock
    entry. If not, store it in a sidecar `skills.inventory.json` beside the
    lock, so existing clients never see a changed lock file.
12. **Write the reference implementation before the PR.** In house
    experience, implementation finds contract holes that design review
    misses (the dtry WIT lesson). The upstream PR is written from code that
    already passes the texture corpus.
13. **Kernel and shell are separate.** `seal-kernel` takes archive headers,
    byte streams to hash, an inventory and a policy, and returns typed
    decisions. It does no I/O, uses no clock and does no networking. Registry
    access, unpacking to disk and lock files belong to the `seal` shell.
14. **Rust, modelled on `oci-wasm`.** Rust is the house language, and no
    Rust implementation of either spec exists, so `seal` would be the first.
    The shell wraps `oci-client` the way `oci-wasm` does: skill-specific
    types and push/pull helpers over a generic client. It doesn't write a
    registry client, and it doesn't use the `oras` stub crate. Whether
    `oci-client` supports the Referrers API is still *(verify)*; if it
    doesn't, signature discovery uses the `sha256-<digest>` fallback tag or
    shells out to `cosign`.

---

## Domain map

| Concept | Construct | Status |
|---|---|---|
| An archive entry as data | `EntryHeader { path, kind, mode, size }` | ❌ absent |
| What unpacking is allowed to do | `Policy { limits, symlinks: Soft \| Forbidden }` | ❌ absent |
| Why an entry was refused | `Rejection` (typed, one variant per rule) | ❌ absent |
| The publisher's list of files | `Inventory { files: Vec<FileEntry> }` | ❌ absent (NVIDIA shape) |
| Content identity apart from packaging | `content_digest(&Inventory)` | ❌ absent |
| Disk vs inventory | `DriftReport { missing, unlisted, changed, mode }` | ❌ absent |
| Where the skill came from | lock entry `source` | ✅ reuse (Vitale) |
| Signature and attestations | cosign referrers | ✅ reuse (Vitale, unchanged) |
| Install layout, copies | `.agents/skills/`, `additionalBasePaths` | ✅ reuse (Vitale) |

---

## Design

### The config, with an inventory (Option A)

```json
{
  "schemaVersion": "1",
  "name": "domain-kernel",
  "version": "1.0.0",
  "description": "Codify, assess, and enforce the domain kernel pattern…",
  "license": "Apache-2.0",
  "files": [
    { "path": "SKILL.md",                  "digest": "sha256:…" },
    { "path": "references/MODE_F_SURVEY.md", "digest": "sha256:…" },
    { "path": "scripts/check_purity.py",   "digest": "sha256:…", "executable": true }
  ]
}
```

Proposed spec text: `files` is OPTIONAL. When present, a client MUST verify
every extracted regular file against it before moving the skill into place,
MUST reject the artifact on any missing, unlisted or mismatched file, and MUST
apply the forbidden-symlink rule (Decision 4).

### The kernel (`seal-kernel`)

```rust
pub enum EntryKind { File, Dir, Symlink { target: String }, HardLink, Device, Fifo, Socket, Other }

pub struct EntryHeader { pub path: String, pub kind: EntryKind, pub mode: u32, pub size: u64 }

pub struct Limits {
    pub max_entries: u32,
    pub max_file_bytes: u64,
    pub max_total_bytes: u64,
    pub max_path_bytes: u16,
}

pub enum SymlinkRule { Soft, Forbidden }

pub struct Policy { pub limits: Limits, pub symlinks: SymlinkRule }

pub enum Rejection {
    AbsolutePath(String), ParentComponent(String), EmptyComponent(String),
    Backslash(String), Nul(String), DrivePrefix(String),
    OutsideRoot { path: String, root: String },
    Duplicate(String), FileDirConflict(String),
    CaseCollision(String, String), NormalizationCollision(String, String),
    ForbiddenKind { path: String, kind: EntryKind },
    SymlinkEscapes { path: String, target: String },
    SymlinkNotAllowed(String),
    SetIdBit(String),                 // reported; the bit is dropped, not restored
    TooManyEntries(u32), FileTooLarge(String, u64), TotalTooLarge(u64), PathTooLong(String),
    // only when an inventory is present:
    Unlisted(String), Missing(String),
    DigestMismatch { path: String, expected: Digest, actual: Digest },
    ExecutableMismatch(String),
}

/// Decide, from headers alone, whether an archive may be unpacked.
pub fn admit(entries: &[EntryHeader], root: &str, policy: &Policy,
             inventory: Option<&Inventory>) -> Result<Admitted, Vec<Rejection>>;

/// Incremental SHA-256 the shell feeds bytes into. Pure; no I/O.
pub struct FileHasher { /* … */ }

/// Compare observed files with an inventory.
pub fn drift(inventory: &Inventory, observed: &[Observed]) -> DriftReport;

/// Decision 9.
pub fn content_digest(inventory: &Inventory) -> Digest;
```

`admit` returns **every** rejection, not just the first, so a report can show
everything wrong with an archive in one pass. Case and normalization
collisions are checked on every platform, because the installer can't know
which filesystem an `additionalBasePaths` copy will land on. This matters most
on macOS, where `.claude/skills/` is case-insensitive by default.

### The shell (`seal`)

```text
seal install <ref>                 pull → verify signature → admit → stage → hash
                                   → drift vs inventory (if any) → move into place
                                   → copy to additionalBasePaths → record content digest
seal verify [<name>]               recompute content digest for every installed copy;
                                   on mismatch, re-pull the locked digest and print per-file drift
seal verify --against <ref> <dir>  compare any directory (e.g. a git checkout) with a
                                   signed artifact's inventory
seal pack <dir>                    build layer + config with `files`; deterministic tar
                                   (sorted, fixed mtime, uid/gid 0)
seal push <dir> <ref>              pack, push, then `cosign sign` on the digest
```

Unpacking happens in a temporary directory under the project. Only a skill
that passes every check is renamed into place. When a check fails, the
temporary directory is removed and nothing under `.agents/` changes.

### Lock entry (Decision 11, first branch)

```json
{
  "name": "domain-kernel",
  "path": ".agents/skills/domain-kernel",
  "additionalPaths": [".claude/skills/domain-kernel"],
  "source": { "registry": "ghcr.io", "repository": "folkengine/dkskills/domain-kernel",
              "tag": "1.0.0", "digest": "sha256:…", "ref": "…" },
  "contentDigest": "sha256:…",
  "installedAt": "…"
}
```

### Texture corpus (kernel-testkit sense)

Each texture is a small tar.gz built in code and named in the test, with the
expected `Rejection` stated alongside it.

| Texture | Expected |
|---|---|
| `../../.bashrc` entry (zip-slip) | `ParentComponent` |
| `/etc/passwd` entry | `AbsolutePath` |
| entry outside `<skill-name>/` | `OutsideRoot` |
| symlink `→ /Users/…/.ssh` | `SymlinkEscapes` |
| symlink `→ ../other-skill/SKILL.md` | `SymlinkEscapes` |
| in-root symlink, artifact with `files` | `SymlinkNotAllowed` |
| hard link, char device, FIFO | `ForbiddenKind` |
| `Skill.md` and `SKILL.md` | `CaseCollision` |
| NFC `é` and NFD `é` in one name | `NormalizationCollision` |
| same path twice, different bytes | `Duplicate` |
| `scripts` as a file and as a directory | `FileDirConflict` |
| setuid script | `SetIdBit` (bit dropped, install continues) |
| 1 KB → 10 GB gzip bomb | `TotalTooLarge` before writing past the limit |
| extra file not in `files` | `Unlisted` |
| file in `files` but absent | `Missing` |
| one byte flipped in `SKILL.md` | `DigestMismatch` |
| `executable: true`, mode 0644 | `ExecutableMismatch` |
| every published skill in the Phase 5 sample | `Ok` (this checks for false positives) |

The last row matters as much as the hostile ones. A rule that rejects real
skills won't be adopted.

---

## Work Items

### Phase 0 — Read before writing

- [ ] **0a.** Read Vitale's spec text, not a summary. Does it say anything
  about unknown config fields, or unknown lock entry fields under
  `lockfileVersion: 1`? Record the exact wording.
- [ ] **0b.** Read Arconia's config and lock parsing. If it uses Jackson,
  check `FAIL_ON_UNKNOWN_PROPERTIES` *(verify)*. Record whether an unknown
  `files` key would be ignored, accepted or rejected.
- [ ] **0c.** Read NVIDIA's `spec/agent-package.md` §§ on extraction and
  inventory in full. Replace each *(verify)* in this document that the reading
  answers.
- [ ] **0d.** Confirm that `oci-client` can push and pull a manifest with a
  custom `artifactType` and config media type (read `oci-wasm` as the worked
  example), and whether it supports the Referrers API.
- [ ] **0e.** Settle Open Question 1 (home and number) and register the EPIC
  there.
- [ ] **0f.** Prior art: read `toolhive-core/oci/skills`. What does
  `LabelSkillFiles` hold (names only, or names and digests)? What exactly do
  its symlink and traversal checks reject? Compare the latter with this
  EPIC's admission rules. Whatever ToolHive already does gets cited in
  Phase 4, not reinvented.

### Phase 1 — Kernel (pure, unblocked)

- [ ] **1a.** `EntryHeader`, `Policy`, `Rejection`, `admit`. Pure. No `std::fs`
  and no `std::net`, enforced by the house purity gate.
- [ ] **1b.** `Inventory`, `FileHasher`, `drift`, `content_digest`. Golden
  test: a fixed inventory produces a fixed content digest, written in the test.
- [ ] **1c.** Texture corpus, built in code, with one named test per row of the
  Design table.
- [ ] **1d.** Property test: for any generated well-formed skill tree,
  `admit(pack(tree))` is `Ok` and `drift(inventory(tree), observe(tree))` is
  empty.
- [ ] **1e.** `POTENTIAL_LIMITS.md` seeded from the Honest Limits section below.

### Phase 2 — Shell, consumer side (no format change)

- [ ] **2a.** `seal install` against a skill already published under Vitale
  v0.1.0 (e.g. one from `arconia-io/agent-skills`). With no `files`, admission
  rules apply with `SymlinkRule::Soft`.
- [ ] **2b.** Content digest recorded per Decision 11 (lock field or sidecar,
  per Phase 0's answer).
- [ ] **2c.** `seal verify` across the primary path and every
  `additionalPaths` copy, with per-file localization by re-pulling the locked
  digest.
- [ ] **2d.** Interop: `arconia skills install` on a project whose lock or
  sidecar `seal` has written still succeeds and doesn't erase the content
  digest. If Arconia rewrites the lock and drops the field, that is a finding.

### Phase 3 — Shell, publisher side, and the deciding experiment

- [ ] **3a.** `seal pack` with deterministic tar, plus `files` in the config.
  Two packs of the same tree give the same layer digest.
- [ ] **3b.** `seal push` to `ghcr.io`, then `cosign sign`.
- [ ] **3c.** **The experiment:** `arconia skills add` on an artifact whose
  config carries `files`. Three outcomes:
  - It installs → Option A is additive under `schemaVersion: "1"`.
  - It rejects → Option A needs `schemaVersion: "2"` and a migration story.
    Open Phase 6 discussion.
  - It installs but rewrites or strips something → record exactly what.
- [ ] **3d.** Same experiment with salaboy's `skills-oci` (the other Vitale
  client, in Go; *(verify whether it parses the config strictly)*) and with
  the ORAS CLI. Also record whether `skills-oci` can read a spec-conformant
  `collection.v1` index, given that it writes `catalog.v1`.

### Phase 4 — Upstream

- [ ] **4a.** Open an issue on `ThomasVitale/agents-skills-oci-artifacts-spec`
  summarizing the gap, the three options and Phase 3's results. Link NVIDIA's
  spec as the source of the inventory shape, and ToolHive (per 0f) as
  evidence that a production tool already enforces some of these rules.
- [ ] **4b.** PR 1, extraction (no format change): the Extraction section,
  the permission amendment (Decision 3) and the soft symlink rule.
- [ ] **4c.** PR 2, inventory: OPTIONAL `files`, the closed-list rule, the
  forbidden-symlink rule when present, and the content digest definition. The
  examples are generated by `seal pack`, not written by hand.
- [ ] **4d.** Short note on NVIDIA's repo pointing to the PR, so the two specs
  know they share an inventory shape.

### Phase 5 — Dogfood with DK skills

- [ ] **5a.** Publish `domain-kernel` and `kernel-testkit` from
  `folkengine/dkskills` with `seal push`.
- [ ] **5b.** `seal verify --against` the git checkout of `dkskills` and the
  published artifacts.
- [ ] **5c.** False-positive sweep: run `admit` over every skill in
  `arconia-io/agent-skills` and a sample of `anthropics/skills`, and record
  every rejection. Any real skill rejected by a MUST rule is a spec finding.
- [ ] **5d.** Set the `Limits` defaults from 5c's largest observed values plus
  a stated margin. Until then they are estimates.

### Phase 6 — 🔒 Gated: inventory as a referrer (Option B)

Built only if upstream declines an additive `files` field. The inventory goes
in a separate artifact, `application/vnd.agentskills.inventory.v1+json`
*(name provisional)*, whose `subject` is the skill manifest digest. It must be
signed itself, because the publisher's manifest signature doesn't cover it.
Clients discover it through the Referrers API or the fallback tag. Phase 6
delivers nothing until this gate opens; the phase exists so the fallback has
an owner.

---

## Honest limits (seed for `POTENTIAL_LIMITS.md`)

1. **Integrity is not trust.** An inventory proves the files match what was
   signed. A malicious publisher signs a malicious skill perfectly well.
2. **Unsigned plus inventory equals consistency only.** Anyone who can rewrite
   the registry can rewrite the config. The inventory adds security only when
   the manifest signature is verified first.
3. **Detection, not prevention, after install.** `verify` finds drift. An agent
   that reads the skill between drift and verification uses the drifted files.
   The time between check and use isn't closed.
4. **Unknown-field tolerance is unconfirmed.** Everything about Option A being
   additive rests on Phase 0 and Phase 3. If clients are strict, the path
   becomes `schemaVersion: "2"`, which current Arconia releases will refuse.
5. **Harnesses may write into skill directories.** If an agent harness writes
   cache or state into `.claude/skills/<name>/` *(verify for each harness)*,
   `verify` will report it as drift. That would be correct, but noisy.
6. **Filesystem semantics vary.** Case and normalization checks are
   conservative and may reject trees that some filesystem would accept.
7. **The content digest is new.** Neither spec defines it. If NVIDIA later
   defines a different canonical form, there will be two.
8. **Both specs are drafts.** v0.1.0 and an initial draft can change
   underneath this work, and Phase 4 may chase a moving target.
9. **The specs still don't converge.** The vendor trees, archive roots and
   plugin support stay different. This EPIC only makes the inventory shape
   shared.
10. **Limits are guesses until Phase 5d.**
11. **The ecosystem is split.** ToolHive, RamaLama, `skillimage` and stax
    each use their own artifact type, and only Arconia and `skills-oci` follow
    Vitale's spec. Even full upstream adoption of this EPIC hardens one
    format among several. The `seal-kernel` admission rules are
    format-independent, so they can be offered to the others; the inventory
    field can't, without each project agreeing.

---

## Test Plan

| Area | Kind | Where | What it proves |
|---|---|---|---|
| `admit` | texture corpus | kernel | each hostile archive gets its named rejection |
| `admit` | property | kernel | well-formed trees are always admitted |
| `drift` | unit + property | kernel | missing, unlisted, changed and mode drift are each detected and localized |
| `content_digest` | golden | kernel | fixed inventory → fixed digest |
| Purity | gate | kernel | no `fs`, `net`, clock or env in `seal-kernel` |
| Deterministic pack | repeat build | shell | same tree → same layer digest |
| Install, legacy artifact | integration | shell | v0.1.0 skills install unchanged under the soft rules |
| Copies | integration | shell | every `additionalPaths` copy is verified |
| Arconia interop | experiment | shell | Phase 3c outcome recorded |
| False positives | sweep | shell | Phase 5c: real skills admitted |

---

## Key Files

| File | Role |
|---|---|
| `seal-kernel/src/admit.rs` | Admission policy and `Rejection` |
| `seal-kernel/src/inventory.rs` | `Inventory`, `FileHasher`, `drift`, `content_digest` |
| `seal-kernel/tests/textures.rs` | Hostile-archive corpus |
| `seal/src/main.rs` | `install`, `verify`, `pack`, `push` |
| `POTENTIAL_LIMITS.md` | From Honest Limits |
| upstream `README.md` (Vitale) | Extraction section, `files`, content digest |

## Reuse (do NOT recreate)

- **NVIDIA's inventory shape** (`files`, `path`, `digest`, `executable`) and its
  extraction rule list. Credit it in the PR.
- **Vitale's lock file, install layout and update workflow,** extended rather
  than replaced.
- **Cosign** for signing and identity policy. No new trust mechanism.
- **`oci-client`** for registry access, wrapped the way **`oci-wasm`** wraps
  it.
- **ToolHive's validation rules** (per 0f) as a cross-check on the admission
  rules.
- **The kernel-testkit skill** for organizing the texture corpus and the
  property tests.
- **The house purity gate** shape for `seal-kernel`.

## Compatibility

Phases 1–2 change no artifact format. Phase 4's extraction PR changes no
artifact format, and only rejects archives that were unsafe to unpack. Phase 4's
inventory PR is additive if Phase 3c confirms tolerance, and a
`schemaVersion` bump otherwise. That fork is the single compatibility
decision in this EPIC, and it is made from evidence.

## Dependencies

- **Upstream:** Vitale's spec v0.1.0, NVIDIA's `agent-package-spec` draft, the
  Agent Skills specification, OCI Image and Distribution Spec v1.1, Cosign.
- **Feeds:** `dkskills` publishing (Phase 5); the kernel-testkit skill (a
  worked example of textures for a security kernel rather than a domain one).
- **Related:** `claude/kernel-ontology-dkskills-fit.md` (how DK skills are
  organized); EPIC-90 Phase 7 (pkcore's own supply chain: same Cosign
  posture, different artifact).

## Verification

```sh
cargo test -p seal-kernel                      # textures, properties, golden digest
make check-purity                              # seal-kernel: no fs/net/clock/env
seal install ghcr.io/arconia-io/agent-skills/<skill>:<tag>   # legacy artifact
seal push ./dkskills/domain-kernel ghcr.io/folkengine/dkskills/domain-kernel:1.0.0
arconia skills add --ref ghcr.io/folkengine/dkskills/domain-kernel   # Phase 3c
seal verify                                    # all copies, all skills
seal verify --against ghcr.io/folkengine/dkskills/domain-kernel:1.0.0 ./dkskills/domain-kernel
```

Done when: every hostile texture is rejected and every real skill in the
Phase 5 sample is admitted; Phase 3c's outcome is recorded; both upstream PRs
are open with examples generated by `seal`; and every *(verify)* and every
estimate in this document has been replaced by a citation or a measurement.

---

## Open Questions

1. **Home and number.** A new repo (working name `skill-seal`: crates
   `seal-kernel`, `seal`), or a workspace inside `dkskills`? Default: its own
   repo, because it serves any skill, not just DK ones. Number per that repo's
   own sequence.
2. **Contribute to Arconia instead of, or as well as, a Rust tool?** Vitale's
   reference implementation is Java and the other client is Go. Default: Rust
   first, both to find the holes and because no Rust implementation exists.
   Then offer the kernel's rules and textures to Arconia, `skills-oci` and
   ToolHive as a test corpus, not as code.
3. **Is the content digest worth proposing,** or should the lock just store the
   config digest? The config digest changes when metadata changes, even if
   no file did. Default: propose it; drop it if upstream prefers fewer
   concepts.
4. **Soft symlink rule: warn or reject in-root symlinks** for artifacts without
   `files`? Default: warn, pending Phase 5c's count of real skills that use
   them.
5. **Should collections carry content digests** on their manifest entries, so a
   collection can promise content as well as digests? Default: out of scope.
   Revisit after Phase 4.
6. **Does Vitale want this at all?** Default: open the issue (4a) before
   writing either PR, with Phase 3's evidence attached.

---

## References

- Thomas Vitale, *Agent Skills as OCI Artifacts* — https://www.thomasvitale.com/agent-skills-as-oci-artifacts/
- Agent Skills OCI Artifacts Specification — https://github.com/ThomasVitale/agents-skills-oci-artifacts-spec
- ORAS CLI walkthrough for that spec — https://github.com/ThomasVitale/agents-skills-oci-artifacts-spec/blob/main/examples/oras-cli.md
- Arconia `skills` commands — https://docs.arconia.io/arconia-cli/0.19.0/skills/skills/
- `arconia-io/agent-skills` — https://github.com/arconia-io/agent-skills
- NVIDIA Agent Package Specification — https://github.com/NVIDIA/agent-package-spec
- NVIDIA draft spec text — https://github.com/NVIDIA/agent-package-spec/blob/main/spec/agent-package.md
- salaboy `skills-oci` (same skill artifact type) — https://pkg.go.dev/github.com/salaboy/skills-oci/pkg/oci
- Red Hat ET `skillimage` (skills as plain OCI images; a different approach) — https://github.com/redhat-et/skillimage
- ToolHive `thv skill build` — https://docs.stacklok.com/toolhive/reference/cli/thv_skill_build
- ToolHive skill build validation (symlinks, traversal) — https://docs.stacklok.com/toolhive/guides-ui/skills-build
- `toolhive-core/oci/skills` (`dev.toolhive.skills.v1`, `LabelSkillFiles`) — https://pkg.go.dev/github.com/stacklok/toolhive-core/oci/skills
- RamaLama PR #2909 — https://github.com/containers/ramalama/pull/2909
- stax spec — https://stax.stakpak.dev/docs/spec
- `oci-client` (Rust) — https://github.com/oras-project/rust-oci-client
- `oci-wasm` (Rust; the wrapper pattern) — https://docs.rs/crate/oci-wasm/0.4.0/source/README.md
- Comparison note that framed this EPIC — this project's 2026-11-19 chat, "Agent Skills OCI vs NVIDIA Agent Package".
