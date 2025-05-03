#!/bin/bash

if [ "$SENDER" = "aerospace_workspace_change" ]; then
  # Get all visible workspaces
  visible_workspaces=$(aerospace list-workspaces --format "%{id} %{workspace-is-visible}" | grep "true" | awk '{print $1}')
  
  # Update only visible workspaces
  for workspace in $visible_workspaces; do
    is_focused=$(aerospace list-workspaces --format "%{id} %{workspace-is-focused}" | grep "^$workspace " | awk '{print $2}')
    apps=$(aerospace list-windows --workspace "$workspace" | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')
    
    sketchybar --set space.$workspace drawing=on
    
    if [ "${apps}" != "" ]; then
      icon_strip=" "
      while read -r app; do
        icon_strip+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
      done <<<"${apps}"
      sketchybar --set space.$workspace label="$icon_strip"
    else
      sketchybar --set space.$workspace label=""
    fi
  done
fi
