\version "2.26.0"
\include "schenker.ily"
\include "gttm.ily"

%% example-gttm.ly — smoke test for gttm.ily (with schenker.ily).
%% A trivial foreground with GTTM metrical dot-grid and grouping brackets
%% above an Ursatz background. Must compile warning-free.

\header {
  title = "GTTM layer smoke test"
  tagline = ##f
}

fgMusic = \fixed c'' {
  \clef treble
  \time 2/4
  \gttmBrackets
  e4\startGroup\startGroup f8[ e8]\stopGroup |
  d4\startGroup d4 |
  c2\stopGroup\stopGroup |
}

dotsEighth  = \lyricmode { \repeat unfold 12 { "•"8 } }
dotsQuarter = \lyricmode { \repeat unfold 6  { "•"4 } }
dotsMeasure = \lyricmode { \repeat unfold 3  { "•"2 } }

urlinie = \fixed c'' {
  \clef treble
  \time 2/4
  \bgStyle
  e8^\markup \hat "3" [ \beamFillOn e8 e8 e8 | \beamFillOff
  d8^\markup \hat "2" \beamFillOn d8 d8 d8 | \beamFillOff
  c8^\markup \hat "1" ] r8 r4 |
}

\score {
  <<
    \new Staff { \fgStyle \fgMusic }
    \new Lyrics \with { \gttmDotRow } \dotsEighth
    \new Lyrics \with { \gttmDotRow } \dotsQuarter
    \new Lyrics \with { \gttmDotRow } \dotsMeasure
    \new Staff \urlinie
  >>
  \layout {
    \schenkerLayout
    \context { \Voice \gttmVoiceMods }
  }
}
