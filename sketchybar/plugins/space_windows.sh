#!/bin/bash

if [ "$SENDER" = "aerospace_workspace_change" ]; then
  # Handle previous workspace
  if [ -n "$PREV_WORKSPACE" ]; then
    prevapps=$(aerospace list-windows --workspace "$PREV_WORKSPACE" | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')
    sketchybar --set space.$PREV_WORKSPACE drawing=on
    if [ "${prevapps}" != "" ]; then
      icon_strip=" "
      while read -r app; do
        icon_strip+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
      done <<<"${prevapps}"
      sketchybar --set space.$PREV_WORKSPACE label="$icon_strip"
    else
      sketchybar --set space.$PREV_WORKSPACE label=""
    fi
  fi

  # Handle current workspace
  if [ -n "$FOCUSED_WORKSPACE" ]; then
    apps=$(aerospace list-windows --workspace "$FOCUSED_WORKSPACE" | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')
    sketchybar --set space.$FOCUSED_WORKSPACE drawing=on
    if [ "${apps}" != "" ]; then
      icon_strip=" "
      while read -r app; do
        icon_strip+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
      done <<<"${apps}"
      sketchybar --set space.$FOCUSED_WORKSPACE label="$icon_strip"
    else
      sketchybar --set space.$FOCUSED_WORKSPACE label=""
    fi
  fi
fi
