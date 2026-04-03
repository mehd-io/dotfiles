#!/bin/sh

# Annotate Highlighter Status Plugin for SketchyBar
# Shows whether the highlighter tool is selected in Annotate app
#
# NOTE: Annotate doesn't expose tool state via standard macOS APIs.
# This plugin uses heuristics to detect when Annotate is active.
# Current implementation shows highlighter as "active" when:
# - Annotate is running AND
# - Annotate is the frontmost application (overlay is likely active)

is_annotate_running() {
    pgrep -x Annotate > /dev/null 2>&1
}

is_annotate_frontmost() {
    osascript -e 'tell application "System Events" to return (name of first application process whose frontmost is true) is "Annotate"' 2>/dev/null | grep -q "true"
}

# Check if highlighter tool is likely selected
# This is a heuristic since Annotate doesn't expose tool state
is_highlighter_selected() {
    if ! is_annotate_running; then
        return 1
    fi
    
    # When Annotate is frontmost, it's likely in annotation mode
    # We assume highlighter might be active (though we can't confirm which tool)
    is_annotate_frontmost
}

# Main function to update SketchyBar
update_sketchybar() {
    local name="${NAME:-annotate_highlighter}"
    local icon="󰨳"  # Highlighter icon from Nerd Fonts
    local icon_color="0x44FFFFFF"  # Dimmed when not active
    
    if is_annotate_running; then
        if is_highlighter_selected; then
            icon_color="0xFFFFFFFF"  # Bright white when Annotate is active (highlighter likely available)
        else
            icon_color="0x66FFFFFF"  # Medium brightness when app is running but not frontmost
        fi
    else
        icon_color="0x44FFFFFF"  # Dimmed when app is not running
    fi
    
    # Update SketchyBar
    sketchybar --set "$name" icon="$icon" icon.color="$icon_color"
}

# Run the update
update_sketchybar
