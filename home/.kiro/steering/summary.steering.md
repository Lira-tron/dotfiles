# Generate Work Summary

## Overview
Creates a comprehensive summary of work completed on a plan or project, including timeline, accomplishments, and impact. Summaries can be generated from daily notes or conversation context. Used for performance reviews, year-end documentation, and project retrospectives.

## ⚠️ CRITICAL REQUIREMENT: Preserve Existing Content

**When working with summary files:**
1. ALWAYS read the existing file first before making changes
2. NEVER overwrite unrelated content
3. APPEND new summaries if the file already contains other data
4. Preserve all existing sections and metadata
5. Add clear separators between different summaries

## What This Generates
A structured work summary document with:
- Project overview and context
- Timeline of key milestones
- Detailed accomplishments
- Business and technical impact
- Challenges and solutions
- Links to related resources

## File Locations
Summaries are saved to:
- **Knowledge Base**: `~/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/summary/{YYYY}/`
- **Year Index**: `~/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/summary/{YYYY}/index.md`

## Parameters
- **project** (required): Project or feature name (e.g., "user-authentication", "api-optimization")
- **date** (optional): Date or date range for this work (defaults to today)
- **from_notes** (optional): Set to "true" to generate summary from daily notes instead of conversation context

## Workflow

### Step 1: Gather Context
Collect information about the work completed.

**From Notes (when from_notes=true):**
- Search for notes in `~/workplace/LimonoctNvim/src/LimonoctNvim/notes/journal`
- Filter notes by date range (if provided) or search for project mentions
- Extract relevant work items, accomplishments, and decisions
- Keep track of note file paths for linking
- Look for patterns: completed tasks, decisions made, problems solved

**From Conversation Context (when from_notes=false):**
- Review current conversation context
- Identify key accomplishments and deliverables
- Note any code reviews, deployments, or milestones
- Capture technical decisions and their rationale
- Look for references to plans, tickets, MCMs

### Step 2: Check for Existing Summary File
**CRITICAL**: Before creating or updating a summary:

1. **Check if file exists**: `~/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/summary/{YYYY}/{YYYY-MM-DD}-{project}.md`
2. **If file exists**:
   - Read the entire file
   - Identify existing sections and content
   - Determine if content is related to current summary
   - If unrelated content exists, prepare to append with clear separator
3. **If file doesn't exist**:
   - Proceed with creating new file

### Step 3: Create Summary Document
Generate a structured summary with the following format:

**Summary Document Template:**

```markdown
---
project: {project-name}
date: {YYYY-MM-DD}
generated_from: {notes|context}
---

# Work Summary: {Project Name}

## Overview
{Brief description of the project/feature and its purpose}

## Timeline
- **Start Date**: {YYYY-MM-DD}
- **{Milestone 1}**: {YYYY-MM-DD} - {Description}
- **{Milestone 2}**: {YYYY-MM-DD} - {Description}
- **Completion Date**: {YYYY-MM-DD} (if applicable)

## What Was Done

### Technical Implementations
- {Implementation 1}: {Description and details}
- {Implementation 2}: {Description and details}
- {Implementation 3}: {Description and details}

### Code Reviews & Deployments
- {CR-XXXXXXXX}: {Description and outcome}
- {Deployment 1}: {What was deployed and when}

### Documentation Created
- {Doc 1}: {Link and description}
- {Doc 2}: {Link and description}

### Problems Solved
- {Problem 1}: {Description and solution}
- {Problem 2}: {Description and solution}

## Impact

### Business Impact
- {Impact 1}: {Description and metrics if available}
- {Impact 2}: {Description and metrics if available}

### Technical Impact
- {Impact 1}: {Description}
- {Impact 2}: {Description}

### Performance Improvements
- {Metric 1}: {Before → After}
- {Metric 2}: {Before → After}

### User Benefits
- {Benefit 1}: {Description}
- {Benefit 2}: {Description}

## Challenges & Solutions

### Challenge 1: {Challenge Title}
- **Problem**: {Description of the challenge}
- **Solution**: {How it was resolved}
- **Outcome**: {Result}

### Challenge 2: {Challenge Title}
- **Problem**: {Description of the challenge}
- **Solution**: {How it was resolved}
- **Outcome**: {Result}

## Links & References
- **Code Reviews**: [CR-XXXXXXXX](link), [CR-YYYYYYY](link)
- **Tickets**: [TICKET-123](link), [TICKET-456](link)
- **MCMs**: [MCM-XXXXXXXX](link)
- **Plans**: `~/.kiro/knowledge/plans/{YY}/{MM}/{component}/{feature}/`
- **Documentation**: [Link 1](url), [Link 2](url)

## Source Notes
{Only include this section if generated from notes}
- `{YYYY-MM-DD}`: `~/workplace/LimonoctNvim/src/LimonoctNvim/notes/journal/{path}`
- `{YYYY-MM-DD}`: `~/workplace/LimonoctNvim/src/LimonoctNvim/notes/journal/{path}`

## Tags
`#{project-name}` `#{technology}` `#{team}` `#{year}`
```

### Step 4: Save or Append Summary
**CRITICAL**: Handle existing content carefully:

**If file doesn't exist:**
- Create new file with summary content
- Use filename format:
  - From notes: `{YYYY-MM-DD}-{project}-notes.md`
  - From context: `{YYYY-MM-DD}-{project}.md`

**If file exists with unrelated content:**
- Read entire existing file
- Add clear separator: `\n\n---\n\n`
- Append new summary below separator
- Preserve all existing content above

**If file exists with related content:**
- Ask user: "A summary for this project already exists. Should I:
  1. Append as a new entry (separate summary)
  2. Update the existing summary
  3. Create a new file with different date"

**Save location:**
- Directory: `~/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/summary/{YYYY}/`
- Ensure directory exists (create if needed)

### Step 5: Update Year Index
Update or create the year index file.

**Index file location:**
`~/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/summary/{YYYY}/index.md`

**Index format:**

```markdown
# Work Summaries - {YYYY}

