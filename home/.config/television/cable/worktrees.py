#!/usr/bin/env python3
"""List Git worktrees for Television and open existing checkouts in Herdr."""

import base64
import json
import os
from pathlib import Path
import shutil
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


def repositories(root):
    root = root.resolve()
    command = ["fd", "--hidden", "--no-ignore", "--prune", "--absolute-path", "--print0"]
    for directory in ["build", "env", "node_modules", ".ai", ".brazil", "brazil-pkg-cache", ".cache", ".venv"]:
        command.extend(["--exclude", directory])
    command.extend(["--glob", ".git", str(root)])
    markers = subprocess.check_output(command).split(b"\0")
    return [Path(os.fsdecode(marker)).parent.resolve() for marker in sorted(filter(None, markers))]


def workplace_rows(root, restrict_paths=True):
    root = root.resolve()
    seen = set()
    for repo in repositories(root):
        if repo in seen:
            continue
        try:
            records = checkouts(repo)
        except subprocess.CalledProcessError as error:
            print(error.stderr.decode(errors="replace").strip(), file=sys.stderr)
            continue
        seen.update(Path(record["worktree"]).resolve() for record in records)
        yield from rows(records, under=root if restrict_paths else None)


def current_rows(root):
    root = root.resolve()
    for scope in (root, *root.parents):
        if scope == scope.parent:
            break
        found = list(workplace_rows(scope, restrict_paths=False))
        if found:
            return found
    return []


