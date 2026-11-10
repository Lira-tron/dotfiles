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

- **CRAP:** pass explicit existing source files to `crapper` and retain scores
  only for affected current functions. Nonexistent arguments become substring
  filters. `--changed` uses Git status and omits unpushed commits. Verify source
  identity and unrounded values using its CLI guide. Full-function coverage is
  necessary even when only one line changed.
- **DRY:** pass selected files to `dryer`. Existing source/tests may be read as
  comparison context. Only pairs with at least one affected declaration belong
  to the gate; exclude unchanged-versus-unchanged pairs from results and fixes.
- **Mutation:** target one selected production file at a time with
  `--lines L1,L2,... --mutate-all` in `mutator`. The line filter confines
  execution; `--mutate-all` prevents reuse of historical kills after tests
  change. Never omit the line selector when the set is empty: skip that file.
  Verify executed sites stay in the selected current added/modified lines.
  Deletion-only and test-only changes do not authorize mutation of otherwise
  unchanged production source.

Snapshot-based differential mode means "changed since the last mutation run,"
not "unpushed changes relative to the upstream base." Do not substitute the
default or `--since-last-run` for Git selection. In unified `mutator`, combine
explicit `--lines` with `--mutate-all`; either alone is insufficient for a fresh
scoped run. Follow [recovery](#mutation-artifacts-and-restoration) for snapshots.
An unchanged snapshot cannot suppress a required rerun after tests change.

The project's build, baseline tests, and coverage may include dependencies or
other tests needed for valid results. That does not expand the source gate.
If a tool cannot select the requested targets or its report cannot be reliably
filtered, report the gate as `blocked`; do not silently run a broader gate.

## Mutation artifacts and restoration

Mutator writes native differential state to `.metrics/mutate/*.edn`, not
source-embedded comments. Workers use `target/mutation-workers/`; legacy
`target/mutator-backup/` files are restored before a non-scan run and can
replace newer source. Inspect and resolve any backup before execution.

Before every invocation, including `--scan`, capture exact source bytes, test
hashes, the staged diff, Git status, and existing metric/recovery state. Keep
snapshots, logs, raw EDN, and recovery evidence in the owning feature's external
directory, resolved by [the artifact rule](../../../rules/ai-artifacts.md);
`/go` uses `<AI_ARTIFACT_ROOT>/go/<run-id>/`. Follow `/go`'s committed-checkpoint
requirement only when running that workflow. Standalone runs preserve all
pre-existing staged and unstaged edits.

After every invocation, including failure or interruption:

1. Archive the raw `.metrics/mutate/*.edn` snapshots and per-site logs before
   cleanup or source repair. Keep native paths during execution; use
   [the tool-output rules](../../../rules/ai-artifact-tools.md) for retention.
2. Verify exact source/test byte equality and an unchanged index. Workers copy
   the mutated file but link other project files, so test side effects may reach
   the real tree. Restore only proven tool changes from the captured bytes.
   Stop on concurrent edits or uncertain ownership; never use a blanket reset.
3. Check worker and recovery paths. Archive and retire only resolved backups;
   a future invocation must not restore stale source. Restore the pre-run Git
   status, accounting explicitly for retained native metrics. Never commit
   generated metrics or recovery state as source changes.

For an explicitly required legacy-tool run, also archive its source-embedded
manifest unchanged and restore the exact pre-run source bytes. Legacy flags and
backup paths are tool-specific; inspect that executable rather than applying
unified Mutator's command syntax to it.

Finish restoration before applying real fixes. Validate and checkpoint fixes
only when authorized, then refresh source/test hashes and line mappings while
preserving the captured base. Rerun affected sites after test changes. Cleanup,
cached kills, and an unchanged Git status do not establish a passing result.
