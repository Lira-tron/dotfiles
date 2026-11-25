#!/usr/bin/env python3
"""PreToolUse hook: Block destructive shell commands that could damage workspaces or push to remote."""

import json
import re
import shlex
import sys
from pathlib import PurePosixPath

from shell_commands import inert_data_command


def dangerous_remove(command: str):
    """Check whether a shell command should be blocked.

    Returns (blocked: bool, reason: str | None).
    """
    # Block rm -rf on dangerous root-level paths. Handles:
    #   - Combined flags: -rf, -fr, -rfv, -Rf, etc. (any flag string containing both r and f)
    #   - Separate flags: rm -r -f /, rm -f -r /
    #   - Long flags: rm --recursive --force /, rm --force --recursive /
    #   - Argument separator: rm -rf -- /
    #   - Trailing slash: rm -rf ~/
    #   - Glob expansion: rm -rf /*
    #   - Extra arguments: rm -rf / somefile
    # Blocked root paths: /, ~, $HOME, .., /src
    rm_flags_combined = r"-(?:[a-zA-Z]*(?:rf|fr|[rR]f|f[rR])[a-zA-Z]*)"
    rm_flags_separate = r"-[a-zA-Z]*[rR][a-zA-Z]*\s+-[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*\s+-[a-zA-Z]*[rR][a-zA-Z]*"
    rm_flags_long = r"--recursive\s+--force|--force\s+--recursive"
    rm_flags = rf"(?:{rm_flags_combined}|{rm_flags_separate}|{rm_flags_long})"
    rm_target = r"(?:/|~|\$HOME|\.\.|/src)/?\*?(?=\s|$|[;&|])"
    rm_pattern = rf"\brm\s+{rm_flags}\s+(?:--\s+)?{rm_target}"
    if re.search(rm_pattern, command):
        return True, "Blocked: destructive rm -rf on a broad path"
    return False, None


def legacy_check_command(command: str):
    """Retain conservative protections for syntax not proven to be inert data."""
    blocked, reason = dangerous_remove(command)
    if blocked:
        return blocked, reason

    # Block git push (all variants: plain, --force, --force-with-lease, etc.)
    if re.search(r"\bgit\s+push\b", command):
        return True, "Blocked: git push is not allowed. Commits stay local."

    # Block CR publishing flags anywhere in the command's arguments.
    cr_publish = r"(?:^|[\s/;&|()])cr(?=\s)[^;&|\n]*\s--(?:auto-)?publish(?=\s|$|[;&|])"
    if re.search(cr_publish, command.replace("\\\n", "")):
        return True, "Blocked: CR publishing is not allowed. Use --no-auto-publish and leave the revision unpublished."

    # Block sudo
    if re.search(r"\bsudo\s+", command):
        return True, "Blocked: sudo commands are not allowed."

    return False, None


def git_subcommand(words):
    """Find the Git operation after global options."""
    index = 1
    value_options = {"-c", "-C", "--git-dir", "--work-tree", "--namespace", "--config-env"}
    while index < len(words) and words[index].startswith("-"):
        index += 2 if words[index] in value_options else 1
    return words[index:] if index < len(words) else []


def git_prohibition(command):
    """Conservatively inspect Git words, including literal Python argv arrays."""
    words = re.findall(r"[\w./=:-]+", command)
    for index, word in enumerate(words):
        if PurePosixPath(word).name != "git":
            continue
        operation = git_subcommand(words[index:])
        if operation and operation[0] == "push":
            return True, "Blocked: git push is not allowed. Commits stay local."
        if operation and (operation[0] == "clean" or
                          (operation[0] == "reset" and "--hard" in operation)):
            return True, "Blocked: destructive Git cleanup is not allowed."
    return False, None


def check_command(command: str):
    """Keep conservative checks, except for narrowly verified literal-data cases."""
    try:
        # Only the header is shell syntax in a here-document. Do not parse its body.
        words = shlex.split(command.split("\n", 1)[0])
    except ValueError:
        return True, "Blocked: malformed shell quoting; use a simple command."
    if inert_data_command(command):
        return dangerous_remove(" ".join(words)) if PurePosixPath(words[0]).name == "rm" else (False, None)
    blocked, reason = dangerous_remove(" ".join(words))
    if blocked:
        return blocked, reason
    blocked, reason = legacy_check_command(command)
    return (blocked, reason) if blocked else git_prohibition(command)


def main():
    tool_input = json.load(sys.stdin)
    command = tool_input.get("tool_input", {}).get("command", "")

    blocked, reason = check_command(command)
    if blocked:
        print(reason, file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
