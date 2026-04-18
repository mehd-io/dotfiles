#!/bin/bash
# Claude Code statusLine hook.
# Reads JSON from stdin, outputs a compact status string for Claude Code's own status line.
#
# State is determined by reading the state file written by the PreToolUse / Stop / SubagentStop
# hooks (claude-on-busy.sh and claude-on-waiting.sh). This is the reliable source of truth:
#
#   busy    → 🔄 (PreToolUse hook fired — model is processing/using a tool)
#   waiting → ✍️  (Stop/SubagentStop hook fired — waiting for user input)
#   (none)  → 💬  (no state file yet — idle/default)

STATE_DIR="$HOME/.claude/run/state"
mkdir -p "$STATE_DIR"

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
[ -z "$SESSION_ID" ] && exit 0

# Read status written by the hooks (busy / waiting); default to idle if absent
STATE_FILE="$STATE_DIR/${SESSION_ID}.state"
STATUS="idle"
if [ -f "$STATE_FILE" ]; then
  STATUS=$(grep '^status=' "$STATE_FILE" | cut -d= -f2)
  [ -z "$STATUS" ] && STATUS="idle"
fi

case "$STATUS" in
  busy)    STATE_LABEL="🔄" ;;
  waiting) STATE_LABEL="✍️"  ;;
  *)       STATE_LABEL="💬" ;;
esac

# --- Additional info from JSON (dir/branch omitted — already in tmux tabs) ---
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // empty')
REMAINING=$(echo "$INPUT" | jq -r '.context_window.remaining_percentage // empty')

CTX_LABEL=""
[ -n "$REMAINING" ] && CTX_LABEL=$(printf "ctx:%.0f%%" "$REMAINING")

PARTS="$STATE_LABEL"
[ -n "$MODEL" ]     && PARTS="$PARTS $MODEL"
[ -n "$CTX_LABEL" ] && PARTS="$PARTS | $CTX_LABEL"

echo "$PARTS"
