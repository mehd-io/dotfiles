#!/bin/bash
# Claude Code statusLine hook.
# Reads JSON from stdin, outputs a compact status string for Claude Code's own status line.
#
# State is determined by reading the state file written by the PreToolUse / Stop / SubagentStop
# hooks (claude-on-busy.sh and claude-on-waiting.sh). This is the reliable source of truth:
#
#   busy    → 🔄 (PreToolUse hook fired — model is processing/using a tool)
#   waiting → ✍️  (Stop/SubagentStop hook fired — waiting for user input)
#   (none)  → 💬  (no state file yet — idle/default)

STATE_DIR="$HOME/.claude/run/state"
mkdir -p "$STATE_DIR"

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
[ -z "$SESSION_ID" ] && exit 0

# Read status written by the hooks (busy / waiting); default to idle if absent
STATE_FILE="$STATE_DIR/${SESSION_ID}.state"
STATUS="idle"
if [ -f "$STATE_FILE" ]; then
  STATUS=$(grep '^status=' "$STATE_FILE" | cut -d= -f2)
  [ -z "$STATUS" ] && STATUS="idle"
fi

case "$STATUS" in
  busy)    STATE_LABEL="🔄" ;;
  waiting) STATE_LABEL="✍️"  ;;
  *)       STATE_LABEL="💬" ;;
esac

# --- Additional info from JSON ---
CWD=$(echo "$INPUT" | jq -r '.workspace.current_dir // .cwd // empty')
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // empty')
REMAINING=$(echo "$INPUT" | jq -r '.context_window.remaining_percentage // empty')

DIR_LABEL=""
[ -n "$CWD" ] && DIR_LABEL=$(basename "$CWD")

CTX_LABEL=""
[ -n "$REMAINING" ] && CTX_LABEL=$(printf "ctx:%.0f%%" "$REMAINING")

# --- Git context: branch + worktree detection ---
GIT_LABEL=""
if [ -n "$CWD" ] && command -v git >/dev/null 2>&1; then
  # Check if the JSON payload carries explicit worktree info (Claude --worktree mode)
  WT_NAME=$(echo "$INPUT" | jq -r '.worktree.name // empty')
  WT_BRANCH=$(echo "$INPUT" | jq -r '.worktree.branch // empty')

  if [ -n "$WT_NAME" ]; then
    # Claude was started with --worktree; use the data Claude already knows
    BRANCH="${WT_BRANCH:-$WT_NAME}"
    GIT_LABEL="⎇ wt:${BRANCH}"
  else
    # Fallback: inspect the filesystem from the CWD
    BRANCH=$(git -C "$CWD" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$BRANCH" ]; then
      # A worktree's .git is a *file* (not a directory) containing "gitdir: ..."
      GIT_DIR=$(git -C "$CWD" --no-optional-locks rev-parse --git-dir 2>/dev/null)
      IS_WORKTREE=0
      if [ -n "$GIT_DIR" ]; then
        # Absolute path to the resolved .git entry
        case "$GIT_DIR" in
          /*) ABS_GIT_DIR="$GIT_DIR" ;;
          *)  ABS_GIT_DIR="$CWD/$GIT_DIR" ;;
        esac
        # In a linked worktree, GIT_DIR points inside .git/worktrees/<name>
        case "$ABS_GIT_DIR" in
          */\.git/worktrees/*) IS_WORKTREE=1 ;;
        esac
        # Also cover the case where .git itself is a file (common worktree layout)
        if [ "$IS_WORKTREE" -eq 0 ] && [ -f "$CWD/.git" ]; then
          IS_WORKTREE=1
        fi
      fi

      if [ "$IS_WORKTREE" -eq 1 ]; then
        GIT_LABEL="⎇ wt:${BRANCH}"
      else
        GIT_LABEL="⎇ ${BRANCH}"
      fi
    fi
  fi
fi

PARTS="$STATE_LABEL"
[ -n "$DIR_LABEL" ] && PARTS="$PARTS $DIR_LABEL"
[ -n "$GIT_LABEL" ] && PARTS="$PARTS | $GIT_LABEL"
[ -n "$MODEL" ]     && PARTS="$PARTS | $MODEL"
[ -n "$CTX_LABEL" ] && PARTS="$PARTS | $CTX_LABEL"

echo "$PARTS"
