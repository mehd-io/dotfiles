#!/usr/bin/env bash
set -euo pipefail

template="${DOTFILES_ENV_TEMPLATE:-$HOME/.config/dotfiles/env.tpl}"
cache="${DOTFILES_ENV_CACHE:-/tmp/.dotfiles-env-$(id -u)}"
ttl="${DOTFILES_ENV_CACHE_TTL_SECONDS:-259200}"

if [[ ! -r "$template" ]]; then
  echo "Missing private template: $template" >&2
  exit 1
fi

refresh=0
[[ "${DOTFILES_ENV_REFRESH:-0}" == 1 ]] && refresh=1
if [[ ! -s "$cache" ]]; then
  refresh=1
elif [[ $(( $(date +%s) - $(stat -f %m "$cache" 2>/dev/null || echo 0) )) -gt "$ttl" ]]; then
  refresh=1
fi

if (( refresh )); then
  generated="$cache.$$"
  args=(inject -i "$template")
  [[ -n "${OP_ACCOUNT:-}" ]] && args+=(--account "$OP_ACCOUNT")
  umask 077
  if op "${args[@]}" > "$generated" 2>/dev/null; then
    chmod 600 "$generated"
    mv "$generated" "$cache"
  else
    rm -f "$generated"
    exit 1
  fi
fi

chmod 600 "$cache"
printf '%s\n' "$cache"
