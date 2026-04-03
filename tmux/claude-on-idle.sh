#!/bin/bash
# Stop / SubagentStop hook — Claude finished its turn, idle
STATE_DIR="$HOME/.claude/run/state"
mkdir -p "$STATE_DIR"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
[ -z "$SESSION_ID" ] && exit 0

TMUX_PANE="${TMUX_PANE:-}"
[ -z "$TMUX_PANE" ] && [ -n "$TMUX" ] && TMUX_PANE=$(tmux display-message -p '#{pane_id}' 2>/dev/null)

printf 'session=%s\npane=%s\nstatus=idle\n' "$SESSION_ID" "$TMUX_PANE" > "$STATE_DIR/${SESSION_ID}.state"

[ -n "$TMUX" ] && tmux refresh-client -S 2>/dev/null &
exit 0
