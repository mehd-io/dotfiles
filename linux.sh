#!/usr/bin/env bash
# linux.sh: best-effort install of the portable CLI subset on Linux.
#
# Scope: only the cross-platform shell tooling. macOS-only items (Aerospace,
# Sketchybar, Hiddenbar, Stats, screencapture defaults, etc.) are skipped.
# Use install.sh --dotfiles afterwards to symlink configs.
#
# Tested loosely on Debian/Ubuntu (apt), Fedora (dnf), Arch (pacman).
# Other distros: read this file and adapt the package names.

set -e

# --- Detect package manager ----------------------------------------------

if command -v apt-get >/dev/null 2>&1; then
  PM=apt
elif command -v dnf >/dev/null 2>&1; then
  PM=dnf
elif command -v pacman >/dev/null 2>&1; then
  PM=pacman
else
  echo "No supported package manager (apt, dnf, pacman). Install packages manually."
  exit 1
fi
echo ">>> Detected: $PM"

# --- Distro packages -----------------------------------------------------
# Same brew formulae as Brewfile, where a distro package exists.
# Names differ per distro; grouped accordingly.

case "$PM" in
  apt)
    sudo apt-get update
    sudo apt-get install -y \
      neovim tmux tree wget curl zsh bash git build-essential \
      jq fd-find ripgrep fzf zoxide \
      ffmpeg imagemagick poppler-utils p7zip-full \
      aria2 rclone yt-dlp mkvtoolnix \
      gh
    # On Debian/Ubuntu, fd binary is fdfind. Symlink to fd for parity with macOS.
    if command -v fdfind >/dev/null && ! command -v fd >/dev/null; then
      sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
    fi
    ;;

  dnf)
    sudo dnf install -y \
      neovim tmux tree wget curl zsh bash git gcc-c++ make \
      jq fd-find ripgrep fzf zoxide \
      ffmpeg ImageMagick poppler-utils p7zip p7zip-plugins \
      aria2 rclone yt-dlp mkvtoolnix \
      gh
    ;;

  pacman)
    sudo pacman -S --needed --noconfirm \
      neovim tmux tree wget curl zsh bash git base-devel \
      jq fd ripgrep fzf zoxide \
      ffmpeg imagemagick poppler 7zip \
      aria2 rclone yt-dlp mkvtoolnix \
      github-cli
    ;;
esac

# --- Tools without reliable distro packages: install via official scripts ---

# Starship prompt
if ! command -v starship >/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Atuin shell history
if ! command -v atuin >/dev/null; then
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi

# Yazi: requires Rust on most distros. Skip if cargo missing.
if ! command -v yazi >/dev/null; then
  if command -v cargo >/dev/null; then
    cargo install --locked yazi-fm yazi-cli
  else
    echo "Skipping yazi (no cargo found). Install rustup first if you want it."
  fi
fi

echo ""
echo ">>> Linux portable subset installed."
echo "Skipped (macOS-only): aerospace, sketchybar, hiddenbar, stats, ghostty cask, screencapture defaults"
echo "Skipped (manual on Linux): duckdb (binary download), neonctl (npm), libpq, ollama, GUI casks"
echo "Next: ./install.sh --dotfiles  to symlink shell configs."
