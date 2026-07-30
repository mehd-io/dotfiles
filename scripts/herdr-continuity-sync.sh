#!/usr/bin/env bash
set -euo pipefail

state_dir="$HOME/.local/share/herdr-continuity"
mkdir -p "$state_dir"
receive_mode=0
[[ "${1:-}" == receive ]] && receive_mode=1

env_file=$(bash "$HOME/.dotfiles/scripts/ensure-dotfiles-env.sh" 2>/dev/null || true)
if [[ ! -s "$env_file" ]]; then
  if (( receive_mode )); then
    echo "Continuity receive failed: private environment is unavailable" >&2
    exit 1
  fi
  exit 0
fi
# shellcheck disable=SC1090
source "$env_file"

if [[ "${HERDR_CONTINUITY_AUTO_SYNC:-0}" != 1 ]] && (( ! receive_mode )); then
  exit 0
fi

binary="${HERDR_CONTINUITY_BIN:-$HOME/.cargo/bin/herdr-continuity}"
if [[ ! -x "$binary" ]]; then
  if (( receive_mode )); then
    echo "Continuity receive failed: $binary is not installed" >&2
    exit 1
  fi
  exit 0
fi

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
