#!/usr/bin/env python3
"""Rex sessions for Television: list them, and open worktrees or directories as sessions."""

import base64
import contextlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

# Importing worktrees.py must not write bytecode into the dotfiles source.
sys.dont_write_bytecode = True

WORKTREES = Path(__file__).resolve().parent / "worktrees.py"
NONE = "none"
REMOTE_PREFIX = "🥊-"

_spec = importlib.util.spec_from_file_location("worktrees", WORKTREES)
worktrees = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(worktrees)


def rex_json(*args):
    return json.loads(subprocess.check_output(["rex", *args, "--json"], stderr=subprocess.PIPE))


def on(server):
    return ["-S", server] if server else []


def sessions(server=None):
    return rex_json(*on(server), "ls")["sessions"]


def session_rows():
    for session in sessions():
        label = session["label"].replace("\t", " ").replace("\n", " ").replace("'", "’")
        yield f"[session] {label}\t{session['session_id']}"


def session_name(path):
    # A Brazil checkout belongs to its workspace (or task worktree), whose directory names the session.
    path = Path(path).resolve()
    for directory in (path, *path.parents):
        if (directory / "packageInfo").is_file():
            return directory.name
    return path.name


def labelled(label, server=None):
    return [session["session_id"] for session in sessions(server) if session["label"] == label]


def select(session_id, server=None):
    subprocess.run(
        ["rex", *on(server), "do", "session.select", f"session_id={session_id}"],
        check=True, stdout=subprocess.DEVNULL,
    )


def session_label(label, server):
    # Run on a Linux host, the picker's own Rex server is that remote host too.
    remote = server or sys.platform != "darwin"
    return REMOTE_PREFIX + label if remote and not label.startswith(REMOTE_PREFIX) else label


def open_session(path, label=None, server=None):
    label = session_label(label or session_name(path), server)
    found = labelled(label, server)
    # A local directory doesn't exist on a remote host, so a remote session starts in its home.
    cwd = [] if server else ["-c", str(path)]
    session_id = found[0] if found else rex_json(*on(server), "new", label, *cwd)["session_id"]
    select(session_id, server)


def pick_server():
    remote = [host["host"]["label"] for host in rex_json("hosts")["hosts"]]
    if not remote:
        return None
    choice = worktrees.prompt(f"Create it on remote ({', '.join(remote)})? [Y/n]: ").lower()
    if choice in ("n", "no"):
        return None
    if choice in ("", "y", "yes") and len(remote) == 1:
        return remote[0]
    if choice in remote:
        return choice
    raise ValueError(f"Answer y or n, or name one of the Rex hosts: {', '.join(remote)}")


def kind(value):
    if value == NONE:
        return "none"
    if value.startswith("session:"):
        return "session"
    if value.startswith("/"):
        return "dir"
    return "tree"


def tree(value):
    return json.loads(base64.urlsafe_b64decode(value))


def connect(value):
    if kind(value) == "session":
        select(value)
    elif kind(value) == "dir":
        open_session(value)
    elif kind(value) == "none":
        create(value)
    else:
        open_session(tree(value)["path"])


def preview(value):
    if kind(value) == "session":
        view = rex_json("session", "inspect", value)
        window = next(w for w in view["windows"] if w["window_id"] == view["active_window_id"])
        screen = subprocess.check_output(
            ["rex", "capture", "-s", value, "-b", window["focused_block_id"], "--trim"]
        )
        sys.stdout.write("\n".join(screen.decode(errors="replace").splitlines()[-200:]) + "\n")
    elif kind(value) == "dir":
        os.execvp("eza", ["eza", "-la", "--color=always", value])
    elif kind(value) == "none":
        print("No worktrees here. Press Enter or Ctrl+G to create one.")
    else:
        os.execv(sys.executable, [sys.executable, str(WORKTREES), "preview", value])


def kill_sessions(session_ids):
    if session_ids:
        subprocess.run(["rex", "session", "kill", *session_ids], check=True, stdout=subprocess.DEVNULL)


def delete(value, force, confirm=None):
    if kind(value) == "session":
        if not force:
            label = next(s["label"] for s in sessions() if s["session_id"] == value)
            print(f"Close Rex session {label}. Its programs will end; files are kept.", file=sys.stderr)
            if worktrees.prompt("Type ok to close it (blank cancels): ") != "ok":
                return
        kill_sessions([value])
    elif kind(value) == "tree":
        selected = tree(value)
        found = labelled(session_name(selected["path"]))
        if found:
            print(f"Rex session {session_name(selected['path'])} will be closed.", file=sys.stderr)
        worktrees.delete_worktree(selected, force=force, confirm=confirm)
        if not Path(selected["path"]).exists():
            kill_sessions(found)


def create(value, name=None):
    if kind(value) == "session":
        server = pick_server()
        name = worktrees.prompt("New Rex session name (blank cancels): ")
        if name:
            open_session(Path.cwd(), name, server)
        return
    if kind(value) == "tree":
        selected = tree(value)
    else:
        parent = worktrees.current_parent(Path.cwd())
        selected = {"parent": parent, "path": parent}
    created = worktrees.create_worktree(selected, name=name)
    if created:
        open_session(created["path"])


def error_message(error):
    if isinstance(error, subprocess.CalledProcessError) and error.stderr:
        return error.stderr.decode(errors="replace").strip()
    return str(error) or type(error).__name__


def native_operation(operation, value, name=None):
    with tempfile.TemporaryFile(mode="w+t") as output:
        def confirm(_):
            output.seek(0)
            result = rex_json("do", "workspace_deletion_confirm", "message=" + output.read())
            return "ok" if result == "ok" else ""

        try:
            with contextlib.redirect_stderr(output):
                if operation == "create":
                    create(value, name)
                elif operation == "delete" and kind(value) == "tree":
                    delete(value, False, confirm=confirm)
                else:
                    raise ValueError("Choose a Git worktree to delete.")
        except (subprocess.CalledProcessError, OSError, ValueError) as error:
            output.seek(0)
            message = "\n".join(filter(None, [error_message(error), output.read()[-4000:]]))
            subprocess.run(
                ["rex", "do", "workspace_operation_failed", "operation=" + operation, "message=" + message],
                check=True, stdout=subprocess.DEVNULL,
            )
            raise


def main():
    mode = sys.argv[1]
    if mode == "sessions":
        print("\n".join(session_rows()))
    elif mode == "current":
        # Television runs no action on an empty list, so a [none] row keeps Enter and Ctrl+G working.
        print("\n".join(worktrees.current_rows(Path.cwd())) or f"[none] No worktrees here\t{NONE}")
    elif mode == "connect":
        connect(sys.argv[2])
    elif mode == "preview":
        preview(sys.argv[2])
    elif mode == "delete":
        delete(sys.argv[2], force="--force" in sys.argv[3:])
    elif mode == "create":
        create(sys.argv[2])
    elif mode == "create-named":
        native_operation("create", sys.argv[2], sys.argv[3])
    elif mode == "delete-native":
        native_operation("delete", sys.argv[2])
    else:
        raise ValueError(f"Unknown Rex worktree action: {mode}")


if __name__ == "__main__":
    try:
        main()
    except (subprocess.CalledProcessError, OSError, ValueError, StopIteration) as error:
        print(error_message(error), file=sys.stderr)
        if sys.argv[1] in ("connect", "create", "delete") and sys.stderr.isatty():
            worktrees.prompt("Press Enter to close.")
        sys.exit(getattr(error, "returncode", 1))
    except KeyboardInterrupt:
        sys.exit(130)
