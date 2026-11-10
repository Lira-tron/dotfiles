#!/usr/bin/env python3
"""List Git worktrees for Television and open existing checkouts in Herdr."""

import base64
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import shutil
import stat
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


def rows(records, under=None, seen_workspaces=None):
    if seen_workspaces is None:
        seen_workspaces = set()
    parent = Path(records[0]["worktree"]).resolve()
    for record in records:
        path = Path(record["worktree"]).resolve()
        if path == parent or not path.is_dir() or "bare" in record or "prunable" in record:
            continue
        if under is not None and not path.is_relative_to(under):
            continue
        workspace = path.parent.parent
        if path.parent.name == "src" and (workspace / "packageInfo").is_file():
            if workspace in seen_workspaces:
                continue
            seen_workspaces.add(workspace)
            label = f"[tree] {workspace.parent.parent.name} · {workspace.name}"
        else:
            branch = record.get("branch", "").removeprefix("refs/heads/")
            branch = branch or f"detached {record.get('HEAD', '')[:7]}"
            label = f"[tree] {parent.name} · {branch}"
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
    seen_workspaces = set()
    for repo in repositories(root):
        if repo in seen:
            continue
        try:
            records = checkouts(repo)
        except subprocess.CalledProcessError as error:
            print(error.stderr.decode(errors="replace").strip(), file=sys.stderr)
            continue
        seen.update(Path(record["worktree"]).resolve() for record in records)
        yield from rows(records, under=root if restrict_paths else None, seen_workspaces=seen_workspaces)


def current_workspace(root):
    root = root.resolve()
    for directory in (root, *root.parents):
        if (directory / "packageInfo").is_file():
            owner = directory.parent.parent
            if directory.parent.name == "worktrees" and (owner / "packageInfo").is_file():
                return owner
            return directory
    return None


def current_rows(root):
    root = root.resolve()
    workspace = current_workspace(root)
    if workspace is not None:
        return list(workplace_rows(workspace, restrict_paths=False))
    for scope in (root, *root.parents):
        if scope == scope.parent:
            break
        found = list(workplace_rows(scope, restrict_paths=False))
        if found:
            return found
    return []


def current_parent(root):
    try:
        package = subprocess.check_output(
            ["brazil-context", "package", "root"], cwd=root, stderr=subprocess.PIPE, timeout=10,
        )
        repo = Path(os.fsdecode(package).strip())
    except subprocess.CalledProcessError:
        workspace = current_workspace(root)
        if workspace is None:
            raise
        packages = [path for path in sorted((workspace / "src").iterdir()) if (path / ".git").exists()]
        if not packages:
            raise ValueError(f"No Git packages in Brazil workspace: {workspace}")
        preferred = workspace / "src" / workspace.name
        repo = preferred if preferred in packages else packages[0]
    return checkouts(repo)[0]["worktree"]


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

    parent = Path(selected["parent"]).resolve()
    owner = brazil_workspace(parent) if brazil_root else None
    if owner:
        # Herdr groups by Git repository; use one package for the Brazil workspace.
        parents = [
            Path(worktree["checkout_path"]).resolve()
            for workspace in snapshot["workspaces"]
            if (worktree := workspace.get("worktree"))
            and not worktree.get("is_linked_worktree")
            and Path(worktree["checkout_path"]).resolve().parent == owner / "src"
        ]
        for repo in [owner / "src" / owner.name, *parents]:
            checkout = brazil_root / "src" / repo.name
            if (repo / ".git").exists() and (checkout / ".git").exists():
                parent, path = repo, checkout
                break
        else:
            if parents:
                # A partial worktree may omit the group's representative package.
                subprocess.run(
                    ["herdr", "workspace", "create", "--cwd", str(brazil_root),
                     "--label", brazil_root.name, "--focus"],
                    check=True,
                )
                return

    subprocess.run(
        ["herdr", "worktree", "open", "--cwd", str(parent),
         "--path", str(path), "--focus"],
        check=True,
    )


def workspace_close_targets(workspace_id):
    snapshot = json.loads(subprocess.check_output(["herdr", "api", "snapshot"]))["result"]["snapshot"]
    workspace = next(
        (item for item in snapshot["workspaces"] if item["workspace_id"] == workspace_id), None,
    )
    if workspace is None:
        raise ValueError(f"Herdr workspace {workspace_id} no longer exists.")
    worktree = workspace.get("worktree") or {}
    if worktree.get("repo_key") and not worktree.get("is_linked_worktree"):
        return [
            item for item in snapshot["workspaces"]
            if (item.get("worktree") or {}).get("repo_key") == worktree["repo_key"]
        ]
    return [workspace]


def close_workspace(workspace_id):
    targets = workspace_close_targets(workspace_id)
    command = ["herdr", "workspace", "close", workspace_id]
    if len(targets) > 1:
        print("Closing this parent also closes its linked Herdr workspaces:", file=sys.stderr)
        for workspace in targets:
            print(
                f"  {workspace['label']} ({workspace['workspace_id']}): "
                f"{workspace['worktree']['checkout_path']}", file=sys.stderr,
            )
        print("Their panes will close. Files and Git worktrees are kept.", file=sys.stderr)
        if prompt("Type ok to close these workspaces (blank cancels): ") != "ok":
            return
        if {item["workspace_id"] for item in targets} != {
            item["workspace_id"] for item in workspace_close_targets(workspace_id)
        }:
            raise ValueError("The workspace group changed; reopen the picker to review it.")
        command.append("--group")
    subprocess.run(command, check=True)


