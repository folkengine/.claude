# /domain-kernel Vocabulary Pass — Design

Date: 2026-09-14
Status: Approved

## Purpose

Fold the cheap, standalone findings from the `dkdocs` analysis into the
`domain-kernel` skill. The analysis maps the pattern onto Domain-Driven
Design (DDD) and onto *Software Architecture: The Hard Parts* (Ford,
Richards, Sadalage, Dehghani, 2021), and proposes ~31 backlog items. This
pass takes only the vocabulary and template items that fit files the skill
already has. It adds no new modes and no new scripts.

Sources (outside this repo):

- `~/src/github.com/folkengine/dkdocs/docs/ddd-framing.md` (DDD-01..07)
- `~/src/github.com/folkengine/dkdocs/docs/hard_parts/hard-parts-and-domain-kernel.md`
- `~/src/github.com/folkengine/dkdocs/docs/hard_parts/hard-parts-backlog.md` (HP-01..23)
- `~/src/github.com/folkengine/dkdocs/docs/domain-surface.md` (not used in this pass)
- `~/src/github.com/folkengine/dkdocs/docs/gridiron-epic-00.md` (used only to check for conflicts)

## The terminology rule

The main risk is that DDD and Hard Parts terms make the skill harder to read.
Every new term follows one rule:

1. **Plain words lead.** The skill's own prose uses plain words.
2. **The borrowed term follows once, in brackets**, at first use in each file:
   "one domain's rules (DDD: *bounded context*)", "the deployable unit
   (Hard Parts: *architecture quantum*)".
3. **After first use, keep the plain words.** Do not switch to the borrowed
   term later in the same file.
4. **Every borrowed term has an entry in `references/glossary.md`.**

## Files

All paths are relative to `skills/domain-kernel/`.

### `references/glossary.md` (new) — DDD-02, HP-02

Two sections: **From DDD** and **From The Hard Parts**. Each entry has four
parts:

- **Term**: the borrowed name.
- **Plain meaning**: one sentence.
- **In a kernel**: what the term is in kernel terms, one or two sentences.
- **Verdict**: *use*, *use with a change* (and what changes), or *refuse*
  (and why).

DDD entries (verdicts from `ddd-framing.md` § "Terms to adopt, adapt, and
refuse"):

- *use*: bounded context, ubiquitous language, published language, open host
  service, anticorruption layer, context map, domain event, integration
  event, invariant, specification, read model, process manager, consistency
  boundary, side-effect-free function, closure of operations, conceptual
  contours, segregated core, cohesive mechanism, core / supporting / generic
  subdomain, Decider.
- *use with a change*: conformist, partnership, command, aggregate,
  application service.
- *refuse*: shared kernel, core domain (as a synonym for kernel), repository
  and entity at the boundary, domain service as a separate category.

The open host service entry notes the naming clash: in WIT a "host" is the
*consumer*, but in DDD the open host is the *provider*.

Hard Parts entries: architecture quantum (a kernel is never one; shell +
kernel(s) + store is), static coupling (empty for a no-import kernel — a
"coupling sink"), dynamic coupling and its three dimensions (communication,
consistency, coordination — all decided by the shell), semantic vs.
implementation coupling, architecture fitness function, architecture
decision record (ADR), stamp coupling, strict vs. loose contract,
disintegrator / integrator.

### `references/invariants.md` — HP-06 (rule only), HP-18, DDD-03

- **Invariant 7 — Things that must change together live in one kernel**
  (DDD: *consistency boundary*). One `apply` is the only all-or-nothing step
  the pattern offers. Changes that span two kernels cannot be all-or-nothing.
  Model them as explicit in-between states (`held`, `awaiting-capture`).
  Name the **intra-kernel question** — when one kernel holds several natural
  consistency groups (several accounts, several hands), does `apply` change
  the whole state at once, or one group? Either answer is fine; record it in
  the ADR.
  Detection: "name an operation that must never half-happen; do its writes
  cross a kernel boundary?"
- **Invariant 8 — State belongs to the kernel that changes it.** Table of
  the four shared-data cases from the book, with the kernel's answer:
  one owner, others ask (*delegate*) = default, the others get a projection;
  split the data (*table split*) = split the kernel; merge the owners
  (*service consolidation*) = god-kernel, resist; shared schema (*data
  domain*) = DDD Shared Kernel in database form, refuse.
- **Note on events** under the existing invariants: events that stay inside
  the kernel's contract (DDD: *domain event*) vs. messages a translator puts
  on the wire (DDD: *integration event*).
- The "Output shape for an assessment" section stays unchanged.

### `references/charter.md` — DDD-01, HP-01, HP-03, HP-04, HP-17 (text)

- **Ancestors.** Add Evans, *Domain-Driven Design* (2003), ch. 10 "Supple
  Design" (side-effect-free functions, closure of operations) and ch. 15
  "Distillation" (segregated core, cohesive mechanism). Add Chassaing's
  Decider (2021): the transition surface is a Decider. Shared Kernel and
  Core Domain stay as neighbors to position against.
- **Companion.** Add *The Hard Parts* as a companion — neither ancestor nor
  neighbor. It is the book about the layer above the kernel.
- **Third leg, restated.** `check_purity.py` and `kernel-purity.yml` are
  fitness functions (automated checks that a design rule still holds). The
  third leg is the step past them: a fitness function is a test that fails;
  a no-import WIT world is a capability that does not exist.
- **Fifth reuse pattern.** Table with the book's four reuse options (copy
  the code, shared library, shared service, sidecar) plus a kernel row: a
  Wasm component is a shared library (in-process, no network hop) with
  shared-service traits (language-neutral contract, sandbox, one artifact
  for all consumers). Versioning stays a cost in the kernel row.
