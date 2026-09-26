#!/usr/bin/env python3
"""Remember and revisit the pane left by a Herdr Television selection."""

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
    current = request(endpoint, "session.snapshot")["snapshot"]["focused_pane_id"]

    if sys.argv[1] == "connect":
        previous = history.read_text() if history.exists() else None
        remember(history, current)
        result = subprocess.run(["bash", "-c", sys.stdin.read()])
        if result.returncode or request(endpoint, "session.snapshot")["snapshot"]["focused_pane_id"] == current:
            remember(history, previous)
        return result.returncode
    elif sys.argv[1] == "previous":
        if not history.exists():
            raise RuntimeError("No previous pane yet; first switch panes with the picker.")
        previous = history.read_text()
        if previous != current:
            remember(history, current)
            try:
                request(endpoint, "pane.focus", pane_id=previous)
            except (OSError, RuntimeError):
                remember(history, previous)
                raise
    else:
        raise RuntimeError("Expected connect or previous.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, RuntimeError) as error:
        print(f"Herdr previous pane: {error}", file=sys.stderr)
        sys.exit(1)
