---
name: share-agent-artifacts
description: Create, move, or update durable agent artifacts intended for both Claude Code and Codex. Use for shared skills, prompts, hooks, or other compatible configuration that should have one canonical copy under home/.agents with tool-specific links or adapters.
---

# Share Agent Artifacts

Manage shared Claude Code and Codex artifacts from the appropriate dotfiles repository:

`$DOTFILES_DIR` is where `make link` runs on this machine. When
`$DOTFILES_DIR/dotfiles/Makefile` exists, `$DOTFILES_DIR` is a private layer
and the public repository is its nested `dotfiles/` checkout; otherwise
`$DOTFILES_DIR` is the public repository and there is no private layer.

| Content | Canonical source |
|---|---|
| Employer-specific workflows, internal tools, or internal references | `$DOTFILES_DIR/home/.agents` in the private layer; never the public repository |
| General-purpose artifacts suitable for public distribution | The public repository's `home/.agents` |

GNU Stow exposes both sources as `~/.agents`. Sharing between clients does not
determine public visibility. Keep employer-specific content in the private layer;
when a generic artifact needs an employer integration, keep that integration there.
Without a private layer, do not create employer-specific artifacts; ask first.
Use `edit-dotfiles` for task-worktree edits and activation. The paths above are
the stable canonical sources; edit their counterparts in the task worktree.

## Sharing model

Keep one canonical artifact under `home/.agents/<kind>/`. Do not assume either client automatically discovers files there. Expose the canonical artifact from each client's expected location with a relative symlink or, when their formats differ, a thin tool-specific adapter.

For a compatible skill named `<name>`, keep its canonical files and discovery
links together in the selected repository:

```text
home/.agents/skills/<name>/         # canonical files
home/.claude/skills/<name>          -> ../../.agents/skills/<name>
home/.codex/skills/<name>           -> ../../.agents/skills/<name>
```

Only share an artifact when both clients can consume the same format and semantics. Otherwise share only the common payload and keep the incompatible configuration in the client-specific directories.

## Workflow

1. Select the repository by content using the table above. Inspect the canonical and client-specific paths in both repositories with `readlink`, and compare existing contents before changing them.
2. Place durable common files under `home/.agents`; do not adopt credentials, caches, histories, generated state, or other machine-specific data.
3. Add the minimum relative links or adapters needed for Claude Code and Codex discovery in the same repository as the canonical artifact. When moving an artifact between repositories, move its existing client links too.
4. Remove a duplicate only after verifying it matches the canonical copy or the user selected which copy is authoritative.
5. Integrate validated task changes into the stable source checkouts using the `edit-dotfiles` workflow, then run `make link` from `$DOTFILES_DIR` so every source tree is re-stowed.
6. Verify each live client path with `readlink -f` and confirm it resolves to the intended canonical artifact.

Preserve unrelated work in the repository and keep changes limited to the requested artifact.