- **Strict contract cost.** WIT is strict on purpose. The bill is
  brittleness and versioning work. Say so.
- **Honest limits: what the kernel does not do.** Scaling, uptime, fault
  tolerance, deployability. These belong to the shell. The kernel's help is
  indirect: you can re-cut the deployable units without touching the domain.

### `assets/DOMAIN_KERNEL_CHARTER.md` — DDD-02, HP-03, HP-23

- Add a one-line plain definition that uses the terminology rule: "one
  domain's rules (DDD: *bounded context*), shipped on their own as a shared
  contract (DDD: *published language*)".
- Add a **What the kernel does not do** section (scaling, uptime, fault
  tolerance, deployability belong to the shell).
- Add a **Where this loses** section, with a placeholder for the project's
  own cases.

### `assets/KERNEL_ADR.md` (new) — HP-08

Fill-in template, one per kernel. Sections:

1. Boundary chosen (the domain in three words).
2. Wider boundary rejected, and why.
3. Narrower boundary rejected, and why.
4. Subdomain type: core / supporting / generic, or cohesive mechanism
   (an algorithm the domain uses, not rules that mean something).
5. What must be all-or-nothing, and the intra-kernel decision
   (invariant 7).
6. Contract change policy: link to `CONTRACT_POLICY.md`.

No saga or granularity-table sections. Those depend on Mode E and Mode F.

### `assets/CONTRACT_POLICY.md` (new) — HP-15

Fill-in template, one per kernel contract. Sections:

1. Package and version (`namespace:pkg@x.y.z`).
2. What counts as breaking: removed export, narrowed type, added required
   field, renamed case.
3. Support window: how long an old major version stays supported.
4. Who decides.
5. How consumers hear about changes.

### `references/wit-boundary.md` — HP-15, HP-17

- **Always version the package** (`org:pkg@x.y.z`); link to
  `assets/CONTRACT_POLICY.md`.
- **Opaque bytes: handles yes, payloads no.** An opaque state handle
  (`type state = list<u8>`, owned by the kernel, never read by hosts) is
  fine. An opaque payload field that stands in for structure (`metadata:
  string`, `extra: list<u8>`) is not: it brings back the ambiguity the typed
  contract removes. Raw bytes that are wire *input* to a sans-I/O kernel
  (e.g. a protocol message) are also fine.
  This resolves a conflict between HP-17 (ban opaque blobs) and the
  gridiron WIT sketches (opaque `state`).

### `SKILL.md` — HP-23 and links

- After "The canonical invariants … live in `references/invariants.md`",
  add a pointer to `references/glossary.md` and one sentence stating the
  terminology rule.
- Mode C: add a step to version the package and ship a contract policy
  (`assets/CONTRACT_POLICY.md`).
- Mode D: add "do not oversell — every charter ends with where the pattern
  loses"; add `assets/KERNEL_ADR.md` as an optional companion per kernel.
- Keep SKILL.md under ~200 lines. Detail goes in the reference files.

## Out of scope

- Mode E (composing kernels, rules 1–8) and Mode F (pre-kernel survey). The
  analysis refers to both, but neither exists in the skill, and their
  source docs (`interlocking-kernels.md`, `POTENTIAL_LIMITS.md`,
  `MODE_F_SURVEY.md`, the prior-art doc) are not in this repo.
- New scripts: `check_projections.py`, `check_compensation.py`,
  `main_sequence.py`, a WIT-level opaque-payload check.
- The domain surface audit.
- Essays, gridiron, Sysops Squad, Silicon Lizzie, and other demo repos.
- The `decide` / `evolve` split in Mode C (DDD-04 spike).
- Any change to `check_purity.py` or the CI / lint assets.

## Verification

1. **Terminology rule.** For each borrowed term in the glossary, grep the
   changed files. Every first use in a file must come after its plain
   words, in brackets. Every borrowed term used anywhere in the skill must
   have a glossary entry.
2. **Links resolve.** Every `references/…`, `assets/…` and `scripts/…` path
   named in `SKILL.md` and the reference files exists.
3. **Script unchanged.** `python3 skills/domain-kernel/scripts/test_check_purity.py`
   passes.
4. **No new modes.** `SKILL.md` still lists Modes A–D only.
5. **README.** No change needed — no new skill is added; the existing
   `domain-kernel` entry stays correct.
