#!/bin/bash

# Exit on error
set -e

echo "Starting workspace configuration..."

# Create folder structure
echo "Creating folder structure..."
mkdir -p ~/.config/warp
mkdir -p ~/.config/powerlevel10k
mkdir -p ~/.config/aerospace
mkdir -p ~/.config/catppuccin
mkdir -p ~/.config/sketchybar
mkdir -p ~/.config/borders
mkdir -p ~/.config/fonts

# Create symbolic links
echo "Creating symbolic links..."

# Remove any existing broken symlinks first
[ -L ~/.warp ] && rm ~/.warp
[ -L ~/.config/starship.toml ] && rm ~/.config/starship.toml
[ -L ~/powerlevel10k ] && rm ~/powerlevel10k
[ -L ~/.zshrc ] && rm ~/.zshrc

# Get the current dotfiles directory
DOTFILES_DIR="$PWD"

# Create new symbolic links from current dotfiles directory
if [ -d "$DOTFILES_DIR/warp" ]; then
    ln -sf "$DOTFILES_DIR/warp" ~/.config/warp
    echo "  ✓ Linked warp config"
fi

if [ -f "$DOTFILES_DIR/starship/starship.toml" ]; then
    ln -sf "$DOTFILES_DIR/starship/starship.toml" ~/.config/starship.toml
    echo "  ✓ Linked starship config"
fi

if [ -d "$DOTFILES_DIR/powerlevel10k" ]; then
    ln -sf "$DOTFILES_DIR/powerlevel10k" ~/powerlevel10k
    echo "  ✓ Linked powerlevel10k"
fi

if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
    ln -sf "$DOTFILES_DIR/zsh/.zshrc" ~/.zshrc
    echo "  ✓ Linked .zshrc"
elif [ -f "$DOTFILES_DIR/.zshrc" ]; then
    ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc
    echo "  ✓ Linked .zshrc"
fi

