---
name: edit-dotfiles
description: Edit config files inside the stow-based dotfiles repo and re-stow them with `make link`. Use this skill whenever the user asks to modify, add, or tweak any config under `$HOME` that lives in dotfiles — `.zshrc`, `.zshenv`, `.zprofile`, anything under `.config/`, `.local/`, `.claude/`, `.kiro/`, `.meshclaw/`, `.aws/`, `.unison/`, the `Makefile`, or any other tracked dotfile. Trigger even if the user phrases it as "change my config", "update my zshrc", "add this to claude settings", "tweak my tmux config", "modify my aliases", etc. — direct edits to `$HOME` are wrong because they bypass version control and get clobbered by the next `make link`.
---

# Edit Dotfiles

Modify config files in a task worktree of the user's stow-based dotfiles repo,
then activate validated changes through the stable Stow sources and `make link`.
Never edit the live `$HOME` copy.

## Why this skill exists

The user's home configs are managed by GNU Stow. Real files live in two source trees and are symlinked into `$HOME`. Editing files in `$HOME` directly:

- Isn't version-controlled (changes vanish on a fresh machine).
- Gets silently overwritten by the next `make link --restow`.
- Can corrupt the symlink graph if a real file replaces a symlink.

The paths below identify the stable canonical sources. Edit their counterparts
in the selected task worktree, then integrate and re-stow.

## The mental flip: `~/.<anything>` → dotfiles source

Whenever the user asks for a change to a file in `$HOME` — phrased as `~/.zshrc`, `~/.config/foo`, `~/.claude/settings.json`, "my zshrc", "my claude config", whatever — translate it before touching anything:

> `~/<rel>` is almost certainly a symlink into one of the two dotfiles repos. **Edit the source, not the symlink target.**

Quick check if you're unsure:

```bash
readlink "$HOME/<rel>"
# e.g. readlink ~/.zshrc → /workplace/limonoct/LimonoctNvim/src/LimonoctNvim/dotfiles/dotfiles/home/.zshrc
```

If `readlink` returns a path inside one of the two dotfiles repos, map that file
to the same repository-relative path in the task worktree. If it returns nothing
(not a symlink), you've found one of two cases:

- The file isn't tracked yet — create it under the appropriate `<repo>/home/<rel>` and stow will pick it up.
- The file is a real file shadowing a tracked source — that's a stow conflict in waiting; handle it via the conflict workflow below.

## The two repos

The user has **two nested dotfiles repos** that share the same `make link` flow:

| Repo | Path | Purpose |
|---|---|---|
| **Parent (Amazon-internal)** | `/workplace/limonoct/LimonoctNvim/src/LimonoctNvim/dotfiles/` | Amazon-only configs: `.aws`, `.claude`, `.kiro`, `.meshclaw`, `.unison`, `knowledge/` |
| **Child (public)** | `/workplace/limonoct/LimonoctNvim/src/LimonoctNvim/dotfiles/dotfiles/` | Cross-machine configs: `.zshrc`, `.zshenv`, `.zprofile`, `.config/`, `.local/`, `.cache/` |

Both source trees stow their `home/` subdirectory into `$HOME`. The parent's `Makefile` includes the child's, so a single `make link` from the parent re-stows everything in the right order.

Source files live under `<repo>/home/<rel-path>` and end up at `$HOME/<rel-path>`. Example: `dotfiles/dotfiles/home/.zshrc` → `$HOME/.zshrc`.

## Workflow

### 1. Locate the file

Take what the user described (e.g., "my zshrc", "claude settings", "kiro agents config") and convert it to a relative path under `$HOME` (e.g., `.zshrc`, `.claude/settings.json`, `.kiro/agents/foo.json`).

Then, **even if the path looks obvious, ask which repo to edit.** The user explicitly asked for confirmation here. Phrase the question concretely:

> Want me to edit this in the **parent (Amazon)** repo or the **child (public)** repo?
> - parent: `/workplace/limonoct/LimonoctNvim/src/LimonoctNvim/dotfiles/home/<path>`
> - child:  `/workplace/limonoct/LimonoctNvim/src/LimonoctNvim/dotfiles/dotfiles/home/<path>`

If the file already exists in only one of the two, mention that and recommend that one. If it exists in both, that's a real problem — surface it before editing (one of them is dead weight or a mistake).

### 2. Edit the source in a task worktree

Read `~/.agents/skills/worktree/SKILL.md`. Create or reuse the task worktree for
the selected repository, then edit its `home/<path>` counterpart. Match existing
style and keep edits surgical.

The internal parent belongs to a Brazil package; the public child is a separate
Git repository ignored by that package. A Brazil worktree does not copy the
public checkout. For a task spanning both, create a linked Git worktree of the
public repository at the expected nested path, using its verified intended
branch. Do not replace that nested path with a symlink to the primary checkout.

Create new files in the selected task source tree.

### 2.5. Validate and integrate before activation

Validate in the task worktrees. With local commits and integration authorized,
delegate scoped commits to the committer and fast-forward the stable canonical
checkouts to those commits, preserving unrelated edits. If a stable branch has
advanced incompatibly, reconcile in the task worktree rather than overwriting
the stable checkout. Honor an explicit no-commit or no-activation restriction;
present the validated changes for the missing authorization.

