\version "2.26.0"
\include "schenker.ily"

\include "middleground.ly"
\include "background-urlinie.ly"
\include "background-bass.ly"

\header {
  title = "Beethoven, Symphony No. 5 in C minor, op. 67 — whole-symphony Urlinie"
  subtitle = "Very simplified background: 3-2-1 (E flat - D - C) over i - V - I; C minor to C major"
  tagline = ##f
}

\score {
  <<
    \new Staff \with { instrumentName = "Mvt." } \mgMusic
    \new Staff \with { instrumentName = "Bg." } \bgUpper
    \new Staff \bgBass
  >>
  \layout { \schenkerLayout }
}
