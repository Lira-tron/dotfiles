# Existing AI artifacts

Read the [artifact rule](ai-artifacts.md) first. Migration is explicit: the
initializer never moves existing files or repoints a selected feature.

1. Identify the source package, feature, original creation date, and exact files.
   Inspect tracked files, active writers, symlinks, and existing destinations.
   Preserve package-owned tracked content and tool-required files in place.
2. For a worktree containing one feature, preserve the existing relative
   subtree under its `YY-MM-DD-<feature>` directory. For mixed primary-checkout
   data, map each feature separately. Keep ambiguous history in an explicitly
   named legacy feature archive, outside the new task's default context.
3. Copy the selected data first and verify paths, file hashes, and symlink
   targets. Recheck that the source did not change while copying. Resolve
   destination conflicts without overwriting either copy.
4. After the mapping and cleanup are authorized and writers have stopped,
   remove only the verified source copies. Initialize the checkout's `.ai`
   link with the selected feature and original date. Keep recovery evidence
   outside the checkout.
5. Verify writes, resume, Git ignore behavior, and the actual package build.
   Inspect generated archives for accidental artifact inclusion. During
   authorized worktree cleanup, verify that the external data remains.

Package-wide standards, glossary/configuration, and historical references may
need explicit shared document paths. Do not point a feature link at all package
history to make an old reference work. Preserve old references until their
readers have been updated.

Link directories, not individual output files: atomic-save tools replace file
symlinks. Keep source-root metadata separate from storage paths, particularly
for editor comments. Coordinate simultaneous writers to the same feature;
independent runs use separate output subdirectories.
