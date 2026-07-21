# Beethoven, Symphony No. 5 in C minor, op. 67 — whole-symphony Urlinie

A **very simplified**, deep-background reading of the entire four-movement
symphony as a single Ursatz: one structural event per movement, a 3̂-line
descent, and the work's defining C‑minor→C‑major transformation shown in the
bass.

![Whole-symphony Urlinie graph](beethoven5-symphony.svg)

## Source

The whole symphony, one structural slot per movement:

| Slot | Movement | Key | Structural role |
|---|---|---|---|
| 1 | I. Allegro con brio | C minor | Kopfton **3̂ = E♭** established (the motto); tonic **i** |
| 2 | II. Andante con moto | A♭ major (♭VI) | prolongation of 3̂ / the tonic area |
| 3 | III. Scherzo. Allegro | C minor → dominant | drive to and prolongation of **V**; **2̂ = D** |
| 4 | IV. Allegro | **C major** | arrival on **1̂ = C** over **I** — the whole-work Picardy |

This is an interpretive whole-work background, not a transcription — the notes
on the page are the *structure*, one gesture standing for each movement, not
the movements' actual surfaces.

## The reading, level by level

### Background (Ursatz)

- **Urlinie: 3̂ – 2̂ – 1̂ = E♭ – D – C.** The head-tone E♭ is the pitch the
  opening motto hammers and the note the whole C‑minor world orbits. It is held
  (prolonged) across movements i and ii, steps to D (2̂) as the music turns to
  the dominant in/after the Scherzo, and resolves to C (1̂) in the finale.
- **Bassbrechung: i – V – I.** Tonic (movement i) → structural dominant (the
  Scherzo and its dominant-pedal bridge into the finale) → tonic (finale). The
  numeral shifts from lowercase **i** to uppercase **I**: the tonic that begins
  the symphony in C minor ends it in C major. That single case change is the
  graphic shorthand for the work's entire darkness-to-light narrative.

### Middleground (movement key-plan)

The "Mvt." staff exposes what the bare i–V–I hides: the tonic of the first half
is prolonged by its **submediant, A♭ major (♭VI)**, in the Andante — E♭, the
head-tone, is the fifth of A♭, so the Kopfton survives the excursion. Movements
i and iii sit in C minor; the finale flips to C major. The deep dominant that
links Scherzo to Finale is carried in the background bass, not here.

### Foreground

None — omitted by design. "Very simplified" means the graph stops at the
movement level; the motto, the Andante's variations, the Scherzo's return, and
the finale's fanfares are all compressed into their single structural tones.

## Judgment calls (and the roads not taken)

1. **A whole-work Ursatz at all.** Treating four movements as one Ursatz is a
   strong interpretive stance; Schenker analysed single movements and was wary
   of spanning them. *Rejected alternative:* four independent Ursätze, one per
   movement. Chosen because the request was explicitly for one simplified
   whole-symphony line, and Beethoven 5's motivic and tonal monomania (the
   motto everywhere, the literal Scherzo-into-Finale bridge) makes the
   monotonal reading unusually defensible.
2. **3̂-line over 5̂-line.** *Rejected:* G–F–E♭–D–C. The motto fixes E♭→D in the
   ear from bar 1; a 3̂-line is both better supported and simpler, which is what
   "very simplified" asks for.
3. **Kopfton E♭ (minor 3̂) resolving into a major tonic.** The Urlinie stays
   E♭–D–C; the mode change lives in the harmony (i→I), i.e. a Picardy third at
   the scale of the whole work. *Rejected:* re-spelling 3̂ as E♮ or drawing a
   mode-mixture at the head-tone — needless complication for a background sketch.
4. **Movement II (A♭) as a prolongation, not a structural bass step.** ♭VI here
   decorates the tonic Stufe; it is not an independent member of the
   Bassbrechung. *Rejected:* reading A♭ as a structural III/♭VI arrival, which
   would fracture the clean i–V–I.
5. **Movement III = the structural dominant.** The Scherzo's goal, and the famous
   sustained-dominant bridge, carry 2̂/V. *Rejected:* deferring V to the finale's
   own internal dominant, which buries the symphony's single most dramatic
   structural event (the bridge) inside movement iv.

## Files

| File | Content |
|---|---|
| `beethoven5-symphony.ly` | assembly: stylesheet + level `\include`s + one `\score` |
| `middleground.ly` | movement key-plan staff (`mgMusic`) |
| `background-urlinie.ly` | Urlinie 3̂–2̂–1̂ (`bgUpper`) |
| `background-bass.ly` | Bassbrechung i–V–I (`bgBass`) |
| `schenker.ily` | copied stylesheet |
| `render.sh` | render helper (graph + per-level SVG/PDF) |
| `beethoven5-symphony.svg` / `.pdf` | rendered graph |
| `middleground.svg/.pdf`, `background-urlinie.svg/.pdf`, `background-bass.svg/.pdf` | per-level images |
| `beethoven5-symphony.md` | this document |
