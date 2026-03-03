---
name: create-memory
description: Store research, investigations, design knowledge, and technical findings to the shared knowledge base. All agents can search this knowledge. Use when documenting package investigations, design explorations, architecture analysis, or any reusable technical knowledge.
compatibility: Designed for Kiro CLI
---

# Store to Knowledge Base Memory

Creates or updates documentation in `/Users/limonoct/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/memory/` as a shared knowledge base for all agents. Files are indexed by Kiro's knowledge base (semantic search via `GlobalKnowledge`) and searchable across all workspaces and agents.

## When to Use
- Investigating a package, service, or API
- Documenting a design or architecture exploration
- Recording how something works (internal system, library, pattern)
- Capturing technical findings that other agents or future sessions should know

## File Location

`/Users/limonoct/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/memory/{project}/{topic}.md`

- **project**: Project or area name (e.g., `my-service`, `coral`, `brazil`)
- **topic**: Descriptive slug (e.g., `package-structure`, `retry-design`, `ddb-stream-patterns`)

## Parameters
- **topic** (required): Topic name for the file
- **project** (optional): Defaults to current workspace name

## Workflow

### Step 1: Determine Context
Identify project, topic, and content source:
- **Direct input**: User provides content directly
- **Document**: User references a file path — read and extract key information
- **URL**: User provides a link — fetch and summarize relevant content

If project is not specified, default to current workspace name.

### Step 2: Check for Existing File
Check if `/Users/limonoct/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/memory/{project}/{topic}.md` exists.

- **Exists** → Read the file. Merge new information — update outdated sections, add new findings, remove stale content. The file should reflect current understanding.
- **Does not exist** → Create the `{project}/` directory if needed, then create the file with frontmatter.

### Step 3: Write

The file is a **living document**. Each write produces a coherent, up-to-date reference.

```markdown
---
topic: {topic}
project: {project}
updated: {YYYY-MM-DD}
tags: [{relevant, searchable, tags}]
---

# {Topic Title}

{content organized by sections relevant to the topic}
```

### Step 4: Refresh Knowledge Index
After writing, update the Kiro knowledge base so the entry is searchable:

```
knowledge tool → update command
  path: /Users/limonoct/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/
  name: GlobalKnowledge
```

### Step 5: Confirm

```
✅ Stored to memory

Topic: {topic}
Project: {project}
Path: /Users/limonoct/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/memory/{project}/{topic}.md
Tags: {tags}

Preview:
{First 150 chars}...
```

## Content Guidelines
- Write as documentation another agent can use without prior context
- Include rationale and "why", not just "what"
- Link resources: CRs, tickets, wiki pages, docs
- Add code snippets when they clarify
- For URL/document sources: summarize key points, include source reference

## Example

```markdown
---
topic: brazil-java-packages
project: brazil
updated: 2026-02-03
tags: [brazil, java, package-structure, build-system]
---

# Brazil Java Package Structure

## Standard Layout

Java packages in Brazil follow a Maven-like layout with Brazil-specific additions:
- `src/` contains main and test sources
- `configuration/` holds Brazil Config files
- `build.xml` defines the build process via BrazilBuild

## Config File

The `Config` file declares dependencies and build settings:
- `build-system` specifies the builder (e.g., `BrazilBuild2`)
- `dependencies` lists runtime and build-time packages
- `build-tools` lists packages needed only during build

## Key Patterns

- Package names are UpperCamelCase
- Test packages mirror source structure under `tst/`
- Generated code goes in `build/generated-src/`

## Common Issues

- Missing dependencies: run `brazil workspace merge` after adding new deps
- Version conflicts: check version set with `brazil vs show`
```
