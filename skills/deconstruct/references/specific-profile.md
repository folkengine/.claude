# Deconstruct methodology — the SPECIFIC profile

Read `methodology.md` first. Everything there applies (litmus test, spec
decision format, perspectives, vector conventions, dumper guidance,
numbering, update mode) **except the rows this file overrides**.

NEUTRAL hands a rebuilder a contract and hides the original. SPECIFIC hands a
reader the same contract **and** shows, step by step, how the original code
keeps it. The reference pack for this profile is bower's REPL control
(`ImperialBower/bower` → `docs/deconstruct/repl/`). When in doubt, match it.

## What stays the same

- The rules in `## Scope` are still the contract. Write them in domain words.
  Name a source identifier in a rule only when it is part of the domain
  vocabulary the user sees (a directive key, a CLI flag, a file name a user
  writes) — never a private type or function.
- Golden vectors are still extracted by a dumper, never written by hand.
- Code excerpts and links **explain**. They do not bind a rebuild. Say so
  once in each epic's opening blockquote.
- Essential vs accident still decides what goes in Scope. Accidents now
  appear in the walkthrough, labelled as how the original happens to do it.

## Deltas vs NEUTRAL

| NEUTRAL | SPECIFIC |
|---|---|
| Pack is portable; nothing depends on the source repo | Pack lives **inside** the source repo and links into it. Excerpts are quoted inline, so it still reads well when copied out; only the links stop working |
| Pack at `<docs-dir>/deconstruct/` | Whole-repo run: `<docs-dir>/deconstruct/`. Scoped run: `<docs-dir>/deconstruct/<subsystem-slug>/`, a self-standing pack with its own MANIFEST and vectors |
| Epic opens with a "Regeneration spec" blockquote | Epic opens with a **How it works** blockquote: the pinned commit (linked), what `// …` cuts mean, that links carry line anchors, that vectors come from that code |
| No plain-language layer | `## In plain words` right after the blockquote, in every epic, in the vectors README and in the appendix: short bullets, one idea each, no jargon left undefined |
| — | Pack-level `README.md`: the plain-words front door (template: `readme-template-specific.md`) |
| Design is language-neutral; rationale never names the mechanism | Design stays a sketch plus **Why** paragraphs. The mechanism moves to the next section |
| — | `## How <project> does it` after Design: a numbered walkthrough in the order data moves through the code. Each stop = a bold heading naming the step, a link to the file with a line-range anchor, one to three sentences, then a fenced excerpt in the source language |
| `## Provenance (non-normative)` with bare `path:line` | `## Code references` as the last section: "At [`<short-sha>`](<commit url>):" then bullets of `symbol: [path](rel/path#Lx-Ly)`, grouped by concern; tests and design history last |
| Spec decisions are code-vs-intent or pin-vs-relax | Same, plus the common SPECIFIC case: **code vs its own design doc**. The pack follows the code, names the doc, and says which vectors are informative because of it |
| Epic, vector and SD mentions are plain text | Every mention is a link: epics `[DECON-02](DECON-02_Name.md)`, vector files `[`file.json`](vectors/<slug>/file.json)`, spec decisions `[SD-03](#sd-03)` or `[SD-03](DECON-02_Name.md#sd-03)` |
| SD blockquote starts `**Spec decision SD-NN:**` | Same, with an anchor first: `> <a id="sd-NN"></a>**Spec decision SD-NN:** …` |
| Anti-constraint lint: no source names outside Provenance | Source names are fine in the walkthrough and Code references. The lint is narrower: Scope rules, Domain map and Not specified stay in domain words (see "What stays the same") |
| Manifest says "regeneration pack", carries a Contract line | Manifest says what the pack **explains**, links the source repo and commit, names its design doc, points new readers at `README.md`, and gives a reading order (template: `manifest-template-specific.md`) |

## Link conventions

- **Relative links** from the pack file to the source file, with GitHub line
  anchors: `[`src/plan.rs`](../../../src/plan.rs#L178-L231)`. Count `../`
  from the file the link sits in (a link in `vectors/README.md` needs one
  more level than a link in an epic).
- The first link to a file in a paragraph shows its repo path; later links
  in the same paragraph may show only the file name.
- Anchor a **range** (`#L10-L24`) for a function or block, a single line
  (`#L314`) for one call.
- **Pin once.** The full commit URL appears in each epic's opening
  blockquote, in Code references, and in the manifest's Source line. Use the
  short SHA as the link text.
- Relative links follow the branch, not the commit. Excerpts are copied from
  the pinned commit, so the excerpt is the truth if a line drifts. Update
  mode re-anchors every link (see below).
- Links into the book, docs or examples the subsystem serves are welcome:
  they ground the plain-words story in a real file.

## Excerpt conventions

- Copy from the pinned commit, never from memory. Keep the original
  comments; they often carry the *why*.
- Mark cuts with the language's line comment and an ellipsis (`// …`,
  `# …`). If you reflow a call onto fewer lines, say so in the blockquote.
- Keep each excerpt short: the lines that make the rule true, usually under
  25. Link the full range for the rest.
- Tie each excerpt back to a numbered Scope rule or a vector case
  ("that is where the extra refusal in [`binding.json`](…) comes from").

## Section order (epic)

Blockquote · In plain words · Context · Status · Goals · Scope · Domain map ·
Design · How <project> does it · Perspectives · Work Items · Test Plan ·
Not specified · Spec decisions · Verification · Dependencies · Code
references. Template: `decon-epic-template-specific.md`.

## Vectors README and appendix

- `vectors/README.md`: add an `In plain words` blockquote at the top. The
  dumper line becomes a table: dumper (linked into the source repo) → files
  it writes (linked) → command to run it. Say whether re-running was checked
  to reproduce every file byte for byte.
- `APPENDIX_Engineering_Constraints.md`: add `In plain words`; describe the
  original's shape (layers, toolchain, tests that exist and do not, costs),
  linking to the code it describes. Still non-normative.

## Update mode (SPECIFIC)

In addition to the shared update rules: re-copy every excerpt from the new
commit, re-anchor every line link, move the pinned SHA everywhere it appears,
and run the link check. An excerpt whose code changed meaning is drift: log
it.
