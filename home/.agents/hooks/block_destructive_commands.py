#!/usr/bin/env python3
"""PreToolUse hook: Block destructive shell commands that could damage workspaces or push to remote."""

import json
import re
import sys


def check_command(command: str):
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

    # Block git push (all variants: plain, --force, --force-with-lease, etc.)
    if re.search(r"\bgit\s+push\b", command):
        return True, "Blocked: git push is not allowed. Commits stay local."

    # Block sudo
    if re.search(r"\bsudo\s+", command):
        return True, "Blocked: sudo commands are not allowed."

    return False, None


def main():
    tool_input = json.load(sys.stdin)
    command = tool_input.get("tool_input", {}).get("command", "")

    blocked, reason = check_command(command)
    if blocked:
        print(reason, file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
