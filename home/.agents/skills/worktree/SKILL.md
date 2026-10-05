---
name: worktree
description: Create or reuse a task worktree before implementation, builds, tests, reviews, or commits. Use when starting or continuing coding work, creating a branch, or moving existing edits into an isolated checkout.
---

# Work in a task worktree

All implementation work uses a task worktree. Read-only discovery and primary
checkout maintenance may run outside it. Creating a worktree does not authorize
commits, publication, deployment, or deletion beyond the user's task.

## Select the task and repository

1. Resolve the actual Git root and read its instructions. For managed dotfiles,
   first resolve the canonical source using `edit-dotfiles`.
2. Inspect `git worktree list --porcelain`, the current branch, and Git status.
   Reuse the worktree already holding this task, including follow-up fixes,
   reviews, and commits. Create a sibling for a different implementation task.
   Do not create another worktree for each workflow phase or committer.
3. Record the primary checkout, task worktree, intended integration branch,
   starting commit, and upstream for each repository in the task's `.ai/`.
   Pass absolute task paths to tools and delegated agents; a shell `cd` does
   not change every tool's working directory.

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

Check for an existing task path and branch before creating anything. Reuse the
matching task; resolve a conflicting name without resetting an existing
branch. Initialize only required submodules in the new checkout.

## Run and finish the task

Perform task edits, builds, tests, reviews, commits, and CR/PR commands in the
selected worktree. Keep `.ai/` evidence inside its owning repository. Invoke
the user's quality workflows only when requested; worktree setup does not
implicitly invoke `/go`. The committer and read-only reviewers use this task's
paths. Independent concurrent implementations use separate worktrees.

Resolve Git metadata paths with `git rev-parse --git-path <path>` rather than
assuming `.git` is a directory. Some metadata, including `info/exclude`, is
shared with sibling worktrees; preserve existing entries.

Worktrees isolate local files, not AWS accounts, databases, ports, or other
external resources. Coordinate access to shared development environments.

Keep the worktree available for revisions. Before authorized cleanup, fetch,
verify where every task commit is retained, and preserve useful ignored `.ai/`
records. A clean status alone does not establish that removal is safe. Use the
owning worktree tool without force; do not delete worktrees automatically when
a subagent or session exits. Report the worktree path with the result.
