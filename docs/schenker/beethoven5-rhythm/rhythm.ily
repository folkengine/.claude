\version "2.26.0"

%% rhythm.ily — stylesheet for pure-rhythm notation (a drum part with no pitches).
%%
%% Conventions:
%%   One-line staff (RhythmicStaff) — every note sits on the single line, so the
%%   page shows only durations, beams, rests, accents and fermatas.
%%   Write every note as `c` (pitch is ignored); real meter, barlines and bar
%%   numbers are kept — unlike schenkerLayout, which strips them.
%%   Independent of schenker.ily: do not include both in one file.

\paper {
  tagline = ##f
}

%% Plain rhythm: engrave normally on one line; autobeaming stays on so eighths
%% group by the meter. Add `\rhythmStyle` at the top of a voice.
rhythmStyle = {
  \stemUp
}

%% Pass to \score: \layout { \rhythmLayout }
rhythmLayout = \layout {
  indent = 0
}
