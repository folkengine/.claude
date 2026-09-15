# Domain-Kernel Vocabulary Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fold the standalone vocabulary and template findings from the `dkdocs` DDD and *Hard Parts* analysis into the `domain-kernel` skill, with every borrowed term written plain-words-first.

**Architecture:** Documentation-only change to `skills/domain-kernel/`. A new plain-words glossary is the anchor. Invariants, charter reference, WIT reference, templates and SKILL.md gain the new content and point to the glossary. A checker script (outside the skill) enforces the terminology rule and link integrity and acts as the test.

**Tech Stack:** Markdown; Python 3 (stdlib only) for the checker; existing `scripts/test_check_purity.py` as a regression check.

**Spec:** `docs/superpowers/specs/2026-09-14-domain-kernel-vocabulary-pass-design.md`

## Global Constraints

- **Never run a state-changing git command** (`git add`, `git commit`, `git stash`, etc.). At each commit point, stop and print the exact command for the user to run. This is a user rule and overrides the normal "commit" step.
- **Terminology rule:** plain words lead; the borrowed term follows once, in brackets, at first use in each file, written exactly as `(DDD: *term*)` or `(Hard Parts: *term*)`; after first use, keep the plain words; every borrowed term has an entry in `references/glossary.md`.
- All paths below are relative to the repo root `/Users/christoph/src/github.com/folkengine/.claude` unless marked otherwise.
- Touch only the files named in each task.
- `skills/domain-kernel/SKILL.md` stays under ~200 lines and lists Modes A–D only.
- Do not change `scripts/check_purity.py`, `scripts/test_check_purity.py`, or the CI / lint assets (`clippy.toml`, `deny-bans.toml`, `kernel-purity.yml`).
- Write in plain, short sentences. The user asked that the DDD terms not make the skill harder to read.

## The checker

The "test" for this plan is one script:

`/private/tmp/claude-501/-Users-christoph-src-github-com-folkengine--claude/61036edf-98d9-4d69-884f-0fa9694f16ad/scratchpad/check_dk_vocab.py`

Below it is called `$CHECK`. Run it from the repo root:

```bash
python3 "$CHECK"
```

It prints one `FAIL …` line per problem, then `PASS` or `FAIL`, and exits 0 or 1.

---

### Task 1: Confirm the checker and the baseline

**Files:**
- Create (if missing): `/private/tmp/claude-501/-Users-christoph-src-github-com-folkengine--claude/61036edf-98d9-4d69-884f-0fa9694f16ad/scratchpad/check_dk_vocab.py`

**Interfaces:**
- Produces: `$CHECK`, used by every later task.

- [ ] **Step 1: Make sure the checker exists**

If the file is missing, create it with exactly this content:

```python
#!/usr/bin/env python3
"""Check the domain-kernel skill's terminology rule and file links.

Run from the repo root:
    python3 <this file>

Checks:
  1. First use of each borrowed term in each .md file (except the glossary
     and the CRITIQUE files) sits right after "DDD: *" or "Hard Parts: *",
     i.e. is written like "(DDD: *bounded context*)".
  2. Every borrowed term has an entry in references/glossary.md.
  3. Every references/, assets/ or scripts/ path named in SKILL.md or in
     references/*.md exists.
Exit 0 if all pass, 1 otherwise.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path("skills/domain-kernel")
EXEMPT = {"references/glossary.md", "CRITIQUE.md", "CRITIQUE-CoPilot.md"}
TERMS = [
    # DDD
    "bounded context", "ubiquitous language", "published language",
    "open host service", "anticorruption layer", "context map",
    "domain event", "integration event", "read model", "process manager",
    "consistency boundary", "side-effect-free function",
    "closure of operations", "conceptual contours", "segregated core",
    "cohesive mechanism", "subdomain", "Decider",
    # The Hard Parts
    "architecture quantum", "static coupling", "dynamic coupling",
    "semantic coupling", "fitness function", "stamp coupling",
    "disintegrator", "integrator", "table split",
    "service consolidation", "data domain",
]
# Terms too common in plain English to check for first use (e.g. "delegate
# to the crate's functions" in hosts.md); they still need a glossary entry.
GLOSSARY_ONLY = ["delegate"]
MARKER = re.compile(r"(DDD|Hard Parts):\s+\*$")
LINK = re.compile(r"((?:references|assets|scripts)/[A-Za-z0-9_.\-]+)")

fail = False

for path in sorted(ROOT.rglob("*.md")):
    rel = path.relative_to(ROOT).as_posix()
    if rel in EXEMPT:
        continue
    text = path.read_text()
    for term in TERMS:
        # Words may wrap across lines, so match any whitespace between them.
        pattern = r"\b" + r"\s+".join(map(re.escape, term.split()))
        m = re.search(pattern, text, re.IGNORECASE)
        if not m:
            continue
        if not MARKER.search(text[max(0, m.start() - 20):m.start()]):
            line = text.count("\n", 0, m.start()) + 1
            print(f"FAIL rule   {rel}:{line}: first '{term}' is not "
                  f"written as '(DDD|Hard Parts: *{term}*)'")
            fail = True

glossary = ROOT / "references/glossary.md"
if not glossary.exists():
    print("FAIL glossary references/glossary.md does not exist")
    fail = True
else:
    gl = " ".join(glossary.read_text().split()).lower()
    for term in TERMS + GLOSSARY_ONLY:
        if term.lower() not in gl:
            print(f"FAIL glossary no entry for '{term}'")
            fail = True

for path in [ROOT / "SKILL.md", *sorted((ROOT / "references").glob("*.md"))]:
    rel = path.relative_to(ROOT).as_posix()
    for n, line in enumerate(path.read_text().splitlines(), 1):
        for target in LINK.findall(line):
            target = target.rstrip(".")
            if not (ROOT / target).exists():
                print(f"FAIL link    {rel}:{n}: '{target}' does not exist")
                fail = True

print("FAIL" if fail else "PASS")
sys.exit(1 if fail else 0)
```

