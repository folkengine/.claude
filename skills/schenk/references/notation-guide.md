# Schenker & GTTM notation guide

How the two stylesheets encode analytical notation, plus the LilyPond 2.26
gotchas they work around. Read this before writing a graph `.ly` file.

## Schenkerian symbols (`schenker.ily`)

| Symbol | Meaning | How to write it |
|---|---|---|
| Open notehead | Structural tone (background/deep middleground) | `\bgStyle` voice; notes written as **8ths** (`es8`) print as half-note heads |
| Filled stemless notehead | Middleground tone | `\mgStyle` voice; durations are spacing only |
| Long flat beam | Urlinie / Bassbrechung connection | Manual beam `[ ... ]` across the structural tones with `\beamFillOn/Off` fillers between them |
| Caret scale degree | Urlinie degree | `es8^\markup \hat "3"` |
| Roman numeral | Harmonic step | `c8_\markup \rn "I"` |
| Slur | Prolongation / unfolding | ordinary `(` `)` in `\mgStyle` |
| Parenthesized head | Implied (unsounded) tone | `\parenthesize c8` |
| Normal notation | Foreground | `\fgStyle` voice |

**Levels as staves.** A graph is one `\score` with aligned staves, top to
bottom: Fg., Mg., Bg. (treble), Bg. bass. All voices share the same hidden
meter (`\time` + spacer rests `s`) so events align vertically; barlines and
time signatures are suppressed by `\schenkerLayout`.

**Why structural tones are 8th notes.** Only beamable durations can carry the
Urlinie beam; `NoteHead.duration-log = #1` makes them *print* as open half
heads. Half notes themselves cannot be beamed.

## GTTM symbols (`gttm.ily`)

| Symbol | Meaning | How to write it |
|---|---|---|
| Dot rows | Metrical grid, one row per level, smallest first | `\new Lyrics \with { \gttmDotRow } \lyricmode { \repeat unfold N { "•"8 } }` placed right after the Fg staff |
| Nested brackets | Grouping structure | `\gttmBrackets` in the Fg voice; `\startGroup`/`\stopGroup` on notes (stack two for simultaneous nesting); add `\context { \Voice \gttmVoiceMods }` to the layout |

Time-span / prolongational **trees are not rendered** — discuss their head
choices in the companion prose instead.

## LilyPond 2.26 gotchas (learned the hard way — do not rediscover)

1. **`Stem.transparent = ##t` hides the Beam too.** Use
   `Stem.thickness = #0` + `\stemUp` (already in `\bgStyle`).
2. **Beams cannot span omitted rests, and `\hideNotes` kills the beam.**
   Bridge long beams with invisible filler notes: `\beamFillOn ... \beamFillOff`
   between the first and last visible beamed tones. Fillers repeat the
   previous pitch; one filler per intervening 8th position.
3. **`Beam.positions` must agree with stem direction** or the beam is
   silently dropped ("stem does not fit in beam" warnings). `\bgStyle` forces
   `\stemUp` with positions `(5 . 5)`.
4. **`proportionalNotationDuration` takes a plain rational** (`#1/8`), not
   `\musicLength`, in this version.
5. **Output-def variables don't compose.** Only the first thing in a
   `\layout { ... }` may be another layout (`\schenkerLayout`); further
   additions must be `\context { ... }` blocks / context mods
   (`\gttmVoiceMods`), never a second layout variable.
6. **SVG and PDF need separate runs**: `lilypond -dbackend=svg -o out file.ly`
   then `lilypond -o out file.ly`.

## Debugging a graph that renders wrong

When an element silently vanishes, bisect: write a scratch file with one
staff per candidate override, changing exactly one variable per staff, and
render once. This finds the offending override in a single compile.

## Smoke tests

- `example.ly` — Ursatz in C major (3̂–2̂–1̂ over I–V–I); tests `schenker.ily`.
- `example-gttm.ly` — adds dot grid + grouping brackets; tests `gttm.ily`.

Both must compile warning-free. If a stylesheet edit breaks them, fix the
stylesheet before using it in a real analysis.
