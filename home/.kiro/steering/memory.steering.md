# Store to Knowledge Base Memory

## Overview
Quickly stores important information, decisions, implementations, or learnings to the knowledge base during active work sessions. Use this when you want to preserve context, decisions, or outputs for future reference.

## ⚠️ CRITICAL: Kiro Knowledge Base Integration

**This uses Kiro's native knowledge base:**
- Files are stored as markdown in `.kiro/knowledge/memory/`
- **Global knowledge base**: Accessible across ALL workspaces and projects
- Automatically indexed and searchable via `/search` in Kiro from any workspace
- No manual indexing needed - Kiro handles it automatically
- Search and list functionality comes from Kiro's core features

## What This Does
Stores knowledge entries during active sessions:
- Implementation details and approaches
- Technical decisions and rationale
- Debugging solutions and findings
- Architecture choices
- Code patterns and conventions
- Lessons learned
- Important outputs or results

## File Locations
Knowledge is stored in:
- **Knowledge Base**: `~/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/memory/{project}/{YYYY}/{MM}/{topic}.md`
- **Index**: `~/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/memory/index.md`

## Parameters
- **topic** (required): Topic name (e.g., "architecture", "debugging", "api-design", "implementation")
- **project** (optional): Project name (defaults to current workspace name)

**Note**: Content can come from:
- Direct user input (what they want to store)
- Open/referenced documents (agent extracts automatically)
- URLs mentioned in the request (agent fetches and extracts)

## Workflow

### Step 1: Determine Context and Source
Identify what needs to be stored and where it comes from:
- Current project/workspace
- Topic category
- Content source (direct input, document, or URL)

**Content Sources:**
1. **Direct input**: User provides content directly
2. **Document**: User references a file path (e.g., "look at design.md")
3. **URL**: User provides a link (e.g., "store info from https://...")

**If source is provided:**
- Read the document or fetch the URL
- Extract relevant information
- Summarize key points
- Include source reference in the entry

**If not specified:**
- Project defaults to current workspace name
- Topic can be inferred from content or ask user
- Content is what user wants to store

### Step 2: Extract Information (if source provided)
If a document path or URL is provided, extract the information:

**For local documents:**
1. Read the file content
2. Extract key information relevant to the topic
3. Summarize main points
4. Include document path as reference

**For URLs:**
1. Fetch the web page content
2. Extract relevant information
3. Summarize key points
4. Include URL as reference
5. Note: Add attribution and source link

**Extraction guidelines:**
- Focus on information relevant to the topic
- Summarize rather than copy verbatim
- Include key technical details
- Preserve code examples if relevant
- Add context about why this is being stored

### Step 3: Prepare File Path
Determine where to store the entry:

**Path format:**
`~/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/memory/{project}/{YYYY}/{MM}/{topic}.md`

**Create directories if needed:**
- Ensure year directory exists
- Ensure month directory exists
- Ensure project directory exists

### Step 4: Check for Existing File
**CRITICAL**: Always check if the topic file already exists:

1. **If file exists**:
   - Read the entire file
   - Append new entry at the end
   - Preserve all existing content

2. **If file doesn't exist**:
   - Create new file with frontmatter header

### Step 4: Format Entry
Create a timestamped entry:

**For new file:**
```markdown
---
topic: {topic}
project: {project}
created: {YYYY-MM-DD}
---

# {Topic Title}

## [YYYY-MM-DD HH:MM]

{content}

---
```

**For existing file (append):**
```markdown

## [YYYY-MM-DD HH:MM]

{content}

---
```

### Step 5: Write to File
Save the entry:
- If new file, create with full template
- If existing file, append entry at the end
- Newest entries at bottom (chronological order)

### Step 6: Update Index
Update the knowledge base index:

**Index path:**
`~/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/memory/index.md`

**Index format:**
```markdown
# Knowledge Base Memory Index

Last updated: YYYY-MM-DD HH:MM

## Projects

### {Project Name}
- **{topic}** - {entry_count} entries - Last updated: YYYY-MM-DD
  - Path: `./{project}/{YYYY}/{MM}/{topic}.md`

### {Another Project}
- **{topic}** - {entry_count} entries - Last updated: YYYY-MM-DD
  - Path: `./{project}/{YYYY}/{MM}/{topic}.md`

## Statistics
- **Total Projects**: {count}
- **Total Topics**: {count}
- **Total Entries**: {count}
- **Last Updated**: {YYYY-MM-DD HH:MM}
```

**Update rules:**
- If index doesn't exist, create it
- If index exists, update the relevant project/topic entry
- Update statistics
- Update last updated timestamp

### Step 7: Confirm and Report
Provide clear feedback:

```
✅ Stored to Knowledge Base Memory

Topic: {topic}
Project: {project}
Timestamp: {YYYY-MM-DD HH:MM}

Saved to:
📁 ~/workplace/.../knowledge/memory/{project}/{YYYY}/{MM}/{topic}.md

Preview:
{First 150 chars of content}...

This entry is now searchable via /search in Kiro.
```

## Usage

### In CLI
```bash
# Store implementation details
kiro "@memory.steering.md Store the GraphQL implementation approach we just discussed"

# Store with specific topic
kiro "@memory.steering.md topic=architecture Store decision to use event-driven architecture"

# Store from a document
kiro "@memory.steering.md Store this design doc to memory" # (with design.md open or referenced)

# Store from a URL
kiro "@memory.steering.md Store this design doc https://example.com/design to memory"

# Store from notes
kiro "@memory.steering.md Store this note to memory bank" # (with note file open or referenced)

# Store debugging solution
kiro "@memory.steering.md topic=debugging Store the fix for the memory leak in user service"

# Store with project and topic
kiro "@memory.steering.md project=api-refactor topic=performance Store the caching strategy that improved latency by 50%"
```

