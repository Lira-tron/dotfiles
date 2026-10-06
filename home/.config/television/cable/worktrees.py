#!/usr/bin/env python3
"""List Git worktrees for Television and open existing checkouts in Herdr."""

import base64
import json
import os
from pathlib import Path
import subprocess
import sys


def checkouts(repo):
    output = subprocess.check_output(
        ["git", "-C", str(repo), "worktree", "list", "--porcelain", "-z"],
        stderr=subprocess.PIPE,
    )
    return [
        dict(os.fsdecode(field).partition(" ")[::2] for field in record.split(b"\0"))
        for record in output.rstrip(b"\0").split(b"\0\0")
        if record
    ]


def rows(records, under=None):
    parent = Path(records[0]["worktree"]).resolve()
    for record in records:
        path = Path(record["worktree"]).resolve()
        if not path.is_dir() or "bare" in record or "prunable" in record:
            continue
        if under is not None and not path.is_relative_to(under):
            continue
        branch = record.get("branch", "").removeprefix("refs/heads/")
        branch = branch or f"detached {record.get('HEAD', '')[:7]}"
        label = f"[tree] {parent.name} · {branch}"
        if path == parent:
            label += " (primary)"
        # The existing channel tests its display label inside a single-quoted shell argument.
        label = label.replace("\t", " ").replace("\n", " ").replace("'", "’")
        payload = base64.urlsafe_b64encode(
            json.dumps({"parent": str(parent), "path": str(path)}).encode()
        ).decode()
        yield f"{label}\t{payload}"


def workplace_rows(root):
    root = root.resolve()
    command = ["fd", "--hidden", "--no-ignore", "--prune", "--absolute-path", "--print0"]
    for directory in ["build", "env", "node_modules", ".ai", ".brazil", "brazil-pkg-cache", ".cache", ".venv"]:
        command.extend(["--exclude", directory])
    command.extend(["--glob", ".git", str(root)])
    markers = subprocess.check_output(command).split(b"\0")
    seen = set()
    for marker in sorted(filter(None, markers)):
        repo = Path(os.fsdecode(marker)).parent.resolve()
        if repo in seen:
            continue
        try:
            records = checkouts(repo)
        except subprocess.CalledProcessError as error:
            print(error.stderr.decode(errors="replace").strip(), file=sys.stderr)
            continue
        seen.update(Path(record["worktree"]).resolve() for record in records)
        yield from rows(records, under=root)


def main():
    mode = sys.argv[1]
    if mode == "current":
        print("\n".join(rows(checkouts(Path.cwd()))))
    elif mode == "all":
        print("\n".join(workplace_rows(Path.home() / "workplace")))
    else:
        selected = json.loads(base64.urlsafe_b64decode(sys.argv[2]))
        path = selected["path"]
        if mode == "path":
            print(path)
        elif mode == "preview":
            print(path, flush=True)
            subprocess.run(["git", "-C", path, "status", "--short"], check=True)
            subprocess.run(["git", "-C", path, "log", "--oneline", "-8", "--color=always"], check=True)
        elif mode == "open":
            subprocess.run(
                ["herdr", "worktree", "open", "--cwd", selected["parent"],
                 "--path", path, "--focus"],
                check=True,
            )
        else:
            raise ValueError(f"Unknown worktree action: {mode}")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        if error.stderr:
            print(error.stderr.decode(errors="replace").strip(), file=sys.stderr)
        sys.exit(error.returncode)
