\version "2.26.0"
\include "schenker.ily"
\include "gttm.ily"

\include "foreground.ly"
\include "middleground.ly"
\include "background-urlinie.ly"
\include "background-bass.ly"
\include "gttm-layer.ly"

\header {
  title = "Beethoven, Symphony No. 5 in C minor, op. 67 — i, mm. 1–5"
  subtitle = "Schenkerian graph with GTTM metrical grid and grouping structure"
  tagline = ##f
}

\score {
  <<
    \new Staff \with { instrumentName = "Fg." } { \gttmBrackets \fgMusic }
    \new Lyrics \with { \gttmDotRow } \dotsEighth
    \new Lyrics \with { \gttmDotRow } \dotsQuarter
    \new Lyrics \with { \gttmDotRow } \dotsMeasure
    \new Staff \with { instrumentName = "Mg." } \mgMusic
    \new Staff \with { instrumentName = "Bg." } \bgUpper
    \new Staff \bgBass
  >>
  \layout {
    \schenkerLayout
    \context { \Voice \gttmVoiceMods }
  }
}
