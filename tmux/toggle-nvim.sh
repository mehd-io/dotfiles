#!/bin/bash
# Toggle nvim pane: kill it if running, open it if not
NVIM_PANE=$(tmux list-panes -F '#{pane_id}:#{pane_current_command}' | grep ':nvim$' | head -1 | cut -d: -f1)

if [ -n "$NVIM_PANE" ]; then
  tmux kill-pane -t "$NVIM_PANE"
else
  PANE_PATH=$(tmux display-message -p '#{pane_current_path}')
  tmux split-window -hb -l 70% -c "$PANE_PATH" "nvim +Neotree"
fi
