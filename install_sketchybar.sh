echo "Installing Dependencies"
brew install --cask sf-symbols
brew install jq
brew install gh
brew tap FelixKratz/formulae
brew install sketchybar
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v1.0.23/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf

if [ -d "$HOME/.config/sketchybar" ]; then
  cp -r $HOME/.config/sketchybar $HOME/.config/sketchybar_backup
fi
cp -r sketchybar $HOME/.config/sketchybar
brew services restart sketchybar
