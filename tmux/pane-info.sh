#!/bin/bash
# ~/.tmux/pane-info.sh <pane_current_path> <pane_pid>
PANE_PATH="$1"
PANE_PID="$2"

# Full branch name
BRANCH=$(cd "$PANE_PATH" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "-")

# Repo root (for state file keying)
REPO_ROOT=$(cd "$PANE_PATH" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)

# --- Recursive descendant discovery ---
get_descendants() {
  local pid=$1
  local depth=${2:-0}
  [ "$depth" -gt 10 ] && return  # safety limit
  local kids=$(pgrep -P "$pid" 2>/dev/null)
  for k in $kids; do
    echo "$k"
    get_descendants "$k" $((depth + 1))
  done
}

ALL_PIDS="$PANE_PID $(get_descendants "$PANE_PID" | tr '\n' ' ')"

# Find listening ports from all descendant processes
PORTS=""
PROC_LIST=""
if [ -n "$ALL_PIDS" ]; then
  PID_PATTERN=$(echo "$ALL_PIDS" | tr ' ' '\n' | sort -u | tr '\n' ',' | sed 's/,$//')
  # Get listening sockets with process info
  while IFS= read -r line; do
    PID=$(echo "$line" | awk '{print $2}')
    CMD=$(echo "$line" | awk '{print $1}')
    ADDR=$(echo "$line" | awk '{print $9}')
    PORT=$(echo "$ADDR" | grep -oE '[0-9]+$')
    # Check if this PID is in our descendant list
    if echo ",$PID_PATTERN," | grep -q ",$PID,"; then
      PORTS="${PORTS}${CMD}:${ADDR} "
      [ -n "$PORT" ] && PROC_LIST="${PROC_LIST}${CMD}:${PORT},"
    fi
  done < <(lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null | tail -n +2)
fi

# Find devcontainer: match pane path to a running devcontainer's local_folder
DC_LINKS=""
DC_ID=""
DC_PORTS=""
if command -v docker &>/dev/null; then
  CHECK_PATH="$PANE_PATH"
  while [ "$CHECK_PATH" != "/" ]; do
    CONTAINER_ID=$(docker ps -q --filter "label=devcontainer.local_folder=$CHECK_PATH" 2>/dev/null | head -1)
    if [ -n "$CONTAINER_ID" ]; then
      DC_ID="$CONTAINER_ID"
      # Check for host-mapped ports first
      MAPPED=$(docker port "$CONTAINER_ID" 2>/dev/null | awk -F'(/tcp| -> )' '{print $1}' | sort -un)
      if [ -n "$MAPPED" ]; then
        DC_LINKS=$(echo "$MAPPED" | awk '{printf "http://localhost:%s ", $1}')
        DC_PORTS=$(echo "$MAPPED" | tr '\n' ',' | sed 's/,$//')
      else
        # No host mapping — use container IP + listening ports inside
        CONTAINER_IP=$(docker inspect "$CONTAINER_ID" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)
        if [ -n "$CONTAINER_IP" ]; then
          INSIDE=$(docker exec "$CONTAINER_ID" ss -tlnp 2>/dev/null | awk 'NR>1 {split($4,a,":"); print a[length(a)]}' | sort -un)
          if [ -n "$INSIDE" ]; then
            DC_LINKS=$(echo "$INSIDE" | awk -v ip="$CONTAINER_IP" '{printf "http://%s:%s ", ip, $1}')
            DC_PORTS=$(echo "$INSIDE" | tr '\n' ',' | sed 's/,$//')
          fi
        fi
      fi
      break
    fi
    CHECK_PATH=$(dirname "$CHECK_PATH")
  done
fi

# Combine display output
INFO="$BRANCH"
[ -n "$PORTS" ] && INFO="$INFO | $PORTS"
[ -n "$DC_LINKS" ] && INFO="$INFO | dc $DC_LINKS"

# Cache for instant URL lookup by open-url.sh
CACHE_DIR="/tmp/tmux-pane-info"
mkdir -p "$CACHE_DIR"
echo "$INFO" > "$CACHE_DIR/$PANE_PID"

# --- Write machine-readable state file for Claude and cleanup scripts ---
if [ -n "$REPO_ROOT" ]; then
  STATE_DIR="/tmp/tmux-proc-state"
  mkdir -p "$STATE_DIR"
  HASH=$(echo -n "$REPO_ROOT" | md5 -q 2>/dev/null || echo -n "$REPO_ROOT" | md5sum | cut -d' ' -f1)
  STATE_FILE="$STATE_DIR/${HASH}.env"

  # Collect local listening ports (just port numbers)
  LOCAL_PORTS=$(echo "$PROC_LIST" | tr ',' '\n' | grep -oE '[0-9]+$' | sort -u | tr '\n' ',' | sed 's/,$//')

  # Atomic write via temp file
  TMP_STATE=$(mktemp "$STATE_DIR/.tmp.XXXXXX")
  cat > "$TMP_STATE" <<EOF
PANE_PATH=$PANE_PATH
REPO_ROOT=$REPO_ROOT
BRANCH=$BRANCH
LOCAL_PORTS=$LOCAL_PORTS
DEVCONTAINER_ID=$DC_ID
DEVCONTAINER_PORTS=$DC_PORTS
PROCESSES=$(echo "$PROC_LIST" | sed 's/,$//')
TIMESTAMP=$(date +%s)
EOF
  mv "$TMP_STATE" "$STATE_FILE"
fi

echo "$INFO"