## {Month Name}

### {YYYY-MM-DD} - {Project Name}
- **File**: [{project-name}](./{YYYY-MM-DD}-{project}.md)
- **Summary**: {One-line description}
- **Impact**: {Key impact metric or outcome}

### {YYYY-MM-DD} - {Another Project}
- **File**: [{project-name}](./{YYYY-MM-DD}-{project}.md)
- **Summary**: {One-line description}
- **Impact**: {Key impact metric or outcome}

## Statistics
- **Total Projects**: {count}
- **Total Summaries**: {count}
- **Last Updated**: {YYYY-MM-DD}
```

**Index update rules:**
- If index doesn't exist, create it with template
- If index exists, append new entry under appropriate month
- Keep entries sorted by date (newest first within each month)
- Update statistics section
- Preserve all existing entries

### Step 6: Confirm and Report
Provide clear feedback on what was done:

```
✅ Work Summary Generated

Project: {project-name}
Date: {YYYY-MM-DD}
Source: {notes|context}

Saved to:
📁 ~/workplace/.../knowledge/summary/{YYYY}/{YYYY-MM-DD}-{project}.md

Status:
- [Created|Appended|Updated] summary document
- Updated year index: {YYYY}/index.md
- {Preserved existing content|Created new file}

Summary includes:
- Timeline with {N} milestones
- {N} technical implementations
- {N} challenges and solutions
- {N} linked resources

This summary is now searchable via /search in Kiro.
```

## Usage

### In CLI
```bash
# Generate summary from conversation context
kiro "@summary.steering.md Generate summary for user-authentication project"

# Generate summary from daily notes
kiro "@summary.steering.md Generate summary for api-optimization from_notes=true"

# Generate summary for specific date range
kiro "@summary.steering.md Generate summary for database-migration date=2026-01-01 to 2026-01-15"
```

### What Happens
1. Agent gathers context from notes or conversation
2. Checks for existing summary file
3. Generates structured summary document
4. Saves or appends to file (preserving existing content)
5. Updates year index
6. Reports what was created/updated
7. Summary becomes searchable

## Important Notes
- **Preserve Content**: ALWAYS read existing files before writing, never overwrite unrelated content
- **Append Mode**: If file exists with unrelated content, append with clear separator
- **Ask First**: If file exists with related content, ask user how to proceed
- **Year Index**: Automatically maintains index of all summaries by year
- **Searchable**: Summaries in knowledge base are searchable via `/search`
- **Metadata**: Include frontmatter with project, date, and source information
- **Links**: Include references to plans, code reviews, tickets, MCMs
- **Tags**: Add relevant tags for easier searching and categorization
- **Source Tracking**: When from_notes=true, list all note files used
- **Impact Focus**: Emphasize business and technical impact with metrics when available

## Use Cases
- **Performance Reviews**: Document accomplishments for review cycles
- **Year-End Documentation**: Compile annual achievements
- **Project Retrospectives**: Capture lessons learned and outcomes
- **Knowledge Sharing**: Share project outcomes with team
- **Portfolio Building**: Track career progression and impact

## Difference from Other Steering Files
- **generate.steering.md**: Creates project documentation (product, tech, structure)
- **plan.steering.md**: Creates implementation plans with requirements and design
- **summary.steering.md**: Creates retrospective summaries of completed work
- All follow knowledge base organization and searchability patterns