### Common Use Cases

**During Implementation:**
```bash
"Store this implementation approach to memory"
"Save this code pattern to knowledge base"
"Remember this solution for future reference"
```

**From Documents:**
```bash
"Store this design doc to memory"
"Save this architecture document to knowledge base"
"Store this note in the memory bank"
"Remember this specification document"
```

**From URLs:**
```bash
"Store this design doc (URL) in the memory"
"Save info from this blog post to knowledge base"
"Store this API documentation to memory"
```

**After Debugging:**
```bash
"Store this debugging solution to memory"
"Save this fix to knowledge base"
"Remember how we solved this issue"
```

**After Decisions:**
```bash
"Store this architecture decision to memory"
"Save this API design choice to knowledge base"
"Remember why we chose this approach"
```

**After Learning:**
```bash
"Store this lesson learned to memory"
"Save this insight to knowledge base"
"Remember this gotcha for next time"
```

## Important Notes

### Kiro Integration
- **Global Knowledge Base**: Stored in central location, accessible from any workspace
- **Automatic Indexing**: Kiro automatically indexes all markdown files in `.kiro/knowledge/`
- **Native Search**: Use `/search` in Kiro to find stored entries from any workspace
- **No Manual Commands**: Just save files - Kiro handles indexing
- **Real-time**: Changes are picked up immediately
- **Cross-workspace**: Search and access knowledge from any project

### File Organization
- **Chronological**: Organized by year/month for easy navigation
- **Project-based**: Each project gets its own directory
- **Topic-based**: Topics are individual markdown files
- **Append-only**: New entries append to existing files (preserves history)

### Best Practices
- **Store During Work**: Capture knowledge while it's fresh
- **Be Specific**: Include context, rationale, and details
- **Link Resources**: Reference code reviews, tickets, plans
- **Use Clear Topics**: Choose descriptive topic names
- **Include Code**: Add code snippets when relevant

### Markdown Format
- **Frontmatter**: YAML metadata for organization
- **Timestamps**: Each entry has `## [YYYY-MM-DD HH:MM]` header
- **Separators**: `---` between entries
- **Rich Content**: Use markdown formatting, code blocks, links

### Common Topics
- **architecture** - System design and architectural decisions
- **implementation** - Implementation approaches and details
- **debugging** - Debugging sessions and solutions
- **api-design** - API design decisions and conventions
- **performance** - Performance optimizations and benchmarks
- **security** - Security considerations and implementations
- **patterns** - Code patterns and best practices
- **decisions** - Technical decisions with rationale
- **learnings** - Lessons learned and insights
- **infrastructure** - Infrastructure setup and configuration

## Example Entries

### From Document/URL Entry
```markdown
## [2026-01-16 13:15]

Key insights from GraphQL best practices documentation.

**Summary**:
- Use DataLoader for batching and caching
- Implement query complexity analysis
- Set depth limits to prevent abuse
- Use persisted queries in production

**Key Patterns**:
```js
// Query complexity calculation
const complexity = query.definitions.reduce((total, def) => {
  return total + calculateComplexity(def);
}, 0);
```

**Recommendations**:
- Max depth: 7 levels
- Max complexity: 1000 points
- Enable query whitelisting for production

**Source**: https://graphql.org/learn/best-practices/

---
```

### Implementation Entry
```markdown
## [2026-01-16 14:30]

Implemented GraphQL resolver caching using DataLoader pattern.

**Approach**:
- Created DataLoader instances per request
- Batched database queries
- Added Redis caching layer

**Code Pattern**:
```js
const userLoader = new DataLoader(async (ids) => {
  return await User.findByIds(ids);
});
```

**Results**:
- Reduced N+1 queries
- Improved response time by 60%

**Links**: CR-12345678

---
```

### Debugging Entry
```markdown
## [2026-01-16 15:45]

Fixed memory leak in WebSocket connection handler.

**Problem**: Memory usage growing unbounded in production.

**Root Cause**: Event listeners not being removed on disconnect.

**Solution**:
```js
socket.on('disconnect', () => {
  socket.removeAllListeners();
  connectionMap.delete(socket.id);
});
```

**Verification**: Memory usage stable after 24h in production.

---
```

### Decision Entry
```markdown
## [2026-01-16 16:20]

Decided to use PostgreSQL over DynamoDB for user data.

**Context**: Need to store user profiles with complex relationships.

**Decision**: PostgreSQL with JSONB for flexible schema.

**Rationale**:
- Complex queries needed
- ACID transactions required
- Existing team expertise
- Cost-effective at current scale

**Trade-offs**: May need to revisit at 10M+ users.

---
```

### From Notes Entry
```markdown
## [2026-01-16 17:00]

Meeting notes: API versioning strategy discussion.

**Decision**: Use URL path versioning (e.g., /v1/, /v2/)

**Key Points**:
- Easier for clients to understand
- Clear deprecation path
- Can run multiple versions simultaneously
- Sunset policy: 12 months after new version

**Action Items**:
- Update API gateway configuration
- Document versioning policy
- Create migration guide for v1 → v2

**Source**: ~/notes/meetings/2026-01-16-api-versioning.md

---
```

## Difference from Other Steering Files
- **generate.steering.md**: Creates project documentation (product, tech, structure)
- **plan.steering.md**: Creates implementation plans with requirements and design
- **summary.steering.md**: Creates retrospective summaries of completed work
- **memory.steering.md**: Stores quick knowledge entries during active work sessions
- All use knowledge base and are searchable via `/search`