def delete_worktree(selected, force=False):
    parent, path = (Path(selected[key]).resolve() for key in ("parent", "path"))
    if path == parent:
        raise ValueError("The primary checkout cannot be deleted from this picker.")
    owner, workspace = brazil_workspace(parent), brazil_workspace(path)
    if (owner is None) != (workspace is None):
        raise ValueError("Cannot resolve the Brazil worktree and its parent; inspect them before cleanup.")
    target = workspace or path
    open_panes = []
    if os.environ.get("HERDR_ENV") == "1":
        snapshot = json.loads(subprocess.check_output(["herdr", "api", "snapshot"]))
        open_panes = [
            pane["pane_id"] for pane in snapshot["result"]["snapshot"]["panes"]
            if any(
                cwd and Path(cwd).resolve().is_relative_to(target)
                for cwd in (pane.get("foreground_cwd"), pane.get("cwd"))
            )
        ]
        open_panes.sort(key=lambda pane: pane == os.environ.get("HERDR_PANE_ID"))
    repos = repositories(workspace) if workspace else [path]
    for repo in repos:
        artifacts = repo / ".ai"
        if artifacts.is_symlink():
            if artifacts.resolve().is_relative_to(target):
                raise ValueError(f"Move artifact storage outside the worktree before deleting: {artifacts}")
        elif artifacts.exists() and (not artifacts.is_dir() or any(artifacts.iterdir())):
            raise ValueError(f"Preserve and migrate {artifacts} before deleting this worktree.")
    if workspace:
        if workspace != owner / "worktrees" / workspace.name:
            raise ValueError("This is not a native Brazil task worktree; inspect it before cleanup.")
        if any(repo.parent != workspace / "src" for repo in repos):
            raise ValueError("Remove the nested Git checkouts before deleting this Brazil worktree.")
        command = ["brazil", "worktree", "delete", "--workspace", str(owner), "--name", workspace.name]
        scope = "all package checkouts, branches (including unmerged branches), build outputs, and local artifact links"
    else:
        command = ["git", "-C", str(parent), "worktree", "remove", str(path)]
        scope = "this checkout and local artifact links; its Git branch and external artifacts are retained"
    dirty = [
        repo for repo in repos
        if subprocess.check_output(["git", "-C", str(repo), "status", "--porcelain"])
    ]
    if workspace or force or dirty:
        command.append("--force")
    print(f"Delete {target}\nThis removes {scope}. Preserve needed work first.", file=sys.stderr)
    if dirty:
        print("Uncommitted changes will be discarded in: " + ", ".join(map(str, dirty)), file=sys.stderr)
    if open_panes:
        print("Open Herdr panes will be closed: " + ", ".join(open_panes), file=sys.stderr)
    if prompt("Type ok to delete (blank cancels): ") != "ok":
        return
    for directory, _, _ in os.walk(target, followlinks=False):
        mode = os.stat(directory, follow_symlinks=False).st_mode
        if stat.S_ISDIR(mode) and not mode & stat.S_IWUSR:
            os.chmod(directory, mode | stat.S_IWUSR, follow_symlinks=False)
    subprocess.run(command, check=True, cwd=parent)
    for pane in open_panes:
        subprocess.run(["herdr", "pane", "close", pane], check=True, cwd=parent)


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
    created = datetime.now(timezone.utc)
    feature = name.removesuffix("-" + created.strftime("%m%d"))
    if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", feature):
        raise ValueError("Use a lowercase kebab-case feature name for artifact storage.")
    artifact_tool = Path.home() / ".local/bin/ai-artifacts"
    if not artifact_tool.is_file():
        raise ValueError("Install the shared ai-artifacts helper with make link before creating a worktree.")
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
    for package in sorted(path.parent.iterdir()):
        if (package / ".git").exists():
            subprocess.run(
                [str(artifact_tool), "init", "--cwd", str(package), "--feature", feature,
                 "--date", created.strftime("%y-%m-%d")],
                check=True, stdout=sys.stderr,
            )
    return {"parent": str(parent), "path": str(path)}


def main():
    mode = sys.argv[1]
    if mode == "current":
        print("\n".join(current_rows(Path.cwd())))
    elif mode == "all":
        print("\n".join(workplace_rows(Path.home() / "workplace")))
    elif mode == "close-workspace":
        close_workspace(sys.argv[2])
    else:
        if mode == "create-current":
            parent = current_parent(Path.cwd())
            selected = {"parent": parent, "path": parent}
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
            delete_worktree(selected, force="--force" in sys.argv[3:])
        elif mode in ("create", "create-current"):
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
        if sys.argv[1] in ("create", "create-current", "delete", "close-workspace") and sys.stderr.isatty():
            prompt("Press Enter to close.")
        sys.exit(getattr(error, "returncode", 1))
    except KeyboardInterrupt:
        sys.exit(130)
