---
name: show-me
description: Help the user review code or understand code, changes, or concepts through focused visual explanations and walkthroughs. Use when the goal is explanation or code review. Do not select solely to create or render a diagram; use a diagram tool directly for standalone diagrams or diagrams in documents.
---

Help the user review code or understand code, a proposed code change, or a concept visually. Skip the preamble and keep prose brief. Pick the smallest view that makes the key point clear.

Choose this skill when the main goal is a focused explanation, code walkthrough, or code review. Use the rendering instructions below for diagrams that support that explanation or review. When the requested deliverable is a standalone diagram or a diagram for a document, use a diagram tool directly.

Before saving an image or HTML file, follow [the shared artifact rule](../../rules/ai-artifacts.md).
Use the calling workflow's absolute output path within the selected feature,
or default to `<AI_ARTIFACT_ROOT>/visuals/`. Create the output directory first.
Replace `<absolute-output-path>` in the examples with that resolved path.

- Show logic or an algorithm as pseudocode:

```text
on(save)
  if content is unchanged
    return cached result
  write new content
  return fresh result
```

- Show runtime control flow as a call tree:

```text
submitForm
  createSession
    persistPrompt
    launchAgent
  navigateToSession
```

- Show UI structure as a component tree, including state and module boundaries that matter:

```tsx
<SessionPage> (apps/example/src/routes/session.tsx)
  useSessionEvents()
  <SessionToolbar>
    <RunSkillButton> (packages/ui)
```

- Show file responsibility or a broad refactor as a shallow file tree:

```text
src/
├── commands/       # parses user actions
├── sessions/       # owns session state
└── transport/      # sends API requests
```

- Show component interaction, control flow, or data flow in the code being explored or reviewed as a diagram. When `~/.agents/skills/show-me/references/rendered-diagrams.md` exists, read it and render the diagram as it describes. Otherwise write the diagram inline as a PlantUML or Mermaid fenced block.

- Use `diff` when the point is what changes and the surrounding shape already exists. Match the diff shape to the topic.

For a component change:

```diff
 <SessionPage>
   useSessionEvents()
   <SessionToolbar>
+    <RunSkillButton />
   <SessionTimeline>
+    <SkillResultCard />
```

For a file-layout change:

```diff
 src/
 ├── commands/
+│   └── show-me.ts       # expands the slash command
 ├── sessions/
-└── transport.ts
+└── transport/
+    ├── client.ts
+    └── stream.ts
```

For a call-tree or call-stack change:

```diff
 submitForm
   createSession
     persistPrompt
+    expandSkillMention
     launchAgent
-  navigateToSession
+  navigateToSession
+    subscribeToEvents
```

For a state or control-flow change:

```diff
 on(save)
-  write content
+  if content is unchanged
+    return cached result
+  write new content
+  invalidate cache
```

- Show the whole block when most of it is new, when omitted context would hide ownership or order, or when the user needs a copyable target shape:

```ts
function expandSkill(command: string): string {
  const skillName = command.slice(1)
  return `use the ${skillName} skill`
}
```

- For a code walkthrough or review whose UI, layout, or state changes benefit from an HTML view, write one focused HTML file. Match the product's colors, type, spacing, and components; use real labels and data; support desktop and mobile. Then open it for the user:

```
Bash(xdg-open '<absolute-output-path>.html')
```

### guidance

Place each visual next to the short text it supports. Keep only the calls, files, props, states, and boundaries needed to answer the user's current question or the options to resolve the current discussion point.

You may use one of these, you may use several, it is unlikely you will use all of them. Use your judgement and don't overwhelm the user.