- [ ] **Step 2: Run it and confirm the baseline fails**

Run: `python3 "$CHECK"`

Expected: exit 1, with exactly these four lines before the final `FAIL`:

```
FAIL rule   assets/DOMAIN_KERNEL_CHARTER.md:41: first 'bounded context' is not written as '(DDD|Hard Parts: *bounded context*)'
FAIL rule   references/charter.md:30: first 'bounded context' is not written as '(DDD|Hard Parts: *bounded context*)'
FAIL rule   references/hexagonal-comparison.md:39: first 'bounded context' is not written as '(DDD|Hard Parts: *bounded context*)'
FAIL glossary references/glossary.md does not exist
```

If you see other lines, stop and report them.

- [ ] **Step 3: Confirm the purity script's tests pass (regression baseline)**

Run: `python3 skills/domain-kernel/scripts/test_check_purity.py`
Expected: `Ran 14 tests … OK`

No commit — the checker lives outside the repo.

---

### Task 2: New templates — decision record and contract policy

**Files:**
- Create: `skills/domain-kernel/assets/KERNEL_ADR.md`
- Create: `skills/domain-kernel/assets/CONTRACT_POLICY.md`

**Interfaces:**
- Consumes: nothing. The ADR names "invariant 7", which Task 4 adds.
- Produces: `assets/KERNEL_ADR.md` and `assets/CONTRACT_POLICY.md`. Later tasks link to them from `references/glossary.md` (Task 3), `references/invariants.md` (Task 4), `references/charter.md` (Task 5), `references/wit-boundary.md` (Task 6) and `SKILL.md` (Task 8). They come first so those links never point at a missing file.

- [ ] **Step 1: Confirm the templates are absent (failing check)**

Run: `ls skills/domain-kernel/assets/KERNEL_ADR.md skills/domain-kernel/assets/CONTRACT_POLICY.md`
Expected: two `No such file or directory` errors.

- [ ] **Step 2: Create `skills/domain-kernel/assets/KERNEL_ADR.md`**

```markdown
# Decision record — `<kernel-name>` boundary

*One per kernel. It records why the boundary sits here, and which wider and
narrower boundaries were rejected. Borrowed terms are explained in the
domain-kernel skill's glossary.*

> Template — replace the bracketed parts; keep the structure.

| Field | Value |
|---|---|
| Kernel | `<kernel-name>` |
| Status | <Proposed / Accepted / Replaced by …> |
| Date | <YYYY-MM-DD> |
| Contract | `<namespace:pkg@x.y.z>` |

## 1. Boundary chosen

<The domain in three words.>

<One paragraph: what the kernel owns — its state, actions, events and
projections — and what it leaves to the shells.>

## 2. Wider boundary rejected

<The next-larger boundary you considered, e.g. "rules and play resolution in
one kernel".>

<Why it was rejected: which rules would then belong to more than one
domain.>

## 3. Narrower boundary rejected

<The next-smaller boundary you considered.>

<Why it was rejected: which rules consumers would then copy into their own
code, because the contract was too narrow to be worth calling.>

## 4. How special this logic is (DDD: *subdomain* type)

Pick one and say why:

- **Core** — it sets the business apart. Expect pressure to keep it vague.
- **Supporting** — needed and specific to us, but not what sets us apart.
- **Generic** — the same everywhere. The easiest kernel to justify.
- **An algorithm the domain uses** (DDD: *cohesive mechanism*) — not rules
  that mean something. Pure and packaged like a kernel, but labeled as not a
  *domain* kernel.

<Choice and reason.>

## 5. What must be all-or-nothing

<List the operations that must never half-happen.>

For each one: is it inside this kernel's single `apply`? If it crosses into
another kernel, name the in-between states that make the crossing safe
(invariant 7 in the domain-kernel skill).

**Intra-kernel decision.** <Does one `apply` change the whole state at once,
or one group of it — one account, one hand? Say which, and why.>

## 6. Contract change policy

<Link to this kernel's CONTRACT_POLICY.md.>
```

- [ ] **Step 3: Create `skills/domain-kernel/assets/CONTRACT_POLICY.md`**

```markdown
# Contract change policy — `<namespace:pkg>`

*How this kernel's contract changes, and what consumers can count on. Ship
it next to the WIT package.*

> Template — replace the bracketed parts; keep the structure.

## 1. Package and version

`<namespace:pkg@x.y.z>`. The version is part of the package name in every
`.wit` file. A breaking change bumps the major version. An additive change
bumps the minor version.

## 2. What counts as breaking

Treat a change as **breaking** (major bump) if it:

- removes or renames an export, a type, a field, or an enum or variant case;
- narrows a type (e.g. `u32` → `u16`);
- adds a field to a record, or a case to an enum or variant — consumers see
  a new type;
- changes what an existing function returns for the same input.

The last point matters most for a kernel: **a rule change is a contract
change, even when no type changes.** <Say whether this project treats a rule
change with unchanged types as major or minor.>

A change is **additive** (minor bump) if it only adds a new function or a
new interface, and leaves every existing one unchanged.

## 3. Support window

<How long an old major version stays supported after a new one ships, e.g.
"two minor releases or 90 days, whichever is longer".>

Hosts pinned to different *minor* versions of one major version must work
together. A host on a different *major* version must fail loudly when it
loads the component — never silently.

## 4. Who decides

<The one party that approves contract changes. A kernel has one owner, not a
committee of consumers.>

<How a consumer asks for a change.>

## 5. How consumers hear about changes

<The channel: a changelog file, release notes, a mailing list.>

<How much notice comes before a breaking release.>
```

