\version "2.26.0"

%% schenker.ily — reusable stylesheet for Schenkerian analysis graphs.
%%
%% Conventions:
%%   Foreground  (Fg.) — real notation: stems, beams, rhythm, fermatas.
%%   Middleground (Mg.) — stemless filled noteheads; slurs mark prolongations
%%                        and unfoldings; durations are used only for spacing.
%%   Background  (Bg.) — open (half-note) heads carried by invisible eighth-note
%%                        stems so the Urlinie/Bassbrechung can take a long beam.
%%   Scale degrees — caret markup via \hat.
%%   Harmony — Roman numeral markup below the bass via \rn.

%% ---------------------------------------------------------------- markup ---

%% \markup \hat "3"  →  caret over the scale-degree numeral
#(define-markup-command (hat layout props num) (markup?)
   (interpret-markup layout props
     #{ \markup \override #'(baseline-skip . 1.2)
          \center-column { \teeny \bold "^" \small #num } #}))

%% \markup \rn "V"  →  Roman numeral, small caps feel
#(define-markup-command (rn layout props num) (markup?)
   (interpret-markup layout props
     #{ \markup \small \upright #num #}))

%% ---------------------------------------------------------- voice styles ---

%% Middleground: black heads, no stems/flags/beams; slurs carry the meaning.
mgStyle = {
  \omit Stem
  \omit Flag
  \autoBeamOff
  \override Slur.height-limit = #3
}

%% Background: open heads on beamable (invisible-stemmed) eighths.
%% Write Urlinie tones as 8ths with manual beams: es'8[ ... d'8]
bgStyle = {
  \autoBeamOff
  \omit Flag
  \override NoteHead.duration-log = #1   % print 8th-note heads as open half heads
  \override Stem.thickness = #0          % stems must exist to carry the beam,
  \stemUp                                %   but zero thickness makes them invisible
                                         %   (Stem.transparent would hide the Beam too)
  \override Beam.positions = #'(5 . 5)   % one flat, high Urlinie beam
  \override Beam.beam-thickness = #0.6
  \omit Rest                             % hidden rests let a beam span gaps
  \omit Dots
}

%% Foreground: normal notation, just quieter autobeams.
fgStyle = {
  \autoBeamOff
}

%% Filler notes that carry a long beam across a span without printing
%% anything themselves (use between the first and last beamed structural
%% tones; stems are already transparent in bgStyle).
beamFillOn = {
  \override NoteHead.transparent = ##t
  \override Accidental.stencil = ##f
}
beamFillOff = {
  \revert NoteHead.transparent
  \revert Accidental.stencil
}

%% -------------------------------------------------------------- layout -----

%% Applies to every file that includes this stylesheet (assembled graphs and
%% the render.sh per-level wrappers alike): drop the "LilyPond vX.Y.Z" footer
%% so nothing prints below the music. Padding is handled at render time by
%% LilyPond's -dcrop (see render.sh), which trims the SVG to the music's
%% bounding box.
\paper {
  tagline = ##f
}

%% Analytic score: no time signature, no barlines, no bar numbers,
%% roughly proportional spacing so the levels align vertically.
schenkerLayout = \layout {
  indent = 12\mm
  \context {
    \Score
    \remove Bar_number_engraver
    proportionalNotationDuration = #1/8
    \override SpacingSpanner.uniform-stretching = ##t
  }
  \context {
    \Staff
    \remove Time_signature_engraver
    \override BarLine.stencil = ##f
  }
}
