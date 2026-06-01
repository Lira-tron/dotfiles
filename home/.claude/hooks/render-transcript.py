#!/usr/bin/env python3
"""Render a Claude Code JSONL transcript as readable markdown.

Collapses consecutive assistant content blocks (thinking, tool_use, text)
into a single ## Assistant turn. Drops user lines that contain only tool
results — those are internal plumbing, not user turns.

Usage:  render-transcript.py <transcript.jsonl>
Writes rendered markdown to stdout.
"""
import json
import re
import sys


TASK_NOTIFICATION_RE = re.compile(r"<task-notification>.*?</task-notification>", re.DOTALL)
SYSTEM_REMINDER_RE = re.compile(r"<system-reminder>.*?</system-reminder>", re.DOTALL)


def strip_system_tags(text: str) -> str:
    # Drop background task-completion notifications and system reminders
    # — these are harness-generated, not user-authored content.
    text = TASK_NOTIFICATION_RE.sub("", text)
    text = SYSTEM_REMINDER_RE.sub("", text)
    return text.strip()


def flatten_content(content):
    if isinstance(content, str):
        text = strip_system_tags(content)
        return [("text", text)] if text else []
    if not isinstance(content, list):
        return []
    out = []
    for block in content:
        if not isinstance(block, dict):
            continue
        t = block.get("type")
        if t == "text":
            text = strip_system_tags(block.get("text", ""))
            if text:
                out.append(("text", text))
        elif t == "thinking":
            # Skip thinking blocks — too noisy for a readable transcript
            continue
        elif t == "tool_use":
            name = block.get("name", "?")
            inp = block.get("input", {})
            # Compact input preview for a few common tools
            preview = ""
            if isinstance(inp, dict):
                if "command" in inp:
                    cmd = str(inp["command"])
                    preview = cmd if len(cmd) <= 160 else cmd[:160] + "…"
                elif "file_path" in inp:
                    preview = inp["file_path"]
                elif "pattern" in inp:
                    preview = inp["pattern"]
                elif "query" in inp:
                    preview = str(inp["query"])[:120]
            if preview:
                out.append(("tool_use", f"_Tool: `{name}` — `{preview}`_"))
            else:
                out.append(("tool_use", f"_Tool: `{name}`_"))
        elif t == "tool_result":
            out.append(("tool_result", None))
    return out


def render(path: str) -> str:
    turns = []  # list of (role, markdown_body)

    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            etype = entry.get("type")
            if etype not in ("user", "assistant"):
                continue

            # Skip system-generated user entries (background task completion
            # notifications, hook-injected messages, etc.). These are not
            # authored by the user.
            if etype == "user" and (entry.get("origin") or {}).get("kind"):
                continue

            msg = entry.get("message") or {}
            blocks = flatten_content(msg.get("content"))

            if etype == "user":
                # Keep only blocks that have user-authored text. A line that
                # only contains tool_result entries is internal plumbing and
                # should not be rendered as a user turn.
                text_parts = [body for kind, body in blocks if kind == "text"]
                if not text_parts:
                    continue
                turns.append(("user", "\n\n".join(text_parts)))
            else:
                # Assistant: emit text + tool_use markers, drop tool_results.
                parts = []
                for kind, body in blocks:
                    if kind in ("text", "tool_use"):
                        parts.append(body)
                if not parts:
                    continue
                turns.append(("assistant", "\n\n".join(parts)))

    # Coalesce consecutive same-role turns into one section. A single
    # "assistant turn" in the user's mental model is usually many JSONL
    # lines (thinking → tool_use → tool_use → text), so we merge them.
    merged = []
    for role, body in turns:
        if merged and merged[-1][0] == role:
            merged[-1] = (role, merged[-1][1] + "\n\n" + body)
        else:
            merged.append((role, body))

    lines = []
    for role, body in merged:
        header = "## User" if role == "user" else "## Assistant"
        lines.append(header)
        lines.append("")
        lines.append(body)
        lines.append("")
        lines.append("---")
        lines.append("")
    return "\n".join(lines)


def count_turns(path: str) -> int:
    # Count coalesced turns (matches what render emits).
    n = 0
    last_role = None
    with open(path) as f:
        for line in f:
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            etype = entry.get("type")
            if etype not in ("user", "assistant"):
                continue
            if etype == "user" and (entry.get("origin") or {}).get("kind"):
                continue
            msg = entry.get("message") or {}
            blocks = flatten_content(msg.get("content"))
            if etype == "user":
                if not any(k == "text" for k, _ in blocks):
                    continue
            else:
                if not any(k in ("text", "tool_use") for k, _ in blocks):
                    continue
            if etype != last_role:
                n += 1
                last_role = etype
    return n


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: render-transcript.py <transcript.jsonl>", file=sys.stderr)
        sys.exit(2)
    path = sys.argv[1]
    if len(sys.argv) > 2 and sys.argv[2] == "--count":
        print(count_turns(path))
    else:
        sys.stdout.write(render(path))
