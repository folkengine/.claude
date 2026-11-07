# DECON-NN: Title

> **How it works.** This epic explains one slice of <project>'s <subsystem>,
> working from the code. The excerpts are quoted from commit
> [`<short-sha>`](<repo-url>/commit/<full-sha>), with `// …` marking cuts.
> Links point to the files in this repo, with line anchors. The golden
> vectors under `vectors/` are what that code produces. The Scope rules and
> the vectors are the contract; the excerpts show one way to keep it.

## In plain words
<!-- 6–15 short bullets. One idea per bullet. Bold each new word the first
time and say what it means. A reader who stops here knows what the slice
does and why. Link the sibling epics this slice hands off to. -->

## Context
<!-- What this slice is, and a bulleted "This epic does **not** cover:" list
with links to the epics that do. -->

## Status
| Component | Status |
|---|---|
| <component> | Planned |

## Goals
<!-- Bulleted intent; load-bearing nouns bold. -->

## Scope
<!-- Numbered rules, each with a bold name: "1. **The directive.** …".
Domain words only; a source identifier only if users see it (see
specific-profile.md). This is what a rebuild must match. -->

## Domain map
| Concept | Required behavior | Vectors |
|---|---|---|
| <concept> | <behavior> | [`vectors/<slug>/<file>.json`](vectors/<slug>/<file>.json) (`<field>`) |

<!-- Optional: "Notes on the vector fields:" bullets. -->

## Design
<!-- A small ASCII sketch of the flow, then **Why …** paragraphs: the domain
reason for each rule that is not obvious. No mechanism here. -->

## How <project> does it
<!-- One sentence on where this slice lives in the code (which crate /
package / module, pure or effectful). Then numbered stops in data-flow
order:

**1. <What happens here>**
([`path/to/file.ext`](../../path/to/file.ext#L10-L24)). One to three
sentences tying this code to Scope rule N:

```<lang>
// the lines that make the rule true
// …
```

Close with anything surprising: a quirk the vectors record, a place the
code and the design doc disagree (→ SD flag). -->

## Perspectives
| Perspective | May | Must not | Boundary invariant |
|---|---|---|---|
| <taxonomy name> | <capabilities> | <limits> | <invariant> |
<!-- Taxonomy names only; "N/A for this slice" rows allowed. -->

## Work Items
### Phase 0: <name>
- [ ] **0a.** <task; names the vector file or case that proves it, linked>

## Test Plan
<!-- **Given** … **when** … **then** …, each naming its vector file (linked)
and case id in backticks. -->

## Not specified (implementer's choice)
<!-- Named freedoms, in domain words. -->

## Spec decisions
> <a id="sd-NN"></a>**Spec decision SD-NN:** <question>. **Options:** <A> /
> <B>. **Chosen:** <one>. <why; which vector cases are informative>.

<!-- Or "None." -->

## Verification
Any implementation must reproduce every file under `vectors/<epic-slug>/`,
within [SD-NN](#sd-NN):

1. [`<file>.json`](vectors/<epic-slug>/<file>.json): <what must match>.

## Dependencies
**Builds on:** [DECON-NN](DECON-NN_Name.md). **Blocks:** [DECON-NN](DECON-NN_Name.md).

## Code references

At [`<short-sha>`](<repo-url>/commit/<full-sha>):

- <symbol or concern>: [`path/to/file.ext`](../../path/to/file.ext#L10-L24).
  <second symbol>: [`file.ext`](../../path/to/file.ext#L30-L41).
- Tests: [`file.ext`](../../path/to/file.ext#L900-L1010).
- Design history: [`<design doc>`](../../<design doc>). <one line: how the
  built code differs from the design, if it does>.
