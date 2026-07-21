#!/usr/bin/env bash
#
# render.sh — render a Schenker graph directory to SVG + PDF.
#
# Usage: render.sh [graph-dir]   (default: current directory)
#
# Renders, in <graph-dir>:
#   * every assembled graph .ly (any .ly that contains a \score) — e.g.
#     <slug>.ly and <slug>-gttm.ly;
#   * each per-level building block that is present (foreground.ly,
#     middleground.ly, background-urlinie.ly, background-bass.ly,
#     gttm-layer.ly), so every level also gets a standalone .svg/.pdf for
#     embedding and editing.
#
# The directory must already contain schenker.ily (and gttm.ily when a GTTM
# layer is used). The per-level building blocks are music-only (no \version,
# no \include, no \score), so each is rendered through a disposable wrapper.
# The wrapper is named differently from the level file on purpose: LilyPond
# searches an including file's own directory first, so a wrapper named
# foreground.ly that does \include "foreground.ly" would include itself and
# hang. Keeping the wrapper name distinct and pointing -I at the graph dir
# makes the include resolve to the real level file.
#
set -euo pipefail

DIR="${1:-.}"
DIR="$(cd "$DIR" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

svgpdf() {  # svgpdf <out-basename> <source.ly> [extra lilypond args...]
  local out="$1"; shift
  local src="$1"; shift
  # SVG: -dcrop trims the page to the music's bounding box (minimal padding).
  # It writes <out>.cropped.svg alongside the full-page <out>.svg; promote the
  # cropped one to <out>.svg so the published image has no page margins. The
  # "LilyPond vX.Y.Z" footer is suppressed upstream via \paper (schenker.ily).
  lilypond -dbackend=svg -dcrop "$@" -o "$DIR/$out" "$src" >/dev/null 2>&1
  mv -f "$DIR/$out.cropped.svg" "$DIR/$out.svg"
  lilypond               "$@" -o "$DIR/$out" "$src" >/dev/null 2>&1
  echo "  $out.svg  $out.pdf"
}

is_level() {
  case "$1" in
    foreground.ly|middleground.ly|background-urlinie.ly|background-bass.ly|gttm-layer.ly) return 0 ;;
    *) return 1 ;;
  esac
}

echo "Assembled graphs:"
for f in "$DIR"/*.ly; do
  [ -e "$f" ] || continue
  b="$(basename "$f")"
  is_level "$b" && continue
  grep -q '\\score' "$f" || continue
  svgpdf "${b%.ly}" "$f"
done

echo "Levels:"
for lvl in foreground middleground background-urlinie background-bass gttm-layer; do
  [ -f "$DIR/$lvl.ly" ] || continue
  w="$TMP/_render_$lvl.ly"
  case "$lvl" in
    foreground) cat > "$w" <<'EOF'
\version "2.26.0"
\include "schenker.ily"
\include "foreground.ly"
\score { \new Staff \fgMusic \layout { \schenkerLayout } }
EOF
      ;;
    middleground) cat > "$w" <<'EOF'
\version "2.26.0"
\include "schenker.ily"
\include "middleground.ly"
\score { \new Staff \mgMusic \layout { \schenkerLayout } }
EOF
      ;;
    background-urlinie) cat > "$w" <<'EOF'
\version "2.26.0"
\include "schenker.ily"
\include "background-urlinie.ly"
\score { \new Staff \bgUpper \layout { \schenkerLayout } }
EOF
      ;;
    background-bass) cat > "$w" <<'EOF'
\version "2.26.0"
\include "schenker.ily"
\include "background-bass.ly"
\score { \new Staff \bgBass \layout { \schenkerLayout } }
EOF
      ;;
    gttm-layer) cat > "$w" <<'EOF'
\version "2.26.0"
\include "schenker.ily"
\include "gttm.ily"
\include "gttm-layer.ly"
\score {
  <<
    \new Lyrics \with { \gttmDotRow } \dotsEighth
    \new Lyrics \with { \gttmDotRow } \dotsQuarter
    \new Lyrics \with { \gttmDotRow } \dotsMeasure
  >>
  \layout { \schenkerLayout }
}
EOF
      ;;
  esac
  svgpdf "$lvl" "$w" -I "$DIR"
done
