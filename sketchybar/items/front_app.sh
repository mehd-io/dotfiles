#!/bin/sh

# Load font configurations
source "$HOME/.config/fonts/fonts.sh"

front_app=(
  label.font="$FONT_JETBRAINS_BLACK_12"
  icon.background.drawing=on
  display=active
  script="$PLUGIN_DIR/front_app.sh"
  click_script="open -a 'Mission Control'"
)

# Function to position front_app after the last workspace
position_front_app() {
  # Get all workspace items sorted numerically
  local workspaces=$(sketchybar --query bar | grep -o 'space\.[0-9]*' | sort -V)
  local last_workspace=$(echo "$workspaces" | tail -1)
  
  if [ -n "$last_workspace" ]; then
    sketchybar --move front_app after "$last_workspace"
  fi
}

# Add front_app item
sketchybar --add item front_app left         \
           --set front_app "${front_app[@]}" \
           --subscribe front_app front_app_switched

# Position it after the last workspace
position_front_app

