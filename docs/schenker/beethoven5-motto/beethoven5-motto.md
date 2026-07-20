# Beethoven, Symphony No. 5 in C minor, op. 67 — i, mm. 1–5

Schenkerian analysis of the opening motto, with an optional GTTM
(Lerdahl & Jackendoff) rhythmic layer.

![Schenker graph](beethoven5-motto.svg)

## The reading

**Source.** Unison strings and clarinets, C minor, 2/4, Allegro con brio:
♪ G–G–G | E♭ (fermata), ♪ F–F–F | D (held, fermata). The passage is
monophonic — every "harmony" below is implied, which is why the bass tones in
the graph are parenthesized.

**Background (Bg.).** The structural top voice is E♭ → D: scale degrees
**3̂–2̂** over an implied **I–V**. This is the opening limb of an interrupted
descent — 2̂ over V is left hanging (Beethoven withholds 1̂), which is the
tonal reason the motto sounds like an unanswered question. The Urlinie beam
connects 3̂–2̂; the Bassbrechung C–G appears in parentheses as implied.

**Middleground (Mg.).** Each gesture composes out a third by **unfolding**:
G→E♭ projects the upper third of the tonic triad down to the structural E♭;
F→D does the same within the dominant (F as seventh/upper third over G). The
slurs mark these unfoldings. G and F are cover tones standing a third above
the structural line, and their stepwise G→F descent foreshadows the larger
5̂–4̂–3̂… descent the movement will pursue.

**Foreground (Fg.).** The surface as notated: anacrustic eighth-note triple
upbeats hammering into each held goal tone, the second phrase a sequence of
the first, down a step.

**Judgment calls.**
- Kopfton: from these five bars alone, 3̂ (E♭) is the defensible reading; a
  5̂-line (G as Kopfton) only becomes arguable over the whole exposition,
  where G is regained and prolonged. For the motto in isolation, G is a cover
  tone, not the Kopfton.
- Harmony of m. 4–5: D is read as 2̂ over V (with F as implied seventh),
  not as part of a ii° sonority — the fermata halt on scale-degree 2 over an
  implied dominant is the interruption gesture.

## GTTM rhythmic layer

![Schenker graph with GTTM layer](beethoven5-motto-gttm.svg)

**Metrical structure** (dot grid, three levels: eighth, quarter, measure).
The notated grid puts the E♭ and D arrivals on strong beats and hears the
G–G–G / F–F–F eighths as anacrusis. Lerdahl & Jackendoff use exactly this
opening to show metrical inference at work: with no downbeat sounding in
m. 1 (the motto begins after an eighth rest) and fermatas suspending
periodicity, the listener cannot yet fix the grid — the famous ambiguity
that the movement exploits when the motto later returns harmonized.
(MPR 5's preference for long notes on strong beats is what pulls the
fermata tones onto the downbeats.)

**Grouping structure** (brackets). Two four-note groups, heard as parallel
(GPR 6, parallelism: identical rhythm, sequence a step apart), nested inside
one larger group closed by the long D. Group boundaries fall after the held
notes (GPR 2, proximity: the fermata's temporal gap forces the boundary).

**Time-span reduction** is not drawn (no tree notation here), but its head
choices coincide with the Schenker levels: E♭ heads the first group, D the
second, matching the 3̂–2̂ background.

## Files

| File | Content |
|---|---|
| `beethoven5-motto.ly` / `.svg` / `.pdf` | Schenker graph |
| `beethoven5-motto-gttm.ly` / `.svg` / `.pdf` | Schenker graph + GTTM layer |
| `schenker.ily` | Schenker notation stylesheet |
| `gttm.ily` | GTTM notation stylesheet |
