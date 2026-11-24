#!/usr/bin/env python3
"""Share previous-pane history between Herdr tab shortcuts and Television."""

import fcntl
import hashlib
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile


def request(endpoint, method, **params):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(5)
        connection.connect(str(endpoint))
        message = {"id": "tv-previous-pane", "method": method, "params": params}
        connection.sendall((json.dumps(message) + "\n").encode())
        with connection.makefile() as stream:
            response = json.loads(stream.readline())
    if "error" in response:
        raise RuntimeError(response["error"]["message"])
    return response["result"]


def history_path(endpoint):
    # A new server can reuse pane IDs, so its socket gets separate history.
    stat = endpoint.stat()
    identity = f"{endpoint.resolve()}:{stat.st_ino}:{stat.st_ctime_ns}"
    key = hashlib.sha256(identity.encode()).hexdigest()
    cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    return cache / "television" / "herdr" / f"{key}.previous-pane"


def remember(path, pane_id):
    if pane_id is None:
        path.unlink(missing_ok=True)
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as temporary:
        temporary.write(pane_id)
    os.replace(temporary.name, path)


def main():
    endpoint = Path(os.environ["HERDR_SOCKET_PATH"])
    history = history_path(endpoint)
    history.parent.mkdir(parents=True, exist_ok=True)
    # Shell keybindings run concurrently; serialize their focus/history changes.
    with history.with_suffix(".lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        return navigate(endpoint, history, sys.argv[1])


def navigate(endpoint, history, action):
    snapshot = request(endpoint, "session.snapshot")["snapshot"]
    current = snapshot["focused_pane_id"]

    if action in ("connect", "next-tab", "previous-tab"):
        previous = history.read_text() if history.exists() else None
        remember(history, current)
        try:
            if action == "connect":
                result = subprocess.run(["bash", "-c", sys.stdin.read()]).returncode
            else:
                tabs = sorted(
                    (tab for tab in snapshot["tabs"]
                     if tab["workspace_id"] == snapshot["focused_workspace_id"]),
                    key=lambda tab: tab["number"],
                )
                if tabs:
                    index = next(i for i, tab in enumerate(tabs)
                                 if tab["tab_id"] == snapshot["focused_tab_id"])
                    offset = 1 if action == "next-tab" else -1
                    request(endpoint, "tab.focus", tab_id=tabs[(index + offset) % len(tabs)]["tab_id"])
                result = 0
            if result or request(endpoint, "session.snapshot")["snapshot"]["focused_pane_id"] == current:
                remember(history, previous)
            return result
        except (OSError, RuntimeError):
            remember(history, previous)
            raise
    elif action == "previous":
        if not history.exists():
            raise RuntimeError("No previous pane yet; first switch with the picker or Ctrl+A n/p.")
        previous = history.read_text()
        if previous != current:
            remember(history, current)
            try:
                request(endpoint, "pane.focus", pane_id=previous)
            except (OSError, RuntimeError):
                remember(history, previous)
                raise
    else:
        raise RuntimeError("Expected connect, next-tab, previous-tab, or previous.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, RuntimeError) as error:
        print(f"Herdr previous pane: {error}", file=sys.stderr)
        sys.exit(1)
