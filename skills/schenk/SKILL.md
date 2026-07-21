---
name: schenk
description: Perform a Schenkerian analysis of a musical piece or section and render it as a Schenker graph with LilyPond, producing .ly, .svg, and .pdf outputs plus a companion prose analysis — optionally layered with a GTTM (Lerdahl & Jackendoff) metrical dot-grid and grouping brackets. Use when the user types `/schenk <piece>` or asks for a "Schenkerian analysis", "Schenker graph/diagram", "Ursatz", "Urlinie", "voice-leading reduction", "structural analysis of this piece", or a "GTTM / metrical / grouping analysis" — even if they never say the word "schenk". Accepts a piece name, a score file (LilyPond, MusicXML, ABC, MIDI), or pasted notation. Asks for a reference score when the notes aren't known with confidence. Requires LilyPond (offers to install it if missing).
---

# Schenk — Schenkerian analysis graphs via LilyPond

Produce a Schenkerian voice-leading graph of a piece or passage: analyze the
tonal structure, engrave the graph with LilyPond using the stylesheets in
`references/`, and explain the reading in a companion markdown document.

## Usage

`/schenk <piece or file or nothing>` — `<piece>` may be a work + measure
range ("Bach BWV 846 Prelude, mm. 1–8"), a path to a score file, or empty
(then ask what to analyze).

## Workflow

### 1. Preflight

Run `lilypond --version`.

- **Missing:** detect the platform and offer to install (`brew install
  lilypond` on macOS; the distro package manager on Linux). If the user
  declines, continue the analysis, write the `.ly` files, skip rendering, and
  print install instructions.

### 2. Gather the music

Accepted inputs: a piece name/reference, a score file in the project
(LilyPond, MusicXML, ABC, MIDI), or notation pasted in chat.

**Reference-score rule (hard rule):** when working from a piece name, only
proceed if confident of the actual notes in the requested passage. For an
obscure piece, an unusual edition, or an uncertain measure range, ask the
user for a reference score instead of guessing — a Schenker graph built on
wrong notes is worthless. State the notes being analyzed (or show the
foreground line) so the user can catch transcription errors.

### 3. Per-run questions

Ask once, together (AskUserQuestion):

- **Depth** — background only / middleground + background / all three levels
  (default: all three).
- **Urlinie**, only if genuinely ambiguous — 3̂- vs 5̂- vs 8̂-line, with a
  recommendation.
- **GTTM rhythmic layer** — off by default; offer it, and enable
  automatically when the user mentions GTTM, Lerdahl & Jackendoff, metrical
  structure, or grouping structure.

### 4. Analyze

Establish: key and any tonicizations; Ursatz form (Urlinie degree, interruption
if any); structural bass (Bassbrechung); prolongations, linear progressions,
unfoldings, neighbor and passing motions; cover tones. Record every
interpretive judgment call — they go in the companion doc, not just the chat.

With the GTTM layer: derive the metrical grid (which levels, where the strong
beats fall) and the grouping hierarchy, noting which preference rules
(GPRs/MPRs) decided anything non-obvious.

### 5. Render

Output dir: `docs/schenker/<slug>/` in the current project (create it).

1. Copy into the output dir so it is self-contained: `references/schenker.ily`,
   `references/gttm.ily` (if the GTTM layer is on), and `references/render.sh`.
2. Read `references/notation-guide.md` **before writing any `.ly`** — it
   documents the notation vocabulary, the per-level building-block files, and
   the known LilyPond gotchas.
3. Write the graph as **per-level building-block files** — one music-only file
   per level: no `\header`/`\version`/`\include`/comments, just the variable
   with its style, clef/key/time, and the markup that prints on the staff.
   Keep the canonical names and variables (`render.sh` keys off them):
   - `foreground.ly` → `fgMusic` (real notation; put any GTTM
     `\startGroup`/`\stopGroup` grouping marks here — inert without the
     bracket engraver, so the same file serves the plain and GTTM graphs)
   - `middleground.ly` → `mgMusic`
   - `background-urlinie.ly` → `bgUpper`
   - `background-bass.ly` → `bgBass`
   - `gttm-layer.ly` → `dotsEighth` / `dotsQuarter` / `dotsMeasure` (GTTM only)

   Then write the thin assembly file `<slug>.ly` (and `<slug>-gttm.ly` when the
   GTTM layer is on): `\version` + stylesheet `\include`s + `\include` of the
   level files + one `\score` of aligned staves Fg./Mg./Bg./bass sharing a
   hidden meter. Model on `references/example.ly` / `example-gttm.ly`.
4. Render with the helper: `bash render.sh <output-dir>` (or `bash render.sh`
   from inside it). It compiles SVG **and** PDF for every assembled graph and
   for every per-level building block, so each level also gets a standalone
   image for embedding. Each SVG is cropped to the music's bounding box
   (`-dcrop`, minimal padding) and the "LilyPond vX.Y.Z" tagline is suppressed
   (`\paper { tagline = ##f }` in `schenker.ily`), so the images embed cleanly.
5. On compile errors: read the log, fix, retry — at most ~3 attempts, then
   deliver the `.ly` with an explanation. For elements that vanish silently,
   use the one-variable-per-staff bisection test from the notation guide.
6. **View the rendered SVGs** (rasterize and look) — the assembled graph and
   the per-level images — and check: beams present, carets on the right notes,
   slurs sensible, levels aligned, nothing colliding. Never declare success on
   exit code alone.

### 6. Companion document

`docs/schenker/<slug>/<slug>.md`: the source passage identified; the reading
level by level (Ursatz, middleground events, foreground); every judgment
call with the rejected alternative; the GTTM section (grid, grouping,
GPR/MPR reasoning) when enabled; embedded SVG image(s); a file table.

## Outputs

| File | Content |
|---|---|
| `<slug>.ly` | assembly file: stylesheet + level `\include`s + one `\score` |
| `foreground.ly` … `gttm-layer.ly` | per-level music-only building blocks |
| `schenker.ily` (+ `gttm.ily` if used) | copied stylesheets |
| `render.sh` | copied render helper (assembled graph + per-level SVG/PDF) |
| `<slug>.svg`, `<slug>.pdf` | rendered assembled graph |
| `foreground.svg/.pdf` … `gttm-layer.svg/.pdf` | rendered per-level images |
| `<slug>.md` | prose analysis with embedded SVG |

With the GTTM layer, either add it to the main graph or produce a second
`<slug>-gttm.ly` variant — ask if the user has a preference.

## Maintaining the stylesheets

The master stylesheets live in `references/`. If a notation bug is fixed
during a run, back-port the fix to the masters and re-run the smoke tests
(`example.ly`, `example-gttm.ly` must compile warning-free).
