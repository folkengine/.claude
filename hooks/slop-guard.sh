#!/bin/bash
# PreToolUse guard against sending unreviewed bulk to other people.
# Written for the No AI Slop manifesto (slopmanifesto.com).
#
# Active only while .claude/slop-guard exists at the repository root: opt-in
# per repository, the same flag-file pattern as dog mode. The /slop-guard
# skill is the switch. While active:
#
#   1. Review-size gate. `git push` and `gh pr create` are denied when the
#      branch's diff against its base is larger than the threshold and no
#      human has marked that exact diff as reviewed. Commits are never gated:
#      local work is cheap, and what costs a reader's time is what gets sent.
#   2. Disclosure prompt. `gh pr create` with no "AI assistance" section in
#      its body becomes an ordinary permission prompt for the human. The
#      section is optional: approve to open the PR as is, or decline and ask
#      for the section. This never denies by itself.
#   3. Switch protection. Claude may not write the flag or the review marker
#      directly, and may not run `reviewed` at all: the marker records that a
#      person read the diff, so written by the agent it would be false.
#      Claude may run `off`, or `on` to change the threshold (the skill does),
#      but each becomes a permission prompt, so loosening the guard is always
#      the human's decision. Turning it on needs no prompt.
#
# Subcommands. The skill runs the first three; `reviewed` is the human's
# alone (a terminal, or the `!` prefix inside Claude Code):
#
#   slop-guard.sh on [lines]   turn on for this repo (default threshold 400)
#   slop-guard.sh off          turn off and forget the review marker
#   slop-guard.sh status       size of the outgoing diff, and whether it is reviewed
#   slop-guard.sh reviewed     "I read this diff": records its fingerprint
#
# The fingerprint is merge-base + HEAD tree, so any new commit invalidates the
# review. Size is added + deleted lines with lockfiles left out.
# `on` and `reviewed` add the flag and marker to .git/info/exclude so they are
# never committed.
#
# Register under PreToolUse with matcher "Bash|Edit|Write".
# Exit 0 = no opinion; exit 2 = deny (stderr is shown to Claude).
# Fails open: when git cannot answer (no repo, no base branch) the call goes
# through. A guard that bricks a session gets turned off for good.
#
# Kept to the bash 3.2 subset, since /bin/bash on macOS is 3.2.

DEFAULT_THRESHOLD=400
EXCLUDES=(':(exclude)*.lock' ':(exclude)package-lock.json' ':(exclude)pnpm-lock.yaml' ':(exclude)go.sum')

# The guard belongs to the repository: flag and marker live in .claude at its
# root, wherever in the tree Claude Code was started. Both sides of this
# script resolve it the same way, so the switch and the hook cannot disagree.
project_root() {
  local d="${CLAUDE_PROJECT_DIR:-$PWD}"
  git -C "$d" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$d"
}

# Base of the outgoing diff: where HEAD forked from the default branch,
# preferring the remote's copy so unpushed commits on main still count.
find_base() {
  local head_ref cand
  head_ref=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
  for cand in "$head_ref" origin/main origin/master main master; do
    [ -n "$cand" ] || continue
    git rev-parse -q --verify "$cand^{commit}" >/dev/null 2>&1 || continue
    git merge-base HEAD "$cand" 2>/dev/null && return 0
  done
  return 1
}

numstat() {
  git diff --numstat "$BASE" HEAD -- . "${EXCLUDES[@]}" 2>/dev/null
}

# Sets BASE, CHURN, NFILES, FINGERPRINT. Returns 1 when git cannot answer.
# Must run from the repository root so the pathspecs cover the whole tree.
measure() {
  local tree
  BASE=$(find_base) || return 1
  tree=$(git rev-parse -q --verify 'HEAD^{tree}' 2>/dev/null) || return 1
  FINGERPRINT="$BASE $tree"
  read -r CHURN NFILES < <(numstat | awk '{ if ($1 != "-") n += $1 + $2; f++ } END { print n + 0, f + 0 }')
  return 0
}

threshold() {
  local t
  t=$(head -n 1 "$FLAG" 2>/dev/null | tr -cd '0-9')
  printf '%s' "${t:-$DEFAULT_THRESHOLD}"
}

is_reviewed() {
  [ -f "$MARKER" ] && [ "$(head -n 1 "$MARKER")" = "$FINGERPRINT" ]
}

# Keep the flag and the marker out of commits without touching .gitignore.
# A committed marker would change the HEAD tree and so invalidate itself.
ignore_locally() {
  local exclude
  exclude=$(git rev-parse --git-path info/exclude 2>/dev/null) || return 0
  mkdir -p "$(dirname "$exclude")" 2>/dev/null
  grep -qxF '**/.claude/slop-*' "$exclude" 2>/dev/null || printf '%s\n' '**/.claude/slop-*' >> "$exclude"
}

