---
name: generate-steering
description: Generate foundational steering documents (product.md, tech.md, structure.md) for current workspace by analyzing codebase. Use when starting new projects or documenting existing ones.
compatibility: Designed for Kiro CLI
---

# Generate Project Steering Documents

## Overview
Generates foundational steering documents for the current workspace and saves them to both local `.kiro/steering/` and the knowledge base for searchability.

## ⚠️ CRITICAL REQUIREMENT: Context Section

**ALL three generated files (product.md, tech.md, structure.md) MUST:**
1. Include a Context section at the end with Timeline and Conversation Summary
2. Have this Context section updated AUTOMATICALLY after EVERY significant interaction
3. Updates happen WITHOUT asking for permission - just do it automatically
4. This enables session recovery if the conversation dies

**Update Context section automatically when:**
- Files are initially generated
- User provides feedback or requests changes
- Documents are updated or regenerated
- User asks questions or provides clarifications
- Any modifications are made to the documents

## What This Generates
Three foundational documents:
1. **product.md** - Your app's features and business logic
2. **structure.md** - How your codebase is organized
3. **tech.md** - Your technology stack and conventions

## File Locations
Documents are saved to TWO locations:
- **Workspace**: `.kiro/steering/` (local to current project)
- **Knowledge Base**: `~/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/steering/{workspace-name}/`

Format:
- `{workspace-name}` = name of the current workspace (e.g., my-api-service, user-dashboard)

## Workflow

### Step 1: Analyze Workspace
Gather information about the current workspace:
- Identify workspace root and name
- Examine README files, package.json, pom.xml, build files
- Review directory structure
- Understand project purpose and architecture
- Identify key technologies and dependencies

### Step 2: Generate product.md
Create a comprehensive product document WITHOUT Context section (for local workspace):

```markdown
# Product: {Project Name}

## Purpose
[What problem does this project solve?]

## Features and Business Logic
- [Feature 1]: [Description and business value]
- [Feature 2]: [Description and business value]
- [Feature 3]: [Description and business value]

## Goals
- [Primary goal 1]
- [Primary goal 2]
- [Primary goal 3]

## Target Users
[Who uses this project?]

## Business Value
[Why does this project matter?]

## Current Status
[Development stage, maturity level]
```

### Step 3: Generate tech.md
Create a detailed technology stack document WITHOUT Context section (for local workspace):

```markdown
# Tech: {Project Name}

## Technology Stack and Conventions

### Programming Languages
- [Language 1]: [Version and usage]
- [Language 2]: [Version and usage]

### Frameworks & Libraries
- [Framework 1]: [Version and purpose]
- [Framework 2]: [Version and purpose]

### Build Tools
- [Tool 1]: [Version and purpose]
- [Tool 2]: [Version and purpose]

### Testing Frameworks
- [Framework 1]: [Version and purpose]
- [Framework 2]: [Version and purpose]

### Infrastructure & Deployment
- [Service/Tool 1]: [Purpose]
- [Service/Tool 2]: [Purpose]

### Development Tools
- [Tool 1]: [Purpose]
- [Tool 2]: [Purpose]

### Key Dependencies
- [Dependency 1]: [Version and purpose]
- [Dependency 2]: [Version and purpose]

### AWS Services (if applicable)
- [Service 1]: [Purpose]
- [Service 2]: [Purpose]

### Coding Conventions
- [Convention 1]: [Description]
- [Convention 2]: [Description]
```

### Step 4: Generate structure.md
Create a project structure document WITHOUT Context section (for local workspace):

```markdown
# Structure: {Project Name}

## How Your Codebase is Organized

### Directory Layout
\`\`\`
{root}/
├── {dir1}/          # [Purpose]
│   ├── {subdir}/    # [Purpose]
│   └── {file}       # [Purpose]
├── {dir2}/          # [Purpose]
├── {config-file}    # [Purpose]
└── README.md
\`\`\`

## Key Components

### {Component 1}
- **Location**: {path}
- **Purpose**: {description}
- **Key Files**: {list}

### {Component 2}
- **Location**: {path}
- **Purpose**: {description}
- **Key Files**: {list}

## Configuration Files
- **{file1}**: {purpose}
- **{file2}**: {purpose}

## Entry Points
- **{entry1}**: {description}
- **{entry2}**: {description}

## Build Artifacts
- **{artifact1}**: {location and purpose}
- **{artifact2}**: {location and purpose}
```

### Step 5: Save to Local Workspace
Save clean versions (WITHOUT Context sections) to:
- `.kiro/steering/product.md`
- `.kiro/steering/tech.md`
- `.kiro/steering/structure.md`

### Step 6: Automatic Sync to Knowledge Base
**CRITICAL**: This happens AUTOMATICALLY without asking for permission.

For each file (product.md, tech.md, structure.md):

