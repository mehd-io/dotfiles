echo "Installing Dependencies"
brew install --cask sf-symbols
brew install jq
brew install gh
brew tap FelixKratz/formulae
brew install sketchybar
brew install --cask font-hack-nerd-font

# sketchybar-app-font: app icons (e.g. :brave_browser:) for workspace labels
# https://github.com/kvndrsslr/sketchybar-app-font/releases/tag/v2.0.51
echo "Installing sketchybar-app-font v2.0.51..."
curl -sL -o /tmp/sketchybar-app-font.ttf \
  "https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.51/sketchybar-app-font.ttf"
mkdir -p "$HOME/Library/Fonts"
cp /tmp/sketchybar-app-font.ttf "$HOME/Library/Fonts/sketchybar-app-font.ttf"
rm -f /tmp/sketchybar-app-font.ttf
echo "Installed sketchybar-app-font to ~/Library/Fonts/"

if [ -d "$HOME/.config/sketchybar" ]; then
  cp -r $HOME/.config/sketchybar $HOME/.config/sketchybar_backup
fi
cp -r sketchybar $HOME/.config/sketchybar
brew services restart sketchybar
