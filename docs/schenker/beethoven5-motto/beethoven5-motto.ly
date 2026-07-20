\version "2.26.0"
\include "schenker.ily"

\header {
  title = "Beethoven, Symphony No. 5 in C minor, op. 67 — i, mm. 1–5"
  subtitle = "Schenkerian graph of the opening motto"
  tagline = ##f
}

%% Timing skeleton: five bars of 2/4 (time signature engraver is removed,
%% barlines are hidden — the meter only drives horizontal alignment).

%% ------------------------------------------------------------ foreground ---
fgMusic = \fixed c' {
  \clef treble
  \key c \minor
  \time 2/4
  r8 g8[ g8 g8] |
  es2\fermata |
  r8 f8[ f8 f8] |
  d2~ |
  d2\fermata |
}

%% ---------------------------------------------------------- middleground ---
%% Two unfolded thirds: G–E-flat over (I), F–D over (V).
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
%% Urlinie fragment: 3 – 2, beamed, left open on the dominant.
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
%% Implied Bassbrechung: (C) – (G); the motto is unison, so the bass is
%% parenthesized.
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

%% Bass gets no beam here (only two implied tones), so silence the beam-fit
%% warnings by never beaming in this voice.

\score {
  <<
    \new Staff \with { instrumentName = "Fg." } { \fgStyle \fgMusic }
    \new Staff \with { instrumentName = "Mg." } \mgMusic
    \new Staff \with { instrumentName = "Bg." } \bgUpper
    \new Staff \bgBass
  >>
  \layout { \schenkerLayout }
}
