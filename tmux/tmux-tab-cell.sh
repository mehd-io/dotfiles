#!/bin/bash
# Renders a fixed-width tab cell: <icon> <folder_name_padded> <agent_status>
# Usage: tmux-tab-cell.sh <pane_id> <pane_current_path> <pane_current_command>
# Output: "⎇ kulpo      ⠹" (fixed 16 display chars with tmux color codes)

PANE_ID="$1"
PANE_PATH="$2"
PANE_CMD="$3"

STATE_DIR="$HOME/.claude/run/state"
FRAMES="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
TICK=$(( $(date +%s) % 10 ))
SPINNER="${FRAMES:$TICK:1}"

NAME_WIDTH=10

# --- Repo icon ---
IS_GIT=0
if [ -n "$PANE_PATH" ]; then
  git -C "$PANE_PATH" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1 && IS_GIT=1
fi

if [ "$IS_GIT" -eq 1 ]; then
  ICON="⎇"
else
  ICON="◇"
fi

# --- Folder name (padded + truncated) ---
FOLDER=""
[ -n "$PANE_PATH" ] && FOLDER=$(basename "$PANE_PATH")
[ -z "$FOLDER" ] && FOLDER="~"
FOLDER_PAD=$(printf "%-${NAME_WIDTH}.${NAME_WIDTH}s" "$FOLDER")

# --- Agent status icon ---
AGENT_ICON=" "
if echo "$PANE_CMD" | grep -qE '^[0-9]+\.[0-9]+'; then
  STATUS=""
  if [ -d "$STATE_DIR" ]; then
    NOW=$(date +%s)
    for f in "$STATE_DIR"/*.state; do
      [ -f "$f" ] || continue
      FILE_PANE=$(grep -m1 '^pane=' "$f" 2>/dev/null | cut -d= -f2)
      if [ "$FILE_PANE" = "$PANE_ID" ]; then
        MTIME=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
        [ $(( NOW - MTIME )) -gt 300 ] && continue
        STATUS=$(grep -m1 '^status=' "$f" 2>/dev/null | cut -d= -f2)
        break
      fi
    done
  fi
  case "$STATUS" in
    busy)    AGENT_ICON="#[fg=yellow,bold]${SPINNER}#[fg=default,none]" ;;
    waiting) AGENT_ICON="#[fg=cyan,bold]⏸#[fg=default,none]" ;;
    idle)    AGENT_ICON="#[fg=green]✓#[fg=default,none]" ;;
    *)       AGENT_ICON="#[fg=#666666]·#[fg=default,none]" ;;
  esac
fi

echo "${ICON} ${FOLDER_PAD} ${AGENT_ICON}"
