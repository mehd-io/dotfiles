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
#   ./install.sh --personalize    render private machine config from a local 1Password template
#   ./install.sh --continuity     install/link Herdr Continuity + launchd sync
#   ./install.sh --help

set -e

DOTFILES="$HOME/.dotfiles"
BACKUP_DIR="$HOME/dotfiles-backup"
LOCAL_CONFIG_DIR="$HOME/.config/dotfiles"

# --- helpers -------------------------------------------------------------

ensure_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"
  brew update
}

load_dotfiles_env() {
  local cache
  cache=$(bash "$DOTFILES/scripts/ensure-dotfiles-env.sh") || return 1
  # shellcheck disable=SC1090
  source "$cache"
}

require_single_line() {
  local name=$1
  local value=${!name:-}
  if [ -z "$value" ] || [[ "$value" == *$'\n'* ]]; then
    echo "Missing or invalid $name in the personalized environment" >&2
    return 1
  fi
}

toml_escape() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  printf '%s' "$value"
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

install_personalization() {
  echo ">>> private machine personalization"
  local template=${DOTFILES_ENV_TEMPLATE:-"$LOCAL_CONFIG_DIR/env.tpl"}
  if [ ! -r "$template" ]; then
    echo "Missing private template: $template" >&2
    echo "Copy personal/env.tpl.example there, replace the placeholder 1Password references, and retry." >&2
    return 1
  fi

  mkdir -p "$LOCAL_CONFIG_DIR"
  chmod 700 "$LOCAL_CONFIG_DIR"
  load_dotfiles_env

  require_single_line DOTFILES_REMOTE_HOST
  require_single_line DOTFILES_REMOTE_USER
  require_single_line DOTFILES_REMOTE_IDENTITY_FILE

  mkdir -p "$HOME/.ssh/config.d"
  chmod 700 "$HOME/.ssh" "$HOME/.ssh/config.d"
  local ssh_target="$HOME/.ssh/config.d/herdr-remote.conf"
  {
    printf 'Host herdr-remote\n'
    printf '  HostName %s\n' "$DOTFILES_REMOTE_HOST"
    printf '  User %s\n' "$DOTFILES_REMOTE_USER"
    printf '  IdentityFile %s\n' "$DOTFILES_REMOTE_IDENTITY_FILE"
    printf '  IdentitiesOnly yes\n'
    printf '  AddKeysToAgent yes\n'
    printf '  ServerAliveInterval 60\n'
    printf '  ServerAliveCountMax 3\n'
    printf '  RequestTTY no\n'
    printf '  RemoteCommand none\n'
  } > "$ssh_target"
  chmod 600 "$ssh_target"

  touch "$HOME/.ssh/config"
  local ssh_include='Include ~/.ssh/config.d/*.conf'
  if ! grep -Fqx "$ssh_include" "$HOME/.ssh/config"; then
    local ssh_config_tmp="$HOME/.ssh/config.personalize.tmp"
    {
      printf '%s\n\n' "$ssh_include"
      cat "$HOME/.ssh/config"
    } > "$ssh_config_tmp"
    chmod 600 "$ssh_config_tmp"
    mv "$ssh_config_tmp" "$HOME/.ssh/config"
  fi
  chmod 600 "$HOME/.ssh/config"
  echo "Private config written outside the repository; shared values remain in the temporary cache."
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
  load_dotfiles_env
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
  local config_file="$config_dir/config.toml"
  if [ -L "$config_file" ]; then
    rm "$config_file"
  fi
  local vault=${OBSIDIAN_VAULT:-"$HOME/Documents/Obsidian"}
  local repo_root=${DOTFILES_REMOTE_REPO_ROOT:-"~/repos"}
  {
    printf 'vault = "%s"\n' "$(toml_escape "$vault")"
    printf 'archive_dir = "~/.local/share/herdr-continuity/archives"\n\n'
    printf '[machines.remote]\n'
    printf 'ssh = "herdr-remote"\n'
    printf 'repo_root = "%s"\n' "$(toml_escape "$repo_root")"
  } > "$config_file"
  chmod 600 "$config_file"

  mkdir -p "$HOME/Library/LaunchAgents" "$HOME/.local/share/herdr-continuity"
  sed "s|__HOME__|$HOME|g" \
    "$DOTFILES/herdr-continuity/io.mehd.herdr-continuity-sync.plist" \
    > "$HOME/Library/LaunchAgents/io.mehd.herdr-continuity-sync.plist"
  launchctl bootout "gui/$(id -u)/io.mehd.herdr-continuity-sync" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" \
    "$HOME/Library/LaunchAgents/io.mehd.herdr-continuity-sync.plist"
}

install_full() {
  local continuity_ready=0
  install_apps
  install_toolchain
  if [ -r "${DOTFILES_ENV_TEMPLATE:-$LOCAL_CONFIG_DIR/env.tpl}" ]; then
    install_personalization
    continuity_ready=1
  else
    echo ">>> private machine personalization skipped (run ./install.sh --personalize when ready)"
  fi
  install_defaults
  install_dotfiles
  install_neovim
  install_sketchybar
  install_aerospace
  install_extras
  if (( continuity_ready )); then
    install_continuity
  else
    echo ">>> Herdr Continuity skipped (private environment is not configured)"
  fi
  echo ""
  echo "Full install done. Next steps:"
  echo "  1. Restart terminal (or source ~/.zshrc)"
  echo "  2. Log out and back in for Aerospace + menu bar changes"
  echo "  3. atuin login   # to sync shell history"
  echo "  4. op signin     # 1Password CLI for secrets injection"
}

print_usage() {
  sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
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
  --personalize) install_personalization ;;
  --continuity)  install_continuity ;;
  --help|-h)     print_usage ;;
  *)             echo "Unknown flag: $1" >&2; print_usage; exit 1 ;;
esac
