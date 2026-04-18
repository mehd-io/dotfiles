# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""
Sync Claude Code session transcripts (~/.claude/projects/**/*.jsonl)
to Obsidian vault as Markdown files.

Output: <vault>/chat_history/claude_code/YYYY-MM-DD_HH-MM_<session-short>_<slug>.md
Idempotent: skips sessions that already have a matching output file.

Reads OBSIDIAN_VAULT env var (fallback: ~/Documents/mehdio_sb).
"""

import json
import glob
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

CLAUDE_PROJECTS = Path.home() / ".claude" / "projects"
OBSIDIAN_VAULT = Path(os.environ.get("OBSIDIAN_VAULT", str(Path.home() / "Documents" / "mehdio_sb")))
OUTPUT_DIR = OBSIDIAN_VAULT / "chat_history" / "claude_code"


def slugify(text: str, max_words: int = 6) -> str:
    # Handle slash command messages: extract command name + args
    cmd_name = re.search(r"<command-name>(/\S+)</command-name>", text)
    cmd_args = re.search(r"<command-args>(.*?)</command-args>", text, re.DOTALL)
    if cmd_name:
        name = cmd_name.group(1).lstrip("/")
        args = cmd_args.group(1).strip() if cmd_args else ""
        text = f"{name} {args}".strip()

    text = re.sub(r"[^\w\s-]", "", text.lower())
    words = text.split()[:max_words]
    return "-".join(words) if words else "untitled"


def extract_user_text(content) -> str:
    if isinstance(content, str):
        text = content.strip()
        # Render slash command XML as readable text
        cmd_name = re.search(r"<command-name>(/\S+)</command-name>", text)
        cmd_args = re.search(r"<command-args>(.*?)</command-args>", text, re.DOTALL)
        if cmd_name:
            name = cmd_name.group(1)
            args = (" " + cmd_args.group(1).strip()) if cmd_args else ""
            return f"*Slash command:* `{name}{args}`"
        return text
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict) and item.get("type") == "text":
                parts.append(item["text"].strip())
        return " ".join(parts)
    return ""


def extract_assistant_text(content: list) -> str:
    parts = []
    for item in content:
        if not isinstance(item, dict):
            continue
        if item.get("type") == "text":
            parts.append(item["text"].strip())
        elif item.get("type") == "tool_use":
            name = item.get("name", "tool")
            inp = item.get("input", {})
            if name in ("Bash",):
                cmd = inp.get("command", "")[:120]
                parts.append(f"*`{name}`: {cmd}*")
            elif name in ("Read", "Edit", "Write", "Glob", "Grep"):
                path = inp.get("file_path") or inp.get("pattern") or inp.get("path", "")
                parts.append(f"*`{name}`: {path}*")
            else:
                parts.append(f"*`{name}`*")
        # skip 'thinking' blocks
    return "\n\n".join(parts)


def parse_session(jsonl_path: Path):
    messages = []
    meta = {
        "session_id": None,
        "cwd": None,
        "model": None,
        "first_ts": None,
        "last_ts": None,
    }

    with open(jsonl_path, encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            msg_type = obj.get("type")

            if msg_type == "user":
                if obj.get("isMeta") or obj.get("isSidechain"):
                    continue
                content = obj.get("message", {}).get("content", "")
                text = extract_user_text(content)
                if not text:
                    continue
                if text.startswith("<local-command-caveat>"):
                    continue
                ts = obj.get("timestamp")
                if ts:
                    if not meta["first_ts"]:
                        meta["first_ts"] = ts
                    meta["last_ts"] = ts
                if not meta["session_id"]:
                    meta["session_id"] = obj.get("sessionId")
                if not meta["cwd"]:
                    meta["cwd"] = obj.get("cwd")
                messages.append({"role": "user", "text": text, "ts": ts})

            elif msg_type == "assistant":
                if obj.get("isSidechain"):
                    continue
                content = obj.get("message", {}).get("content", [])
                if not isinstance(content, list):
                    continue
                text = extract_assistant_text(content)
                if not text:
                    continue
                if not meta["model"]:
                    meta["model"] = obj.get("message", {}).get("model")
                messages.append({"role": "assistant", "text": text})

    return meta, messages


def session_to_markdown(meta: dict, messages: list) -> str:
    session_id = meta.get("session_id") or "unknown"
    cwd = meta.get("cwd") or ""
    model = meta.get("model") or "unknown"
    first_ts = meta.get("first_ts") or ""
    last_ts = meta.get("last_ts") or ""

    duration_str = ""
    if first_ts and last_ts and first_ts != last_ts:
        try:
            t0 = datetime.fromisoformat(first_ts.replace("Z", "+00:00"))
            t1 = datetime.fromisoformat(last_ts.replace("Z", "+00:00"))
            mins = int((t1 - t0).total_seconds() / 60)
            duration_str = f"{mins} min"
        except Exception:
            pass

    first_user = next((m["text"] for m in messages if m["role"] == "user"), "")
    cmd_name = re.search(r"<command-name>(/\S+)</command-name>", first_user)
    cmd_args = re.search(r"<command-args>(.*?)</command-args>", first_user, re.DOTALL)
    if cmd_name:
        first_user = cmd_name.group(1) + (" " + cmd_args.group(1).strip() if cmd_args else "")
    title_snippet = first_user[:80].replace("\n", " ")

    date_str = first_ts[:10] if first_ts else "unknown"
    lines = [
        "---",
        f"date: {date_str}",
        f'session_id: "{session_id}"',
        f'cwd: "{cwd}"',
        f"model: {model}",
        f"turns: {len(messages)}",
    ]
    if duration_str:
        lines.append(f"duration: {duration_str}")
    lines += ["tags:", "  - claude_code", "---", ""]

    time_str = first_ts[11:16] if len(first_ts) >= 16 else ""
    lines.append(f"# {date_str} {time_str} - {title_snippet}")
    lines.append("")

    if cwd:
        lines.append(f"> **Project:** `{cwd}`")
        lines.append("")

    for msg in messages:
        if msg["role"] == "user":
            lines.append("**User:**")
            lines.append("")
            lines.append(msg["text"])
            lines.append("")
        else:
            lines.append("**Claude:**")
            lines.append("")
            lines.append(msg["text"])
            lines.append("")
        lines.append("---")
        lines.append("")

    return "\n".join(lines)


def output_filename(meta: dict, messages: list) -> str:
    first_ts = meta.get("first_ts") or "1970-01-01T00:00:00Z"
    session_id = meta.get("session_id") or "unknown"

    date_part = first_ts[:10]
    time_part = first_ts[11:16].replace(":", "-")
    session_short = session_id[:8]

    first_user = next((m["text"] for m in messages if m["role"] == "user"), "untitled")
    slug = slugify(first_user)

    return f"{date_part}_{time_part}_{session_short}_{slug}.md"


def main():
    dry_run = "--dry-run" in sys.argv
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    existing = {
        p.name.split("_")[2]
        for p in OUTPUT_DIR.glob("*.md")
        if len(p.name.split("_")) >= 3
    }

    jsonl_files = sorted(CLAUDE_PROJECTS.glob("**/*.jsonl"))
    jsonl_files = [p for p in jsonl_files if "subagents" not in str(p)]

    new_count = 0
    skip_count = 0

    for jsonl_path in jsonl_files:
        session_id_quick = None
        try:
            with open(jsonl_path, encoding="utf-8", errors="replace") as f:
                for line in f:
                    try:
                        obj = json.loads(line)
                        if obj.get("type") == "user" and obj.get("sessionId"):
                            session_id_quick = obj["sessionId"][:8]
                            break
                    except Exception:
                        continue
        except Exception:
            continue

        if session_id_quick and session_id_quick in existing:
            skip_count += 1
            continue

        try:
            meta, messages = parse_session(jsonl_path)
        except Exception as e:
            print(f"  ERROR parsing {jsonl_path.name}: {e}")
            continue

        if not messages:
            continue

        real_user_msgs = [m for m in messages if m["role"] == "user" and len(m["text"]) > 10]
        if not real_user_msgs:
            continue

        filename = output_filename(meta, messages)
        out_path = OUTPUT_DIR / filename

        if out_path.exists():
            skip_count += 1
            continue

        md = session_to_markdown(meta, messages)

        if dry_run:
            print(f"  [DRY] Would write: {filename} ({len(messages)} messages)")
        else:
            out_path.write_text(md, encoding="utf-8")
            print(f"  + {filename}")
            new_count += 1

    print(f"\nDone. {new_count} new sessions written, {skip_count} skipped (already exported).")


if __name__ == "__main__":
    main()
