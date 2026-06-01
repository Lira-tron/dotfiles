---
name: slack-catchup
description: "Summarize unread Slack threads from key channels, highlight action items"
---

# Slack Catchup

When asked to catch up on Slack, summarize channels, or used via `/loop`:

## Process

1. **Identify channels** — Check configured channels of interest. Common security team channels:
   - Team channel
   - Oncall channel
   - Security announcements
   - Incident response channels
   - Cross-team collaboration channels

2. **Fetch recent messages** — Use the Slack MCP server to:
   - Get conversation history from each channel (last 24h or since last catchup)
   - Get thread replies for active discussions
   - Get user info to resolve display names

3. **Identify action items** — Look for:
   - Direct mentions of your name/alias
   - Questions directed at you or your team
   - Requests for review, approval, or input
   - Oncall escalations or handoffs
   - Deadlines or time-sensitive items

4. **Summarize threads** — For each active thread:
   - Topic and key participants
   - Current status / conclusion (if any)
   - Whether your input is needed

5. **Generate catchup** — Produce a prioritized summary.

## Output Format

```
# Slack Catchup — [Date/Time]

## Action Items (X items)
- **#oncall**: @you was mentioned — [person] needs help with [issue]
- **#team**: Review requested on [topic] by EOD

## Active Discussions
- **#security-announcements**: New policy change — TL;DR: SLA for critical issues reduced to 7 days
- **#team**: Discussion about [topic] — 12 messages, concluded with [decision]

## FYI
- **#general**: All-hands moved to Thursday
```

## Loop Schedule
Recommended: `/loop` 2-3x daily or on-demand after meetings

## MCP Dependencies
- Slack MCP server (ai-community-slack-mcp or equivalent)