- [ ] **Step 4: Run the checker**

Run: `python3 "$CHECK"`
Expected: `FAIL` with exactly the same four baseline lines as Task 1 Step 2 — nothing new. (The ADR's `(DDD: *subdomain* type)` and `(DDD: *cohesive mechanism*)` already follow the rule.) The glossary comes in Task 3.

No commit yet — the first commit point is after Task 3.

---

### Task 3: Glossary, and fix the three existing term uses

**Files:**
- Create: `skills/domain-kernel/references/glossary.md`
- Modify: `skills/domain-kernel/references/charter.md:30`
- Modify: `skills/domain-kernel/references/hexagonal-comparison.md:39`
- Modify: `skills/domain-kernel/assets/DOMAIN_KERNEL_CHARTER.md:41`

**Interfaces:**
- Produces: `references/glossary.md`. Later tasks link to it by that path. Entries later tasks rely on: consistency boundary (→ invariant 7), the four shared-data answers (→ invariant 8), fitness function and strict contract (→ `references/charter.md`), ADR (→ `assets/KERNEL_ADR.md`), change policy (→ `assets/CONTRACT_POLICY.md`).

- [ ] **Step 1: Create `skills/domain-kernel/references/glossary.md`**

```markdown
# Glossary — borrowed terms in plain words

Use this when reading or writing any domain-kernel doc. The skill borrows
words from two sources: Domain-Driven Design (DDD — Evans 2003; Vernon 2013
and 2016; and the functional-DDD line of Wlaschin and Chassaing) and
*Software Architecture: The Hard Parts* (Ford, Richards, Sadalage and
Dehghani, 2021).

**The rule.** Plain words lead. The borrowed term follows once, in
brackets, at first use in each file:
"one domain's rules (DDD: *bounded context*)". After that, keep the plain
words. A reader who has never read DDD or the book must be able to read
every doc in this skill.

Entries are grouped by verdict. Each gives the plain meaning and what the
term is for a kernel. Where the verdict is not a plain "use", the entry says
what changes or why the term is refused.

## From DDD

### Use

- **Bounded context** — *Plain:* the area inside which one set of words has
  one meaning. *Kernel:* a kernel covers exactly one. If you cannot name the
  domain in three words, it is more than one.
- **Ubiquitous language** — *Plain:* the shared words that domain experts and
  the code both use. *Kernel:* the kernel's WIT world is these words, checked
  by a machine. A name clash between two domains is fixed in the contract.
- **Published language** — *Plain:* a documented contract that other teams
  translate to and from. *Kernel:* what a kernel ships — its WIT world. The
  right answer to "isn't this just a Shared Kernel?"
- **Open host service** — *Plain:* a team offers one defined protocol that
  anyone may call. *Kernel:* the kernel's exports. Name clash: in DDD the
  "host" is the *provider*; in WebAssembly the host is the *consumer* that
  runs the component. Say "open host service" only in DDD passages.
- **Anticorruption layer** — *Plain:* translation code that stops another
  team's words from leaking into yours. *Kernel:* a translator between two
  kernels. A good one is itself pure, total and deterministic, so it can be
  tested alone.
- **Context map** — *Plain:* a diagram of the domains and how each pair
  relates. *Kernel:* the graph of which kernel's output is routed into which
  kernel's input.
- **Domain event** — *Plain:* a fact the domain records, in the domain's own
  words. *Kernel:* the `event` values the kernel emits. They stay inside the
  contract.
- **Integration event** — *Plain:* a message sent to another system, in a
  shared wire format. *Kernel:* made by a shell or translator from domain
  events. The kernel never emits one.
- **Invariant** — *Plain:* a rule that is always true. *Kernel:* what `apply`
  refuses to break — or better, what the state type cannot even represent.
- **Specification** — *Plain:* a yes/no test on the state. *Kernel:*
  `legal-actions` and any other predicate the contract exposes.
- **Read model** — *Plain:* a view of the data shaped for one reader.
  *Kernel:* `view-for(state, party)`. Keep the name `view-for` in contracts.
- **Process manager** — *Plain:* the part that runs a multi-step process and
  decides the next step. *Kernel:* if the routing between kernels starts to
  make decisions, those decisions are a kernel of their own, with the process
  as its state.
- **Consistency boundary** — *Plain:* the data that must change together, all
  or nothing. *Kernel:* one kernel's state. See invariant 7 in
  `invariants.md`.
- **Side-effect-free function** — *Plain:* a function that returns a result
  and changes nothing else. *Kernel:* every kernel operation. Evans named it
  in 2003 (ch. 10, "Supple Design").
- **Closure of operations** — *Plain:* an operation whose output has the same
  type as its input, so calls chain. *Kernel:* `apply : state × action →
  state`.
- **Conceptual contours** — *Plain:* the natural seams of the domain.
  *Kernel:* where to cut the boundary. Cut along the seams, not to the
  smallest size.
- **Segregated core** — *Plain:* the core model, kept physically apart from
  support code. *Kernel:* the kernel crate or component, apart from its
  shells. A kernel adds a sandbox around it.
- **Cohesive mechanism** — *Plain:* an algorithm the domain uses, split out
  behind a clear interface (a solver, a graph walk). *Kernel:* it can be
  packaged like a kernel, but it is not a *domain* kernel — it holds no rules
  that mean something. Label it honestly. A rules engine called "the domain"
  is this mistake.
- **Core / supporting / generic subdomain** — *Plain:* how special this logic
  is to the business: what sets it apart (core), needed and specific but not
  special (supporting), or the same everywhere (generic). *Kernel:* record it
  per kernel in the decision record (`assets/KERNEL_ADR.md`). Supporting and
  generic logic is the easiest to make a kernel. Core logic is often kept
  vague by its owner on purpose.
- **Decider** — *Plain:* a four-part functional shape for data that changes
  together: `decide(command, state) → events`, `evolve(state, event) →
  state`, a starting state, and a "finished?" test (Chassaing, 2021).
  *Kernel:* the transition surface is a Decider folded together — `apply`
  runs `decide`, then `evolve` over each event; `outcome` is the "finished?"
  test.

### Use with a change

- **Conformist** — *Plain:* one team adopts another team's model as-is, with
  no translation. *Change:* DDD treats this as giving up. With a kernel it is
  safe, because what you adopt is pure, versioned, and has a stated change
  policy (`assets/CONTRACT_POLICY.md`).
- **Partnership** — *Plain:* two teams change their models together.
  *Change:* fine for kernels owned by one team, but only while no kernel
  names another. Values cross between kernels; calls do not.
- **Command** — *Plain:* a request to change the state. *Change:* the kernel
  calls this an `action`. Keep `action` in contracts; say "command" once for
  DDD readers.
- **Aggregate** — *Plain:* a cluster of objects that change together in one
  transaction. *Change:* use the idea under the name *consistency boundary*.
  Use the word "aggregate" only for the intra-kernel question in invariant 7.
  The word carries object and storage baggage a kernel does not have.
- **Application service** — *Plain:* the layer that runs a use case.
  *Change:* this is the shell — minus any code that decides. Code that
  decides is domain logic and belongs in a kernel.

### Refuse

- **Shared kernel** — *Plain:* model code two teams own together and change
  by agreement. *Why refused:* a domain kernel shares a published contract
  with one owner, not co-owned code. This is the look-alike readers most
  often assume.
- **Core domain** (as another name for "kernel") — *Plain:* the most valuable
  part of the business. *Why refused:* it says where to invest, not how the
  code is built. A kernel may be core, supporting, or generic.
- **Repository** and **entity** at the boundary — *Plain:* an object that
  loads and saves data; an object with a lasting identity. *Why refused:* a
  kernel has no storage, and only values cross its boundary. Inside a kernel
  you may model entities; the contract never shows one.
- **Domain service** as a separate category — *Plain:* domain logic that
  belongs to no single object. *Why refused:* every function in a kernel
  already is one.

## From The Hard Parts

### Use

- **Architecture quantum** — *Plain:* the smallest unit you can deploy on its
  own, with everything it needs, data included. *Kernel:* a kernel is never
  one. It has no I/O, store or clock, so it cannot run alone. The deployable
  unit is shell + kernel(s) + store.
- **Static coupling** — *Plain:* what must be wired up for a unit to run:
  libraries, database, framework. *Kernel:* empty for a no-import kernel. The
  kernel is the one part of the deployable unit with none.
- **Dynamic coupling** — *Plain:* how running units talk. Three choices: sync
  or async (communication); all-or-nothing or eventually (consistency); one
  central coordinator or each unit reacts to events (coordination).
  *Kernel:* the shell makes all three choices. Inside a kernel, `apply` is
  just a function call.
- **Semantic coupling vs. implementation coupling** — *Plain:* coupling the
  problem itself forces, vs. coupling our code adds. *Kernel:* semantic
  coupling lives in the contract, visible and versioned. Implementation
  coupling stays in the shell. This is why a boundary has a best size, not a
  smallest one: cutting below it does not remove semantic coupling — it
  spreads copies of the rules into consumers.
- **Architecture fitness function** — *Plain:* an automated check that a
  design rule still holds. *Kernel:* `check_purity.py`, the lint configs and
  `kernel-purity.yml` are fitness functions. A no-import WIT world goes one
  step further (see `charter.md`).
- **Architecture decision record (ADR)** — *Plain:* a short doc that records
  a decision, why, and the options rejected. *Kernel:* one per kernel, from
  `assets/KERNEL_ADR.md`.
- **Stamp coupling** — *Plain:* sending far more data than the receiver
  needs. *Kernel:* returning full state where a projection belongs. The book
  counts it as a coupling cost. For a kernel it is also a security leak.
  `view-for` is the fix.
- **Strict vs. loose contract** — *Plain:* an exact, typed interface vs.
  free-form name/value data. *Kernel:* WIT is strict on purpose. It costs
  brittleness and versioning work (see `charter.md`). Loose payloads belong
  in shells, never in a kernel's contract.
- **Disintegrator / integrator** — *Plain:* a reason to split a unit / a
  reason to keep it whole. *Kernel:* for sizing a kernel, only the
  domain-shaped reasons count: scope, rate of change, security. Scaling and
  fault tolerance are shell reasons, never a reason to split a domain. The
  strongest reason to keep things whole is "must change all-or-nothing"
  (invariant 7).
- **Delegate, table split, service consolidation, data domain** — *Plain:*
  the book's four answers when two services both claim the same data.
  *Kernel:* see invariant 8 in `invariants.md` for the kernel's answer to
  each.
```

- [ ] **Step 2: Fix `references/charter.md:30`**

Replace:
```
- **DDD Shared Kernel** — a subset of a domain *model* two bounded contexts agree
  to co-own.
```
with:
```
- **DDD Shared Kernel** — a subset of a domain *model* that two teams' domain
  areas (DDD: *bounded contexts*) agree to co-own.
```

- [ ] **Step 3: Fix `references/hexagonal-comparison.md:39`**

Replace the text `Typically one hexagon per service/bounded context,` with
`Typically one hexagon per service or domain area (DDD: *bounded context*),`.

- [ ] **Step 4: Fix `assets/DOMAIN_KERNEL_CHARTER.md:41`**

Replace the text `shares a model subset between bounded contexts;` with
`shares a model subset between two teams' domain areas (DDD: *bounded contexts*);`.

- [ ] **Step 5: Run the checker**

Run: `python3 "$CHECK"`
Expected: `PASS`, exit 0.

- [ ] **Step 6: Commit point — stop and ask the user**

Do not run git. Print this for the user:

```bash
git add skills/domain-kernel/assets/KERNEL_ADR.md skills/domain-kernel/assets/CONTRACT_POLICY.md skills/domain-kernel/references/glossary.md skills/domain-kernel/references/charter.md skills/domain-kernel/references/hexagonal-comparison.md skills/domain-kernel/assets/DOMAIN_KERNEL_CHARTER.md && git commit -m "domain-kernel: add plain-words glossary, decision record and contract policy templates"
```

---

### Task 4: Invariants 7 and 8, and the note on events

**Files:**
- Modify: `skills/domain-kernel/references/invariants.md`

**Interfaces:**
- Consumes: `references/glossary.md` (Task 3), `assets/KERNEL_ADR.md` (Task 2).
- Produces: headings `## 7. Things that must change together live in one kernel` and `## 8. State belongs to the kernel that changes it`. The glossary (Task 3) and the ADR template (Task 2) already refer to them as "invariant 7" and "invariant 8".

- [ ] **Step 1: Confirm the new content is absent (failing check)**

Run: `grep -c -E "^## (7|8)\. |^## Events: inside" skills/domain-kernel/references/invariants.md`
Expected: `0`

- [ ] **Step 2: Add the glossary pointer**

Replace:
```
Use this when assessing (Mode A) or deciding what to enforce (Mode B). Each
invariant has a definition, the failure mode, and how to spot it in real code.
```
with:
```
Use this when assessing (Mode A) or deciding what to enforce (Mode B). Each
invariant has a definition, the failure mode, and how to spot it in real code.
Borrowed terms are defined in plain words in `glossary.md`.
```

- [ ] **Step 3: Insert the new sections before `---` / `## Output shape for an assessment`**

Replace:
```
callers. A transition surface (`to_act` / `legal_actions` / `apply` / `view_for` /
`outcome`) is the ideal shape; it is also what maps cleanly to a WIT world.

---
```
with:
```
callers. A transition surface (`to_act` / `legal_actions` / `apply` / `view_for` /
`outcome`) is the ideal shape; it is also what maps cleanly to a WIT world.

## 7. Things that must change together live in one kernel

**Definition.** One `apply` is the only all-or-nothing step the pattern
offers. So anything that must change all-or-nothing belongs in one kernel
(DDD: *consistency boundary*). A change that spans two kernels cannot be
all-or-nothing. Model it as explicit in-between states that the kernels
already know — `held`, `awaiting-capture`, `awaiting-settlement` — and let
the shell move each kernel through them.

**The intra-kernel question.** One kernel can hold several natural groups of
data that change together — several accounts in a ledger, several hands in a
tournament. Does one `apply` change the whole state at once, or only one
group, with the others catching up later? Both answers are fine. Pick one on
purpose and record it in the kernel's decision record
(`assets/KERNEL_ADR.md`). Vernon's rules for sizing a DDD aggregate are the
best guide.

**Failure mode.** A shell updates two kernels and assumes both succeed or
both fail — for example, "post to the ledger and update the exposure limit
together" — with no in-between state to land in when one of them fails.

**Detection.** Ask: "Name an operation that must never half-happen. Do its
writes cross a kernel boundary?" If they do, either the two parts belong in
one kernel, or the domain needs explicit in-between states. Crossing *with*
in-between states is fine. Crossing *without* them is a hard finding.

## 8. State belongs to the kernel that changes it

**Definition.** Every piece of state has exactly one owner: the kernel whose
`apply` changes it. Other kernels and consumers get a projection
(`view_for`) — never a direct read of the owner's state, and never a shared
copy they can write.

**When two domains claim the same data.** *Software Architecture: The Hard
Parts* (ch. 9) gives four answers. The kernel's version of each:

| The book's answer | Plain meaning | Kernel answer |
|---|---|---|
| one owner, others ask (Hard Parts: *delegate*) | One side owns the data; the other asks it | **Default.** The owner kernel changes it; the other gets a projection. |
| split the data (Hard Parts: *table split*) | Each side takes the part it changes | Split the kernel along the same line. |
| merge the owners (Hard Parts: *service consolidation*) | Put both sides in one unit | **Resist.** This is how a god-kernel grows — one kernel covering more than one domain. |
| a schema both sides write (Hard Parts: *data domain*) | Both sides share one set of tables | **Refuse.** It is DDD's Shared Kernel in database form. |

**Failure mode.** Two kernels — or a kernel and a service — both write the
same state. Or a consumer reads full state and filters it itself (see
invariant 5).

**Detection.** For each state field, ask: which kernel's `apply` changes it?
No answer, or two answers, is a finding. Classify a shared-data finding by
its row in the table above.

## Events: inside the contract vs. on the wire

The `event` values a kernel emits are facts in the domain's own words
(DDD: *domain event*). They stay inside the kernel's contract. A message sent to
another system in a shared wire format (DDD: *integration event*) is made by
a shell or a translator from those events — never by the kernel. If a
kernel's event type carries a wire format, a topic name, or another system's
field names, a delivery concern has leaked in (invariant 4).

---
```

- [ ] **Step 4: Run the checks**

Run: `grep -c -E "^## (7|8)\. |^## Events: inside" skills/domain-kernel/references/invariants.md`
Expected: `3`

Run: `python3 "$CHECK"`
Expected: `PASS`

---

### Task 5: Charter reference — ancestors, companion book, reuse table, honest limits

**Files:**
- Modify: `skills/domain-kernel/references/charter.md`

**Interfaces:**
- Consumes: `references/glossary.md` (Task 3), `assets/CONTRACT_POLICY.md` (Task 2).
- Produces: sections `### Saying it to a *Hard Parts* reader`, `## Ancestors worth naming`, `## A companion, not an ancestor`, `## Reuse: a fifth option`, and three new honest-limits bullets. Task 8 points SKILL.md Mode D at these by file name.

- [ ] **Step 1: Confirm the new content is absent (failing check)**

Run: `grep -c -E "^### Saying it to a|^## Ancestors worth naming|^## A companion, not an ancestor|^## Reuse: a fifth option" skills/domain-kernel/references/charter.md`
Expected: `0`

- [ ] **Step 2: Insert the four new sections after "The one rule"**

Replace:
```
State that synthesis up front, or the piece has no reason to exist.
```
with:
````
State that synthesis up front, or the piece has no reason to exist.

### Saying it to a *Hard Parts* reader

Readers of *Software Architecture: The Hard Parts* already trust automated
checks that a design rule still holds (Hard Parts: *fitness functions*).
`check_purity.py`, the lint configs and `kernel-purity.yml` are fitness
functions in exactly that sense. The third leg is the step past them: **a
fitness function is a test that fails; a no-import WIT world is a capability
that does not exist.** The check catches a violation after someone writes
it. The sandbox makes the violation impossible to write. One sentence for
that reader: *a domain kernel is the purity check, moved from CI into the
runtime.*

## Ancestors worth naming

The two ancestors above give the two legs. Two more show where purity came
from. Name them for DDD and functional-programming readers:

- **Evans, *Domain-Driven Design* (2003), ch. 10 "Supple Design."** Evans
  asks for as much logic as possible in functions that return a result and
  change nothing else (DDD: *side-effect-free functions*), and for
  operations whose output has the same type as their input, so calls chain
  (DDD: *closure of operations*). `apply : state × action → state` is both.
  He also asks you to cut the model along the domain's natural seams
  (DDD: *conceptual contours*) — the reason a kernel's boundary has a best
  size, not a smallest one. Ch. 15 "Distillation" adds two more: keep the
  core model physically apart from support code (DDD: *segregated core*),
  and split a pure algorithm the domain uses out of the model
  (DDD: *cohesive mechanism*). A kernel can package either, but only the
  first is a *domain* kernel.
- **Chassaing (2021).** The functional-DDD community's standard four-part
  shape for data that changes together (functional DDD: *Decider*):

  ```
  decide  : (command, state) -> list<event>
  evolve  : (state, event)   -> state
  initial : state
  terminal: state -> bool
  ```

  A kernel's transition surface is this shape folded together: `apply` runs
  `decide`, then `evolve` over each event; `outcome` is `terminal`. Say so —
  it makes the functional-DDD line an ancestor, not an omission.

So DDD is an ancestor as well as a neighbor. Keep Shared Kernel and Core
Domain as the two look-alikes to position against (below). The honest
lineage: Evans described the pure core as a discipline in 2003; hexagonal
architecture gave it a boundary; the component model made it enforceable.

## A companion, not an ancestor

Ford, Richards, Sadalage and Dehghani, *Software Architecture: The Hard
Parts* (2021), is about the layer above the kernel: how many deployable
units to have, how they talk, and where the data lives. It is neither
ancestor nor neighbor. Its unit is the smallest thing you can deploy alone,
data included (Hard Parts: *architecture quantum*). A kernel is never one:
it has no I/O, store or clock. The deployable unit is always shell +
kernel(s) + store.

The book decides how to cut the deployable units. The kernel decides what is
pure inside each one — and it makes the book's hard choices cheaper to
revisit, because re-cutting the units does not touch the kernel. (Mark
Richards, a co-author, also wrote up the microkernel pattern positioned
against below.)

## Reuse: a fifth option

*The Hard Parts* (ch. 8) lists four ways to reuse code. A kernel packaged as
a WebAssembly component is a fifth. Without this table, readers of the book
file it under "shared library" and bring that row's objections with it.

| Option | Runs | Contract | Main cost |
|---|---|---|---|
| Copy the code into each consumer | In-process | None | Copies drift apart |
| Shared library | In-process | One language's API | Versioning; dependency conflicts |
| Shared service | Over the network | Language-neutral (HTTP, gRPC) | Network hop; if it is down, callers fail |
| Sidecar / service mesh | Next to each service | Operational only | Fits cross-cutting ops concerns, not domain logic |
| **Kernel as a Wasm component** | In-process | Language-neutral (WIT), sandboxed | Versioning (see `assets/CONTRACT_POLICY.md`) |

The kernel row takes the good column from both library and service. It runs
in-process like a library: no network hop, and no failure when another
service is down. It is language-neutral and isolated like a service, with one
artifact for every consumer. It has no transitive dependencies to conflict.
Versioning stays a real cost — do not hide it.
````

- [ ] **Step 3: Add three bullets to "Honest limits to include"**

Replace:
```
- **Abstraction risk.** A cross-domain kernel contract must stay thin or it
  becomes useless.
```
with:
```
- **Abstraction risk.** A cross-domain kernel contract must stay thin or it
  becomes useless.
- **Strict contracts cost something.** WIT is an exact, typed contract,
  chosen on purpose. The bill is brittleness and versioning work: every
  change is visible, and every consumer feels it. A loose contract around a
  pure core would bring back the ambiguity that purity removes. Own the
  cost, and ship a change policy (`assets/CONTRACT_POLICY.md`).
- **What the kernel does not do.** Scaling, uptime, fault tolerance and
  deployment belong to the deployable unit — the shell — not to the kernel.
  The kernel helps testability and maintainability only. Its help with scale
  is indirect: you can re-cut the deployable units without touching the
  domain. Never claim a scaling benefit.
- **Don't oversell.** Every charter ends with where the pattern loses.
  *The Hard Parts* (ch. 15) puts it plainly: once you are selling a pattern
  instead of analyzing a situation, you have stopped being an architect.
```

- [ ] **Step 4: Update the "Structure" paragraph**

Replace:
```
WIT boundary; honest limits; a one-line citable definition. Keep it ~1.5 pages —
a manifesto, not a book.
```
with:
```
WIT boundary; what the kernel does not do; honest limits; where this loses; a
one-line citable definition. Keep it ~1.5 pages — a manifesto, not a book.
```

- [ ] **Step 5: Run the checks**

Run: `grep -c -E "^### Saying it to a|^## Ancestors worth naming|^## A companion, not an ancestor|^## Reuse: a fifth option" skills/domain-kernel/references/charter.md`
Expected: `4`

Run: `python3 "$CHECK"`
Expected: `PASS`

---

### Task 6: WIT reference — versioning and opaque bytes

**Files:**
- Modify: `skills/domain-kernel/references/wit-boundary.md`

**Interfaces:**
- Produces: sections `## Version the package, always` and `## Opaque bytes: handles yes, payloads no`. Task 8 points SKILL.md Mode C at them.

- [ ] **Step 1: Confirm the new content is absent (failing check)**

Run: `grep -c -E "^## Version the package|^## Opaque bytes" skills/domain-kernel/references/wit-boundary.md`
Expected: `0`

- [ ] **Step 2: Insert the two sections before the type-mapping table**

Replace:
```
holds the state. That is exactly the pure-kernel model, and it is why a no-import
component works.
```
with:
```
holds the state. That is exactly the pure-kernel model, and it is why a no-import
component works.

## Version the package, always

Put the version in the package name: `package <org>:<domain>@x.y.z;`. The
contract is what other stacks depend on, so they need a version they can pin
and a written change policy: what counts as breaking, how long an old
version lives, and who decides. Use `assets/CONTRACT_POLICY.md` as the
template.

## Opaque bytes: handles yes, payloads no

A typed contract is strict on purpose. A field that carries untyped data
brings back the ambiguity the types removed. Tell the cases apart:

- **Fine — an opaque state handle.** `type state = list<u8>;` — made and
  read only by the kernel, passed back unchanged by the host. The host never
  looks inside, so no meaning leaks out of the contract.
- **Fine — raw wire input to a protocol kernel.** A kernel whose job is to
  parse a protocol message takes the bytes as *input* (`message:
  list<u8>`). Parsing them is the kernel's work, not a hidden agreement.
- **Not fine — an opaque payload field.** `metadata: string`, `extra:
  list<u8>`, or a JSON string inside a record. Consumers must agree on what
  it means outside the contract, so the contract no longer says what the
  kernel does. Model the structure in WIT instead.
```

- [ ] **Step 3: Run the checks**

Run: `grep -c -E "^## Version the package|^## Opaque bytes" skills/domain-kernel/references/wit-boundary.md`
Expected: `2`

Run: `python3 "$CHECK"`
Expected: `PASS`

- [ ] **Step 4: Commit point — stop and ask the user**

Do not run git. Print this for the user:

```bash
git add skills/domain-kernel/references/invariants.md skills/domain-kernel/references/charter.md skills/domain-kernel/references/wit-boundary.md && git commit -m "domain-kernel: add consistency and ownership invariants, charter lineage, WIT versioning"
```

---

### Task 7: Charter template — plain definition, limits, where this loses

**Files:**
- Modify: `skills/domain-kernel/assets/DOMAIN_KERNEL_CHARTER.md`

**Interfaces:**
- Produces: sections `## What the kernel does not do` and `## Where this loses` in the template. Mode D (Task 8) tells the agent every charter has them.

- [ ] **Step 1: Confirm the new content is absent (failing check)**

Run: `grep -c -E "^\*\*In plain words:\*\*|^## What the kernel does not do|^## Where this loses" skills/domain-kernel/assets/DOMAIN_KERNEL_CHARTER.md`
Expected: `0`

- [ ] **Step 2: Add the plain definition under the subtitle**

Replace:
```
in.*

> Template — replace bracketed parts; keep the structure. See
```
with:
```
in.*

**In plain words:** one domain's rules (DDD: *bounded context*), shipped on
their own as a shared, versioned contract (DDD: *published language*) — with
no storage, no I/O, and only values crossing the boundary.

> Template — replace bracketed parts; keep the structure. See
```

- [ ] **Step 3: Add "What the kernel does not do" before "Honest limits"**

Replace:
```
## Honest limits
```
with:
```
## What the kernel does not do

Scaling, uptime, fault tolerance and deployment belong to <name the shells
and services>, not to the kernel. The kernel keeps <domain>'s rules in one
place and makes them testable. Its help with scale is indirect: we can
re-cut services without touching the domain.

## Honest limits
```

- [ ] **Step 4: Add "Where this loses" before "One-line definition"**

Replace:
```
## One-line definition
```
with:
```
## Where this loses

<Name at least one real case in this project where the kernel costs more
than it saves. For example: a rule that changes every week, so every change
ripples through the contract; a decision that needs human judgment and can
only enter the kernel as an input; a consumer that needs a scaling story the
kernel cannot give.>

## One-line definition
```

- [ ] **Step 5: Run the checks**

Run: `grep -c -E "^\*\*In plain words:\*\*|^## What the kernel does not do|^## Where this loses" skills/domain-kernel/assets/DOMAIN_KERNEL_CHARTER.md`
Expected: `3`

Run: `python3 "$CHECK"`
Expected: `PASS`

---

### Task 8: SKILL.md — glossary pointer, Mode C versioning, Mode D rules

**Files:**
- Modify: `skills/domain-kernel/SKILL.md`

**Interfaces:**
- Consumes: `assets/CONTRACT_POLICY.md` and `assets/KERNEL_ADR.md` (Task 2), `references/glossary.md` (Task 3), `references/charter.md` sections (Task 5), `references/wit-boundary.md` sections (Task 6).

- [ ] **Step 1: Confirm the new content is absent (failing check)**

Run: `grep -c -E "references/glossary.md|assets/CONTRACT_POLICY.md|assets/KERNEL_ADR.md" skills/domain-kernel/SKILL.md`
Expected: `0`

- [ ] **Step 2: Add the glossary pointer and the terminology rule**

Replace:
```
The canonical invariants and how to detect violations live in
`references/invariants.md` — read it before assessing or enforcing.
```
with:
```
The canonical invariants and how to detect violations live in
`references/invariants.md` — read it before assessing or enforcing.

Terms borrowed from Domain-Driven Design and *Software Architecture: The Hard
Parts* are defined in plain words in `references/glossary.md`. In anything
you write, lead with plain words and give the borrowed term once, in
brackets — "one domain's rules (DDD: *bounded context*)" — so readers who
know neither source can follow.
```

- [ ] **Step 3: Add the Mode C versioning step and renumber**

Replace:
```
   by raise/throw, Rust enum-with-payload → WIT `variant`). Full recipe in
   `references/wit-boundary.md`.
3. **Validate without a Rust toolchain** by generating bindings:
```
with:
```
   by raise/throw, Rust enum-with-payload → WIT `variant`). Full recipe in
   `references/wit-boundary.md`.
3. **Version it and state the change policy.** Put the version in the package
   name (`org:pkg@x.y.z`) and ship a change policy from
   `assets/CONTRACT_POLICY.md`. Keep opaque bytes to state handles and raw
   wire input — never an untyped payload field (`references/wit-boundary.md`).
4. **Validate without a Rust toolchain** by generating bindings:
```

Then replace:
```
4. Scaffold the guest (the real kernel via `cargo component build`) and a host
```
with:
```
5. Scaffold the guest (the real kernel via `cargo component build`) and a host
```

- [ ] **Step 4: Add the Mode D rules**

Replace:
```
hexagonal implementation — is in `references/hexagonal-comparison.md`.
```
with:
```
hexagonal implementation — is in `references/hexagonal-comparison.md`.

Two more rules. **Do not oversell:** every charter ends with where the
pattern loses, and never claims a scaling, uptime or fault-tolerance benefit
— those belong to the shell. **Record the boundary:** for each kernel, offer
a decision record from `assets/KERNEL_ADR.md` that names the wider and
narrower boundaries rejected. For readers who know DDD or *The Hard Parts*,
`references/charter.md` has the extra ancestors, the companion book, and the
reuse-options table.
```

- [ ] **Step 5: Run the checks**

Run: `grep -c -E "references/glossary.md|assets/CONTRACT_POLICY.md|assets/KERNEL_ADR.md" skills/domain-kernel/SKILL.md`
Expected: `3`

Run: `python3 "$CHECK"`
Expected: `PASS`

Run: `wc -l skills/domain-kernel/SKILL.md`
Expected: under 200 (about 196).

---

### Task 9: Final verification (the spec's five checks)

**Files:** none changed.

- [ ] **Step 1: Terminology rule and links (spec checks 1 and 2)**

Run: `python3 "$CHECK"`
Expected: `PASS`, exit 0.

- [ ] **Step 2: Purity script unchanged and green (spec check 3)**

Run: `git diff --stat -- skills/domain-kernel/scripts skills/domain-kernel/assets/clippy.toml skills/domain-kernel/assets/deny-bans.toml skills/domain-kernel/assets/kernel-purity.yml`
Expected: no output.

Run: `python3 skills/domain-kernel/scripts/test_check_purity.py`
Expected: `Ran 14 tests … OK`

- [ ] **Step 3: No new modes (spec check 4)**

Run: `grep -n -E "^## Mode [A-Z]" skills/domain-kernel/SKILL.md`
Expected: exactly four lines — Mode A, B, C, D.

- [ ] **Step 4: README needs no change (spec check 5)**

Run: `git diff --stat -- README.md`
Expected: no output. The existing `domain-kernel` entry in `README.md` is still accurate, since the skill's description and name did not change.

- [ ] **Step 5: Read-through for plainness**

Read `skills/domain-kernel/references/glossary.md` and every section and template added in Tasks 2 and 4–8 once, top to bottom. Fix any sentence that uses a borrowed term without its plain words, or that runs past about 25 words. Re-run `python3 "$CHECK"` after any fix.

- [ ] **Step 6: Final commit point — stop and ask the user**

Do not run git. Print this for the user:

```bash
git add skills/domain-kernel/assets/DOMAIN_KERNEL_CHARTER.md skills/domain-kernel/SKILL.md && git commit -m "domain-kernel: plain-words charter template, Mode C versioning, Mode D limits"
```
