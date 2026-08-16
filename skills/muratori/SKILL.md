---
name: muratori
description: Evaluate a library's public API against Casey Muratori's 2004 "Designing and Evaluating Reusable Components" criteria — the five characteristics (granularity, redundancy, coupling, retention, flow control) scored against fixed anchors, the practical checklist, and a domain-kernel cross-read — written as a standardized, re-runnable audit in the repo's docs folder (MURATORI_AUDIT.md). Use when the user types `/muratori` or `/muratori <target>`, or asks "how reusable is this API", "evaluate this library's API design", "is this API well designed", "will this be painful to integrate", "find the integration discontinuities", "Muratori review", "retained vs immediate mode check", or "does this library invert control" — even if they never say Muratori. Do NOT trigger for kernel-purity assessment alone (that is /domain-kernel Mode A) or dependency entanglement (that is /untangle).
---

# /muratori

Evaluate how a library's public API will behave under real integration
pressure, using the criteria Casey Muratori distilled from Granny 3D
(stable across 2,600+ SKUs for ~12 years). The question the audit answers:
**where will an integrator hit a discontinuity** — a gap where the only way
forward is a rewrite or workaround instead of an incremental step?

Three guiding principles:

- **Anchored scores, not prose labels.** The five characteristics are scored
  1–5 against the fixed anchors in `references/characteristics.md` (5 =
  best). The anchors are the scale; quote the matched anchor next to each
  score. Never invent a scale inline, never average scores into an overall
  number — the headline is the prose discontinuity verdict.
- **Usage sketches are the evidence.** Muratori's first rule — write usage
  code before designing the API — is also the audit method. Most of these
  characteristics (retention, flow control, coupling) only surface at call
  sites, not in greps. Sketches go in the report's evidence appendix.
- **This measures API design, not purity or dependency cost.** Kernel purity
  is `/domain-kernel`; dependency entanglement is `/untangle`. The report's
  Kernel lens section bridges to the former when findings are kernel-shaped.

The distilled source lecture is vendored at
`references/REUSABLE_COMPONENTS_2004.md` — read it before the first audit
in a session.

## Modes

| Invocation | Does |
|---|---|
| `/muratori` | Audit the current repo's primary library → `<docs>/MURATORI_AUDIT.md` |
| `/muratori <path-or-member>` | Audit a specific crate/package (workspace member or path); one audit file per audited library, next to its docs |

Detect the repo's docs folder the way the other house skills do (`docs/` or
wherever existing design docs live). The audit **refreshes
`MURATORI_AUDIT.md` in place** — regenerate each run with a fresh header,
preserve any `## Notes (human)` section verbatim, and when a previous audit
exists, add a one-line `Δ` note to any characteristic whose score changed.

## Method

### 1. Classify the reuse kind first

Layer, engine, or component — the three fail differently, and the five
characteristics are calibrated for components:

- **Layer** — thin abstraction over an underlying service. Evaluate
  thinness and whether two layers would compete for the resource beneath.
- **Engine** — the reused code owns control flow by design; the caller is a
  plugin. Flow control and retention are its *contract*, not defects —
  score them n/a-by-design in prose rather than 1/5.
- **Component** — data flows both ways and the caller's program stays in
  charge. Full five-characteristic scoring applies.

Scoring an engine 1/5 on flow control is a category error, not a finding.
The classification and its one-sentence justification are REQUIRED in the
report header.

### 2. Gather evidence

- Map the public API surface: exported types, constructors, every `pub`
  entry point (lib.rs / `__init__.py` / `index.ts` equivalents).
- **Write 3–5 usage sketches** against the API as it exists (scratchpad or
  in-report; they need not compile, they must be honest): the **first
  integration** happy path, a **requirement shift** (new data source, one
  step needed without its siblings, different lifecycle), and a
  **ship-week workaround** (the blessed path fails late — what does escape
  cost?). Each sketch ends with a verdict: incremental step or
  discontinuity?
- Collect mechanical signals with `rg`: callback-typed parameters
  (`Box<dyn Fn`, handler traits), third-party types on public items,
  path-taking functions, init gates / `NotInitialized`-style errors,
  step-enumerating names (`load_and_play`), whole-struct sync setters,
  `[features]` vs format crates in `[dependencies]`.
- Read-only git for the header commit hash. Never run state-changing git.

### 3. Score the five characteristics

Read `references/characteristics.md` and score each characteristic against
its anchor table. Integer scores; between two anchors, take the lower and
say why. Every score cites file:line evidence plus at least one sketch.
Redundancy measures **coherence, not quantity** — a spartan single-path API
over a fine core is a 3, conflicting duplicate paths are the real failure.

### 4. Run the practical checklist

The 9 items from the lecture, each graded pass / partial / fail / n-a with
evidence. The template has the canonical wording. Items 2 (immediate-mode
equivalents) and 3 (non-callback alternatives) are the two Muratori calls
out as unconditional.

### 5. Emit the report

Fill `references/report-template.md` — every REQUIRED slot. Structure:
header (with reuse kind), summary table, discontinuity verdict, five
characteristic dossiers (anchor quote + evidence + minimal fix), checklist
table, **Kernel lens**, leverage-ordered recommendations, evidence appendix
(sketches + mechanical signals), preserved `## Notes (human)`.

**Kernel lens:** map findings onto the domain-kernel invariants — coupling →
purity, retention → the pure transition function, flow control →
delivery-agnosticism, granularity → boundary shape; redundancy stays
unmapped (the one characteristic where structural enforcement runs out).
When low coupling/retention/flow-control scores trace to I/O, hidden state,
or callback inversion, recommend running `/domain-kernel` (Mode A first).
When findings aren't kernel-shaped, one line saying so — don't force the
mapping. Large reworks (multi-session, API-breaking) → recommend `/epic`
for a phased design doc.

## Other ecosystems

The method is language-agnostic; only the mechanical-signal tactics are
Rust-first. Swap the grep targets: Python → `Callable` parameters, ABC
registration, module-level singletons; TypeScript → constructor DI of
handler interfaces, `EventEmitter`-only notification, class-typed options
objects. Sketches and anchors carry unchanged. Thinner tooling → say so in
the report rather than skipping fields.

## Common mistakes

| Mistake | Fix |
|---|---|
| Inventing a report filename per run | Always `MURATORI_AUDIT.md`, refreshed in place — diffability is the point |
| Defining the 1–5 scale inline | The anchors file is the scale; quote the matched anchor per score |
| Scoring zero redundancy as 1/5 | Redundancy measures coherence; spartan-but-coherent is a 3 |
| Averaging into an "overall n/5" | No arithmetic headline; write the discontinuity verdict in prose |
| Evidence = code citations only | Usage sketches are REQUIRED; retention and flow control hide from greps |
| Scoring an engine 1/5 on flow control | Classify layer/engine/component first; engines score it n/a-by-design |
| Forcing the kernel mapping | If findings aren't kernel-shaped, one line saying so suffices |
| Regenerating the audit and losing human edits | `## Notes (human)` is preserved verbatim, always |
| Auditing internals instead of the public API | The subject is what integrators touch; private helpers only matter as evidence |