# -------------------------------------------------------------- subcommands
if [ $# -gt 0 ]; then
  PROJECT=$(project_root)
  FLAG="$PROJECT/.claude/slop-guard"
  MARKER="$PROJECT/.claude/slop-reviewed"
  cd "$PROJECT" 2>/dev/null

  case "$1" in
    on)
      lines="${2:-$DEFAULT_THRESHOLD}"
      case "$lines" in
        ''|*[!0-9]*) echo "slop-guard: threshold must be a whole number of lines" >&2; exit 2 ;;
      esac
      mkdir -p "$PROJECT/.claude" && printf '%s\n' "$lines" > "$FLAG"
      ignore_locally
      echo "slop-guard: on for $PROJECT (threshold $lines changed lines)"
      ;;
    off)
      rm -f "$FLAG" "$MARKER"
      echo "slop-guard: off for $PROJECT"
      ;;
    status)
      if [ -f "$FLAG" ]; then echo "slop-guard: on (threshold $(threshold))"; else echo "slop-guard: off"; fi
      if measure; then
        if is_reviewed; then state="reviewed"; else state="not reviewed"; fi
        echo "outgoing: $CHURN changed lines across $NFILES files since ${BASE:0:9} ($state)"
      else
        echo "outgoing: no base branch found, so the size gate would let everything through"
      fi
      ;;
    reviewed)
      if ! measure; then
        echo "slop-guard: no base branch found, nothing to mark" >&2
        exit 1
      fi
      mkdir -p "$PROJECT/.claude" && printf '%s\n%s\n' "$FINGERPRINT" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$MARKER"
      ignore_locally
      echo "slop-guard: marked $CHURN changed lines across $NFILES files as reviewed"
      ;;
    *)
      echo "usage: slop-guard.sh on [lines] | off | status | reviewed" >&2
      exit 2
      ;;
  esac
  exit 0
fi

# ----------------------------------------------------------------- hook side
PROJECT=$(project_root)
FLAG="$PROJECT/.claude/slop-guard"
MARKER="$PROJECT/.claude/slop-reviewed"
[ -f "$FLAG" ] || exit 0

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
  TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
  FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
  CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
else
  # Fallback: match against the whole payload (coarse but safe).
  TOOL=$(printf '%s' "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"[[:space:]]*$/\1/')
  CMD=$INPUT
  FILE=$INPUT
  CWD=""
fi

deny() {
  printf '%s\n' "$1" >&2
  exit 2
}

HANDS_OFF="Slop guard: do not write or remove .claude/slop-guard or .claude/slop-reviewed yourself, and never run \`reviewed\`. The marker records that a person read the diff. Ask the human to run \`! $0 reviewed\` once they have read it. To switch the guard, run \`$0 on|off\` and let the human confirm."

case "$TOOL" in
  Edit|Write|NotebookEdit)
    case "$FILE" in
      *".claude/slop-guard"|*".claude/slop-reviewed"|*".claude/slop-guard\""*|*".claude/slop-reviewed\""*) deny "$HANDS_OFF" ;;
    esac
    exit 0
    ;;
  Bash) ;;
  *) exit 0 ;;
esac

# Word boundaries for matching commands. Quotes count as boundaries so that
# `bash -c "git push"` and the jq-less fallback (raw JSON payload, where an
# inner quote arrives as \") both match.
Q="\"'"
PRE="(^|[;&|($Q]|[[:space:]])"
POST="([[:space:];\\&|)$Q]|\$)"

if printf '%s' "$CMD" | grep -Eq "\\.claude/slop-(guard|reviewed)([^.[:alnum:]_-]|\$)|slop-guard\\.sh[[:space:]]+reviewed${POST}"; then
  deny "$HANDS_OFF"
fi

# The guard is on, so `off` and `on <lines>` can only loosen it: ask the human.
if printf '%s' "$CMD" | grep -Eq "slop-guard\\.sh[[:space:]]+(on|off)${POST}"; then
  cat <<'ASK_EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Slop guard: this turns the guard off or changes its threshold for this repository. Approve only if you asked for that."}}
ASK_EOF
  exit 0
fi

IS_PUSH=no
IS_PR=no
printf '%s' "$CMD" | grep -Eq "${PRE}git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?push${POST}" && IS_PUSH=yes
printf '%s' "$CMD" | grep -Eq "${PRE}gh[[:space:]]+pr[[:space:]]+create${POST}" && IS_PR=yes
[ "$IS_PUSH" = yes ] || [ "$IS_PR" = yes ] || exit 0
printf '%s' "$CMD" | grep -Eq -- "${PRE}(--dry-run|--help)${POST}" && exit 0

# ---- 1. review-size gate
[ -n "$CWD" ] && cd "$CWD" 2>/dev/null
TOP=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$TOP" ] && cd "$TOP" && measure; then
  LIMIT=$(threshold)
  if [ "$CHURN" -gt "$LIMIT" ] && ! is_reviewed; then
    BIGGEST=$(numstat | awk '$1 != "-" { printf "  %6d  %s\n", $1 + $2, $3 }' | sort -rn | head -5)
    deny "Slop guard: this would send $CHURN changed lines across $NFILES files (threshold $LIMIT) that no human has marked as reviewed.
Do not work around this. In the chat instead:
  1. Say what the change is for, in two sentences.
  2. Give a reading order: the files that carry the risk first, the mechanical ones last, and what is safe to skim.
  3. Say whether it can be split or cut down. Deleting code is a valid answer.
Then stop. Once the human has read it they run \`$0 reviewed\` (or raise the threshold with \`on <lines>\`) and you retry.
Largest files:
$BIGGEST"
  fi
fi

# ---- 2. optional disclosure in the PR body
if [ "$IS_PR" = yes ]; then
  # The human writes the body themselves in the browser.
  printf '%s' "$CMD" | grep -Eq -- "${PRE}(--web|-w)${POST}" && exit 0
  printf '%s' "$CMD" | grep -Eiq 'AI[ -]assist' && exit 0
  BODY_FILE=$(printf '%s' "$CMD" | sed -nE 's/.*(--body-file|-F)[[:space:]=]+"?([^"[:space:]]+)"?.*/\2/p' | head -1)
  if [ -n "$BODY_FILE" ] && [ -f "$BODY_FILE" ] && grep -Eiq 'AI[ -]assist' "$BODY_FILE"; then
    exit 0
  fi
  cat <<'ASK_EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Slop guard: this PR body has no \"AI assistance\" section (what the agent wrote, what you checked). It is optional. Approve to open the PR as is, or decline and ask for the section."}}
ASK_EOF
fi

exit 0
