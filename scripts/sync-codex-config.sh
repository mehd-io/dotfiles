#!/usr/bin/env bash
set -euo pipefail

target="${1:?usage: sync-codex-config.sh TARGET_CONFIG MANAGED_FRAGMENT}"
fragment="${2:?usage: sync-codex-config.sh TARGET_CONFIG MANAGED_FRAGMENT}"

if [[ ! -f "$target" || ! -r "$target" ]]; then
  echo "Codex config is missing or unreadable: $target" >&2
  exit 1
fi

if [[ -L "$target" ]]; then
  echo "Refusing to replace a symlinked Codex config: $target" >&2
  exit 1
fi

if [[ ! -f "$fragment" || ! -r "$fragment" ]]; then
  echo "Managed Codex fragment is missing or unreadable: $fragment" >&2
  exit 1
fi

target_dir=$(dirname "$target")
generated=$(mktemp "$target_dir/.config.toml.XXXXXX")
cleanup() {
  [[ -z "${generated:-}" || ! -e "$generated" ]] || rm -f -- "$generated"
}
trap cleanup EXIT HUP INT TERM

# Remove the Chrome DevTools tables managed by this repository and the legacy
# Scenario model-run auto-approval. Preserve every other local setting,
# including project trust, Scenario's server connection, and hook state.
awk '
  /^\[mcp_servers\.("chrome-devtools"|chrome-devtools)(\.tools\.[^]]+)?\][[:space:]]*$/ {
    skip = 1
    next
  }
  /^\[mcp_servers\.("scenario"|scenario)\.tools\.("model_run"|model_run)\][[:space:]]*$/ {
    skip = 1
    next
  }
  /^\[/ { skip = 0 }
  !skip { print }
' "$target" > "$generated"

printf '\n' >> "$generated"
cat "$fragment" >> "$generated"
chmod 600 "$generated"
mv -f "$generated" "$target"
generated=""
