# AI Task Artifacts

Apply this rule to task artifacts produced by skills, system prompts, delegated
agents, and plugins. Pass the resolved output directory to each producer.

Store task artifacts in `~/knowledge/ai/artifacts/<package>/YY-MM-DD-<feature>/`.
Use the feature's original creation date on resume. Each checkout's `.ai` is a
directory symlink to that one feature, never to the knowledge root or package
directory.

Before reading or writing task artifacts, resolve the selected checkout:

```sh
ai-artifacts path --cwd /absolute/source/checkout
```

For a new feature, initialize it once:

```sh
ai-artifacts init --cwd /absolute/source/checkout --feature feature-name
```

Use `--date YY-MM-DD` when attaching a known existing feature. Use `--package`
only when the package declared in `Config`, or otherwise the Git root name,
does not identify the intended owner. For a non-Git project, supply its source
directory and an explicit package name. Keep different packages separate even
when a workspace groups them together.

Use the returned absolute path as `AI_ARTIFACT_ROOT` in shell commands and
delegation. Paths such as `.ai/specs/`, `.ai/reviews/`, and `.ai/comments/`
resolve through this link. Read the selected feature for specs, AI comments,
and prior task evidence; consult another feature only when the task requires it.

Keep the source checkout as the working directory for builds, tests, Git, and
source-relative comment anchors. Artifact storage does not become the source
root. Pass both absolute paths to subagents. For constrained clients, authorize
the selected feature directory using their supported directory controls.

The helper preserves the selected feature and its original date. It rejects
physical `.ai` directories, broken links, targets outside the artifact root,
and conflicting targets. Preserve existing data before changing a link; follow
`~/.agents/rules/ai-artifact-migration.md`. Recheck task selection when changing
branches.

Keep generated artifacts out of commits unless explicitly requested. Ignore
the `.ai` link itself using a pattern without a trailing slash. Removing a
worktree removes only the local link; retain the external feature directory.

Keep skills, agents, hooks, plugins, source, tests, and native tool configuration
in their required locations. Route persistent plugin reports through supported
output arguments; read `~/.agents/rules/ai-artifact-tools.md` for exceptions.
