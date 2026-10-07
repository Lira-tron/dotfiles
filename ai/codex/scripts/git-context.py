#!/usr/bin/env python3
"""Git footer data for Codex, using the same label detector as Starship."""

import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path


STARSHIP_DETECTOR = Path.home() / ".config/starship/worktree.sh"


def git(root, *arguments):
    result = subprocess.run(
        ["git", "-C", str(root), *arguments],
        capture_output=True,
        text=True,
        timeout=5,
        env={
            **os.environ,
            "GIT_OPTIONAL_LOCKS": "0",
            "GIT_TERMINAL_PROMPT": "0",
            "LC_ALL": "C",
        },
    )
    return result.stdout.strip() if result.returncode == 0 else None


def label(root):
    result = subprocess.run(
        ["sh", str(STARSHIP_DETECTOR)],
        cwd=root,
        capture_output=True,
        text=True,
        timeout=5,
    )
    return result.stdout.strip() if result.returncode == 0 else ""


def repositories(root):
    repository = git(root, "rev-parse", "--show-toplevel")
    if repository:
        return [Path(repository)]
    if not label(root):
        return []
    for parent in (root, *root.parents):
        if (parent / "packageInfo").is_file():
            source = parent / "src"
            if not source.is_dir():
                return []
            return sorted(
                {path.resolve() for path in source.iterdir() if (path / ".git").exists()}
            )
    return []


def default_branch(root):
    remotes = (git(root, "remote") or "").splitlines()
    remotes.sort(key=lambda remote: remote != "origin")
    for remote in remotes:
        reference = git(root, "symbolic-ref", "--quiet", f"refs/remotes/{remote}/HEAD")
        if (
            reference
            and reference.startswith(f"refs/remotes/{remote}/")
            and git(root, "rev-parse", "--verify", "--quiet", reference)
        ):
            return reference
        for line in (git(root, "remote", "show", remote) or "").splitlines():
            if line.strip().startswith("HEAD branch:"):
                branch = line.split(":", 1)[1].strip()
                reference = f"refs/remotes/{remote}/{branch}"
                if git(root, "rev-parse", "--verify", "--quiet", reference):
                    return reference
    for branch in ("main", "master"):
        reference = f"refs/heads/{branch}"
        if git(root, "rev-parse", "--verify", "--quiet", reference):
            return reference
    return None


def repository_changes(root):
    reference = default_branch(root)
    if not reference:
        return None
    base = git(root, "merge-base", "HEAD", reference)
    if not base:
        return None
    output = git(root, "diff", "--no-ext-diff", "--numstat", f"{base}..HEAD")
    if output is None:
        return None
    counts = {"additions": 0, "deletions": 0}
    for line in output.splitlines():
        added, deleted, _path = line.split("\t", 2)
        if added.isdigit() and deleted.isdigit():
            counts["additions"] += int(added)
            counts["deletions"] += int(deleted)
    return counts


def changes(root):
    roots = repositories(root)
    if not roots:
        return None
    with ThreadPoolExecutor(max_workers=8) as pool:
        results = list(pool.map(repository_changes, roots))
    if any(result is None for result in results):
        return None
    return {key: sum(result[key] for result in results) for key in ("additions", "deletions")}


def main():
    root = Path.cwd().resolve()
    mode = sys.argv[1] if len(sys.argv) == 2 else ""
    try:
        if mode == "label":
            print(label(root))
        elif mode == "changes":
            print(json.dumps(changes(root)))
        else:
            return 2
    except (OSError, subprocess.TimeoutExpired, ValueError):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
