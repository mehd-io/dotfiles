#!/usr/bin/env bash
set -euo pipefail

template="${1:?usage: op-env-cache.sh TEMPLATE CACHE_KEY [ACCOUNT]}"
cache_key="${2:?usage: op-env-cache.sh TEMPLATE CACHE_KEY [ACCOUNT]}"
op_account="${3:-}"
cache_ttl="${OP_ENV_CACHE_TTL:-86400}"

case "$cache_key" in
  *[!A-Za-z0-9._-]*)
    echo "Invalid 1Password cache key" >&2
    exit 2
    ;;
esac

case "$cache_ttl" in
  ''|*[!0-9]*)
    echo "Invalid 1Password cache TTL" >&2
    exit 2
    ;;
esac

if [[ ! -r "$template" ]]; then
  echo "1Password template is missing: $template" >&2
  exit 1
fi

if ! command -v op >/dev/null 2>&1; then
  echo "1Password CLI is unavailable" >&2
  exit 1
fi

runtime_root="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
cache_dir="$runtime_root/dotfiles-op-cache-$(id -u)"
cache_file="$cache_dir/$cache_key.env"

umask 077
if [[ ! -d "$runtime_root" || -L "$runtime_root" ]]; then
  echo "Unsafe runtime directory: $runtime_root" >&2
  exit 1
fi
if [[ -L "$cache_dir" ]]; then
  echo "Unsafe 1Password cache directory" >&2
  exit 1
fi
mkdir -p "$cache_dir"
chmod 700 "$cache_dir"

expected_owner=$(id -u)
cache_owner=$(stat -f %u "$cache_dir" 2>/dev/null || stat -c %u "$cache_dir" 2>/dev/null || echo unknown)
if [[ "$cache_owner" != "$expected_owner" ]]; then
  echo "1Password cache directory has the wrong owner" >&2
  exit 1
fi

if [[ -L "$cache_file" ]]; then
  echo "Unsafe 1Password cache file" >&2
  exit 1
fi
[[ ! -f "$cache_file" ]] || chmod 600 "$cache_file"

now=$(date +%s)
mtime=0
if [[ -f "$cache_file" ]]; then
  mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0)
fi

generated=""
cleanup() {
  [[ -z "$generated" || ! -e "$generated" ]] || rm -f -- "$generated"
}
trap cleanup EXIT HUP INT TERM

if [[ ! -s "$cache_file" ]] || (( mtime > now || now - mtime > cache_ttl )); then
  generated=$(mktemp "$cache_dir/$cache_key.env.tmp.XXXXXX")
  op_args=(inject -i "$template")
  [[ -z "$op_account" ]] || op_args+=(--account "$op_account")
  if op "${op_args[@]}" >"$generated" 2>/dev/null; then
    chmod 600 "$generated"
    mv -f "$generated" "$cache_file"
    generated=""
  else
    rm -f -- "$generated" "$cache_file"
    generated=""
    echo "1Password injection failed for $template" >&2
    exit 1
  fi
fi

printf '%s\n' "$cache_file"
