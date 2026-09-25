# Scope of local changes

Quality gates assess unpushed commits plus staged, unstaged, and relevant
non-ignored untracked edits. Intersect that set with the user's task scope.
Already-upstream, unchanged code is context, not a gate or cleanup target.
Never substitute the whole repository or an arbitrary historical commit when
the applicable set is empty. Report an empty scope as `skipped`, with the reason.

## Establish and preserve the upstream comparison

Before assuming commits are local-only, fetch the branch's configured remote
and resolve its actual tracked upstream. Record the upstream ref, fetched SHA,
HEAD, and their merge base. Do not guess `origin/mainline`, `HEAD~1`, or the
original goal's starting commit. A failed fetch, missing upstream, or unrelated
histories blocks scope selection unless the user supplies an explicit base.

Use Git to obtain the base and changed paths; the placeholders below mean the
verified remote and recorded merge-base SHA:

```sh
git fetch <configured-remote>
git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'
git merge-base HEAD '@{upstream}'
git diff --numstat --no-renames --no-ext-diff --no-textconv -z <recorded-base> --
git ls-files --others --exclude-standard -z
```

Parse NUL-delimited paths deterministically. The diff from the merge base to
the working tree includes unpushed commits and current tracked edits without
mistaking remote-only changes on a diverged branch for local deletions. Add
relevant untracked files. Record the patch, file/line inventory, and source/test
hashes outside the repository without changing the index or working tree.

The existing `lean-verify/scripts/scope.py --mode uncommitted` can supplement
this with staged/unstaged patches and untracked hashes, but it does not include
unpushed commits and is not the complete scope collector.

Analyze current working-tree contents. Derive current added/modified line ranges
against the recorded merge base, not HEAD or the previous tool manifest.
Staged and unstaged patches use different coordinates and cannot simply be
concatenated. Include all current lines of genuinely new source files.
Do not claim to have analyzed a staged version that differs from the on-disk
version. Exclude deleted files and generated/vendor output with reasons. For
language gates, also exclude non-source files. Retain in-scope feature files for
applicable APS checks under [the test workflow policy](quality-gates.md#test-workflow).
Keep test changes as test/DRY scope, not production mutation targets.

Use the language parser to map hunks to current functions/declarations for
CRAP and DRY, including functions affected by deletions. A deleted function
has no current CRAP score or mutation sites. Pure renames and metadata-only
changes do not manufacture executable changes.

For `/go`, use this same comparison for coverage, reviews, CRAP, DRY, Lean,
and mutation. Capture it before checkpoint commits and preserve the base for
the run, refreshing line mappings and hashes after scoped fixes. Local commits
remain in scope; a clean working tree does not mean there is no unpushed work.
A new invocation refreshes the upstream comparison.

## Select targets without broadening the gate

- **CRAP:** pass explicit selected source files and retain scores only for
  affected current functions. `crap4go` arguments are path-substring filters,
  so verify each reported file/function belongs to the inventory.
  `crap4java` accepts explicit files; do not trust `--changed` to include every
  staged and untracked input without verification. Full-function coverage is
  necessary for the metric even when only one line changed.
- **DRY:** pass selected files to `dry4go` or `dry4java`. Existing source/tests
  may be read as comparison context to find reuse opportunities. Only pairs
  with at least one affected function/declaration belong to the gate; exclude
  unchanged-versus-unchanged pairs from the result and from automatic cleanup.
- **Mutation:** target one selected production file at a time and pass explicit
  `--lines L1,L2,...` for its current added/modified source lines. Both language
  tools support this selector. Never omit it when the line set is empty:
  report that file as skipped instead. Check that executed sites stay in the
  selected line set. Deletion-only and test-only changes do not authorize
  mutation of otherwise unchanged source.

Manifest-based differential mode means "changed since the last mutation run,"
not "unpushed changes relative to the upstream base." Do not use the normal manifest default,
`--since-last-run`, or `--mutate-all` as a substitute for the explicit Git line
selection; do not combine them with `--lines`. Preserve tool-written manifests
without hand editing them. An unchanged manifest cannot suppress a required
rerun after tests change within the captured scope.

The project's build, baseline tests, and coverage may include dependencies or
other tests needed for valid results. That does not expand the source gate.
If a tool cannot select the requested targets or its report cannot be reliably
filtered, report the gate as `blocked`; do not silently run a broader gate.

Before mutation, preserve the exact pre-run source outside the repository and
inspect active tool recovery backups. A stale backup must not overwrite current
uncommitted edits, even during `--scan`. Verify restoration after every run,
including failures; preserve legitimate manifest updates and unrelated edits.
Follow `/go`'s committed-checkpoint requirement when running that workflow.
