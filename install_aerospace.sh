brew install --cask nikitabobko/tap/aerospace
mkdir -p $HOME/.config/aerospace
if [ -f "$HOME/.config/aerospace/aerospace.toml" ]; then
  cp $HOME/.config/aerospace/aerospace.toml $HOME/.config/aerospace_backup
fi
ln -sf "$PWD/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"

