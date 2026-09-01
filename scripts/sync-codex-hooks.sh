#!/usr/bin/env bash
set -euo pipefail

target="${1:?usage: sync-codex-hooks.sh TARGET_HOOKS MANAGED_FRAGMENT}"
fragment="${2:?usage: sync-codex-hooks.sh TARGET_HOOKS MANAGED_FRAGMENT}"

if [[ ! -f "$fragment" || ! -r "$fragment" ]]; then
  echo "Managed Codex hook fragment is missing or unreadable: $fragment" >&2
  exit 1
fi

target_dir=$(dirname "$target")
mkdir -p "$target_dir"
generated=$(mktemp "$target_dir/.hooks.json.XXXXXX")
cleanup() {
  [[ -z "${generated:-}" || ! -e "$generated" ]] || rm -f -- "$generated"
  [[ -z "${generated:-}" || ! -e "$generated.source" ]] || rm -f -- "$generated.source"
}
trap cleanup EXIT HUP INT TERM

if [[ -e "$target" && ! -f "$target" ]]; then
  echo "Refusing to replace a non-regular Codex hooks path: $target" >&2
  exit 1
fi

source_json="$target"
if [[ ! -f "$source_json" ]]; then
  printf '%s\n' '{"hooks":{}}' > "$generated.source"
  source_json="$generated.source"
fi

jq --slurpfile managed "$fragment" '
  def is_managed_group:
    any(.hooks[]?;
      ((.command // "") | contains("herdr_auto_name.py")) or
      ((.command // "") | contains("herdr-continuity-sync.sh title-hook"))
    );
  .hooks //= {} |
  reduce (($managed[0].hooks // {}) | to_entries[]) as $entry (.;
    .hooks[$entry.key] = (
      [(.hooks[$entry.key] // [])[] | select(is_managed_group | not)]
      + $entry.value
    )
  )
' "$source_json" > "$generated"

rm -f -- "$generated.source"
chmod 600 "$generated"
mv -f "$generated" "$target"
generated=""
