#!/bin/bash
# Print the app name of every window AeroSpace reports on workspace $1,
# skipping windows whose owning process no longer exists. AeroSpace can keep
# ghost windows for quit apps after long uptimes; without this filter they
# show up as stale icons in the bar.

sid="$1"
[ -z "$sid" ] && exit 1

aerospace list-windows --workspace "$sid" --format "%{app-pid}|%{app-name}" 2>/dev/null |
while IFS='|' read -r pid app; do
  pid="${pid// /}"
  app="${app## }"; app="${app%% }"
  [ -z "$pid" ] && continue
  kill -0 "$pid" 2>/dev/null || continue
  printf '%s\n' "$app"
done
