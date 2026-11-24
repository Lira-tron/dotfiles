# Tool output paths

Follow [the artifact rule](ai-artifacts.md) and pass the resolved absolute
feature directory to each producer and reader. A `.ai` link redirects only
paths that traverse it.

| Output | Handling |
| --- | --- |
| Planner artifacts | Supply an absolute `project_dir` under the feature's `specs/`; use the resolved path in handoffs and resume instructions. |
| TDD team runs | Use `<feature-root>/tdd-runs/<run-id>/`; resume the recorded run, not the newest global run. |
| Ralph tasks and runtime state | Keep files at the workflow's configured `tasks_dir` and scratchpad paths. Copy retained task and decision evidence into the selected feature after completion. |
| Reviews, research, quality evidence, screenshots | Assign distinct absolute output paths under the feature. |
| Skill evaluation workspaces and reports | Pass the feature workspace to evaluators/viewers; use supported `--output`, `--static`, `--report`, and `--results-dir` arguments. Check each installed command's help. |
| Packaged skill archives | Supply the feature export directory as the supported output argument. |
| TestSpaces progress notes | Keep personal progress/compaction notes under the feature; preserve native test configuration and runtime records. |
| Investigation state and progress files | Qualify otherwise bare filenames with the feature path, including subsequent reads. |
| Build analyzer logs | Keep the tool's write/replay contract intact; capture retained build evidence under the feature after the run. Use an output override only when supported. |
| Crapper, Dryer, Mutator | Keep `--root` as the owning project. Archive `.metrics/crap.edn`, `.metrics/dry.edn`, and `.metrics/mutate/*.edn` under the feature after execution. Preserve native state during a run and apply the shared mutation recovery rules to `target/mutation-workers/` and `target/mutator-backup/`. |
| Fixed temporary paths or native caches | Preserve the tool's required working paths and cleanup/recovery lifecycle. Copy retained evidence to the feature after completion; never claim a shell variable redirects a hardcoded assignment. |

Keep installers' caches and generated profiles owned by their tools. Implement
durable changes in maintained source, supported arguments, or adapters rather
than editing installed plugin copies. Native session histories, credentials,
databases, test configuration, source checkouts, and temporary command
registrations retain their own locations.
