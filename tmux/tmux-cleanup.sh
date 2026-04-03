#!/bin/bash
# ~/.dotfiles/tmux/tmux-cleanup.sh <pane_pid> <pane_current_path>
# Called by tmux pane-exited hook. Kills orphaned processes and stops devcontainers
# when the last pane for a repo closes.

PANE_PID="$1"
PANE_PATH="$2"

[ -z "$PANE_PATH" ] && exit 0

# Clean up the pane info cache
rm -f "/tmp/tmux-pane-info/$PANE_PID" 2>/dev/null

# Find repo root
REPO_ROOT=$(git -C "$PANE_PATH" rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_ROOT" ] && exit 0

# Count remaining tmux panes still in this repo
REMAINING=$(tmux list-panes -a -F '#{pane_current_path}' 2>/dev/null | while read -r p; do
  git -C "$p" rev-parse --show-toplevel 2>/dev/null
done | grep -c "^${REPO_ROOT}$")

# If other panes are still in this repo, nothing to do
[ "$REMAINING" -gt 0 ] && exit 0

# --- Last pane for this repo: full cleanup ---

# 1. Stop devcontainer if running
if command -v docker &>/dev/null; then
  CONTAINER_ID=$(docker ps -q --filter "label=devcontainer.local_folder=$REPO_ROOT" 2>/dev/null | head -1)
  if [ -n "$CONTAINER_ID" ]; then
    docker stop "$CONTAINER_ID" >/dev/null 2>&1 &
  fi
fi

# 2. Kill local processes whose cwd is under this repo
# Safety: collect PIDs first, exclude our own process tree
MY_PID=$$
lsof -d cwd 2>/dev/null | awk -v path="$REPO_ROOT" '$NF ~ "^"path {print $2}' | sort -u | while read -r pid; do
  [ "$pid" = "$MY_PID" ] && continue
  [ "$pid" = "1" ] && continue
  # Don't kill tmux server or other tmux panes
  CMD=$(ps -p "$pid" -o comm= 2>/dev/null)
  case "$CMD" in
    tmux*|bash|zsh|fish|login) continue ;;
  esac
  kill -TERM "$pid" 2>/dev/null
done

# 3. Remove state file
HASH=$(echo -n "$REPO_ROOT" | md5 -q 2>/dev/null || echo -n "$REPO_ROOT" | md5sum | cut -d' ' -f1)
rm -f "/tmp/tmux-proc-state/${HASH}.env" 2>/dev/null

exit 0
