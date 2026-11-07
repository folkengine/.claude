#!/bin/bash
# UserPromptSubmit hook for language mode (the /lang skill).
#
# While ~/.claude/lang holds a language name, print a one-line reminder so
# every reply comes back in that language. A UserPromptSubmit hook's stdout is
# added to Claude's context, so this re-states the rule on EVERY turn — that is
# the point. A SessionStart hook would fire once and be lost to compaction in a
# long session, which is exactly how a language preference silently drifts back
# to English.
#
# No flag file, or an empty one, means language mode is off: print nothing and
# exit 0 so the turn proceeds untouched.

set -u

FLAG="$HOME/.claude/lang"
[ -f "$FLAG" ] || exit 0

# First line only, CR and surrounding whitespace stripped, so a file written by
# any editor (or with a stray trailing newline) still reads cleanly.
LANG_NAME=$(head -n 1 "$FLAG" | tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
[ -n "$LANG_NAME" ] || exit 0

cat <<EOF
Language mode is ON: write every reply to the user in ${LANG_NAME}.
Only the language changes. The active output style still governs length, tone and structure.
Code, file paths, commands, identifiers, and quoted tool output stay exactly as they are — never translate them.
If you are not fluent in ${LANG_NAME}, say so once, then do your best and mark what you are unsure of. Do not fake fluency.
The user turns this off with /lang off.
EOF
