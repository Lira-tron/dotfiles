# Continue work that started outside a worktree

Prefer reusing an existing task worktree. Transfer only when the task's code
or required artifacts live in another checkout. The source remains intact
until the destination has been verified.

## Capture and copy

1. Identify the task's committed starting point and exact paths. Inventory
   staged changes, unstaged changes, task-relevant untracked files, and ignored
   `.ai/` records. Preserve unrelated work. Ask about ambiguous ownership rather
   than treating all dirty files as part of the task.
2. Create the destination from the same committed state. For Brazil, use the
   Brazil procedure and verify each included package's HEAD. Existing local
   task commits may be the intended base; record them and the eventual review
   base separately.
3. Store the inventory and binary patches under the destination's `.ai/`.
   Capture staged and unstaged patches separately with `git diff --binary
   --full-index --no-ext-diff --no-textconv`, adding `--cached` for the staged
   patch and limiting both to the task paths.
4. Check and apply the staged patch with `git apply --index`, then check and
   apply the unstaged patch without `--index`. This preserves partial staging.
   Skip empty patches. Do not use `git add` to recreate staging.
5. Copy the selected untracked files and `.ai/` records as independent files,
   preserving executable modes and symlinks. Check destination collisions.
   Do not copy `.git`, build caches, credentials, or the entire ignored tree.
   Do not symlink mutable `.ai/` state between worktrees.

## Verify before cleanup

Compare source and destination task inventories, staged and unstaged diffs,
file hashes, executable modes, and symlink targets. Verify relevant untracked
files and selected ignored records explicitly; `git diff` omits them. Recheck
the source snapshot so concurrent edits cannot silently escape the transfer.

Review absolute paths in copied task records and update only those that must
refer to the new checkout. Old build/test reports are historical evidence;
run the checks needed for the current checkout before claiming it is verified.

Report the destination and preserved source. Original cleanup is a separate
step: perform it only when authorized, the transfer is verified, and the work
has a retained recovery copy or task commit. Remove or restore only the exact
transferred source paths after rechecking them. Never use a broad stash,
`reset --hard`, or `git clean` to make the primary checkout clean.