if [ -d "$DOTFILES_DIR/aerospace" ]; then
    for file in "$DOTFILES_DIR/aerospace"/*; do
        if [ -e "$file" ]; then
            ln -sf "$file" ~/.config/aerospace/
        fi
    done
    echo "  ✓ Linked aerospace configs"
fi

if [ -d "$DOTFILES_DIR/catppuccin" ]; then
    for file in "$DOTFILES_DIR/catppuccin"/*; do
        if [ -e "$file" ]; then
            ln -sf "$file" ~/.config/catppuccin/
        fi
    done
    echo "  ✓ Linked catppuccin configs"
fi

if [ -d "$DOTFILES_DIR/fonts" ]; then
    # Remove existing symlink or directory if it exists
    [ -L ~/.config/fonts ] && rm ~/.config/fonts
    [ -d ~/.config/fonts ] && rm -rf ~/.config/fonts
    ln -sf "$DOTFILES_DIR/fonts" ~/.config/fonts
    echo "  ✓ Linked fonts config"
fi

if [ -d "$DOTFILES_DIR/sketchybar" ]; then
    for file in "$DOTFILES_DIR/sketchybar"/*; do
        if [ -e "$file" ]; then
            ln -sf "$file" ~/.config/sketchybar/
        fi
    done
    echo "  ✓ Linked sketchybar configs"
fi

if [ -d "$DOTFILES_DIR/borders" ]; then
    for file in "$DOTFILES_DIR/borders"/*; do
        if [ -e "$file" ]; then
            ln -sf "$file" ~/.config/borders/
        fi
    done
    echo "  ✓ Linked borders configs"
fi

# Grant executable rights
echo "Setting executable permissions..."
[ -f aerospace/organize-workspaces.sh ] && chmod +x aerospace/organize-workspaces.sh
chmod +x configure_workspace.sh 2>/dev/null || true
chmod +x configure_workspace_fixed.sh 2>/dev/null || true
[ -f powerlevel10k/gitstatus/gitstatus.plugin.sh ] && chmod +x powerlevel10k/gitstatus/gitstatus.plugin.sh
[ -f powerlevel10k/gitstatus/gitstatus.prompt.sh ] && chmod +x powerlevel10k/gitstatus/gitstatus.prompt.sh
[ -f sketchybar/items/front_app.sh ] && chmod +x sketchybar/items/front_app.sh
[ -f sketchybar/plugins/aerospace.sh ] && chmod +x sketchybar/plugins/aerospace.sh
[ -f sketchybar/plugins/battery.sh ] && chmod +x sketchybar/plugins/battery.sh
[ -f sketchybar/plugins/clock.sh ] && chmod +x sketchybar/plugins/clock.sh
[ -f sketchybar/plugins/front_app.sh ] && chmod +x sketchybar/plugins/front_app.sh
[ -f sketchybar/plugins/icon_map_fn.sh ] && chmod +x sketchybar/plugins/icon_map_fn.sh
[ -f sketchybar/plugins/load_spaces.sh ] && chmod +x sketchybar/plugins/load_spaces.sh
[ -f sketchybar/plugins/neutonfoo_battery.sh ] && chmod +x sketchybar/plugins/neutonfoo_battery.sh
[ -f sketchybar/plugins/neutonfoo_clock.sh ] && chmod +x sketchybar/plugins/neutonfoo_clock.sh
[ -f sketchybar/plugins/neutonfoo_volume.sh ] && chmod +x sketchybar/plugins/neutonfoo_volume.sh
[ -f sketchybar/plugins/reinit_workspaces.sh ] && chmod +x sketchybar/plugins/reinit_workspaces.sh
[ -f sketchybar/plugins/space.sh ] && chmod +x sketchybar/plugins/space.sh
[ -f sketchybar/plugins/space_windows.sh ] && chmod +x sketchybar/plugins/space_windows.sh
[ -f sketchybar/plugins/spotify.sh ] && chmod +x sketchybar/plugins/spotify.sh
[ -f sketchybar/plugins/update_workspace_icons.sh ] && chmod +x sketchybar/plugins/update_workspace_icons.sh
[ -f sketchybar/plugins/volume.sh ] && chmod +x sketchybar/plugins/volume.sh
[ -f sketchybar/plugins/weather.sh ] && chmod +x sketchybar/plugins/weather.sh
[ -f sketchybar/plugins/workspace_monitor.sh ] && chmod +x sketchybar/plugins/workspace_monitor.sh

# Source Zsh terminal (only if it exists)
echo "Sourcing .zshrc..."
# Note: sourcing might not work as expected in a bash script
# You may need to open a new terminal for changes to take effect
source ~/.zshrc 2>/dev/null || echo "  Note: Please open a new terminal for .zshrc changes to take effect"

# Install fonts from fonts/fonts.sh
echo "Installing required fonts..."
if command -v brew &> /dev/null; then
    # Source the font configuration to know which fonts are needed
    if [ -f "$DOTFILES_DIR/fonts/fonts.sh" ]; then
        source "$DOTFILES_DIR/fonts/fonts.sh"
        echo "  Found font configuration file"
        
        # Install Homebrew tap for fonts
        echo "  Adding homebrew-cask-fonts tap..."
        brew tap homebrew/cask-fonts 2>/dev/null || true
        
        # Install JetBrainsMono Nerd Font
        echo "  Installing JetBrainsMono Nerd Font..."
        brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || echo "    JetBrainsMono Nerd Font might already be installed"
        
        # Install Hack Nerd Font
        echo "  Installing Hack Nerd Font..."
        brew install --cask font-hack-nerd-font 2>/dev/null || echo "    Hack Nerd Font might already be installed"
        
        # SF Pro is included with macOS, no need to install
        echo "  SF Pro font is included with macOS"
        
        # Install sketchybar-app-font (essential for app icons)
        echo "  Installing sketchybar-app-font..."
        # Download and install the sketchybar-app-font
        if ! ls ~/Library/Fonts/sketchybar-app-font.ttf &>/dev/null; then
            echo "    Downloading sketchybar-app-font..."
            curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/latest/download/sketchybar-app-font.ttf -o /tmp/sketchybar-app-font.ttf 2>/dev/null
            if [ -f "/tmp/sketchybar-app-font.ttf" ]; then
                mv /tmp/sketchybar-app-font.ttf ~/Library/Fonts/
                echo "    ✓ sketchybar-app-font installed successfully"
            else
                echo "    ⚠️  Failed to download sketchybar-app-font"
            fi
        else
            echo "    sketchybar-app-font already installed"
        fi
        
        echo "  ✓ Font installation complete"
    else
        echo "  Warning: fonts/fonts.sh not found, skipping font installation"
    fi
else
    echo "  Homebrew not found. Please install Homebrew first to install fonts."
fi

# Install services (check if brew is available)
echo "Installing services with Homebrew..."
read -p "Do you want to install the services (borders, sketchybar, aerospace)? [y/N] " -n 1 -r
echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        brew tap FelixKratz/formulae
        brew install borders || echo "  borders might already be installed"
        brew install sketchybar || echo "  sketchybar might already be installed"
        brew install --cask nikitabobko/tap/aerospace || echo "  aerospace might already be installed"
    fi


# Start services (only if installed)
echo "Starting services..."
if [ -d "/Applications/AeroSpace.app" ]; then
    echo "  Starting AeroSpace..."
    open -a AeroSpace 2>/dev/null || true
    sleep 2
    
    # Check if aerospace command is available and try to enable it
    if command -v aerospace &> /dev/null; then
        # Try to enable aerospace, check for accessibility permission error
        if ! aerospace enable on 2>&1 | tee /tmp/aerospace_output.txt | grep -q "Can't connect to AeroSpace server"; then
            echo "    ✓ AeroSpace enabled successfully"
        else
            echo "  Starting AeroSpace..."
            open -a AeroSpace 2>/dev/null || true
            sleep 2
            echo "    ⚠️  AeroSpace needs accessibility permissions!"
            echo "    Opening System Settings - Privacy & Security - Accessibility..."
            echo "    Please enable AeroSpace in the Accessibility settings."
            echo ""
            
            # Open System Settings at the Accessibility pane
            open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            
            # Wait for user to grant permissions
            echo "    Press Enter after you have enabled AeroSpace in Accessibility settings..."
            read -r
            
            # Try to enable aerospace again after permissions granted
            echo "    Attempting to enable AeroSpace again..."
            aerospace enable on 2>/dev/null || echo "    ⚠️  If AeroSpace still fails, try restarting AeroSpace.app"
        fi
        rm -f /tmp/aerospace_output.txt 2>/dev/null
    fi
fi

if command -v borders &> /dev/null; then
    echo "  Starting borders..."
    # Kill existing borders process if running
    pkill borders 2>/dev/null || true
    borders &
    if command -v brew &> /dev/null; then
        brew services start borders 2>/dev/null || true
    fi
fi

if command -v sketchybar &> /dev/null; then
    echo "  Starting sketchybar..."
    if command -v brew &> /dev/null; then
        brew services start sketchybar 2>/dev/null || true
    fi
fi

# Reload configs (only if services are running)
echo "Reloading configurations..."
if command -v brew &> /dev/null; then
    if brew services list 2>/dev/null | grep -q "borders.*started"; then
        brew services restart borders
        echo "  ✓ Restarted borders"
    fi
fi

if command -v aerospace &> /dev/null; then
    aerospace reload-config 2>/dev/null && echo "  ✓ Reloaded aerospace config"
fi

if command -v sketchybar &> /dev/null; then
    sketchybar --reload 2>/dev/null && echo "  ✓ Reloaded sketchybar"
fi

echo "Workspace configuration complete!"
echo ""
echo "Note: If any symbolic links failed, make sure the source files exist in:"
echo "  $DOTFILES_DIR"
echo ""
echo "You may need to open a new terminal for all changes to take effect."
