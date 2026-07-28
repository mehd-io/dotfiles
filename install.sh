#!/usr/bin/env bash
# install.sh: dotfiles bootstrap for macOS.
# Idempotent. Run any subset via flags.
#
# Usage:
#   ./install.sh                  full install (apps + defaults + dotfiles + neovim + sketchybar + aerospace)
#   ./install.sh --full           same as no args
#   ./install.sh --apps           brew bundle from Brewfile
#   ./install.sh --defaults       macOS defaults (runs macos.sh)
#   ./install.sh --dotfiles       symlinks (zsh, tmux, ghostty, starship, atuin, claude, borders) + chmods
#   ./install.sh --neovim         clone LazyVim starter into ~/.config/nvim
#   ./install.sh --sketchybar     symlink config + download font + restart service
#   ./install.sh --aerospace      symlink aerospace.toml
#   ./install.sh --extras         tools not on brew (duckman)
#   ./install.sh --toolchain      install pinned runtimes with mise
#   ./install.sh --continuity     install/link Herdr Continuity + launchd sync
#   ./install.sh --help

set -e

DOTFILES="$HOME/.dotfiles"
BACKUP_DIR="$HOME/dotfiles-backup"

# --- helpers -------------------------------------------------------------

ensure_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"
  brew update
}

# --- subcommands ---------------------------------------------------------

install_apps() {
  echo ">>> apps (brew bundle)"
  ensure_brew
  # --no-lock: skip Brewfile.lock.json generation
  # Allow partial failures (a single cask download blip won't abort the whole run)
  brew bundle --file="$DOTFILES/Brewfile" --no-lock || {
    echo ""
    echo "WARNING: brew bundle had failures. Run 'brew bundle --file=~/.dotfiles/Brewfile' to retry failed items."
  }
}

install_defaults() {
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
  ln -sfn "$DOTFILES/zsh/zshrc.symlink"            "$HOME/.zshrc"
  ln -sfn "$DOTFILES/zsh/zprofile.symlink"         "$HOME/.zprofile"
  ln -sfn "$DOTFILES/tmux/tmux.conf.symlink"       "$HOME/.tmux.conf"
  ln -sfn "$DOTFILES/tmux/tmux.conf.local.symlink" "$HOME/.tmux.conf.local"

  # ~/.config/* symlinks
  mkdir -p "$HOME/.config/borders" "$HOME/.config/ghostty" "$HOME/.config/atuin"
  ln -sfn "$DOTFILES/borders/bordersrc.symlink" "$HOME/.config/borders/bordersrc"
  ln -sfn "$DOTFILES/ghostty/config"            "$HOME/.config/ghostty/config"
  ln -sfn "$DOTFILES/starship/starship.toml"    "$HOME/.config/starship.toml"
  ln -sfn "$DOTFILES/atuin/config.toml"         "$HOME/.config/atuin/config.toml"

  # Tmux runtime scripts
  mkdir -p "$HOME/.tmux"
  ln -sfn "$DOTFILES/tmux/pane-info.sh" "$HOME/.tmux/pane-info.sh"
  ln -sfn "$DOTFILES/tmux/open-url.sh"  "$HOME/.tmux/open-url.sh"
  ln -sfn "$DOTFILES/tmux/log-pane.sh"  "$HOME/.tmux/log-pane.sh"
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
  echo ">>> Aerospace"
  # The brew cask itself is in Brewfile (nikitabobko/tap/aerospace).
  mkdir -p "$HOME/.config/aerospace"
  if [ -f "$HOME/.config/aerospace/aerospace.toml" ] && [ ! -L "$HOME/.config/aerospace/aerospace.toml" ]; then
    cp "$HOME/.config/aerospace/aerospace.toml" "$HOME/.config/aerospace_backup.toml"
  fi
  ln -sfn "$DOTFILES/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
}

install_extras() {
  echo ">>> extras (not on brew)"
  # duckman: DuckDB version manager — installs to ~/.local/bin/duckman
  if ! command -v duckman >/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/NiclasHaderer/duckdb-version-manager/main/install.sh)"
  else
    echo "duckman already installed, skipping"
  fi
}

install_toolchain() {
  echo ">>> pinned developer toolchain (mise)"
  ensure_brew
  mkdir -p "$HOME/.config/mise"
  ln -sfn "$DOTFILES/mise/mise.toml" "$HOME/.config/mise/config.toml"
  ln -sfn "$DOTFILES/mise/mise.lock" "$HOME/.config/mise/mise.lock"
  mise trust "$DOTFILES/mise/mise.toml"
  mise install -C "$DOTFILES/mise"
}

install_continuity() {
  echo ">>> Herdr Continuity"
  local repo="$HOME/repos/mehd-io/herdr-continuity"
  if [ ! -d "$repo/.git" ]; then
    git clone git@github.com:mehd-io/herdr-continuity.git "$repo"
  fi
  (
    cd "$repo"
    mise trust mise.toml
    mise install
    mise exec -- cargo install --locked --path .
  )
  herdr plugin link "$repo"
  local config_dir
  config_dir=$(herdr plugin config-dir mehd-io.continuity)
  mkdir -p "$config_dir"
  ln -sfn "$DOTFILES/herdr-continuity/config.toml" "$config_dir/config.toml"

  mkdir -p "$HOME/Library/LaunchAgents" "$HOME/.local/share/herdr-continuity"
  sed "s|__HOME__|$HOME|g" \
    "$DOTFILES/herdr-continuity/io.mehd.herdr-continuity-sync.plist" \
    > "$HOME/Library/LaunchAgents/io.mehd.herdr-continuity-sync.plist"
  launchctl bootout "gui/$(id -u)/io.mehd.herdr-continuity-sync" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" \
    "$HOME/Library/LaunchAgents/io.mehd.herdr-continuity-sync.plist"
}

install_full() {
  install_apps
  install_toolchain
  install_defaults
  install_dotfiles
  install_neovim
  install_sketchybar
  install_aerospace
  install_extras
  install_continuity
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
  --extras)      install_extras ;;
  --toolchain)   install_toolchain ;;
  --continuity)  install_continuity ;;
  --help|-h)     print_usage ;;
  *)             echo "Unknown flag: $1" >&2; print_usage; exit 1 ;;
esac
