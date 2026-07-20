\version "2.26.0"

%% gttm.ily — optional rhythmic-analysis vocabulary after Lerdahl & Jackendoff,
%% "A Generative Theory of Tonal Music" (1983).
%%
%%   Metrical structure — rows of dots beneath the staff, one row per metrical
%%                        level (GTTM ch. 4). Implemented as Lyrics contexts.
%%   Grouping structure — nested horizontal brackets beneath the dot grid
%%                        (GTTM ch. 3), via Horizontal_bracket_engraver.
%%
%% Time-span / prolongational trees are deliberately not rendered (LilyPond
%% has no robust tree drawing); their content belongs in the companion text.

%% Apply inside the analyzed voice: brackets open downward, clear of the grid.
gttmBrackets = {
  \override HorizontalBracket.direction = #DOWN
  \override HorizontalBracket.staff-padding = #3.5
  \override HorizontalBracket.bracket-flare = #'(0 . 0)
}

%% Dot-row styling for a metrical-grid Lyrics context.
gttmDotRow = \with {
  \override LyricText.font-size = #-2
  \override VerticalAxisGroup.nonstaff-nonstaff-spacing.minimum-distance = #1.2
}

%% Context mod: enables analysis brackets in a Voice. Apply in the score's
%% layout as:  \layout { \schenkerLayout \context { \Voice \gttmVoiceMods } }
gttmVoiceMods = \with {
  \consists "Horizontal_bracket_engraver"
}
