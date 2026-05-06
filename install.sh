#!/usr/bin/env bash
# install.sh: dotfiles bootstrap. macOS-first, Linux best-effort.
# Idempotent. Run any subset via flags.
#
# Usage:
#   ./install.sh                  full install (apps + defaults + dotfiles + neovim + sketchybar + aerospace)
#   ./install.sh --full           same as no args
#   ./install.sh --apps           macOS: brew bundle from Brewfile. Linux: runs linux.sh
#   ./install.sh --defaults       macOS only: runs macos.sh. Skipped on Linux
#   ./install.sh --dotfiles       symlinks (zsh, tmux, ghostty, starship, atuin, claude, borders) + chmods
#   ./install.sh --neovim         clone LazyVim starter into ~/.config/nvim
#   ./install.sh --sketchybar     macOS only: symlink config + download font + restart service
#   ./install.sh --aerospace      macOS only: symlink aerospace.toml
#   ./install.sh --help

set -e

DOTFILES="$HOME/.dotfiles"
BACKUP_DIR="$HOME/dotfiles-backup"
OS="$(uname -s)"

mac_only() {
  # Returns 0 if on macOS, 1 otherwise (with a skip message)
  if [ "$OS" != "Darwin" ]; then
    echo ">>> $1 is macOS-only, skipping on $OS"
    return 1
  fi
  return 0
}

# --- helpers -------------------------------------------------------------

ensure_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

# --- subcommands ---------------------------------------------------------

install_apps() {
  case "$OS" in
    Darwin)
      echo ">>> apps (brew bundle)"
      ensure_brew
      brew bundle --file="$DOTFILES/Brewfile"
      ;;
    Linux)
      echo ">>> apps (linux.sh, portable subset)"
      bash "$DOTFILES/linux.sh"
      ;;
    *)
      echo "Unsupported OS: $OS. Install packages manually."
      exit 1
      ;;
  esac
}

install_defaults() {
  mac_only "macOS defaults" || return 0
  echo ">>> macOS defaults"
  bash "$DOTFILES/macos.sh"
}

install_dotfiles() {
  echo ">>> dotfiles symlinks"
  mkdir -p "$BACKUP_DIR"

  # Back up any existing real files in $HOME that match a *.symlink in dotfiles
  local linkables
  linkables=$(find -H "$DOTFILES" -maxdepth 3 -name '*.symlink')
  for file in $linkables; do
    local filename=".$(basename "$file" '.symlink')"
    local target="$HOME/$filename"
    if [ -f "$target" ] && [ ! -L "$target" ]; then
      echo "backing up $filename"
      cp "$target" "$BACKUP_DIR"
    fi
  done

  # Top-level dotfile symlinks
  ln -sfn "$DOTFILES/zsh/zshrc.symlink"          "$HOME/.zshrc"
  ln -sfn "$DOTFILES/zsh/zprofile.symlink"       "$HOME/.zprofile"
  ln -sfn "$DOTFILES/tmux/tmux.conf.symlink"     "$HOME/.tmux.conf"
  ln -sfn "$DOTFILES/tmux/tmux.conf.local.symlink" "$HOME/.tmux.conf.local"

  # ~/.config/* symlinks
  mkdir -p "$HOME/.config/borders" "$HOME/.config/ghostty" "$HOME/.config/atuin"
  ln -sfn "$DOTFILES/borders/bordersrc.symlink"  "$HOME/.config/borders/bordersrc"
  ln -sfn "$DOTFILES/ghostty/config"             "$HOME/.config/ghostty/config"
  ln -sfn "$DOTFILES/starship/starship.toml"     "$HOME/.config/starship.toml"
  ln -sfn "$DOTFILES/atuin/config.toml"          "$HOME/.config/atuin/config.toml"

  # Tmux runtime scripts
  mkdir -p "$HOME/.tmux"
  ln -sfn "$DOTFILES/tmux/pane-info.sh"  "$HOME/.tmux/pane-info.sh"
  ln -sfn "$DOTFILES/tmux/open-url.sh"   "$HOME/.tmux/open-url.sh"
  ln -sfn "$DOTFILES/tmux/log-pane.sh"   "$HOME/.tmux/log-pane.sh"
  chmod +x "$DOTFILES/tmux/"*.sh

  # Claude Code
  mkdir -p "$HOME/.claude"
  ln -sfn "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"

  # Default shell
  if [ "$SHELL" != "/bin/zsh" ]; then
    chsh -s /bin/zsh || true
  fi
}

install_neovim() {
  echo ">>> LazyVim"
  if [ ! -d "$HOME/.config/nvim" ]; then
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
  else
    echo "~/.config/nvim already exists, skipping clone"
  fi
}

install_sketchybar() {
  mac_only "Sketchybar" || return 0
  echo ">>> Sketchybar"
  ensure_brew
  # The brew formula itself is in Brewfile (felixkratz/formulae/sketchybar).
  # This step handles the custom font + config symlink + restart.

  # sketchybar-app-font: app icons (e.g. :brave_browser:) for workspace labels
  # https://github.com/kvndrsslr/sketchybar-app-font
  local font_version="v2.0.51"
  echo "Installing sketchybar-app-font $font_version"
  curl -sL -o /tmp/sketchybar-app-font.ttf \
    "https://github.com/kvndrsslr/sketchybar-app-font/releases/download/${font_version}/sketchybar-app-font.ttf"
  mkdir -p "$HOME/Library/Fonts"
  cp /tmp/sketchybar-app-font.ttf "$HOME/Library/Fonts/sketchybar-app-font.ttf"
  rm -f /tmp/sketchybar-app-font.ttf

  # Backup existing config if it is a real dir (not already a symlink)
  if [ -d "$HOME/.config/sketchybar" ] && [ ! -L "$HOME/.config/sketchybar" ]; then
    cp -r "$HOME/.config/sketchybar" "$HOME/.config/sketchybar_backup"
    rm -rf "$HOME/.config/sketchybar"
  fi
  ln -sfn "$DOTFILES/sketchybar" "$HOME/.config/sketchybar"

  brew services restart sketchybar || true
}

install_aerospace() {
  mac_only "Aerospace" || return 0
  echo ">>> Aerospace"
  # The brew cask itself is in Brewfile.
  mkdir -p "$HOME/.config/aerospace"
  if [ -f "$HOME/.config/aerospace/aerospace.toml" ] && [ ! -L "$HOME/.config/aerospace/aerospace.toml" ]; then
    cp "$HOME/.config/aerospace/aerospace.toml" "$HOME/.config/aerospace_backup.toml"
  fi
  ln -sfn "$DOTFILES/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
}

install_full() {
  install_apps
  install_defaults
  install_dotfiles
  install_neovim
  install_sketchybar
  install_aerospace
  echo ""
  echo "Full install done. Next steps:"
  echo "  1. Restart terminal (or source ~/.zshrc)"
  echo "  2. Log out and back in for Aerospace + menu bar changes"
  echo "  3. atuin login   # to sync shell history"
  echo "  4. op signin     # 1Password CLI for secrets injection"
}

print_usage() {
  sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
}

# --- main ----------------------------------------------------------------

case "${1:-}" in
  ""|--full)     install_full ;;
  --apps)        install_apps ;;
  --defaults)    install_defaults ;;
  --dotfiles)    install_dotfiles ;;
  --neovim)      install_neovim ;;
  --sketchybar)  install_sketchybar ;;
  --aerospace)   install_aerospace ;;
  --help|-h)     print_usage ;;
  *)             echo "Unknown flag: $1" >&2; print_usage; exit 1 ;;
esac
