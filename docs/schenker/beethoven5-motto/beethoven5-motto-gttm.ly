\version "2.26.0"
\include "schenker.ily"
\include "gttm.ily"

\header {
  title = "Beethoven, Symphony No. 5 in C minor, op. 67 — i, mm. 1–5"
  subtitle = "Schenkerian graph with GTTM metrical grid and grouping structure"
  tagline = ##f
}

%% ------------------------------------------------------------ foreground ---
%% Grouping structure (GTTM ch. 3): the two motto gestures are parallel
%% groups (GPR 6); both nest inside one larger group.
fgMusic = \fixed c' {
  \clef treble
  \key c \minor
  \time 2/4
  \gttmBrackets
  r8 g8\startGroup\startGroup [ g8 g8] |
  es2\fermata\stopGroup |
  r8 f8\startGroup [ f8 f8] |
  d2~ |
  d2\fermata\stopGroup\stopGroup |
}

%% Metrical structure (GTTM ch. 4): dot rows, largest level last.
%% The fermatas suspend but do not cancel the notated 2/4 grid.
dotsEighth  = \lyricmode { \repeat unfold 20 { "•"8 } }
dotsQuarter = \lyricmode { \repeat unfold 10 { "•"4 } }
dotsMeasure = \lyricmode { \repeat unfold 5  { "•"2 } }

%% ---------------------------------------------------------- middleground ---
mgMusic = \fixed c' {
  \clef treble
  \key c \minor
  \time 2/4
  \mgStyle
  s8 g8( s8 s8 |
  es2) |
  s8 f8( s8 s8 |
  d2) |
  s2 |
}

%% ------------------------------------------------------ background upper ---
bgUpper = \fixed c' {
  \clef treble
  \key c \minor
  \time 2/4
  \bgStyle
  s2 |
  es8^\markup \hat "3" [ \beamFillOn es8 es8 es8 |
  es8 es8 es8 es8 | \beamFillOff
  d8^\markup \hat "2" ] r8 r4 |
  s2 |
}

%% ------------------------------------------------------- background bass ---
bgBass = \fixed c {
  \clef bass
  \key c \minor
  \time 2/4
  \bgStyle
  s2 |
  \parenthesize c8_\markup \rn "I" r8 r4 |
  r2 |
  \parenthesize g,8_\markup \rn "V" r8 r4 |
  s2 |
}

\score {
  <<
    \new Staff \with { instrumentName = "Fg." } { \fgStyle \fgMusic }
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
