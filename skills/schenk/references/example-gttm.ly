\version "2.26.0"
\include "schenker.ily"
\include "gttm.ily"

%% example-gttm.ly — smoke test for gttm.ily (with schenker.ily), assembled
%% from the per-level building blocks. The C-major foreground carries GTTM
%% grouping brackets; the metrical dot-grid sits beneath it, above an Urlinie
%% background. Must compile warning-free.

\include "foreground.ly"
\include "background-urlinie.ly"
\include "gttm-layer.ly"

\header {
  title = "GTTM layer smoke test"
  tagline = ##f
}

\score {
  <<
    \new Staff { \gttmBrackets \fgMusic }
    \new Lyrics \with { \gttmDotRow } \dotsEighth
    \new Lyrics \with { \gttmDotRow } \dotsQuarter
    \new Lyrics \with { \gttmDotRow } \dotsMeasure
    \new Staff \bgUpper
  >>
  \layout {
    \schenkerLayout
    \context { \Voice \gttmVoiceMods }
  }
}
