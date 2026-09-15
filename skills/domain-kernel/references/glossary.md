# Glossary — borrowed terms in plain words

Use this when reading or writing any domain-kernel doc. The skill borrows
words from two sources: Domain-Driven Design (DDD — Evans 2003; Vernon 2013
and 2016; and the functional-DDD line of Wlaschin and Chassaing) and
*Software Architecture: The Hard Parts* (Ford, Richards, Sadalage and
Dehghani, 2021).

**The rule.** Plain words lead. The borrowed term follows once, in
brackets, at first use in each file:
"one domain's rules (DDD: *bounded context*)". A term from one branch of
DDD may say so — "(functional DDD: *Decider*)". After that, keep the plain
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
