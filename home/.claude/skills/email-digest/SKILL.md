---
name: email-digest
description: "Summarize unread emails via Outlook MCP, group by priority, draft replies"
---

# Email Digest

When asked to summarize emails, check inbox, or used via `/loop` on a schedule:

## Process

1. **Fetch unread emails** — Use the Outlook MCP server to retrieve unread messages:
   - Filter to unread only
   - Sort by date descending
   - Limit to last 24 hours (or since last digest)

2. **Categorize** — Group emails into:
   - **Action Required**: Emails that need a response or action from you
   - **FYI / Informational**: Newsletters, announcements, automated notifications
   - **Threads You're CC'd On**: Conversations where you're copied but not primary
   - **Calendar**: Meeting invites and updates

3. **Summarize each** — For action-required emails:
   - Who sent it and when
   - One-line summary of what they need
   - Suggested response or action

4. **Draft quick replies** — For routine emails (meeting accepts, simple questions), draft a reply the user can review and send.

5. **Generate digest** — Produce a prioritized summary.

## Output Format

```
# Email Digest — [Date/Time]

## Action Required (X emails)
- **From**: [sender] — [subject]
  Summary: They need approval for the design doc by Friday.
  Suggested action: Review and reply with feedback.

## FYI (X emails)
- [sender]: [subject] — TL;DR: New security policy update effective next month.

## Threads (X emails)
- [subject] — 3 new replies, no action needed from you.

## Draft Replies
1. Re: [subject] — "Looks good, approved. Thanks!"
```

## Loop Schedule
Recommended: `/loop` 2-3x daily (morning, after lunch, end of day)

## MCP Dependencies
- Outlook MCP server (for email access)

## Note
The Outlook MCP server must be configured and enabled in your MCP settings. The installer can set this up if you have the server available.