1. **Copy content** from local workspace file
2. **Add Context section** at the end
3. **Save to knowledge base**: `~/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/steering/{workspace-name}/`
4. **Update Context section** with current timestamp and activity

**Context Section Template** (ONLY for knowledge base copies):

```markdown
## Context

### Timeline
- **{Date/Time}**: Initial generation - Created {filename}
- **{Date/Time}**: Synced from local workspace
- **{Date/Time}**: [Future updates will be logged here]

### CONVERSATION SUMMARY
═════════════════════════════════════════════════════════════════════

#### OBJECTIVE
Document the {product/tech/structure} for {Project Name}

#### USER GUIDANCE
- [Key requests and clarifications from user]
- [Important decisions made]

#### COMPLETED
- Generated initial {filename} document
- Synced to knowledge base
- [Future completions will be logged here]

#### TECHNICAL CONTEXT
- Workspace: {workspace path}
- Workspace name: {workspace-name}
- [Other relevant technical details]

#### TOOLS EXECUTED
1. Workspace analysis - Examined project structure
2. File generation - Created {filename}
3. Automatic sync - Synced to knowledge base
4. [Future tool executions will be logged here]

#### NEXT STEPS
1. Review and update as project evolves
2. Automatic sync will keep knowledge base current

#### TODO LIST
[Outstanding items or updates needed]

**CRITICAL**: Update this CONVERSATION SUMMARY and timeline automatically after every significant interaction without being asked. This enables session recovery and tracks document history.
```

### Step 7: Continuous Automatic Sync
**CRITICAL**: Sync happens AUTOMATICALLY without asking whenever:
- User modifies local steering files (product.md, tech.md, structure.md)
- User updates project documentation
- User makes changes to workspace structure or technology
- Any significant interaction occurs with these files

**Sync Process:**
1. Detect changes in local `.kiro/steering/` files
2. Copy updated content to knowledge base
3. Preserve and update Context section in knowledge base copy
4. Add new Timeline entry with sync timestamp
5. Update CONVERSATION SUMMARY with what changed
6. **DO NOT** ask permission - sync automatically

**What Gets Synced:**
- Content changes from local files
- New sections or updates
- Structural changes

**What Stays in Knowledge Base Only:**
- Context section with Timeline
- CONVERSATION SUMMARY
- Historical tracking information

### Step 8: Confirm and Report
Provide clear feedback on what was done:

```
✅ Generated Project Steering Documents

Created/Updated:
- product.md (clean version in workspace)
- tech.md (clean version in workspace)
- structure.md (clean version in workspace)

Locations:
📁 Workspace: .kiro/steering/ (clean, no Context sections)
📁 Knowledge Base: ~/workplace/.../knowledge/steering/{workspace-name}/ (with Context sections)

Status:
- [Created/Updated] product.md
- [Created/Updated] tech.md
- [Created/Updated] structure.md

Automatic Sync:
✅ All files synced to knowledge base with Context sections
✅ Context sections updated automatically
✅ Future changes will sync automatically without asking

These documents are now searchable via /search in Kiro.
```

**After Generation:**
- Local workspace files are clean (no Context sections)
- Knowledge base copies have Context sections at the end
- Context sections will be updated automatically on every interaction
- Automatic sync keeps knowledge base current without asking
- No need to ask permission for Context updates or syncs - they happen automatically

## Usage

## How to Use This Skill

### Add to Agent Resources
Add this skill to your agent configuration:

```json
{
  "resources": [
    "skill://.kiro/skills/generate-steering/SKILL.md"
  ]
}
```

### Usage in Chat
Once added to your agent, simply ask to generate steering documents:

```bash
# Generate project steering documents for current workspace
kiro "Generate steering documents"

# Or with explicit instruction
kiro "Generate the project documentation"
```

The agent will automatically invoke this skill when it detects you want to generate steering documents.

### What Happens
1. Agent analyzes your workspace
2. Generates three foundational documents
3. Saves to both workspace and knowledge base
4. Reports what was created/updated
5. Documents become searchable

## Important Notes
- **Context Sections**: ONLY in knowledge base copies, NOT in local workspace files
- **Automatic Context Updates**: Context sections in knowledge base update WITHOUT asking after every significant interaction
- **Automatic Sync**: Changes to local files automatically sync to knowledge base WITHOUT asking
- **Clean Local Files**: Workspace steering files remain clean and focused
- **Historical Tracking**: Knowledge base copies track full history via Context sections
- **Workspace-Specific**: Each workspace gets its own folder in knowledge base
- **Searchable**: Documents in knowledge base are searchable via `/search`
- **No Approval Gates**: Unlike create-plan skill, this runs automatically without approval gates
- **Session Recovery**: Context sections in knowledge base enable recovery if conversation dies
- **Bidirectional Sync**: Local → Knowledge Base (automatic), Knowledge Base → Local (ask first)
