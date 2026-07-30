#!/usr/bin/env bash
# macos.sh: set macOS defaults. Apps live in the Brewfile.
# Idempotent. Comment out any line you do not want.
# Run via: ./install.sh --defaults  (or directly: ./macos.sh)

set -e

# --- 1. Settings you currently have customized (kept as-is) --------------

# Dock auto-hides; only appears when you mouse to the screen edge
defaults write com.apple.dock autohide -bool true

# Stop macOS from reordering Spaces by most recent use (required for Aerospace)
defaults write com.apple.dock mru-spaces -bool false

# Pin Dock to the left edge of the screen
defaults write com.apple.dock orientation -string "left"

# Dock icon size in pixels (small, since it auto-hides anyway)
defaults write com.apple.dock tilesize -int 43

# Auto-hide the macOS menu bar (Sketchybar replaces it)
defaults write NSGlobalDomain _HIHideMenuBar -bool true

# Finder default view = List (Nlsv); other options: icnv, clmv, glyv
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Save screenshots to ~/Documents/scratch instead of cluttering the Desktop
mkdir -p "$HOME/Documents/scratch"
defaults write com.apple.screencapture location -string "$HOME/Documents/scratch"

# Hold cmd+ctrl and click anywhere in a window to drag it (no need to grab title bar)
defaults write NSGlobalDomain NSWindowShouldDragOnGesture -bool true


# --- 2. Keyboard ---------------------------------------------------------

# Key repeat rate. 1 = fastest possible (faster than the slider min). 2 = very fast but less jittery
defaults write NSGlobalDomain KeyRepeat -int 2

# Delay before key repeat starts (lower = quicker). 15 is "Fast", default is 25
defaults write NSGlobalDomain InitialKeyRepeat -int 15


# --- 3. Text input. Disable smart substitutions (matches your no-em-dash, no-curly-quotes rule) ---

# Disable autocorrect in system text fields
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Stop macOS from auto-capitalizing the first letter of sentences
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Stop double-space from inserting a period
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Stop -- from being replaced with an em dash
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Stop straight quotes from being replaced with curly quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false


# --- 4. Finder -----------------------------------------------------------

# Always show file extensions (.txt, .md, etc) in Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files (dotfiles) in Finder. Cmd+Shift+. also toggles this
defaults write com.apple.finder AppleShowAllFiles -bool true

# Finder window title shows the full POSIX path instead of only the folder name
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Skip the "are you sure you want to change the extension?" warning when renaming
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Finder search defaults to current folder (SCcf) instead of whole Mac
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"


# --- 5. Screenshots ------------------------------------------------------

# No drop shadow on window screenshots (cmd+shift+4 then space). Tighter crops
defaults write com.apple.screencapture disable-shadow -bool true

# Default screenshot file format (already default, but explicit)
defaults write com.apple.screencapture type -string "png"


# --- 6. System hygiene ---------------------------------------------------

# Don't write .DS_Store files on network/SMB shares (they spam shared drives)
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Stop the "Use this disk for Time Machine?" prompt every time you plug in a drive
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Disable window open/close animations for a snappier feel
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

# Disable Finder's various fade/animate effects (column resize, etc)
defaults write com.apple.finder DisableAllAnimations -bool true


# --- 7. Multi-monitor (with Aerospace) -----------------------------------

# Each display gets its own Spaces (vs one Space spanning both monitors)
defaults write com.apple.spaces spans-displays -bool false


# --- 8. Spotlight --------------------------------------------------------

# Disable Spotlight search shortcut (Cmd+Space) — freed for Raycast
/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:64:enabled false" \
  "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist" 2>/dev/null || true

# Disable Spotlight window shortcut (Cmd+Option+Space)
/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:65:enabled false" \
  "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist" 2>/dev/null || true


# --- 9. Apply ------------------------------------------------------------
killall Dock Finder SystemUIServer 2>/dev/null || true
echo "Done. Some changes (menu bar, key repeat, Spotlight shortcuts) need a logout to fully apply."
