#!/usr/bin/env python3
"""Snapshot Lean verification candidates without changing the index/worktree."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
from datetime import datetime, timezone


def git(repo, *args, check=True):
    return subprocess.run(
        ["git", "--no-optional-locks", "-c", "diff.autoRefreshIndex=false",
         "-C", str(repo), *args], check=check, capture_output=True
    )


def paths(repo, *args):
    return {os.fsdecode(p) for p in git(repo, *args).stdout.split(b"\0") if p}


def changed_paths(repo, *args):
    # numstat compares content even with a stale stat cache; name-only does not.
    data = git(repo, "diff", *args, "--numstat", "--no-renames",
               "--no-ext-diff", "--no-textconv", "-z").stdout
    return {os.fsdecode(row.split(b"\t", 2)[2]) for row in data.split(b"\0") if row}


def fingerprint(root, name):
    path = root / name
    if path.is_symlink():
        return {"kind": "symlink", "sha256": hashlib.sha256(
            os.fsencode(os.readlink(path))).hexdigest()}
    if not path.exists():
        return {"kind": "deleted", "sha256": None}
    if not path.is_file():
        return {"kind": "directory", "sha256": None}
    with path.open("rb") as source:
        digest = hashlib.file_digest(source, "sha256").hexdigest()
    return {"kind": "file", "sha256": digest}


def snapshot(repo, mode):
    root = Path(os.fsdecode(git(repo, "rev-parse", "--show-toplevel").stdout).strip())
    staged = changed_paths(root, "--cached")
    unstaged = changed_paths(root)
    untracked = paths(root, "ls-files", "--others", "--exclude-standard", "-z")
    selected = staged | unstaged | untracked
    if mode == "all":
        selected |= paths(root, "ls-files", "--cached", "-z")
    head = git(root, "rev-parse", "--verify", "HEAD", check=False)
    files = []
    for name in sorted(selected):
        changes = [label for label, members in [
            ("staged", staged), ("unstaged", unstaged), ("untracked", untracked)
        ] if name in members]
        files.append({"path": name, "changes": changes, **fingerprint(root, name)})
    return {
        "schema_version": 1, "root": str(root), "mode": mode,
        "head": head.stdout.decode().strip() if head.returncode == 0 else None,
        "created_at": datetime.now(timezone.utc).isoformat(), "files": files,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default=".")
    parser.add_argument("--mode", choices=["all", "uncommitted"], default="uncommitted")
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    result = snapshot(args.repo, args.mode)
    out = args.out.resolve()
    if out.is_relative_to(Path(result["root"])):
        parser.error("--out must be outside the repository to avoid self-inclusion")
    if (out / "scope.json").exists():
        parser.error("scope.json already exists; use a fresh --out directory")
    out.mkdir(parents=True, exist_ok=True)
    with (out / "scope.json").open("x") as stream:
        json.dump(result, stream, indent=2)
        stream.write("\n")
    for name, extra in [("staged.patch", ["--cached"]), ("unstaged.patch", [])]:
        patch = git(result["root"], "diff", *extra, "--no-ext-diff",
                    "--no-textconv", "--no-renames", "--binary").stdout
        (out / name).write_bytes(patch)
    print(json.dumps({"scope": str(out / "scope.json"), "files": len(result["files"])}))


if __name__ == "__main__":
    main()
