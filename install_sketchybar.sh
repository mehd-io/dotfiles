echo "Installing Dependencies"
brew install --cask sf-symbols
brew install jq
brew install gh
brew tap FelixKratz/formulae
brew install sketchybar
brew install --cask font-hack-nerd-font

if [ -d "$HOME/.config/sketchybar" ]; then
  cp -r $HOME/.config/sketchybar $HOME/.config/sketchybar_backup
fi
cp -r sketchybar $HOME/.config/sketchybar
brew services restart sketchybar
