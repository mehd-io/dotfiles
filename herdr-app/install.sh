#!/bin/sh
# Installs this repo's Herdr App setup: personal mods, the `mehdi` layout,
# keys, settings, programs, icons and theme. Mods are copied (not symlinked)
# and checked; the app reloads them by itself. Run again after every change.
#
#   ./install.sh            install everything
#   ./install.sh --mods     only the mods
#
# Files it replaces (keys.json, settings.json, ...) are backed up first to
# $app/.herdr-setup-backup/<timestamp>/ when they differ from the repo.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
app=${HERDR_APP_HOME:-$HOME/.config/herdr-app}
backup=$app/.herdr-setup-backup/$(date +%Y%m%d-%H%M%S)

install_file() { # repo-relative path
  src=$here/$1 dst=$app/$1
  if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
    mkdir -p "$(dirname "$backup/$1")"
    cp "$dst" "$backup/$1"
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
}

for m in "$here"/mods/*/; do
  name=$(basename "$m")
  mkdir -p "$app/mods/$name"
  # Dot folders in an installed mod are its runtime state; leave them alone.
  rsync -a --exclude '.*' "$m" "$app/mods/$name/"
  # macOS has no `timeout`; a check that can't reach the app must not hang.
  perl -e 'alarm 90; exec @ARGV' herdr-app check "$app/mods/$name"
  echo "mod $name installed"
done
[ "${1:-}" = "--mods" ] && exit 0

for f in keys.json settings.json programs.json layouts/*.json themes/*.json my-icons/*; do
  [ -f "$here/$f" ] && install_file "$f"
done
[ -d "$backup" ] && echo "previous versions saved in $backup"
[ -f "$app/layouts/layout.error" ] && { cat "$app/layouts/layout.error"; exit 1; }
echo "Installed in $app"
