# `/schenk` Skill — Design Spec

**Date:** 2026-07-20
**Status:** Approved design, pending implementation
**Repo:** `folkengine/.claude` (personal Claude Code configuration)

## Purpose

A Claude Code skill that performs Schenkerian analysis of a musical piece or
section and renders the result as a Schenker graph using LilyPond, producing
`.ly` source plus `.svg` and `.pdf` outputs, with a companion prose analysis
document. An optional rhythmic step adds Lerdahl & Jackendoff (GTTM) metrical
and grouping analysis beneath the foreground staff.

## Skill Structure

```
skills/schenk/
├── SKILL.md                  # frontmatter + workflow instructions
└── references/
    ├── schenker.ily          # reusable LilyPond stylesheet (notation vocabulary)
    ├── gttm.ily              # optional GTTM stylesheet (metrical dot-grid, grouping brackets)
    ├── notation-guide.md     # Schenkerian + GTTM symbol conventions and how the .ily files encode them
    ├── example.ly            # small worked example (8-bar Ursatz graph); doubles as render test
    └── example-gttm.ly       # example with the GTTM rhythmic layer enabled; render test for gttm.ily
```

### Frontmatter

- `name: schenk`
- `description` triggers on: `/schenk`, "Schenkerian analysis", "Schenker
  graph", "Schenker diagram", "Ursatz", "Urlinie", "voice-leading reduction" —
  even when the user never types "schenk".

### `schenker.ily` — the notation vocabulary (Approach A)

A single reusable include file defining the Schenker idiom once, so per-piece
`.ly` files stay small and consistent:

- Stemless **open (white) noteheads** for structural tones; **filled black
  noteheads** for foreground/diminution tones.
- Long **dashed slurs** for prolongational spans; solid slurs for local motion.
- **Cross-span beams** connecting the Urlinie tones (and Bassbrechung).
- **Caret scale-degree markup** above the Urlinie (^3 ^2 ^1 style).
- **Roman numeral markup** below the bass staff.
- No time signature, no bar lines (or dotted barlines only), proportional
  spacing suited to analytical graphs.

Fixing a notation bug in `schenker.ily` fixes every future diagram.

### `gttm.ily` — optional rhythmic vocabulary (Lerdahl & Jackendoff)

A second, independent include file for the optional GTTM step, kept separate
so it is only copied into output folders that use it:

- **Metrical dot-grid**: rows of aligned dots beneath the foreground staff,
  one row per metrical level, dot presence showing beat strength (GTTM's
  metrical structure notation). Implemented with `Lyrics` contexts / markup
  columns aligned to note columns.
- **Grouping brackets**: nested horizontal brackets under the grid showing
  motive → phrase → section grouping, via LilyPond's built-in
  `Horizontal_bracket_engraver`.

Deliberately excluded: GTTM time-span and prolongational **trees** — LilyPond
has no native tree drawing and markup/PostScript trees are fragile. The
substance of time-span reduction is covered by the staged reduction staves of
the Schenker graph; the companion doc carries the rule-based reasoning.

## Workflow (what SKILL.md prescribes)

1. **Preflight** — run `lilypond --version`. If missing: detect platform and
   offer to install (`brew install lilypond` on macOS; distro package manager
   otherwise). If the user declines, still write the `.ly` file, skip
   rendering, and print install instructions.
2. **Gather input** — accept any of:
   - a piece name/reference (e.g. "Bach BWV 846 Prelude, mm. 1–8"),
   - a score file path in the repo (LilyPond, MusicXML, ABC, or MIDI),
   - pasted notation in chat.

   **Reference-score rule:** when working from a piece name, if Claude is not
   confident of the actual notes (obscure piece, precise measure range,
   edition differences), it must ask the user for a reference score rather
   than guess. A Schenker graph built on wrong notes is worthless.
3. **Ask depth per run** — one question with default "all three levels":
   - background (Ursatz) only,
   - middleground + background,
   - foreground + middleground + background (default).

   Also confirm the Urlinie reading when ambiguous (3̂-line vs 5̂-line vs
   8̂-line), and offer the **optional GTTM rhythmic step** (off by default;
   also triggered when the user mentions GTTM, Lerdahl & Jackendoff, metrical
   structure, or grouping structure).
4. **Analyze** — identify key, Ursatz form, structural bass (Bassbrechung),
   prolongations, and linear progressions; record every interpretive judgment
   call for the companion document. When the GTTM step is enabled, also derive
   the metrical grid and grouping hierarchy, noting which GTTM well-formedness
   and preference rules (GWFRs/GPRs, MWFRs/MPRs) drove non-obvious choices.
5. **Render** — write `docs/schenker/<slug>/<slug>.ly` (in the user's current
   project) importing `schenker.ily` (copied alongside, so the output folder
   is self-contained); run LilyPond to produce both SVG and PDF (separate
   invocations if the installed version can't emit both in one run); verify
   both files exist; **view the rendered SVG** to visually check the graph
   before declaring success.
6. **Companion doc** — `docs/schenker/<slug>/<slug>.md`: the reading explained
   (Urlinie choice, key structural events, prolongations, judgment calls),
   with the SVG embedded. When the GTTM step ran, add a section discussing the
   grouping and metrical analysis and the GPR/MPR reasoning behind it.

## Error Handling

- LilyPond compile errors: read the log, fix the `.ly`, retry — bounded at
  roughly 3 attempts. If still failing, deliver the `.ly` plus an explanation
  of the error. Never silently present a diagram that did not render.
- Unreadable/unsupported input score: say so and ask for an alternative form
  (paste, different format).

## Outputs

For a piece slugged `<slug>`, in the current project's `docs/schenker/<slug>/`:

| File | Content |
|---|---|
| `<slug>.ly` | LilyPond source for the Schenker graph |
| `schenker.ily` | copy of the stylesheet (self-contained folder) |
| `gttm.ily` | copy of the GTTM stylesheet (only when the rhythmic step ran) |
| `<slug>.svg` | rendered graph |
| `<slug>.pdf` | rendered graph |
| `<slug>.md` | prose analysis with embedded SVG |

## Testing

- `references/example.ly` must compile standalone against `schenker.ily`.
- `references/example-gttm.ly` must compile against `schenker.ily` + `gttm.ily`.
- Implementation of this skill includes actually rendering both examples with
  the locally installed LilyPond (2.26.0) to prove the stylesheets work before
  the skill ships.

## Repo Integration

- Add `schenk` to `README.md` under `## Skills` (link text = skill `name`,
  description from frontmatter), per project CLAUDE.md rules.

## Out of Scope

- Audio input / transcription from recordings.
- Automated (algorithmic) reduction — the analysis is Claude's musical
  judgment, documented, not a deterministic algorithm.
- External converters (musicxml2ly, Verovio) in the render pipeline.
- GTTM time-span / prolongational **tree diagrams** (fragile in LilyPond; the
  reduction staves and companion-doc discussion carry that content instead).
