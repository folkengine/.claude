\version "2.26.0"
\include "rhythm.ily"
\include "rhythm.ly"

\header {
  title = "Symphony No. 5 in C minor, Op. 67, I"
  subtitle = "rhythm only, mm. 1–5"
  composer = "Ludwig van Beethoven"
  tagline = ##f
}

\score {
  \new RhythmicStaff \rhythmMusic
  \layout { \rhythmLayout }
}
