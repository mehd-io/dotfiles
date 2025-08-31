#!/bin/bash

# Source Catppuccin colors
source "$HOME/.config/catppuccin/catppuccin-mocha.sh"

# Load font configurations
source "$HOME/.config/fonts/fonts.sh"

CONFIG_DIR="$HOME/.config/sketchybar"

# Function to initialize workspace items
reinit_workspaces() {
  # Check if aerospace is available
  if ! command -v aerospace &> /dev/null; then
    echo "Aerospace not found"
    return 1
  fi
  
  # Wait a moment for aerospace to be ready (if just started)
  local max_attempts=10
  local attempt=0
  while [ $attempt -lt $max_attempts ]; do
    if aerospace list-monitors --format "%{monitor-appkit-nsscreen-screens-id}" &>/dev/null; then
      break
    fi
    sleep 0.5
    ((attempt++))
  done
  
  # Remove any existing space items first to avoid duplicates
  for sid in {1..10}; do
    sketchybar --remove space.$sid &>/dev/null
  done
  
  # Get all unique workspaces across all monitors
  all_workspaces=$(aerospace list-workspaces --all 2>/dev/null | sort -u)
  
  # Add all workspaces without display association so they appear on all displays
  for sid in $all_workspaces; do
    sketchybar --add item space.$sid left \
      --subscribe space.$sid aerospace_workspace_change \
      --set space.$sid \
      drawing=on \
      background.color=$CAT_SURFACE0_TRANSPARENT \
      background.corner_radius=5 \
      background.drawing=on \
      background.border_color=$CAT_OVERLAY2 \
      background.border_width=0 \
      background.height=25 \
      icon="$sid" \
      icon.padding_left=10 \
      icon.shadow.distance=4 \
      icon.shadow.color=$CAT_CRUST \
      label.font="$FONT_SKETCHYBAR_APP_16" \
      label.padding_right=20 \
      label.padding_left=0 \
      label.y_offset=-1 \
      label.shadow.drawing=off \
      label.shadow.color=$CAT_CRUST \
      label.shadow.distance=4 \
      click_script="aerospace workspace $sid" \
      script="$CONFIG_DIR/plugins/aerospace.sh $sid"
  done
  
  # Load Icons on startup for all workspaces
  for sid in $all_workspaces; do
    apps=$(aerospace list-windows --workspace "$sid" 2>/dev/null | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')
    
    sketchybar --set space.$sid drawing=on
    
    icon_strip=" "
    if [ "${apps}" != "" ]; then
      while read -r app; do
        icon_strip+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
      done <<<"${apps}"
    else
      icon_strip=""
    fi
    sketchybar --set space.$sid label="$icon_strip"
  done
  
  # Trigger an update
  focused_workspace=$(aerospace list-workspaces --focused 2>/dev/null || echo "1")
  sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$focused_workspace"
  
  # Reposition front_app after reinit
  local workspaces=$(sketchybar --query bar | grep -o 'space\.[0-9]*' | sort -V)
  local last_workspace=$(echo "$workspaces" | tail -1)
  
  if [ -n "$last_workspace" ]; then
    sketchybar --move front_app after "$last_workspace"
  fi
}

# Run the reinitialization
reinit_workspaces
