---
name: edit-dotfiles
description: Edit user-managed home configuration through the stow-based dotfiles/dotfiles repository. Use for changes to shell files, Codex settings or skills, editor settings, and other durable configuration under the user's home directory. Do not use for credentials, caches, histories, generated state, or tool-owned runtime files.
---

# Edit Dotfiles

Manage durable home configuration from:

`/workplace/limonoct/LimonoctNvim/src/LimonoctNvim/dotfiles/dotfiles/home`

GNU Stow links that tree into `/local/home/limonoct`. Edit the repository source instead of editing the linked home path directly.

## Map Home Paths

Translate `/local/home/limonoct/<relative-path>` to:

`/workplace/limonoct/LimonoctNvim/src/LimonoctNvim/dotfiles/dotfiles/home/<relative-path>`

Check `readlink` and both file contents before changing an existing path. Preserve unrelated work in the dirty repository.

## Decide Whether to Track

Track durable, cross-machine configuration. Do not automatically adopt:

- Credentials, tokens, private keys, or machine-specific secrets.
- Caches, histories, logs, lock files, databases, sockets, or session state.
- Files regenerated or exclusively owned by another tool.
- Amazon-internal configuration or knowledge that belongs in the parent repository.

If an untracked home file may fall into one of these categories, ask before moving it into the public repository.

## Make Changes

1. Edit or create the source under `dotfiles/dotfiles/home`.
2. Match the existing style and keep changes scoped to the request.
3. If adopting a real home file, copy it to the source, verify the contents match, then remove the home copy only as needed for Stow.
4. Never remove a tracked source file without explicit user confirmation.

Use `apply_patch` for manual edits.

## Re-link

Run from the child repository:

```bash
make link
```

The full command location is:

```bash
cd /workplace/limonoct/LimonoctNvim/src/LimonoctNvim/dotfiles/dotfiles
make link
```

If Stow reports a conflict, compare the home file and source with `diff -u`. Remove a real home file only when it matches the source or the user has selected the source as canonical. Retry `make link` after resolving the conflict.

## Verify

Confirm the command succeeded and that the home path resolves to the intended source. Report the source path and any file intentionally left unmanaged.
