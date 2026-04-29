#!/bin/bash
# PreToolUse hook (matcher: Bash) — block server-starting commands when ports are already in use.
# Reads JSON from stdin per Claude Code hook protocol.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
[ "$TOOL" != "Bash" ] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0

# Strip quoted strings before pattern-matching so embedded text in heredocs,
# commit messages, PR bodies, grep patterns, etc. doesn't false-positive.
# (e.g. `pkill -f "next dev"` shouldn't be treated as starting Next.)
SCAN=$(echo "$COMMAND" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")

# Only check commands that look like they actually start a server. Anchored
# at start-of-line or after a shell separator so substrings like "pnpm devops"
# or "next development" don't match.
echo "$SCAN" | grep -qE '(^|[[:space:];&|]|^cd[[:space:]][^;]*;[[:space:]]*)(pnpm[[:space:]]+(dev|run[[:space:]]+dev|start)|npm[[:space:]]+(run[[:space:]]+dev|start)|yarn[[:space:]]+(dev|start)|next[[:space:]]+(dev|start)|trigger[[:space:]]+dev|npx[[:space:]]+serve|python[[:space:]]+-m[[:space:]]+http\.server|node[[:space:]]+[^|&;]*server|vite|nuxt[[:space:]]+dev)([[:space:]]|$)' || exit 0

# Resolve our working dir — Claude Code passes it via tool_input.cwd; fall
# back to $PWD for older harnesses.
CWD=$(echo "$INPUT" | jq -r '.tool_input.cwd // empty')
[ -z "$CWD" ] && CWD="$PWD"

# Extract port from the command if specified (e.g., --port 3001)
CMD_PORT=$(echo "$COMMAND" | grep -oE '(--port|-p)[[:space:]]*[0-9]+' | grep -oE '[0-9]+' | head -1)
# Default ports to check — covers Next.js (3000) plus our common alt (3100).
CHECK_PORTS="${CMD_PORT:-3000 3100}"

# Returns 0 (true) if $1 contains $2 as a prefix, in either direction. Used to
# tell whether two project trees overlap.
paths_overlap() {
  case "$1" in "$2"*) return 0 ;; esac
  case "$2" in "$1"*) return 0 ;; esac
  return 1
}

# Check if any of the target ports are already listening. We only block when
# the listener belongs to the SAME project (its CWD is in/under ours, or vice
# versa) — a Next dev server in some other repo on port 3000 is fine.
CONFLICT=""
for PORT in $(echo "$CHECK_PORTS" | tr ',' ' '); do
  LISTENER=$(lsof -iTCP:"$PORT" -sTCP:LISTEN -P -n 2>/dev/null | tail -n +2 | head -1)
  [ -z "$LISTENER" ] && continue
  PROC_NAME=$(echo "$LISTENER" | awk '{print $1}')
  PROC_PID=$(echo "$LISTENER" | awk '{print $2}')

  # Best-effort listener CWD via lsof. -F n prints filenames on lines starting
  # with 'n'; for the cwd fd that's the absolute path.
  PROC_CWD=$(lsof -p "$PROC_PID" -a -d cwd -F n 2>/dev/null | awk '/^n/{sub(/^n/,""); print; exit}')

  if [ -n "$PROC_CWD" ] && paths_overlap "$PROC_CWD" "$CWD"; then
    CONFLICT="${CONFLICT}Port $PORT is in use by $PROC_NAME (PID $PROC_PID, cwd: $PROC_CWD). "
  fi
done

[ -z "$CONFLICT" ] && exit 0

# Enrich with state file context
EXTRA=""
for STATE_FILE in /tmp/tmux-proc-state/*.env; do
  [ -f "$STATE_FILE" ] || continue
  # Check staleness (ignore files older than 60s)
  FILE_AGE=$(( $(date +%s) - $(stat -f %m "$STATE_FILE" 2>/dev/null || stat -c %Y "$STATE_FILE" 2>/dev/null || echo 0) ))
  [ "$FILE_AGE" -gt 60 ] && continue
  DC_ID=$(grep '^DEVCONTAINER_ID=' "$STATE_FILE" | cut -d= -f2)
  PROCS=$(grep '^PROCESSES=' "$STATE_FILE" | cut -d= -f2)
  REPO=$(grep '^REPO_ROOT=' "$STATE_FILE" | cut -d= -f2)
  [ -n "$DC_ID" ] && EXTRA="${EXTRA}Devcontainer running for $REPO (ID: ${DC_ID:0:12}). "
  [ -n "$PROCS" ] && EXTRA="${EXTRA}Active processes: $PROCS. "
done

# Block the command
cat <<EOF
{"decision": "block", "reason": "${CONFLICT}${EXTRA}Do NOT start another server. To interact with the running service, use curl or check its logs. To restart it, kill the existing process first (kill <PID>)."}
EOF
