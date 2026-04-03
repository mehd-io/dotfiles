#!/bin/bash
# ~/.tmux/open-url.sh — extract URLs from pane border info and open in browser
PANE_PID=$(tmux display-message -p '#{pane_pid}')

# Read from cache (written by pane-info.sh every status refresh)
CACHE="/tmp/tmux-pane-info/$PANE_PID"
if [ -f "$CACHE" ]; then
  INFO=$(cat "$CACHE")
else
  # Fallback: run the script if no cache yet
  PANE_PATH=$(tmux display-message -p '#{pane_current_path}')
  INFO=$(~/.tmux/pane-info.sh "$PANE_PATH" "$PANE_PID")
fi
URLS=()
while IFS= read -r url; do
  URLS+=("$url")
done < <(echo "$INFO" | grep -oE 'https?://[^ ]+')

if [ ${#URLS[@]} -eq 0 ]; then
  echo "No URLs found for this pane."
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
