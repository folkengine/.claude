# Beethoven, Symphony No. 5, I — rhythm only (mm. 1–5)

![Rhythm of mm. 1–5](beethoven5-rhythm.svg)

## Passage

Opening of the first movement, Allegro con brio, 2/4. Pitches are left out
on purpose. Only durations, rests, ties and fermatas remain, on a one-line
(drum-part style) staff.

## The rhythm

| Bar | Rhythm |
|---|---|
| 1 | eighth rest, three eighths (beamed) |
| 2 | half note, fermata |
| 3 | eighth rest, three eighths (beamed) |
| 4 | half note, tied to m. 5 |
| 5 | half note, fermata (the tied note, held) |

Bars 3–5 repeat bars 1–2, but the second held note lasts two bars (tie from
m. 4 into m. 5, fermata in m. 5).

For reference, the dropped pitches are G–G–G–E♭ (mm. 1–2) and
F–F–F–D (mm. 3–5). The tied D matches the foreground in
`../beethoven5-motto/foreground.ly`.

## Files

| File | Content |
|---|---|
| `beethoven5-rhythm.ly` | assembly: `rhythm.ily` + `rhythm.ly` + one `\score` |
| `rhythm.ly` | `rhythmMusic` building block |
| `rhythm.ily` | rhythm stylesheet |
| `render.sh` | render helper (`bash render.sh .`) |
| `beethoven5-rhythm.svg/.pdf` | rendered rhythm staff |
| `rhythm.svg/.pdf` | the same staff, from the building block |
