#!/usr/bin/env python3
"""Parse loop requests and track a cooperative, conversation-scoped schedule."""

import argparse
import json
import math
import os
from pathlib import Path
import re
import tempfile
import time


DEFAULT_INTERVAL_MS = 600_000
MIN_INTERVAL_MS = 10_000
MAX_AGE_MS = 7 * 24 * 60 * 60 * 1000
ACTIVE = {"waiting", "running"}
NUMBER = r"(?:\d+(?:\.\d+)?|\.\d+)"
FACTORS = {"s": 1000, "m": 60_000, "h": 3_600_000, "d": 86_400_000}


def parse_request(text):
    text = text.strip()
    if not text or text == "help":
        return {"action": "help"}
    if text == "list":
        return {"action": "list"}
    if text == "stop" or text.startswith("stop "):
        return {"action": "stop", "id": text[4:].strip() or None}

    first, rest = re.fullmatch(r"(\S+)(?:\s+([\s\S]*))?", text).groups()
    leading = re.fullmatch(f"({NUMBER})([smhd])", first, re.I)
    trailing = re.fullmatch(
        rf"([\s\S]+?)\s+every\s+({NUMBER})\s*"
        r"(s|seconds?|m|minutes?|h|hours?|d|days?)",
        text,
        re.I,
    )
    if leading:
        number, unit = leading.groups()
        prompt = (rest or "").strip()
    elif trailing:
        prompt, number, unit = trailing.groups()
        unit = unit[0]
    else:
        if re.fullmatch(rf"[+-]?{NUMBER}[a-z]+", first, re.I):
            raise ValueError("Use a positive interval with s, m, h, or d units.")
        return {
            "action": "add",
            "prompt": text,
            "interval_ms": DEFAULT_INTERVAL_MS,
            "clamped": False,
        }
    if not prompt:
        raise ValueError("Provide a prompt after the interval.")
    milliseconds = float(number) * FACTORS[unit.lower()]
    if not math.isfinite(milliseconds):
        raise ValueError("The interval must be finite.")
    return {
        "action": "add",
        "prompt": prompt,
        "interval_ms": max(MIN_INTERVAL_MS, math.ceil(milliseconds)),
        "clamped": milliseconds < MIN_INTERVAL_MS,
    }


def dispatch(
    state, action, now_ms, *, request=None, job_id=None,
    max_runs=None, duration_ms=None,
):
    if max_runs is not None and max_runs <= 0:
        raise ValueError("--max-runs must be positive.")
    if duration_ms is not None and duration_ms <= 0:
        raise ValueError("--duration-ms must be positive.")
    jobs = state.setdefault("jobs", [])
    for job in jobs:
        if job["status"] == "waiting" and now_ms >= job["expires_at_ms"]:
            job["status"] = "expired"

    if action == "request":
        parsed = parse_request(request)
        action = parsed["action"]
        if action == "add":
            sequence = state.get("next_id", 1)
            state["next_id"] = sequence + 1
            job = {
                "id": f"loop-{sequence}",
                "prompt": parsed["prompt"],
                "interval_ms": parsed["interval_ms"],
                "created_at_ms": now_ms,
                "expires_at_ms": now_ms + min(duration_ms or MAX_AGE_MS, MAX_AGE_MS),
                "next_due_ms": now_ms,
                "status": "waiting",
                "runs_started": 0,
                "runs_completed": 0,
                "max_runs": max_runs,
            }
            jobs.append(job)
            return {"action": "added", "job": job, "clamped": parsed["clamped"]}
        job_id = parsed.get("id")

    if action == "help":
        return {"action": "help", "usage": "$loop [interval] prompt | list | stop [id]"}
    if action == "list":
        return {"action": "list", "jobs": jobs}
    if action == "stop":
        stopped = []
        for job in jobs:
            if job["status"] in ACTIVE and (job_id is None or job["id"] == job_id):
                job["status"] = "stopped"
                stopped.append(job["id"])
        return {"action": "stopped", "ids": stopped}
    if action == "done":
        job = next((job for job in jobs if job["id"] == job_id), None)
        if job is None:
            raise ValueError(f"Unknown loop: {job_id}")
        if job["status"] == "running":
            job["runs_completed"] += 1
            if now_ms >= job["expires_at_ms"]:
                job["status"] = "expired"
            elif job.get("max_runs") and job["runs_completed"] >= job["max_runs"]:
                job["status"] = "completed"
            else:
                elapsed = now_ms - job["created_at_ms"]
                slot = elapsed // job["interval_ms"] + 1
                job["next_due_ms"] = job["created_at_ms"] + slot * job["interval_ms"]
                job["status"] = "waiting"
        return {"action": "done", "job": job}
    if action == "next":
        running = [job for job in jobs if job["status"] == "running"]
        if running:
            return {"action": "running", "ids": [job["id"] for job in running]}
        waiting = [job for job in jobs if job["status"] == "waiting"]
        if not waiting:
            return {"action": "idle"}
        job = min(waiting, key=lambda item: item["next_due_ms"])
        if job["next_due_ms"] <= now_ms:
            job["status"] = "running"
            job["runs_started"] += 1
            return {"action": "run", "job": job}
        wake_at = min(
            job["next_due_ms"],
            min(item["expires_at_ms"] for item in waiting),
        )
        return {"action": "wait", "duration_ms": min(60_000, wake_at - now_ms)}
    raise ValueError(f"Unknown action: {action}")


def state_path(explicit):
    if explicit:
        return explicit
    thread_id = os.environ.get("CODEX_THREAD_ID", "")
    if not re.fullmatch(r"[A-Za-z0-9_-]+", thread_id):
        raise ValueError("CODEX_THREAD_ID is unavailable; pass --state with a session-specific path.")
    return Path(tempfile.gettempdir()) / f"codex-loop-{os.getuid()}" / f"{thread_id}.json"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state", type=Path, help="Override the conversation's temporary state file.")
    commands = parser.add_subparsers(dest="command", required=True)
    for command in ("parse", "request"):
        subparser = commands.add_parser(command)
        subparser.add_argument("text")
        if command == "request":
            subparser.add_argument("--max-runs", type=int)
            subparser.add_argument("--duration-ms", type=int)
    for command in ("next", "list"):
        commands.add_parser(command)
    commands.add_parser("done").add_argument("id")
    commands.add_parser("stop").add_argument("id", nargs="?")
    args = parser.parse_args()
    try:
        if args.command == "parse":
            result = parse_request(args.text)
        else:
            path = state_path(args.state)
            state = json.loads(path.read_text()) if path.exists() else {}
            result = dispatch(
                state,
                args.command,
                time.time_ns() // 1_000_000,
                request=getattr(args, "text", None),
                job_id=getattr(args, "id", None),
                max_runs=getattr(args, "max_runs", None),
                duration_ms=getattr(args, "duration_ms", None),
            )
            path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
            with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as output:
                json.dump(state, output)
                temporary = Path(output.name)
            temporary.replace(path)
        print(json.dumps(result))
    except (ValueError, OSError) as error:
        parser.exit(2, f"{error}\n")


if __name__ == "__main__":
    main()
