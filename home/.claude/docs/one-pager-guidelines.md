---
name: one-pager-guidelines
description: One-pager format and guidelines for proposing features, projects, or changes
version: 1.0.0
tags: ["one-pager", "documentation", "proposal"]
inclusion: auto
---

# One-Pager Guidelines

One-pager format for proposing features, projects, or changes. A one-pager is a concise document that communicates the what, why, and how of a proposal in a single narrative.

---

## Purpose

A one-pager:
1. **Communicates** a proposal clearly and concisely
2. **Aligns** stakeholders on the problem and approach
3. **Gets approval** to proceed with detailed design or implementation
4. **Creates a record** of the decision and rationale

---

## Formatting Standards

- **Length**: 1–2 pages maximum (excluding appendix)
- **Style**: Narrative prose — no bullet-point-only sections
- **Tone**: Direct, data-driven, action-oriented
- **Font**: Readable, 1" margins

---

## Document Structure

### 1. Title and Metadata

```markdown
# One-Pager: {Proposal Name}

**Author**: {alias}
**Date**: {YYYY-MM-DD}
**Status**: Draft | In Review | Approved | Rejected
**Reviewers**: {list of aliases}
**Related**: {links to tickets, design docs, or prior art}
```

### 2. Problem Statement

State the problem in 2–3 sentences. Be specific and quantitative.

- What is broken, missing, or suboptimal?
- Who is affected and how?
- What is the business or operational impact?

**Good**: "Order processing latency P99 increased from 200ms to 1.2s over the past 3 months, causing 2% of checkout attempts to time out. This affects approximately 50K customers per day."

**Bad**: "The system is slow and customers are unhappy."

### 3. Tenets (Optional)

If the proposal involves trade-offs, list 1–3 tenets that guide the decision:
- Use present tense, positive language
- Each tenet should help resolve a specific trade-off
- Avoid obvious statements ("We prioritize customers")

### 4. Proposed Solution

Describe the approach in 2–4 paragraphs:
- What will you build or change?
- How does it solve the problem?
- What is the high-level architecture or approach?

Include a simple diagram if it aids understanding.

### 5. Alternatives Considered

For each alternative (2–3 minimum):

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| {Name} | {advantages} | {disadvantages} | {specific rejection reason} |

### 6. Scope

#### In Scope
- What this proposal covers

#### Out of Scope
- What this proposal explicitly does NOT cover and why

### 7. Success Criteria

Define measurable outcomes:
- Use specific metrics with targets
- Include both business and operational metrics
- Define the measurement timeframe

**Example**:
- P99 latency < 300ms within 2 weeks of launch
- Error rate < 0.1% (baseline: 2%)
- Zero customer-facing incidents during rollout

### 8. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| {risk description} | Low/Med/High | Low/Med/High | {mitigation plan} |

### 9. Estimated Effort

- **Timeline**: {estimated duration}
- **Team**: {number of engineers, roles}
- **Dependencies**: {external teams or systems}
- **Cost**: {infrastructure, operational costs if applicable}

### 10. Next Steps

Numbered list of concrete actions with owners:
1. {Action} — {owner} — {target date}
2. {Action} — {owner} — {target date}

---

## Writing Tips

### DO
- ✅ Lead with the problem, not the solution
- ✅ Use data and metrics to quantify impact
- ✅ Be honest about trade-offs and risks
- ✅ Keep it short — respect the reader's time
- ✅ Include alternatives to show you've thought broadly
- ✅ Make the ask explicit (approval, feedback, resources)

### DON'T
- ❌ Write more than 2 pages (move details to appendix)
- ❌ Use vague language ("improve performance", "enhance experience")
- ❌ Skip alternatives — it signals you haven't explored the space
- ❌ Bury the ask — state what you need upfront
- ❌ Include implementation details — save those for the design doc
- ❌ Use bullet points as a substitute for narrative prose

---

## Common Anti-patterns

### 1. Solution-First Thinking
Starting with "We should build X" instead of "The problem is Y."
Fix: Always lead with the problem statement.

### 2. Vague Impact
"This will improve customer experience."
Fix: "This reduces checkout latency P99 from 1.2s to 200ms, eliminating 2% timeout rate."

### 3. Missing Alternatives
Only presenting one option signals lack of exploration.
Fix: Always include 2–3 alternatives with honest pros/cons.

### 4. Scope Creep
Trying to solve everything in one proposal.
Fix: Be explicit about out-of-scope items and why.

### 5. No Clear Ask
Reader finishes and doesn't know what to do.
Fix: End with explicit next steps and what you need from reviewers.

---

## Quality Checklist

- [ ] Problem is stated in first paragraph with quantitative impact
- [ ] Solution is described in 2–4 paragraphs
- [ ] At least 2 alternatives are documented with rejection rationale
- [ ] Success criteria are measurable with specific targets
- [ ] Risks are identified with mitigations
- [ ] Effort estimate includes timeline, team, and dependencies
- [ ] Next steps have owners and dates
- [ ] Document is ≤ 2 pages (excluding appendix)
- [ ] Active voice throughout
- [ ] No vague or unquantified statements
