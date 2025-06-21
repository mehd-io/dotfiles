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

# Assigning spaces to monitors dynamically for multiple screen setups
monitor_index=1
for monitor in $(aerospace list-monitors --format "%{monitor-appkit-nsscreen-screens-id}"); do
  for sid in $(aerospace list-workspaces --monitor "$monitor"); do
    sketchybar --add item space.$sid left \
      --set space.$sid display="$monitor_index" \
      --subscribe space.$sid aerospace_workspace_change \
      --set space.$sid \
      drawing=on \
      background.color=0x44ffffff \
      background.corner_radius=5 \
      background.drawing=on \
      background.border_color=0xAAFFFFFF \
      background.border_width=0 \
      background.height=25 \
      icon="$sid" \
      icon.padding_left=10 \
      icon.shadow.distance=4 \
      icon.shadow.color=0xA0000000 \
      label.font="sketchybar-app-font:Regular:16.0" \
      label.padding_right=20 \
      label.padding_left=0 \
      label.y_offset=-1 \
      label.shadow.drawing=off \
      label.shadow.color=0xA0000000 \
      label.shadow.distance=4 \
      click_script="aerospace workspace $sid" \
      script="$CONFIG_DIR/plugins/aerospace.sh $sid"
  done
  monitor_index=$((monitor_index + 1))
done