def brazil_workspace(repo):
    if not shutil.which("brazil-context"):
        return None
    result = subprocess.run(
        ["brazil-context", "package", "root"], cwd=repo,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    if result.returncode or Path(os.fsdecode(result.stdout).strip()).resolve() != repo:
        return None
    root = subprocess.check_output(["brazil-context", "workspace", "root"], cwd=repo)
    return Path(os.fsdecode(root).strip()).resolve()


def prompt(message):
    print(message, end="", file=sys.stderr, flush=True)
    with open("/dev/tty") as terminal:
        return terminal.readline().strip()


def open_worktree(selected):
    path = Path(selected["path"]).resolve()
    brazil_root = brazil_workspace(path)

    def same_checkout(candidate):
        if candidate == path:
            return True
        if brazil_root:
            # Sibling packages share a session; nested Brazil worktrees do not.
            for root in (candidate, *candidate.parents):
                if (root / "packageInfo").is_file():
                    return root == brazil_root
        return False

    snapshot = json.loads(subprocess.check_output(["herdr", "api", "snapshot"]))["result"]["snapshot"]
    for workspace in snapshot["workspaces"]:
        worktree = workspace.get("worktree")
        if worktree and same_checkout(Path(worktree["checkout_path"]).resolve()):
            subprocess.run(["herdr", "workspace", "focus", workspace["workspace_id"]], check=True)
            return

    # Also reuse ordinary sessions opened inside this checkout.
    for pane in snapshot["panes"]:
        cwd = Path(pane.get("foreground_cwd") or pane["cwd"]).resolve()
        if not same_checkout(cwd):
            if not cwd.is_relative_to(path):
                continue
            root = subprocess.run(
                ["git", "-C", str(cwd), "rev-parse", "--show-toplevel"],
                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
            )
            if root.returncode or Path(root.stdout.strip()).resolve() != path:
                continue
        subprocess.run(["herdr", "tab", "focus", pane["tab_id"]], check=True)
        return

    subprocess.run(
        ["herdr", "worktree", "open", "--cwd", selected["parent"],
         "--path", selected["path"], "--focus"],
        check=True,
    )


def delete_worktree(selected):
    parent, path = (Path(selected[key]).resolve() for key in ("parent", "path"))
    if path == parent:
        raise ValueError("The primary checkout cannot be deleted from this picker.")
    owner, workspace = brazil_workspace(parent), brazil_workspace(path)
    if (owner is None) != (workspace is None):
        raise ValueError("Cannot resolve the Brazil worktree and its parent; inspect them before cleanup.")
    target = workspace or path
    if Path.cwd().resolve().is_relative_to(target):
        raise ValueError("Move to the parent checkout before deleting this worktree.")
    if os.environ.get("HERDR_ENV") == "1":
        snapshot = json.loads(subprocess.check_output(["herdr", "api", "snapshot"]))
        open_panes = [
            pane["pane_id"] for pane in snapshot["result"]["snapshot"]["panes"]
            if Path(pane.get("foreground_cwd") or pane["cwd"]).resolve().is_relative_to(target)
        ]
        if open_panes:
            raise ValueError("Close the worktree's Herdr panes first: " + ", ".join(open_panes))
    if workspace:
        if workspace != owner / "worktrees" / workspace.name:
            raise ValueError("This is not a native Brazil task worktree; inspect it before cleanup.")
        if any(repo.parent != workspace / "src" for repo in repositories(workspace)):
            raise ValueError("Remove the nested Git checkouts before deleting this Brazil worktree.")
        command = ["brazil", "worktree", "delete", "--workspace", str(owner), "--name", workspace.name]
        scope = "all package checkouts, branches, build outputs, and ignored .ai files"
    else:
        command = ["git", "-C", str(parent), "worktree", "remove", str(path)]
        scope = "this checkout and its ignored .ai files; its Git branch is retained"
    print(f"Delete {target}\nThis removes {scope}. Preserve needed work first.", file=sys.stderr)
    if prompt(f"Type {target.name} to delete (blank cancels): ") != target.name:
        return
    subprocess.run(command, check=True)


def create_worktree(selected):
    root = subprocess.check_output(
        ["brazil-context", "package", "root"], cwd=selected["parent"], stderr=subprocess.PIPE,
    )
    parent = Path(os.fsdecode(root).strip()).resolve()
    root = subprocess.check_output(
        ["brazil-context", "workspace", "root"], cwd=parent, stderr=subprocess.PIPE,
    )
    workspace = Path(os.fsdecode(root).strip()).resolve()
    base = subprocess.check_output(["git", "-C", str(parent), "rev-parse", "HEAD"]).decode().strip()
    branch = subprocess.check_output(["git", "-C", str(parent), "branch", "--show-current"]).decode().strip()
    print(f"Repository: {parent}\nBase: {branch or 'detached HEAD'} @ {base[:12]}", file=sys.stderr)
    print(f"Brazil parent: {workspace}\nAll parent packages use their current committed HEADs.", file=sys.stderr)
    print("Uncommitted edits stay in the original checkout.", file=sys.stderr)
    name = prompt("New worktree name (blank cancels): ")
    if not name:
        return None
    if "/" in name or "\\" in name or name.startswith("-"):
        raise ValueError("Use a worktree name without slashes or a leading dash.")
    subprocess.run(["git", "check-ref-format", "--branch", name], check=True, stdout=subprocess.DEVNULL)
    for package in (workspace / "src").iterdir():
        if (package / ".git").exists() and subprocess.run(
            ["git", "-C", str(package), "show-ref", "--verify", "--quiet", f"refs/heads/{name}"],
        ).returncode == 0:
            raise ValueError(f"Branch {name} already exists in {package.name}; reuse it from the picker.")
    subprocess.run(
        ["brazil", "worktree", "create", "--workspace", str(workspace),
         "--name", name, "--inheritAll"], check=True, stdout=sys.stderr,
    )
    path = workspace / "worktrees" / name / "src" / parent.name
    return {"parent": str(parent), "path": str(path)}


def main():
    mode = sys.argv[1]
    if mode == "current":
        print("\n".join(current_rows(Path.cwd())))
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
            open_worktree(selected)
        elif mode == "delete":
            delete_worktree(selected)
        elif mode == "create":
            created = create_worktree(selected)
            if created:
                if os.environ.get("HERDR_ENV") == "1":
                    open_worktree(created)
                else:
                    print(created["path"])
        else:
            raise ValueError(f"Unknown worktree action: {mode}")


if __name__ == "__main__":
    try:
        main()
    except (subprocess.CalledProcessError, OSError, ValueError) as error:
        if isinstance(error, subprocess.CalledProcessError) and error.stderr:
            print(error.stderr.decode(errors="replace").strip(), file=sys.stderr)
        else:
            print(error, file=sys.stderr)
        if sys.argv[1] in ("create", "delete") and sys.stderr.isatty():
            prompt("Press Enter to close.")
        sys.exit(getattr(error, "returncode", 1))
    except KeyboardInterrupt:
        sys.exit(130)