Run `make link` only from the stable parent after integration. Live configuration
links must continue to point at stable canonical sources, not disposable task
worktrees. Keep worktrees and their evidence until integration is verified.

### 3. Run `make link`

Always re-stow from the **parent** repo (its Makefile includes the child's, so one invocation covers both):

```bash
cd /workplace/limonoct/LimonoctNvim/src/LimonoctNvim/dotfiles && make link
```

Show the output. Stow's `--verbose --restow` prints `LINK:` lines for every symlink it touches — that's normal and noisy. The thing to watch for is errors.

### 3.5. If the file isn't tracked yet, ask before adopting it

When the user wants to edit a file that exists in `$HOME` but **not** in either dotfiles repo, don't silently move it into the source tree. Some files belong in `$HOME` only:

- Tool-managed files that get regenerated automatically by their owning tool. This is *per-file*, not per-directory — within the same folder, some files may be tool-rewritten and others hand-curated. Don't generalize from one file to its siblings.
- Runtime state, caches, lockfiles, history files (e.g., `~/.zsh_history`, `~/.cache/...`).
- Machine-specific values (credentials, hostnames, secrets) that shouldn't sync across machines.
- Files written by app installers that the app expects to own.

**Ask the user**: "This file isn't tracked in dotfiles. Should I (a) move it into the source tree so it's version-controlled going forward, or (b) edit it directly in `$HOME` (one-off, won't sync)?" If the file looks like it might be tool-managed or runtime state, flag that observation in the question — but let the user confirm rather than assume.

If the answer is (a), `mv "$HOME/<rel>" "<repo>/home/<rel>"`, then `make link` so the symlink points at the new source. If the answer is (b), edit `$HOME/<rel>` directly — and consider whether the specific file should be added to a stow ignore in the Makefile to prevent future conflicts.

### 4. Handle stow conflicts

`stow` fails when a real (non-symlink) file in `$HOME` shadows a source file. The error looks like:

```text
WARNING! stowing home would cause conflicts:
  * existing target is neither a link nor a directory: .kiro/agents/foo.json
```

When this happens, **don't blindly delete.** The user wants you to compare first:

1. For each conflicting path `<rel>`, compare `$HOME/<rel>` against the source `<repo>/home/<rel>`:
   ```bash
   diff -u "$HOME/<rel>" "<repo>/home/<rel>"
   ```
2. **If they're identical**: the real file is just a stale copy. Delete it (`rm "$HOME/<rel>"`) and retry `make link`.
3. **If they differ**: stop and decide. Show the diff, then ask the user which version is canonical:
   - The `$HOME` version may contain hand-edits the user made directly that should be promoted into the source tree.
   - The source version may be the intended one and the `$HOME` copy is stale.
   - The specific file may be tool-regenerated (some configs in a tracked directory get rewritten by their owning tool while neighboring files are hand-curated — evaluate per-file, don't generalize from one file to its siblings). When this is the case, the right move is often to *untrack just that file* from the dotfiles source so the tool can own it in `$HOME`.
   - When in doubt, ask. Don't lose work.

### Always confirm before removing files from the dotfiles source

This is a hard rule: **never `rm` or `git rm` a file from either dotfiles repo without explicit user confirmation.** This applies even when the file looks redundant, stale, tool-managed, or obviously about to be untracked. Removing source files is destructive and changes what gets stowed onto every other machine — show the user what you'd remove and why, and wait for a yes.

Removing files in `$HOME` (to clear stow conflicts, after diffing) is fine following the rules above. Removing files in the source tree is not.

After resolving a conflict, re-run `make link` and confirm it completes cleanly.

Only delete `$HOME/<rel>` files that (a) exist in the source tree at the same relative path and (b) are non-symlinks. Never delete arbitrary files in `$HOME`.

### 5. Confirm the result

After `make link` succeeds, briefly confirm what changed: which file was edited, in which repo, and that it's now linked.

## Things to avoid

- **Editing `$HOME` directly.** Even quick "I'll just append one line" changes bypass version control.
- **Choosing the repo silently.** Always ask, even when it seems obvious — the user explicitly wants this confirmation.
- **Running `make link` from the child dir.** Always run from the parent (`/workplace/limonoct/LimonoctNvim/src/LimonoctNvim/dotfiles/`) so both Makefiles execute in the right order.
- **Auto-deleting conflicting files without diffing.** A real file in `$HOME` may contain unsaved edits. Compare first; only delete when content matches or the user agrees.
- **Skipping `make link`.** An edit without re-stowing leaves the source tree ahead of `$HOME`; nothing actually changes for the user.

## Quick reference

| Task | Where |
|---|---|
| Edit `.zshrc`, `.config/...`, `.local/...` | child: `dotfiles/dotfiles/home/<path>` |
| Edit `.claude/...`, `.kiro/...`, `.aws/...`, `.meshclaw/...` | parent: `dotfiles/home/<path>` |
| Run after every edit | `cd /workplace/limonoct/LimonoctNvim/src/LimonoctNvim/dotfiles && make link` |
| On conflict | `diff -u "$HOME/<rel>" "<repo>/home/<rel>"` → delete only if identical, else ask |
