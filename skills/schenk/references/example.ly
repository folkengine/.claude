\version "2.26.0"
\include "schenker.ily"

%% example.ly — smoke test for schenker.ily, assembled from the per-level
%% building blocks. A complete C-major graph: foreground and middleground
%% diminutions reducing to Urlinie 3–2–1 over Bassbrechung I–V–I.
%% Must compile warning-free; if this breaks, fix schenker.ily (or the level
%% files) before use.

\include "foreground.ly"
\include "middleground.ly"
\include "background-urlinie.ly"
\include "background-bass.ly"

\header {
  title = "Ursatz in C major"
  subtitle = "3-line: schenker.ily smoke test"
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
