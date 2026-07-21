\version "2.26.0"
\include "schenker.ily"

\include "foreground.ly"
\include "middleground.ly"
\include "background-urlinie.ly"
\include "background-bass.ly"

\header {
  title = "Beethoven, Symphony No. 5 in C minor, op. 67 — i, mm. 1–5"
  subtitle = "Schenkerian graph of the opening motto"
  tagline = ##f
}

\score {
  <<
    \new Staff \with { instrumentName = "Fg." } \fgMusic
    \new Staff \with { instrumentName = "Mg." } \mgMusic
    \new Staff \with { instrumentName = "Bg." } \bgUpper
    \new Staff \bgBass
  >>
  \layout { \schenkerLayout }
}
