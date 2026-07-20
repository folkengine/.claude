\version "2.26.0"
\include "schenker.ily"

%% example.ly — smoke test for schenker.ily.
%% A complete Ursatz in C major: Urlinie 3–2–1 over Bassbrechung I–V–I.
%% Must compile warning-free; if this breaks, fix schenker.ily before use.

\header {
  title = "Ursatz in C major"
  subtitle = "3-line: schenker.ily smoke test"
  tagline = ##f
}

urlinie = \fixed c'' {
  \clef treble
  \time 2/4
  \bgStyle
  e8^\markup \hat "3" [ \beamFillOn e8 e8 e8 | \beamFillOff
  d8^\markup \hat "2" \beamFillOn d8 d8 d8 | \beamFillOff
  c8^\markup \hat "1" ] r8 r4 |
}

bassbrechung = \fixed c {
  \clef bass
  \time 2/4
  \bgStyle
  c8_\markup \rn "I" [ \beamFillOn c8 c8 c8 | \beamFillOff
  g,8_\markup \rn "V" \beamFillOn g,8 g,8 g,8 | \beamFillOff
  c8_\markup \rn "I" ] r8 r4 |
}

\score {
  <<
    \new Staff \urlinie
    \new Staff \bassbrechung
  >>
  \layout { \schenkerLayout }
}
