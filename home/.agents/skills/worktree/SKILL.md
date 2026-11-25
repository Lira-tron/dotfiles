---
name: worktree
description: Select the task checkout before implementation, builds, tests, reviews, or commits. Use when starting or continuing coding work, creating a branch, or moving existing edits into an isolated checkout.
---

# Select the task checkout

Implementation uses a task worktree unless Codex's checkout selection below
keeps the current branch. Read-only discovery and primary checkout maintenance
may run outside a task worktree. Creating a worktree does not authorize commits,
publication, deployment, or deletion beyond the user's task.

## Select the task and repository

1. Resolve the actual Git root and read its instructions. For managed dotfiles,
   first resolve the canonical source using `edit-dotfiles`.
2. Inspect `git worktree list --porcelain`, the current branch, and Git status.
   Reuse the worktree already holding this task, including follow-up fixes,
   reviews, and commits.
   Do not create another worktree for each workflow phase or committer.
3. **Codex:** When no task worktree is being reused and the current checkout is
   a regular Git checkout on a branch, ask whether to create a task worktree or
   continue on that branch. Wait for the answer. Honor a choice already made
   for this task. This rule takes precedence over automatic worktree requirements
   in other skills. Other clients create a sibling worktree for a different
   implementation task.
4. Once the selected checkout exists, resolve the feature's external directory
   using [the shared artifact rule](../../rules/ai-artifacts.md). Record the primary
   checkout, selected checkout, user's choice, intended integration branch,
   starting commit, and upstream there. Pass both absolute source and artifact
   paths to tools and delegated agents; a shell `cd` does not change every
   tool's working directory.

When continuing on the current branch, skip starting-point selection, transfer,
and creation; continue at **Run and finish the task**.

If the existing task has edits outside a worktree, read
[transfer.md](references/transfer.md) before moving it. A new checkout alone
does not preserve those edits or ignored task artifacts.

## Choose the starting point

Fetch the intended remote before deciding which commits are local. For a fresh
task, resolve the remote's actual default branch, using its advertised HEAD
rather than guessing `mainline`, `main`, or `development`. Preserve a different
integration branch established by the user or repository, such as a personal
configuration branch. Continuing a task uses its recorded base and commits.

Inspect local commits before using the primary checkout's HEAD. Unrelated
commits are not a valid starting point for a fresh task. Leave unrelated edits
and branches intact; do not automatically stash, reset, or commit them.

## Create the worktree

Name new worktrees and their branches with two short, descriptive words joined
by a hyphen, then append `-MMDD` using the creation date's zero-padded month
and day (`date +%m%d`), such as `ams-image-1007` or `fix-index-1007`. Use
lowercase and the same name for a Brazil workspace. Keep review/ticket IDs,
usernames, and hashes in `.ai/` records rather than in names.

When the Git root is a Brazil package root, read
`~/.agents/skills/worktree/references/brazil.md` and use that procedure. A
separately versioned nested repository is its own Git target. If the Brazil
reference is unavailable, report that instead of creating a bare Git worktree
for a Brazil package.

For a standalone Git repository, use an explicit verified starting revision:

```sh
git worktree add -b <task-name> <task-path> <verified-start>
```

Verify the resulting root, branch, HEAD, and remote-tracking upstream. Set the
intended upstream if creation did not establish it; quality gates must not
guess a base because the task branch has no upstream.

Initialize each package's `.ai` link to its own external feature directory
before creating task artifacts. Use the feature slug without the worktree's
`-MMDD` suffix; the artifact helper applies the original `YY-MM-DD` creation
date. On resume, preserve the existing target and date.

Check for an existing task path and branch before creating anything. Reuse the
matching task. If the name belongs to a different task, insert the smallest
available numeric suffix before the date, such as `ams-image-2-1007`, without
resetting an existing branch. Initialize only required submodules in the new
checkout.

## Run and finish the task

Before lengthy validation, follow `~/.agents/rules/workflow-preflight.md` when
present. It supplies the local environment's task-specific readiness checks.

Perform task edits, builds, tests, reviews, commits, and CR/PR commands in the
selected checkout. Keep evidence in its owning package/feature directory. Invoke
the user's quality workflows only when requested; worktree setup does not
implicitly invoke `/go` or `/code-finalizer`. The committer and read-only reviewers use this task's
paths. Independent concurrent implementations use separate worktrees.

Resolve Git metadata paths with `git rev-parse --git-path <path>` rather than
assuming `.git` is a directory. Some metadata, including `info/exclude`, is
shared with sibling worktrees; preserve existing entries.

Worktrees isolate local files, not AWS accounts, databases, ports, or other
external resources. Coordinate access to shared development environments.

When using a worktree, keep it available for revisions. Before authorized
cleanup, fetch, verify where every task commit is retained, and preserve useful
legacy physical `.ai/` records. Retain external feature directories when
removing their checkout links. A clean status alone does not establish that removal is
safe. Use the owning worktree tool without force; do not delete worktrees
automatically when a subagent or session exits. Report the selected checkout
path with the result.
