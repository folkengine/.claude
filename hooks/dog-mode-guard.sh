#!/bin/bash
# PreToolUse guard for dog mode ("walking the dog").
# While <project>/.claude/dog-mode exists, deny file-editing tools and
# mutating Bash commands so Claude can only guide, read, and verify.
# Exit 0 = allow; exit 2 = deny (stderr is shown to Claude).

FLAG="${CLAUDE_PROJECT_DIR:-.}/.claude/dog-mode"
[ -f "$FLAG" ] || exit 0

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
  TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
else
  TOOL=$(printf '%s' "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"[[:space:]]*$/\1/')
  CMD=$INPUT # fallback: match the denylist against the whole payload (coarse but safe)
fi

DENY_MSG="🐕 Dog mode is active — you guide, the human types. Describe this change as a step for the developer instead of doing it yourself. (Disable with /dog off)"

deny() {
  echo "$DENY_MSG" >&2
  exit 2
}

case "$TOOL" in
  Edit|Write|NotebookEdit)
    deny
    ;;
  Bash)
    # Carve-out: commands that manage the flag file itself (the /dog toggle).
    case "$CMD" in
      *".claude/dog-mode"*) exit 0 ;;
    esac

    # Ignore harmless redirects before scanning for '>' (2>&1, >/dev/null etc.).
    CLEAN=$(printf '%s' "$CMD" | sed -E 's/[0-9]*>&[0-9]+//g; s/[0-9]*&?>+[[:space:]]*\/dev\/null//g')

    case "$CLEAN" in
      *">"*) deny ;;
    esac

    if printf '%s' "$CLEAN" | grep -Eq \
      '(^|[;&|[:space:]("'"'"'`])(rm|mv|cp|touch|mkdir|rmdir|chmod|chown|ln|tee|truncate|install|dd|patch)([[:space:]]|$)|sed[[:space:]]+-[a-zA-Z]*i|git[[:space:]]+(add|commit|push|checkout|switch|restore|reset|stash|merge|rebase|tag|rm|mv|clean|cherry-pick|revert|apply|am)([[:space:]]|$)|cargo[[:space:]]+(fix|fmt|publish|install|add|remove|new|init)([[:space:]]|$)'; then
      deny
    fi
    ;;
esac

exit 0
