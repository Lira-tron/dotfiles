---
name: sync-steering
description: Sync existing steering documents from workspace .kiro/steering/ to knowledge base with Context sections. Use when steering docs already exist and need syncing to knowledge base.
compatibility: Designed for Kiro CLI
---

# Sync Steering Documents to Knowledge Base

## Overview
Syncs existing steering documents from the local workspace to the knowledge base, adding Context sections for searchability and session recovery. Use this when steering documents already exist in `.kiro/steering/` and need to be synced to the knowledge base.

## ⚠️ CRITICAL REQUIREMENT: Context Section

**ALL synced files MUST:**
1. Include a Context section at the end (in knowledge base copy only)
2. Have this Context section updated AUTOMATICALLY after EVERY significant interaction
3. Updates happen WITHOUT asking for permission - just do it automatically
4. This enables session recovery if the conversation dies

**Update Context section automatically when:**
- Files are initially synced
- User provides feedback or requests changes
- Documents are updated or regenerated
- User asks questions or provides clarifications
- Any modifications are made to the documents

## What This Syncs
Any steering documents from local workspace:
- **product.md** - Your app's features and business logic
- **tech.md** - Your technology stack and conventions
- **structure.md** - How your codebase is organized
- **Any other .md files** in `.kiro/steering/`

## File Locations
Documents are synced FROM and TO:
- **Source (Workspace)**: `.kiro/steering/` (local to current project)
- **Destination (Knowledge Base)**: `~/.kiro/knowledge/steering/{workspace-name}/`

Format:
- `{workspace-name}` = name of the current workspace (e.g., my-api-service, user-dashboard)

## Workflow

### Step 1: Identify Workspace
Gather information about the current workspace:
- Identify workspace root and name
- Locate `.kiro/steering/` directory
- List all steering documents present

### Step 2: Check Existing Steering Documents
Scan `.kiro/steering/` for existing documents:
- List all `.md` files
- Verify content is present
- Identify which files need syncing

### Step 3: Automatic Sync to Knowledge Base
**CRITICAL**: This happens AUTOMATICALLY without asking for permission.

For each steering file found:

1. **Read content** from local workspace file
2. **Add Context section** at the end (if not already present)
3. **Save to knowledge base**: `~/.kiro/knowledge/steering/{workspace-name}/`
4. **Update Context section** with current timestamp and activity

**Context Section Template** (ONLY for knowledge base copies):

```markdown
## Context

### Timeline
- **{Date/Time}**: Initial sync from local workspace
- **{Date/Time}**: Synced {filename} to knowledge base
- **{Date/Time}**: [Future updates will be logged here]

### CONVERSATION SUMMARY
═════════════════════════════════════════════════════════════════════

#### OBJECTIVE
Sync {filename} from local workspace to knowledge base for {Project Name}

#### USER GUIDANCE
- [Key requests and clarifications from user]
- [Important decisions made]

#### COMPLETED
- Synced {filename} from workspace to knowledge base
- Added Context section for tracking
- [Future completions will be logged here]

#### TECHNICAL CONTEXT
- Workspace: {workspace path}
- Workspace name: {workspace-name}
- Source: .kiro/steering/{filename}
- Destination: ~/workplace/.../knowledge/steering/{workspace-name}/{filename}

#### TOOLS EXECUTED
1. Workspace identification - Located workspace and steering files
2. File sync - Copied {filename} to knowledge base
3. Context addition - Added tracking section
4. [Future tool executions will be logged here]

#### NEXT STEPS
1. Review and update as project evolves
2. Automatic sync will keep knowledge base current

#### TODO LIST
[Outstanding items or updates needed]

**CRITICAL**: Update this CONVERSATION SUMMARY and timeline automatically after every significant interaction without being asked. This enables session recovery and tracks document history.
```

### Step 4: Preserve Local Files
**IMPORTANT**: Local workspace files remain unchanged:
- No Context sections added to local files
- Original content preserved exactly
- Clean, focused documentation in workspace

### Step 5: Continuous Automatic Sync
**CRITICAL**: Sync happens AUTOMATICALLY without asking whenever:
- User modifies local steering files
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
- New files added to `.kiro/steering/`

**What Stays in Knowledge Base Only:**
- Context section with Timeline
- CONVERSATION SUMMARY
- Historical tracking information

### Step 6: Confirm and Report
Provide clear feedback on what was synced:

```
✅ Synced Steering Documents to Knowledge Base

Synced Files:
- {filename1} (from workspace to knowledge base)
- {filename2} (from workspace to knowledge base)
- {filename3} (from workspace to knowledge base)

Locations:
📁 Source: .kiro/steering/ (clean, no Context sections)
📁 Destination: ~/workplace/.../knowledge/steering/{workspace-name}/ (with Context sections)

Status:
- [Synced] {filename1}
- [Synced] {filename2}
- [Synced] {filename3}

Automatic Sync:
✅ All files synced to knowledge base with Context sections
✅ Context sections updated automatically
✅ Future changes will sync automatically without asking

These documents are now searchable via /search in Kiro.
```

**After Sync:**
- Local workspace files remain clean (no Context sections)
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
    "skill://.kiro/skills/sync-steering/SKILL.md"
  ]
}
```

### Usage in Chat
Once added to your agent, simply ask to sync steering documents:

```bash
# Sync all steering documents from current workspace
kiro "Sync steering documents"

# Or with explicit instruction
kiro "Sync my steering docs to knowledge base"
```

The agent will automatically invoke this skill when it detects you want to sync steering documents.
1. Agent identifies your workspace
2. Locates all steering documents in `.kiro/steering/`
3. Syncs each file to knowledge base
4. Adds Context sections (knowledge base only)
5. Reports what was synced
6. Documents become searchable

## Important Notes
- **Context Sections**: ONLY in knowledge base copies, NOT in local workspace files
- **Automatic Context Updates**: Context sections in knowledge base update WITHOUT asking after every significant interaction
- **Automatic Sync**: Changes to local files automatically sync to knowledge base WITHOUT asking
- **Clean Local Files**: Workspace steering files remain clean and focused
- **Historical Tracking**: Knowledge base copies track full history via Context sections
- **Workspace-Specific**: Each workspace gets its own folder in knowledge base
- **Searchable**: Documents in knowledge base are searchable via `/search`
- **No Approval Gates**: Sync runs automatically without approval gates
- **Session Recovery**: Context sections in knowledge base enable recovery if conversation dies
- **Bidirectional Sync**: Local → Knowledge Base (automatic), Knowledge Base → Local (ask first)
- **Preserves Originals**: Local files are never modified during sync
- **Handles All Files**: Syncs any `.md` file in `.kiro/steering/`, not just product/tech/structure

## Difference from generate-steering Skill
- **generate-steering**: Creates new steering documents from scratch by analyzing workspace
- **sync-steering**: Syncs existing steering documents that are already present in workspace
- Both follow the same Context section rules and automatic sync behavior
- Both keep local files clean and add Context only to knowledge base copies
