---
name: share-agent-artifacts
description: Create, move, or update durable agent artifacts intended for both Claude Code and Codex. Use for shared skills, prompts, hooks, or other compatible configuration that should have one canonical copy under home/.agents with tool-specific links or adapters.
---

# Share Agent Artifacts

Manage shared Claude Code and Codex artifacts from the dotfiles repository:

`/workplace/limonoct/LimonoctNvim/src/LimonoctNvim/dotfiles/dotfiles/home/.agents`

GNU Stow exposes this as `~/.agents`. Edit the repository source, not the live home path.

## Sharing model

Keep one canonical artifact under `home/.agents/<kind>/`. Do not assume either client automatically discovers files there. Expose the canonical artifact from each client's expected location with a relative symlink or, when their formats differ, a thin tool-specific adapter.

For a compatible skill named `<name>`, use:

```text
home/.agents/skills/<name>/         # canonical files
home/.claude/skills/<name>          -> ../../.agents/skills/<name>
home/.codex/skills/<name>           -> ../../.agents/skills/<name>
```

Only share an artifact when both clients can consume the same format and semantics. Otherwise share only the common payload and keep the incompatible configuration in the client-specific directories.

## Workflow

1. Inspect the canonical and client-specific paths with `readlink`, and compare existing contents before changing them.
2. Place durable common files under `home/.agents`; do not adopt credentials, caches, histories, generated state, or other machine-specific data.
3. Add the minimum relative links or adapters needed for Claude Code and Codex discovery.
4. Remove a duplicate only after verifying it matches the canonical copy or the user selected which copy is authoritative.
5. Run `make link` from the dotfiles repository.
6. Verify each live client path with `readlink -f` and confirm it resolves to the intended canonical artifact.

Preserve unrelated work in the repository and keep changes limited to the requested artifact.
