#!/bin/bash
# Shows Claude Code state icon in tmux tab.
# State is written by the Claude Code statusLine hook to ~/.claude/run/state/<session_id>.
# Usage: tmux-claude-status.sh <pane_id>
#   🔄 = busy (processing/using a tool)
#   ✍️  = waiting for user input
#   (nothing) = no claude in this pane or no state file found

PANE_ID="${1:-}"
[ -z "$PANE_ID" ] && exit 0

# Check if the pane is running a claude process (version number as command name, e.g. "2.1.76")
PANE_CMD=$(tmux display-message -p -t "$PANE_ID" '#{pane_current_command}' 2>/dev/null)
if ! echo "$PANE_CMD" | grep -qE '^[0-9]+\.[0-9]+'; then
  exit 0
fi

STATE_DIR="$HOME/.claude/run/state"
[ -d "$STATE_DIR" ] || exit 0

# Find the most recently modified state file for this pane by matching pane_id inside the file.
# State files are written by the statusLine hook: one file per session_id.
STATE=""
LATEST_FILE=""
LATEST_TIME=0

for f in "$STATE_DIR"/*.state; do
  [ -f "$f" ] || continue
  # Check if this state file belongs to a session running in this pane
  FILE_PANE=$(grep -m1 '^pane=' "$f" 2>/dev/null | cut -d= -f2)
  if [ "$FILE_PANE" = "$PANE_ID" ]; then
    FILE_TIME=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)
    if [ "${FILE_TIME:-0}" -gt "$LATEST_TIME" ]; then
      LATEST_TIME="$FILE_TIME"
      LATEST_FILE="$f"
    fi
  fi
done

STATE="idle"
if [ -n "$LATEST_FILE" ]; then
  STATE=$(grep -m1 '^status=' "$LATEST_FILE" 2>/dev/null | cut -d= -f2)
  [ -z "$STATE" ] && STATE="idle"
fi

case "$STATE" in
  busy)    echo "🔄" ;;
  waiting) echo "✍️" ;;
  *)       echo "💬" ;;
esac
