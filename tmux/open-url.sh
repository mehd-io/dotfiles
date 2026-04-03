#!/bin/bash
# ~/.dotfiles/tmux/open-url.sh — find listening ports for this repo and open in browser
# Sources: pane-info cache, proc-state file, and direct port scan

PANE_PATH=$(tmux display-message -p '#{pane_current_path}')
PANE_PID=$(tmux display-message -p '#{pane_pid}')

URLS=()

# 1. Check proc-state file for this repo (written by pane-info.sh)
REPO_ROOT=$(git -C "$PANE_PATH" rev-parse --show-toplevel 2>/dev/null)
if [ -n "$REPO_ROOT" ]; then
  HASH=$(echo -n "$REPO_ROOT" | md5 -q 2>/dev/null || echo -n "$REPO_ROOT" | md5sum | cut -d' ' -f1)
  STATE_FILE="/tmp/tmux-proc-state/${HASH}.env"
  if [ -f "$STATE_FILE" ]; then
    # Ports from state file (local processes)
    LOCAL_PORTS=$(grep '^LOCAL_PORTS=' "$STATE_FILE" | cut -d= -f2)
    for PORT in $(echo "$LOCAL_PORTS" | tr ',' ' '); do
      [ -n "$PORT" ] && URLS+=("http://localhost:$PORT")
    done
    # Ports from devcontainer
    DC_PORTS=$(grep '^DEVCONTAINER_PORTS=' "$STATE_FILE" | cut -d= -f2)
    for PORT in $(echo "$DC_PORTS" | tr ',' ' '); do
      [ -n "$PORT" ] && URLS+=("http://localhost:$PORT")
    done
  fi
fi

# 2. Also check pane-info cache for any http:// URLs (catches devcontainer IPs)
CACHE="/tmp/tmux-pane-info/$PANE_PID"
if [ -f "$CACHE" ]; then
  while IFS= read -r url; do
    URLS+=("$url")
  done < <(cat "$CACHE" | grep -oE 'https?://[^ ]+')
fi

# 3. Fallback: scan common dev ports if nothing found yet
if [ ${#URLS[@]} -eq 0 ]; then
  for PORT in 3000 3001 3002 4000 5173 8000 8080; do
    if lsof -iTCP:"$PORT" -sTCP:LISTEN -P -n &>/dev/null; then
      URLS+=("http://localhost:$PORT")
    fi
  done
fi

# Deduplicate
URLS=($(printf '%s\n' "${URLS[@]}" | sort -u))

if [ ${#URLS[@]} -eq 0 ]; then
  echo "No listening ports found."
  read -n1 -p "Press any key..."
  exit 0
fi

# Single URL — open directly
if [ ${#URLS[@]} -eq 1 ]; then
  open "${URLS[0]}"
  exit 0
fi

# Multiple URLs — j/k navigable list
SEL=0
draw() {
  printf '\033[H\033[J'  # clear screen
  echo "Open URL (j/k navigate, Enter select, q quit)"
  echo ""
  for i in "${!URLS[@]}"; do
    if [ "$i" -eq "$SEL" ]; then
      printf '  \033[7m %s \033[0m\n' "${URLS[$i]}"
    else
      printf '   %s\n' "${URLS[$i]}"
    fi
  done
}

tput civis 2>/dev/null  # hide cursor
draw
while true; do
  read -rsn1 KEY
  case "$KEY" in
    j) (( SEL < ${#URLS[@]} - 1 )) && (( SEL++ )) ;;
    k) (( SEL > 0 )) && (( SEL-- )) ;;
    "") open "${URLS[$SEL]}"; break ;;  # Enter
    q) break ;;
  esac
  draw
done
tput cnorm 2>/dev/null  # restore cursor
