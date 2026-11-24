# Codex simplify: research and design

Verified September 23, 2026.

## Recommendation

Use an instruction-only Codex skill, invoked as `$simplify`, with four native
reviewer subagents running concurrently. Give all reviewers the same complete
scope, then have the coordinating agent evaluate their findings, apply the
worthwhile fixes, and validate the result.

Four reviewers match the current official Claude Code workflow. The three
user-supplied examples are useful snapshots of the earlier three-reviewer
pattern; they do not establish today's full behavior.

The instructions here are an original Codex adaptation, not a copy of
third-party TypeScript or an assertion of exact prompt parity.

## What the sources establish

| Source | Verified behavior | Implication |
| --- | --- | --- |
| [Official Claude Code commands](https://code.claude.com/docs/en/commands) | Four parallel cleanup reviewers: reuse, simplification, efficiency, and abstraction level. Cleanup is separate from correctness-bug review. | Use four distinct lenses and keep this skill focused on behavior-preserving improvements. |
| [Official Claude Code changelog](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md) | The v2.1.154 entry records reuse, simplification, efficiency, and altitude as a quality-focused workflow. | The fourth lens is part of the documented product, not an invention from a community port. |
| [Pi extension implementation](https://github.com/emanuelcasco/pi-mono-extensions/blob/e4e047a5a203cac78f5e420c92a3115ccd2fe6bb/extensions/simplify/index.ts) | Three review prompts embedded in a command handler. The handler appends focus text and calls `pi.sendUserMessage`; the prompt requests concurrency. | Retain the workflow idea; Pi registration, package dependencies, and message injection are unnecessary in Codex. |
| [Third-party simplify.ts snapshot](https://github.com/codeaashu/claude-code/blob/b564857c0b7e5008cbfe86a19bed7085f30323cf/src/skills/bundled/simplify.ts) | Three lenses: reuse, quality, efficiency. Launch all in one message with the complete diff, wait, then fix. | Supports shared input, concurrent review, and coordinator-owned fixes. It is a community-hosted snapshot, not an official Anthropic release. |
| [vimota gist](https://gist.github.com/vimota/34e7781a1b98ea731e6584af91aa252e/8fc4885385f316988a917b05497faf39f5de0a42) | The same three-stage identify/review/fix workflow, with a smaller checklist. | Useful corroboration of the older workflow, not an independently authenticated Claude version. |

The Pi revision inspected was
`e4e047a5a203cac78f5e420c92a3115ccd2fe6bb`. Its
[README](https://github.com/emanuelcasco/pi-mono-extensions/blob/e4e047a5a203cac78f5e420c92a3115ccd2fe6bb/extensions/simplify/README.md)
claims a Claude Code port and points to another community repository.

The TypeScript file was checked at repository revision
`b564857c0b7e5008cbfe86a19bed7085f30323cf`, blob
`7fe1f60f2ee9718ba547b36db237f1d129dc4ec1`; the file commit was March 31,
2026. The gist revision above was dated March 8, 2026. The repository's
[provenance disclaimer](https://github.com/codeaashu/claude-code/blob/main/README.md)
explicitly says it is unofficial.

Compared with the gist, the TypeScript adds checks for unnecessary JSX wrappers,
unnecessary comments, and ineffective updates that fail to preserve a no-change
signal. Both cover duplicated functionality, redundant state, parameter growth,
abstraction leaks, repeated work, missing concurrency, retained resources, and
overly broad operations.

Both older prompts use Git changes first, falling back to files identified by
the user or edited during the conversation. They do not instruct the agent to
pick the latest commit arbitrarily. Neither explicitly supplies untracked-file
handling, a post-fix test requirement, failure handling, or an enforced
read-only sandbox for reviewers. This adaptation adds explicit instructions for
these workflow gaps where appropriate.

## Why a native skill

[OpenAI's skills documentation](https://learn.chatgpt.com/docs/build-skills)
documents `SKILL.md`, `$skill-name` invocation, optional `agents/openai.yaml`,
symlink support, and discovery from `~/.agents/skills`. Instruction-only skills
are the normal starting point.

[OpenAI's subagent documentation](https://learn.chatgpt.com/docs/agent-configuration/subagents)
documents native parallel review, applicable skills authorizing delegation,
inherited model settings, and the coordination risks of simultaneous writes.
These are exactly the capabilities this task needs.

| Approach | Decision |
| --- | --- |
| Skill plus native subagents | Chosen: discoverable, small, inherits the active model and tools, and needs no extra runtime. |
| Custom slash prompt | [Deprecated by OpenAI](https://learn.chatgpt.com/docs/custom-prompts). Its invocation is `/prompts:name`; it does not create a native `/simplify` command. |
| Separate custom agent TOML files | Useful for independently configured models or permissions, but unnecessary for these four prompt-defined lenses. |
| Pi extension or subprocess orchestration | Adds another runtime, credentials/configuration surface, and result collection without helping the requested native Codex workflow. |

Concurrency is executed by Codex's native tools after reading the skill. A
Markdown skill is not a deterministic scheduler or an OS permission boundary.
The reviewer instructions prohibit edits; the skill does not claim to install a
separate read-only sandbox.

## Decisions that preserve useful behavior

- **Four independent reviews:** reuse; simplification; efficiency; abstraction
  level. All start before the coordinator waits. A fourth review costs more
  tokens than the older three-lens workflow and preserves the current product's
  separate abstraction assessment.
- **One writer:** reviewers supply evidence and suggested fixes. Only the
  coordinator edits, after all reviews finish.
- **Complete common input:** each reviewer gets the same paths, full diff,
  relevant new files, user focus, and constraints.
- **Bounded scope:** respect explicit paths and comparison bases; preserve
  unrelated working-tree changes; ask when no target can be established.
- **Behavior preservation:** inspect callers and contracts. In particular,
  moving work out of loops or adding concurrency can change evaluation,
  exceptions, iterable consumption, ordering, or side effects.
- **Evidence-based filtering:** deduplicate findings, reject speculative
  optimizations and stylistic churn, and accept an empty review result.
- **Honest completion:** missing native tools or failed reviews must be
  reported. Do not silently run sequentially and label the result concurrent.
- **Focused validation:** inspect the final diff and run applicable checks;
  preserve existing tests and separate existing failures from regressions.

## Local validation

The skill passed the bundled skill validator and was loaded successfully by a
fresh Codex `skills/list` call with `forceReload: true`. Discovery followed a
symlink from a temporary `.agents/skills` directory and parsed the interface
metadata without errors.

Installation uses the canonical `~/.agents/skills/simplify` files plus a relative
`~/.codex/skills/simplify` discovery link, following the existing shared skills.
The installed build discovered the temporary repository skill but did not
discover the user-level `.agents` directory alone. Keep the Codex link until
user-level discovery without it is verified on the installed client.

A temporary Python fixture exercises reusable normalization, redundant state,
ordering, duplicates, Unicode handling, conditional field access, equality
semantics, and input preservation. Ten baseline tests pass. Native reviewers
identified reuse and simplification opportunities and rejected unsafe filter
caching because one-shot iterators and mutable filters make evaluation timing
observable.

Four independent reviewers were launched in one parallel tool group against the
same complete fixture input. All completed before the coordinator edited the
target. The resulting cleanup passed all ten tests plus four before/after
probes for one-shot filters, mutable filters, exception ordering, and invalid
filters after a match. Hash comparisons confirmed that the helper, tests, and
unrelated source file were unchanged. The abstraction reviewer returned no
findings rather than inventing additional structure.

An independent child-session test lacked nested subagent tools. It correctly
reported an incomplete pass and left all fixture files unchanged. The skill
therefore keeps orchestration in the session that can spawn reviewers.

A fresh standalone CLI inference test failed before executing the skill because
the configured model provider returned an organization-policy authorization
denial. This does not establish a skill failure, and discovery does not establish
working model access. Native tool execution in the active session is a separate
validation path.
