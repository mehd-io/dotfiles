#!/bin/bash
printf '\033]2;logs\033\\'  # Set pane title for toggle detection
DIR=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null || pwd)
cd "$DIR"

OPTIONS=()
[ -f docker-compose.yml ] || [ -f docker-compose.yaml ] || [ -f compose.yml ] && OPTIONS+=("docker compose logs -f")
[ -d logs ] && OPTIONS+=("tail -f logs/*.log")
ls /tmp/*.log 2>/dev/null | head -1 >/dev/null && OPTIONS+=("tail -f /tmp/*.log")
OPTIONS+=("custom command")

if [ ${#OPTIONS[@]} -eq 1 ]; then
  eval "${OPTIONS[0]}"
elif command -v fzf &>/dev/null; then
  CHOICE=$(printf '%s\n' "${OPTIONS[@]}" | fzf --prompt="Log source> ")
  [ "$CHOICE" = "custom command" ] && read -p "Command: " CHOICE
  [ -n "$CHOICE" ] && eval "$CHOICE" || echo "No selection" && read
else
  select CHOICE in "${OPTIONS[@]}"; do
    [ "$CHOICE" = "custom command" ] && read -p "Command: " CHOICE
    [ -n "$CHOICE" ] && eval "$CHOICE"
    break
  done
fi
