#!/usr/bin/env bash
# claude-search: fuzzy search all Claude Code conversations, then resume in the original directory
# Searches ALL prompts (not just last-per-session) + can grep full session content
set -euo pipefail

HISTORY="$HOME/.claude/history.jsonl"
PROJECTS="$HOME/.claude/projects"

if [[ ! -f "$HISTORY" ]]; then
  echo "No Claude Code history found at $HISTORY"
  exit 1
fi

# Build searchable list: every prompt from history.jsonl, grouped by session
# Show all prompts so any keyword from any point in the conversation is findable
# Fields: sessionId \t projectPath \t date  ~/short/path  prompt
selected=$(
  jq -r --arg home "$HOME" '
    [.sessionId, .project,
     (.timestamp / 1000 | strftime("%Y-%m-%d %H:%M")),
     (.project | sub($home; "~")),
     (.display | gsub("\n";" ") | .[0:150])]
    | @tsv
  ' "$HISTORY" \
  | tail -r \
  | awk -F'\t' '{printf "%s\t%s\t%-18s %-42s  %s\n", $1, $2, $3, $4, $5}' \
  | fzf --with-nth=3.. \
        --delimiter=$'\t' \
        --no-sort \
        --exact \
        --header="Claude conversations (?=preview, ctrl-a=search all text)" \
        --preview='
          session_id=$(echo {} | cut -f1)
          files=$(find "$HOME/.claude/projects" -name "${session_id}.jsonl" 2>/dev/null)
          if [[ -n "$files" ]]; then
            jq -r "select(.type==\"user\" or .type==\"assistant\") | .message.content[]? | select(.type==\"text\") | .text" $files 2>/dev/null | head -100
          else
            echo "Session file not found"
          fi
        ' \
        --preview-window=right:45%:wrap:hidden \
        --bind='?:toggle-preview' \
) || exit 0

# Parse selection
session_id=$(echo "$selected" | cut -f1)
project_path=$(echo "$selected" | cut -f2)

if [[ -z "$session_id" ]]; then
  exit 0
fi

# cd to the original project directory, then resume
if [[ -d "$project_path" ]]; then
  cd "$project_path"
fi

tmux rename-window "$(basename "$project_path")" 2>/dev/null || true

exec claude --resume "$session_id"
