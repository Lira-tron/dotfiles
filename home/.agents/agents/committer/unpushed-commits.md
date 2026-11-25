# Commit and regroup unpushed work

Read this policy for every commit request, before deciding that a clean working
tree means there is nothing to do. It governs history selection and rewriting
for both committers and the `/commit` dispatcher.

Before saving messages, snapshots, or recovery evidence, resolve the selected
feature using [the shared artifact rule](../../rules/ai-artifacts.md). Keep that
evidence under its `committer/` directory and pass the absolute path to helpers.

## Authority and scope

A request to commit authorizes the committer to reconsider and regroup
the current task's verified unpushed commits together with its staged,
unstaged, and relevant untracked changes. This includes folding review fixes
into their original logical groups and removing work that has been canceled.
Separate rewrite approval is unnecessary within this boundary. Honor explicit
instructions to append only, preserve commits, or approve the plan first.

The committer owns the groups and their number. The dispatcher passes task
context, scope, known base, validation evidence, and user restrictions; it
does not prescribe a squash or a fixed number of commits. `all` includes all
uncommitted work, but does not make unrelated local history part of the task.
An explicit request to regroup all unpushed work broadens that history scope.

Other message-only amendments still require an authorized target and scope.
CR footer amendments follow the separate `submit-cr` rule. Committing or
regrouping grants no permission to push or create, update, or publish a review.

## Select a safe range

1. Inspect status, staged and unstaged diffs, relevant untracked files, task
   context, branch/upstream configuration, and the existing commits and their
   diffs. Include already committed corrections and reversions in the analysis.
2. Before classifying commits as unpushed, fetch every configured remote.
   Verify coverage of its branches and tags, including restricted fetch
   refspecs and distinct push destinations. An ahead count or absence from one
   upstream branch is insufficient. Stop before rewriting if fetching fails,
   publication status is uncertain, or the upstream/base cannot be established.
   Without remotes, rewrite only when the repository is known to be local-only.
3. Record a fixed base and a contiguous task-owned suffix ending at `HEAD`.
   Every replaced commit must be absent from all fetched remote branches and
   tags and have no known prior presence on a source remote. Uploading commits
   to the same code review alone does not freeze them; an automatic merge or
   push does. Verify the source remotes again after review activity.
   Check patch-equivalent upstream
   changes as well; do not reintroduce work already integrated under other hashes.
   Protect unrelated commits, tagged commits, and commits used by other local
   branches, worktrees, or review stack dependencies. A backup ref created by
   this workflow is recovery evidence, not another consumer.
4. Regroup only after the last protected commit; preserve that commit and its
   ancestors exactly. If the task cannot be isolated without rewriting protected
   commits or a merge, leave that history intact and explain the limitation.
   Append scoped corrections when possible. Keep the recorded base even when
   upstream has advanced; regrouping does not authorize synchronizing branches.

## Group the final changes

Compare the intended final contents with the fixed base, combining the selected
commits and current scoped edits. Reapply the normal semantic grouping rules to
this net diff; old commit boundaries and editing chronology are evidence, not
constraints.

- Each group has one coherent purpose and can be explained and reviewed on its
  own. Keep implementation, its tests, and directly supporting changes together;
  order dependent groups so each commit is internally consistent.
- Fold a later correction into the group it changes. Omit both sides of a
  change that was introduced and then fully undone inside the selected range.
  A partial undo leaves only the retained behavior in the appropriate group.
- Keep independent purposes separate even when they share a file or feature
  name. One commit is appropriate only when the final diff has one cohesive
  purpose; explain that conclusion instead of defaulting to a squash.
- Preserve useful existing groups and hashes when new work merely adds an
  independent group. Regroup when it improves the final history, not on every
  invocation.

### After review fixes

On every post-review commit request, reassess the complete eligible task suffix,
including corrections already committed on top. Fold fixes to unpushed task
work into the logical groups they correct. An extra "fix review comments" commit
is not the default final history. Append a correction only when its original
commit is protected or the user requires append-only history; state that reason.

For example, four unpushed feature commits followed by a review fix to the second
become coherent replacement groups with that fix included. The committer may
retain four groups, split them, or combine related groups based on the final
contents; the old count is not a constraint. Rebuild the eligible suffix when
needed, using the recovery and verification procedure below.

Write each message to explain its resulting change and purpose. Remove obsolete
claims from replaced messages. Completion requires a disposition for every
review-fix commit: folded into a named group, retained for an independent
purpose, or appended because protected history or user instructions require it.

For example, independent groups `A, B, C` followed by removal of `B` become
`A, C` (with replacement hashes where necessary). Fold the removal into history
even if it was already committed as `D`. If part of `B` remains, retain that
part as its own group when its purpose is still independent. This example does
not impose a commit count on other tasks.

Present the fixed base, replacement range, proposed groups with files/hunks and
rationale, and any groups being dropped. Wait only when HITL was requested.
An empty net diff can still require removing a fully canceled unpushed suffix;
finish at the protected base without manufacturing an empty commit.

## Execute and verify

Before mutation, satisfy the repository's build gate and prepare and validate
messages for every proposed group. Record the original branch, base and `HEAD`;
create a unique backup ref for the old tip. Save recoverable staged and unstaged
binary patches, the original index state, and relevant untracked contents in
the task's external artifact directory. Record the intended final tree and
excluded changes so recovery and comparison cover work that a backup ref alone
cannot preserve.

Use the smallest rewrite that realizes the plan. A tip-only correction may use
`git commit --amend`; rebuilding a selected suffix may use
`git reset --mixed <fixed-base>` followed by explicit per-group staging and
commits. Reset once before the first group, not before each commit.
Preserve working-file contents throughout. Stage individual hunks or
index-only content when a file crosses group or scope boundaries. Restore
excluded staging exactly. Never use interactive rebase, `reset --hard`,
`git clean`, or broad staging.

Verify before reporting completion:

- The final tree matches the intended scoped snapshot, and excluded staged,
  unstaged, and untracked work is unchanged.
- The protected base and its ancestors are unchanged; all replacement commits
  lie after it, with the intended groups and no canceled intermediate work.
- Each resulting commit passes the applicable message checks. Report build
  evidence accurately; a preserved final tree does not prove intermediate
  commits were built separately.

If mutation fails, retain the backup and snapshots and report the exact state;
do not improvise destructive recovery. Return the old-to-new group mapping
(including dropped groups), new hashes, backup ref, verification results, and
any limitation that prevented regrouping.
