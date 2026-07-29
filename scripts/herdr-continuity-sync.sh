#!/usr/bin/env bash
set -euo pipefail

state_dir="$HOME/.local/share/herdr-continuity"
env_file="/tmp/.herdr-continuity-env-$(id -u)"
mkdir -p "$state_dir"

# Keep continuity secrets isolated: a missing item never breaks the main shell
# environment generated from zsh/env.tpl.
if [[ ! -s "$env_file" ]] ||
   [[ $(( $(date +%s) - $(stat -f %m "$env_file" 2>/dev/null || echo 0) )) -gt 86400 ]]; then
  generated="$env_file.tmp"
  if op inject --account my.1password.com \
      -i "$HOME/.dotfiles/herdr-continuity/env.tpl" >"$generated" 2>/dev/null; then
    chmod 600 "$generated"
    mv "$generated" "$env_file"
  else
    rm -f "$generated"
  fi
fi

[[ -s "$env_file" ]] || exit 0
# shellcheck disable=SC1090
source "$env_file"

[[ "${HERDR_CONTINUITY_AUTO_SYNC:-0}" == 1 ]] || exit 0

binary="${HERDR_CONTINUITY_BIN:-$HOME/.cargo/bin/herdr-continuity}"
[[ -x "$binary" ]] || exit 0

if (( $# == 0 )); then
  current_hour=$(date +%H)
  start_hour="${HERDR_CONTINUITY_SYNC_START_HOUR:-7}"
  end_hour="${HERDR_CONTINUITY_SYNC_END_HOUR:-23}"
  if (( 10#$current_hour < start_hour || 10#$current_hour >= end_hour )); then
    exit 0
  fi
fi

if [[ "${1:-}" == push-current ]]; then
  input=$(cat)
  session_id=$(jq -r '.session_id // empty' <<<"$input")
  [[ -n "$session_id" ]] || exit 0
  set -- push-session "$session_id"
fi

if (( $# > 0 )); then
  exec "$binary" "$@"
else
  exec "$binary" sync
fi
