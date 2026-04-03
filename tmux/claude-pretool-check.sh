#!/bin/bash
# PreToolUse hook (matcher: Bash) — block server-starting commands when ports are already in use.
# Reads JSON from stdin per Claude Code hook protocol.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
[ "$TOOL" != "Bash" ] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0

# Only check commands that look like they start a server
echo "$COMMAND" | grep -qE '(pnpm dev|pnpm run dev|npm run dev|npm start|next dev|next start|trigger dev|npx serve|python.*-m.*http\.server|(^|[[:space:]])node[[:space:]]+[^|&;]*server|vite|nuxt dev)' || exit 0

# Extract port from the command if specified (e.g., --port 3001)
CMD_PORT=$(echo "$COMMAND" | grep -oE '(--port|-p)\s*[0-9]+' | grep -oE '[0-9]+' | head -1)
# Default ports to check
CHECK_PORTS="${CMD_PORT:-3000}"

# Check if any of the target ports are already listening
CONFLICT=""
for PORT in $(echo "$CHECK_PORTS" | tr ',' ' '); do
  LISTENER=$(lsof -iTCP:"$PORT" -sTCP:LISTEN -P -n 2>/dev/null | tail -n +2 | head -1)
  if [ -n "$LISTENER" ]; then
    PROC_NAME=$(echo "$LISTENER" | awk '{print $1}')
    PROC_PID=$(echo "$LISTENER" | awk '{print $2}')
    CONFLICT="${CONFLICT}Port $PORT is in use by $PROC_NAME (PID $PROC_PID). "
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
