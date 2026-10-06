\version "2.26.0"
\include "rhythm.ily"

%% example-rhythm.ly — smoke test for rhythm.ily, assembled from rhythm.ly.
%% The rhythm of the opening of Beethoven's Symphony No. 5 (mm. 1–5): three
%% eighths after an eighth rest, then a half note under a fermata; again three
%% eighths after a rest, then a half note tied into a second half note under
%% the second fermata (m. 5). Must compile warning-free.

\include "rhythm.ly"

\header {
  title = "Symphony No. 5, I"
  subtitle = "rhythm only, mm. 1–5: rhythm.ily smoke test"
  tagline = ##f
}

\score {
  \new RhythmicStaff \rhythmMusic
  \layout { \rhythmLayout }
}
