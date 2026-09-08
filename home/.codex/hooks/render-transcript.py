#!/usr/bin/env python3
"""Render a Codex JSONL rollout as readable markdown."""

import json
import sys


def message_text(content):
    parts = []
    for block in content or []:
        if not isinstance(block, dict):
            continue
        if block.get("type") not in ("input_text", "output_text"):
            continue
        text = block.get("text", "").strip()
        if text:
            parts.append(text)
    return "\n\n".join(parts)


def tool_marker(payload):
    item_type = payload.get("type")
    if item_type in ("function_call", "custom_tool_call"):
        name = payload.get("name", "?")
        namespace = payload.get("namespace")
        if namespace:
            name = f"{namespace}.{name}"
        return f"_Tool: `{name}`_"
    if item_type == "web_search_call":
        return "_Tool: `web_search`_"
    if item_type == "tool_search_call":
        return "_Tool: `tool_search`_"
    return None


def transcript_items(path):
    with open(path) as transcript:
        for line in transcript:
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue

            if entry.get("type") != "response_item":
                continue

            payload = entry.get("payload") or {}
            if payload.get("type") == "message":
                role = payload.get("role")
                if role not in ("user", "assistant"):
                    continue
                text = message_text(payload.get("content"))
                if text:
                    yield role, text
                continue

            marker = tool_marker(payload)
            if marker:
                yield "assistant", marker


def merged_turns(path):
    merged = []
    for role, body in transcript_items(path):
        if merged and merged[-1][0] == role:
            merged[-1] = (role, merged[-1][1] + "\n\n" + body)
        else:
            merged.append((role, body))
    return merged


def render(path):
    lines = []
    for role, body in merged_turns(path):
        lines.extend(
            [
                "## User" if role == "user" else "## Assistant",
                "",
                body,
                "",
                "---",
                "",
            ]
        )
    return "\n".join(lines)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: render-transcript.py <transcript.jsonl>", file=sys.stderr)
        sys.exit(2)
    if len(sys.argv) > 2 and sys.argv[2] == "--count":
        print(len(merged_turns(sys.argv[1])))
    else:
        sys.stdout.write(render(sys.argv[1]))
