#!/usr/bin/env bash
# mdorg: switch between MotherDuck organizations.
#
# Orgs are declared in a private INI file (default ~/.config/dotfiles/mdorg.conf,
# see mdorg.conf.example). Tokens are 1Password references in that file and are
# resolved through op-env-cache.sh, so they never sit in the config on disk.
set -euo pipefail

config="${MDORG_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/mdorg.conf}"
dotfiles="${DOTFILES:-$HOME/.dotfiles}"
cache_key="mdorg"

usage() {
  cat <<'EOF'
usage: mdorg <command>

  ls [--names]             list configured orgs (never prints tokens)
  current                  show the org active in this shell
  env [org]                print export lines for an org (for eval)
  run <org> [--] <cmd...>  run one command against an org
  open [org]               open the org's app URL in the browser
  refresh                  drop cached tokens; next call re-reads 1Password

In an interactive shell, `mdorg use <org>` (or bare `mdorg` for a picker)
switches the current shell. That part is a zsh function, see zprofile.
EOF
}

die() {
  echo "mdorg: $*" >&2
  exit 1
}

# conf_get FILE SECTION KEY: print the value, or nothing when it is absent.
conf_get() {
  awk -v sec="$2" -v key="$3" '
    /^[[:space:]]*[#;]/ { next }
    /^[[:space:]]*\[/ {
      cur = $0
      sub(/^[[:space:]]*\[[[:space:]]*/, "", cur)
      sub(/[[:space:]]*\][[:space:]]*$/, "", cur)
      next
    }
    cur == sec {
      i = index($0, "=")
      if (!i) next
      k = substr($0, 1, i - 1)
      v = substr($0, i + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      if (k == key) { print v; exit }
    }
  ' "$1"
}

list_orgs() {
  awk '
    /^[[:space:]]*\[[[:space:]]*org[[:space:]]+/ {
      s = $0
      sub(/^[[:space:]]*\[[[:space:]]*org[[:space:]]+/, "", s)
      sub(/[[:space:]]*\][[:space:]]*$/, "", s)
      print s
    }
  ' "$config"
}

require_config() {
  [[ -r "$config" ]] || die "config not found: $config (copy mdorg.conf.example there)"
}

# Echo the org to act on: the argument, or [default] org.
pick_org() {
  local org="${1:-}"
  [[ -n "$org" ]] || org=$(conf_get "$config" default org)
  [[ -n "$org" ]] || die "no org given and no [default] org in $config"
  case "$org" in
    *[!A-Za-z0-9._-]*) die "invalid org name: $org" ;;
  esac
  list_orgs | grep -Fxq -- "$org" || die "unknown org '$org' (try: mdorg ls)"
  printf '%s\n' "$org"
}

cache_file_path() {
  local runtime_root="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
  printf '%s/dotfiles-op-cache-%s/%s.env\n' "${runtime_root%/}" "$(id -u)" "$cache_key"
}

# Echo the path of the config with 1Password references resolved.
resolved_config() {
  if [[ -n "${MDORG_RESOLVED:-}" ]]; then
    # Test hook: use an already resolved file instead of calling 1Password.
    printf '%s\n' "$MDORG_RESOLVED"
    return
  fi
  local account="" account_file
  account_file="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/op-account"
  if [[ -r "$account_file" ]]; then
    IFS= read -r account <"$account_file" || true
  fi
  bash "$dotfiles/scripts/op-env-cache.sh" "$config" "$cache_key" "$account" \
    || die "could not resolve tokens from 1Password (is op signed in?)"
}

# Set ORG_TOKEN, ORG_HOST and ORG_APP_URL for an org.
load_org() {
  local org="$1" resolved
  resolved=$(resolved_config)
  ORG_TOKEN=$(conf_get "$resolved" "org $org" token)
  ORG_HOST=$(conf_get "$config" "org $org" host)
  ORG_APP_URL=$(conf_get "$config" "org $org" app_url)
  [[ -n "$ORG_TOKEN" ]] || die "no token for org '$org'"
  case "$ORG_TOKEN" in
    *op://* | *'{{'*) die "token for org '$org' is still a placeholder; edit $config" ;;
  esac
}

cmd_ls() {
  require_config
  if [[ "${1:-}" == "--names" ]]; then
    list_orgs
    return
  fi
  local org default active marker
  default=$(conf_get "$config" default org)
  active="${MD_ORG:-}"
  printf '%-2s %-24s %-14s %s\n' "" ORG REGION APP_URL
  while IFS= read -r org; do
    marker=""
    [[ "$org" != "$default" ]] || marker="d"
    [[ "$org" != "$active" ]] || marker="*"
    printf '%-2s %-24s %-14s %s\n' "$marker" "$org" \
      "$(conf_get "$config" "org $org" region)" \
      "$(conf_get "$config" "org $org" app_url)"
  done < <(list_orgs)
  echo
  echo "* active in this shell, d default"
}

cmd_current() {
  if [[ -n "${MD_ORG:-}" ]]; then
    printf '%s\n' "$MD_ORG"
  else
    echo "none selected (using the login token)"
  fi
}

cmd_env() {
  require_config
  local org
  org=$(pick_org "${1:-}")
  load_org "$org"
  printf 'export motherduck_token=%q\n' "$ORG_TOKEN"
  printf 'export MOTHERDUCK_TOKEN=%q\n' "$ORG_TOKEN"
  printf 'export MD_ORG=%q\n' "$org"
  if [[ -n "$ORG_HOST" ]]; then
    printf 'export motherduck_host=%q\n' "$ORG_HOST"
  else
    echo 'unset motherduck_host'
  fi
  if [[ -n "$ORG_APP_URL" ]]; then
    printf 'export MOTHERDUCK_APP_URL=%q\n' "$ORG_APP_URL"
  else
    echo 'unset MOTHERDUCK_APP_URL'
  fi
}

cmd_run() {
  require_config
  [[ $# -ge 1 ]] || die "usage: mdorg run <org> [--] <cmd...>"
  local org
  org=$(pick_org "$1")
  shift
  [[ "${1:-}" != "--" ]] || shift
  [[ $# -ge 1 ]] || die "usage: mdorg run <org> [--] <cmd...>"
  load_org "$org"
  export motherduck_token="$ORG_TOKEN" MOTHERDUCK_TOKEN="$ORG_TOKEN" MD_ORG="$org"
  unset motherduck_host MOTHERDUCK_APP_URL
  [[ -z "$ORG_HOST" ]] || export motherduck_host="$ORG_HOST"
  [[ -z "$ORG_APP_URL" ]] || export MOTHERDUCK_APP_URL="$ORG_APP_URL"
  exec "$@"
}

cmd_open() {
  require_config
  local org url
  org=$(pick_org "${1:-${MD_ORG:-}}")
  url=$(conf_get "$config" "org $org" app_url)
  [[ -n "$url" ]] || die "org '$org' has no app_url"
  open "$url"
}

cmd_refresh() {
  rm -f -- "$(cache_file_path)"
  echo "mdorg: token cache cleared"
}

case "${1:-}" in
  ls) shift; cmd_ls "$@" ;;
  current) cmd_current ;;
  env) shift; cmd_env "$@" ;;
  run) shift; cmd_run "$@" ;;
  open) shift; cmd_open "$@" ;;
  refresh) cmd_refresh ;;
  use) die "'use' changes the current shell; it needs the mdorg zsh function from zprofile" ;;
  "" | -h | --help | help) usage ;;
  *) usage >&2; exit 2 ;;
esac
