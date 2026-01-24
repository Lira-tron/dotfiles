---
name: create-design
description: Create clear, effective engineering design documents following structured templates. Use when writing technical design docs for software implementations with problem statement, solution, and alternatives.
compatibility: Designed for Kiro CLI
---

# Writing Effective Design Documents

When the user asks to create a design, follow a structured workflow with explicit approval gates. Generate design documents following AWS best practices.

## Purpose

This guide provides structured instructions for creating clear, effective engineering design documents. A good design document:

> 📝 **Note:** This document focuses on technical design documents for software engineering implementations. For business narratives and decision-making documents, see narrative-writing documentation.

1. **Communicates** ideas and transfers knowledge to the team
2. **Convinces** stakeholders of the value of your approach
3. **Solicits feedback** to improve the design before implementation
4. **Facilitates thinking through** complex problems in a structured way
5. **Enables collaboration** by creating shared understanding

## Document Structure and Format

### Formatting Standards

- **Length**: No longer than 6 pages (plus appendix and diagrams) with readable font and 1" margins
- **Organization**: Break content into clearly labeled sections for non-linear reading
- **Navigation aids**: Use numbered headings (1, 1.1, 1.1.2) and numbered lists to enable precise references
- **Formatting**:
  - Use **bold** for emphasis and key terms
  - Use *italics* for notes or commentary
  - Use `code formatting` for system commands, API endpoints, or code references

### Call-outs for Important Information

- ⚠️ **Warning blocks** for potential issues or pitfalls
- 📝 **Note blocks** for additional context
- 🔑 **Key point indicators** for critical information that must not be overlooked

## Design Document Structure

> 📝 **Note:** This template provides a comprehensive structure for design documents. However, **not all sections are mandatory** for every design. Consider each section's applicability to your specific design document. Design reviewers should not ask for sections purely for template conformance; sections should only be added if they provide meaningful value.

The recommended length is less than 6 pages (excluding appendices). Consider moving supporting sections, detailed user stories, and less important diagrams to the Appendix. For complex systems, consider splitting into a high-level design document and multiple detail-oriented component design documents.

### 1. Overview

Start with a clear introduction that defines:
- What the document addresses (scope)
- Why it is needed (justification)

**Example format:**
> This design proposes a new caching architecture for the Order Processing System to reduce database load during peak hours.

### 2. Background and Context

- Briefly describe existing system components relevant to your design
- Include a simple block diagram showing how things fit together
- Provide historical context (why the current system exists in its present form)
- Explain why this topic requires attention now
- Provide links to other related documentation
- Expand acronyms on first use (e.g., "Simple Token Service (STS)")
- Define abstractions with concrete examples

#### 2.1 Glossary (Optional)

Create a dedicated glossary section for key terminology:
- **Terms**: Domain-specific terminology and abbreviations
- **Services**: Key services that interact with the design, with descriptions of what they do/own

### 3. Goals, Objectives, and Problem Statement

- Define clear, measurable goals and objectives
- Explain the problem(s) this design addresses
- Link to relevant functional and non-functional requirements

#### 3.1 Functional Requirements
- List specific functionalities the solution must provide
- Use precise, measurable language

#### 3.2 Non-Functional Requirements
- Performance requirements with specific metrics
- Scalability parameters
- Security requirements
- Reliability targets
- Maintenance and operational requirements

### 4. Current and Desired Situation

#### 4.1 Current Status
- Describe how the stated problem is currently being handled
- Identify pain points in the existing approach

#### 4.2 Desired Status
- Describe the ideal situation after the problem is resolved
- Explain what success looks like

#### 4.3 Related Work and Similar Systems
- Describe other systems that address similar problems
- Explain how your solution differs from existing approaches
- Note any learnings from previous similar projects

### 5. Stakeholders
- Identify who benefits from this solution
- Define the end users and their needs
- List teams impacted by the implementation

### 6. Tenets
- List key principles that guide design decisions (limit to 7 or fewer)
- Reference organizational or team values that inform choices
- Ensure each tenet helps resolve conflicting priorities

### 7. Scope

#### 7.1 Assumptions
- Document critical assumptions the design relies upon
- Consider what happens if assumptions prove incorrect

#### 7.2 Constraints
- List technical, physical, regulatory, or other constraints
- Evaluate impact if constraints were removed

#### 7.3 In Scope
- Clearly define what the design addresses

#### 7.4 Out of Scope
- Explicitly document what will NOT be addressed
- Explain why certain elements are excluded

#### 7.5 Success Criteria
- Define SMART metrics for measuring success
- Include both business and operational metrics

### 8. Design/Solution

#### 8.1 Overview of Solution
- Provide a high-level overview of the proposed solution
- Include 2-3 paragraphs explaining the approach

#### 8.2 Architectural and Component-level Design
- Detail the solution's architecture with diagrams
- Include a clear System Architecture Diagram that shows the overall structure
- Describe components and their relationships
- Document:
  - Dependencies and consumers
  - System interactions
  - API changes
  - Data schemas and storage

#### 8.3 Security
- Assess security risks and mitigations
- Include threat modeling considerations
- Document access control mechanisms

#### 8.4 Scaling
- Describe expected scale at launch and growth projections
- Identify bottlenecks and scaling strategies
- Consider 10x/20x load scenarios

#### 8.5 Availability
- Detail failure handling strategies
- Address dependency failures, errors, and outages
- Explain redundancy across Availability Zones
- Document load shedding and traffic prioritization
- Consider idempotent API design

#### 8.6 Alternative Designs
Document alternatives that were considered using a structured format:

##### Alternative 1: [Name]
**One-line summary:** [Concise description of the alternative approach]

| Pros | Cons |
|------|------|
| • Specific advantage 1 | • Specific disadvantage 1 |
| • Specific advantage 2 | • Specific disadvantage 2 |
| • Specific advantage 3 | • Specific disadvantage 3 |

**Rejection rationale:** Explain precisely why this alternative was not selected with specific reasons.

#### 8.7 Key Decisions
- Document significant decisions with rationale
- Use comparison tables or pros/cons lists

### 9. Operations

- Detail how the system will be operated and monitored
- Include:
  - Configuration management
  - Metrics and dashboards
  - Alerting strategy
  - System diagnostics and tools
  - Pipeline approval processes

### 10. Rollout Strategy

- Describe release and deployment strategy
- Detail feature toggles, weblabs, configuration flags
- Plan for regional/phased rollouts
- Include bake times and testing gates

### 11. Risks

- Identify project risks that could affect success
- Develop mitigation plans
- Consider impacts of incorrect assumptions

### 12. Testing Plan

#### 12.1 Testing Strategy
- Outline testing strategy across levels:
  - Automated unit and integration tests
  - System and load tests
  - Manual testing (if required)
  - Test data management

#### 12.2 Automated Testing and Verification
- Detail how to validate behavior in both beta and production environments
- Consider specific test resources needed for complete testing
- Address how to test asynchronous components:
  - Prefer verifying the outcome of successful execution (e.g., status updates)
  - Use direct observation (e.g., logs) only as a last resort
- Plan for returning the system to a healthy state after testing
- Ensure tests can be executed consistently across environments

### 13. Open Questions

- List unresolved questions or decisions
- Track items that need follow-up

### 14. Appendices

- Include supporting information:
  - Detailed technical specifications
  - Extended code examples
  - Reference materials
  - Supporting calculations

### 15. Implementation Costs (IMR)

- Detail project costs at launch
- Project ongoing operational costs
- Include scaling and expansion costs

### 16. Development Plan

- Break down implementation into milestones
- Include tasks, estimates, and success criteria
- Link to tracking items (SIMs, tickets)
- List references, FAQs, and pre-mortem analysis
- Document ownership and review history

#### 16.1 Story Breakdown
- Break features into implementable stories (ideally 5 points or less)
- For each story:
  - Provide a clear title and point estimate
  - List specific acceptance criteria
  - Include details on implementation approach
  - Note dependencies between stories

## Tenet Writing Guidelines

A tenet is a principle or belief that helps teams align around critical questions. Following these guidelines ensures your tenets serve as effective decision-making tools.

### Core Principles for Effective Tenets

#### Structure and Format

1. ✅ **MUST**: Number tenets sequentially rather than using bullet points
   - Place most important tenets first
   - Limit to 7 or fewer tenets for maximum effectiveness

2. ✅ **SHOULD**: Begin each tenet with a short, memorable phrase
   - Highlight key words for emphasis
   - Create "catchy" wording that team members can easily recall

3. ✅ **SHOULD**: Keep tenets concise and focused
   - Each tenet should contain exactly one main idea
   - Eliminate unnecessary words and phrases

#### Content and Language

1. ✅ **MUST**: Use present tense, positive language
   - Describe what the team does (not what it doesn't do)
   - Avoid negative constructions like "do not" or "never"
   - ❌ **Incorrect**: "We do not sacrifice quality for speed"
   - ✅ **Correct**: "We deliver high-quality solutions at sustainable pace"

2. ✅ **MUST**: Provide context and rationale
   - Explain both *how* and *why*
   - Include enough detail that readers understand the underlying value

3. ✅ **SHOULD**: Write in a declarative, present-tense style
   - Avoid future-oriented words like "will," "want," "plan," or "should"
   - Phrase tenets as current practice, not aspirational goals

### Common Anti-patterns to Avoid

1. ❌ **NEVER**: Create "Who Doesn't Do That?" (WDDT) tenets
   - Avoid obvious statements that no one would argue against
   - **Example**: "We prioritize customers" (too generic to guide decisions)
   - **Better**: "We optimize for customer time savings over internal convenience"

2. ❌ **NEVER**: Combine multiple ideas in one tenet
   - When you see "X and Y" or "X; Y" structure, split into separate tenets
   - Each tenet should provide clear guidance on a single decision point

3. ❌ **SHOULD NOT**: Write prescriptive commandments
   - Avoid rigid rules that leave no room for interpretation
   - Include rationale that explains the underlying principle

4. ❌ **SHOULD NOT**: Use Leadership Principles as team tenets
   - Leadership Principles are company-wide values
   - Team tenets should be specific to your team's unique challenges

5. ❌ **SHOULD NOT**: Use acronyms or specialized jargon
   - Tenets should be understandable to people outside your team
   - Define any necessary technical terms

### Verifying Tenet Quality

A high-quality tenet **MUST**:

- Function as a tie-breaker between multiple viable options
- Be easily remembered by all team members
- Clearly convey what the team believes is important and why
- Be written in crisp, positive language
- Contain a single, focused idea
- Anchor in what is (or what is believed to be) true, not aspirational futures

Use these verification questions to evaluate each tenet:

1. "Would this help us decide between two reasonable options?"
2. "Can team members easily recall and apply this principle?"
3. "Does this communicate our unique values to outsiders?"
4. "Is this written in present tense with positive language?"

## Creating Effective Diagrams

Diagrams are critical for design documentation, providing visual representations of system flows, interactions, and architectures.

### Diagram Tool Selection and LLM Accessibility

#### 🔑 **PlantUML (Preferred)**
- **✅ RECOMMENDED**: PlantUML is the preferred diagramming tool for design documents
- **LLM-readable**: Source code can be analyzed by AI tools for detailed technical review
- **Version control friendly**: Text-based source integrates well with code review processes
- **Collaborative**: Easy to modify and iterate on diagrams through text editing

#### **Mermaid (Preferred)**
- **✅ RECOMMENDED**: Mermaid is a preferred diagramming tool for design documents
- **LLM-readable**: Source code can be analyzed by AI tools for detailed technical review

#### **Design Inspector (Allowed)**
- **⚠️ LIMITED REVIEW**: Diagrams created in Design Inspector are allowed but have review limitations
- **Not LLM-readable**: AI tools cannot analyze diagram content in detail without MCP server
- **Source linking required**: MUST include links to source diagrams on https://design-inspector.a2z.com

#### **Other Tools (Allowed with Restrictions)**
- **📝 SOURCE REQUIRED**: Any other diagramming tool is allowed provided there is a clear link to the diagram source
- **Review limitations**: Detailed technical analysis may not be possible depending on tool accessibility

### General Diagram Guidelines

- Choose the appropriate diagram type based on what you need to communicate
- **🔑 CRITICAL**: Ensure there is a link to the source for all diagrams to enable editing and review
- Make it extremely clear on the diagram what is being proposed/added vs. what is existing
- Include a descriptive title and caption for each diagram
- Ensure the diagram has a clear purpose that is stated in the text
- Break complex diagrams into multiple simpler ones when appropriate

### Diagram Types and Their Purposes

#### Data Flow Diagrams (DFD)
- **Focus**: Capturing input, output, and persistent state
- **Best for**: Security models and high-level data transformations
- **Key characteristic**: Arrows labeled with nouns indicating data flow direction

#### Component Diagrams
- **Focus**: Actions between components
- **Best for**: High-level system architecture
- **Key characteristic**: Arrows labeled with verbs showing which component triggers the action

#### Sequence Diagrams
- **Focus**: Detailed actions, data flow, and sequencing
- **Best for**: Complex interactions where order matters
- **Key characteristic**: Shows complete request/response flow with time sequence
- **Review criteria**:
  - Time flows vertically from top to bottom
  - Alternative paths are clearly labeled with conditions
  - Nested calls show proper nesting with activation bars
  - Critical decision points are highlighted

#### Entity Relationship Diagrams
- **Focus**: Data model and relationships
- **Best for**: Database design and data structure documentation

#### Activity Diagrams
- **Focus**: Flow of actions in a process
- **Best for**: Business processes and algorithms

#### State Diagrams
- **Focus**: Different states of a system and transitions between them
- **Best for**: Complex state-based behaviors

### Diagram Quality Criteria

#### 1. Structural Integrity
- ✅ All system entities or actors are clearly defined
- ✅ Participants use consistent naming conventions matching the rest of the document
- ✅ Message direction arrows correctly show the initiator and recipient
- ✅ Related actions are grouped using boxes, alt/opt blocks, or loops

#### 2. Technical Accuracy
- ✅ All critical service interactions are represented
- ✅ The diagram accurately reflects the described design in the document text
- ✅ Message labels are descriptive but concise
- ✅ State transitions are logical and complete

#### 3. Visual Clarity
- ✅ The diagram fits within reasonable screen bounds
- ✅ Text is readable and not crowded
- ✅ Important flows or decision points are emphasized
- ✅ Diagram focuses on one aspect of the system at an appropriate level of detail

#### 4. Documentation Integration
- ✅ The diagram has a descriptive title and caption
- ✅ The purpose of the diagram is clear from context
- ✅ The diagram source code is accessible (either inline or linked)

### Common Diagram Anti-patterns

#### Flow Issues
- ❌ **Crossing Arrows**: Messages that cross over each other, making flow difficult to follow
- ❌ **Inconsistent Direction**: Right-to-left messages mixed with left-to-right without logical pattern
- ❌ **Missing Returns**: Showing calls without necessary return messages

#### Content Issues
- ❌ **Overloaded Diagrams**: Trying to show too much in a single diagram
- ❌ **Generic Labels**: Using vague terms like "process data" instead of specific operations
- ❌ **Mixed Abstraction Levels**: Combining high-level architecture with low-level implementation details

#### Visual Issues
- ❌ **Poor Spacing**: Elements crowded together, making the diagram hard to read
- ❌ **Inconsistent Styling**: Random use of colors, line styles, or fonts
- ❌ **Unreadable Text**: Overly long message labels that extend beyond view or are truncated

## Writing Guidelines

### Technical Writing Best Practices

1. **Write simply**: Avoid unnecessarily complex language. Aim for a professional but accessible tone.

2. **Write concisely**: Remove unnecessary qualifiers and vague adjectives:
   - Avoid qualifiers that add no information: actually, basically, essentially, really, very, definitely, literally
   - Eliminate vague words: might, could, generally, usually, probably, some, most, somewhat
   - Replace non-specific adjectives with precise values when possible

3. **Minimize passive voice**: Use active voice for clarity and directness.
   - Passive: "The EMR cluster will be terminated"
   - Active: "The workflow will terminate the EMR cluster"

4. **Use precise language**:
   - Replace "some users may experience issues" with "10% of mobile users will experience 3-second delays"
   - Use concrete metrics and specific impacts
   - Provide exact requirements rather than suggestions

5. **Layer technical depth appropriately**:
   - Begin with high-level concepts accessible to all readers
   - Progress to detailed technical implementation
   - Separate deeply technical details into dedicated sections

6. **System References**: Always use the complete pattern:
   - Full system name with acronym in parentheses on first mention
   - Example: "Simple Storage Service (S3)" or "Content Delivery Network (CDN)"
   - Use the acronym consistently in subsequent mentions

## Design Document Review Guidelines

### Providing Feedback: Critical Issues First

When providing feedback on a design document, structure your review to maximize impact and clarity:

#### 🔑 **Executive Summary + Critical Issues Pattern**

1. **Start with Executive Summary** (1-2 sentences)
   - Briefly state your overall assessment
   - Example: "The approach is sound, but there are critical concerns about scalability and failure handling that must be addressed."

2. **Immediately Follow with Critical Issues** (if any exist)
   - List blocking or high-priority concerns that could fundamentally impact the design
   - Use clear severity indicators: 🚨 **CRITICAL**, ⚠️ **HIGH PRIORITY**, 📝 **IMPORTANT**
   - Be specific about the impact and what needs to change
   - Example format:

   > 🚨 **CRITICAL: Scalability Bottleneck**
   >
   > The proposed single-instance cache will become a bottleneck at 10K requests/second (Section 8.4). The design must address horizontal scaling before implementation.
   >
   > ⚠️ **HIGH PRIORITY: Missing Failure Recovery**
   >
   > Section 8.5 does not address cache failure scenarios. What happens when the cache is unavailable? This needs explicit handling.

3. **Then Provide Detailed Feedback**
   - After critical issues are highlighted, proceed with section-by-section detailed review
   - Include positive observations, suggestions for improvement, and minor issues

#### Why This Pattern Matters

- **Efficiency**: Readers immediately understand if there are blockers
- **Prioritization**: Authors know what to address first
- **Decision-making**: Stakeholders can quickly assess if the design is ready to proceed
- **Respect**: Shows you've identified the most important concerns upfront

#### Feedback Structure Template

```markdown
## Executive Summary
[2-3 sentence overview of the design and your assessment]

## Critical Issues
[List any blocking or high-priority concerns with severity indicators]

## Detailed Feedback

### Section 1: Introduction
[Detailed comments on this section]

### Section 8: Design/Solution
[Detailed comments on this section]

[Continue with other sections...]

## Positive Observations
[Highlight what the design does well]

## Recommendations
[Summarize key action items]
```

### For Reviewers: Evaluating Missing Alternatives

When reviewing design documents, **actively consider architectural alternatives that are not explicitly mentioned** in the document. A comprehensive review should evaluate whether the author has considered all relevant architectural patterns and best practices, even if they weren't included as formal alternatives.

#### Reviewer Questions to Ask

When reviewing alternatives sections, consider these questions:

1. **Industry Standards**: "Are there well-established industry patterns for this type of problem that weren't mentioned?"

2. **Trade-off Analysis**: "Are there obvious trade-offs (performance vs. cost, complexity vs. maintainability) that suggest other approaches?"

3. **Scale Considerations**: "Would different architectural patterns be more appropriate at different scales?"

4. **Technology Ecosystem**: "Are there complementary technologies or patterns commonly used with the proposed solution that weren't discussed?"

5. **Failure Modes**: "Are there alternative approaches that would handle the identified failure modes differently?"

#### When to Request Additional Alternatives

Request the author to consider additional alternatives when:

- ✅ A well-known architectural pattern directly addresses the stated problem but wasn't mentioned
- ✅ The proposed solution has obvious limitations that could be addressed by common alternative approaches
- ✅ Industry best practices suggest multiple viable approaches for the problem domain
- ✅ The trade-offs presented seem incomplete or one-sided

## Design Document Checklist

Before submitting your design document, verify that you've addressed:

### Content and Structure
- [ ] Introduction includes a one-line summary of the proposal
- [ ] Document explains why the proposal is needed with specific context
- [ ] Requirements are explicitly stated and measurable
- [ ] Out-of-scope items are explicitly documented
- [ ] Alternative designs are documented with structured pros/cons tables
- [ ] Document follows hierarchical organization (1, 1.1, 1.1.1)

### Design Considerations
- [ ] Failure cases are addressed with specific recovery mechanisms
- [ ] Latency requirements are stated with quantitative metrics
- [ ] Scalability is addressed with specific growth factors
- [ ] Cost implications are evaluated with numerical estimates where possible
- [ ] Security concerns are addressed with threat models
- [ ] Future extensions and system growth are considered

### Technical Precision
- [ ] System inputs are clearly explained with formats
- [ ] System outputs are clearly explained with formats
- [ ] Persistent state is documented with data models
- [ ] System triggers are defined with activation conditions
- [ ] Abstractions include concrete examples and details
- [ ] Code samples or API examples are included where appropriate

### Diagrams and Visuals
- [ ] Diagrams explain component relationships clearly
- [ ] Diagram arrows are consistent (data flow or action initiation)
- [ ] Entity relationships are explicitly defined
- [ ] Diagrams include legends or annotations for clarity
- [ ] Diagrams meet quality criteria for structural integrity
- [ ] Diagrams are technically accurate and match document text
- [ ] Diagrams are visually clear with appropriate layout
- [ ] Diagrams are appropriately integrated with the documentation

### Editorial
- [ ] Document is under 6 pages (plus appendices)
- [ ] Numbered lists and headings are used where appropriate
- [ ] Document is proofread for spelling and grammar
- [ ] Writing is concise with unnecessary words removed
- [ ] Call-outs highlight critical information
- [ ] Tables are used to structure comparative information

## Common Anti-patterns to Avoid

### 1. Insufficient Requirements Specification
**Anti-pattern**: The document does not clearly specify or clarify the requirements of the intended system.

**Solution**: Always include a dedicated section that explicitly states the functional and non-functional requirements that drove the design decisions.

### 2. Missing Decision Framework
**Anti-pattern**: The document is not driving any decisions or the decisions are not explicitly specified.

**Solution**: Clearly state what decisions need to be made as a result of this document and provide sufficient information to make those decisions.

### 3. Solution-First Thinking
**Anti-pattern**: The document starts with the solution and only describes the solution without discussing requirements and alternatives.

**Solution**: Follow the structure in this guide—begin with problem statement and requirements, then proposed solution, followed by alternatives considered.

### 4. Ignoring Historical Context
**Anti-pattern**: When designing a replacement for an existing system, the document fails to discuss the existing system and its weaknesses in sufficient detail.

**Solution**: Include a thorough analysis of the current system, highlighting specific pain points and limitations that motivated the redesign.

### 5. No Implementation Path
**Anti-pattern**: There is no clear path forward after the document has been reviewed.

**Solution**: Always include a detailed "Next Steps" section with concrete actions, owners, and timelines.

### 6. Missing Architectural Direction
**Anti-pattern**: The solution is an incremental improvement but lacks discussion about the direction the architecture is headed in.

**Solution**: Include considerations for both short-term and long-term architectural evolution.

### 7. Unjustified Flexibility
**Anti-pattern**: The solution is designed to be highly flexible but the need for flexibility is not explained.

**Solution**: If designing for flexibility, explicitly justify why this flexibility is needed and which specific future scenarios it will accommodate.

### 8. Abstraction Without Implementation
**Anti-pattern**: The document spends significant time describing a new abstraction but never details the implementation specifics.

**Solution**: For each abstraction introduced, include concrete implementation details, examples, and potential edge cases.

### 9. Unclear Stakeholder Involvement
**Anti-pattern**: Reviewers are not sure why they are invited to the design document review, or key stakeholders are missing from the review meeting.

**Solution**: Include a section that identifies key stakeholders and their roles in the review process.

### 10. Vague or Unquantified Statements
**Anti-pattern**: Using imprecise language like "fast enough," "scalable," or "efficient" without specific metrics.

**Solution**: Replace qualitative descriptions with quantitative metrics:
- Instead of "fast enough," specify "response time under 100ms for 99% of requests"
- Instead of "scalable," specify "supports 10,000 concurrent users with ability to scale to 100,000"

## 🚨 NON-NEGOTIABLE RULE: Context Section Updates 🚨

**ABSOLUTE REQUIREMENT - NO EXCEPTIONS:**

Design documents MUST have Context sections that update AUTOMATICALLY after EVERY significant interaction. This is NOT optional. This is NOT negotiable.

**ALL design documents MUST:**
1. ✅ Include a Context section at the end with Timeline and Conversation Summary
2. ✅ Have this Context section updated AUTOMATICALLY after EVERY significant interaction
3. ✅ Updates happen WITHOUT asking for permission - just do it automatically
4. ✅ Track ALL links to related resources (CRs, tickets, other docs, knowledge entries)
5. ✅ This enables session recovery if the conversation dies

**Update Context section automatically when:**
- User provides feedback, requests changes, or makes decisions
- Design content is modified or refined
- User asks questions or provides clarifications
- Any iteration or approval gate is reached
- Links to CRs, tickets, or other resources are created
- Progress is made or milestones are achieved

**Link Tracking:**
- AUTOMATICALLY add links to Context section when working on design documents
- Track: Code reviews (CRs), tickets, related docs, knowledge entries, external resources
- Format: `- [Description](URL)` or `- [path/to/file.md](path)`
- Check for duplicates before adding (don't add if already exists)
- NEVER remove existing links

### Context Section Template

Add this section at the end of every design document:

```markdown
## Context

### Timeline
- **YYYY-MM-DD HH:MM**: Initial design created - {brief description}
- **YYYY-MM-DD HH:MM**: Decision - {what was decided and why}
- **YYYY-MM-DD HH:MM**: Change requested - {what changed}
- **YYYY-MM-DD HH:MM**: Progress - {milestone achieved}

### Links
- [PR-12345](https://github.com/org/repo/pull/12345)
- [Ticket ABC-123](https://jira.company.com/browse/ABC-123)
- [Related design](path/to/related-design.md)
- [Knowledge entry](~/.kiro/knowledge/memory/topic.md)

### CONVERSATION SUMMARY
═════════════════════════════════════════════════════════════════════

#### OBJECTIVE
{What the design is trying to accomplish}

#### USER GUIDANCE
- {Key requests and clarifications from user}
- {Important decisions made}

#### COMPLETED
- {Design sections finished}
- {Milestones achieved}

#### TECHNICAL CONTEXT
- {Relevant technical details}
- {File paths, configurations, dependencies}
- {System information}

#### TOOLS EXECUTED
1. {Tool name} - {outcome}
2. {Tool name} - {outcome}

#### NEXT STEPS
1. {Immediate next action}
2. {Follow-up tasks}

#### TODO LIST
{Outstanding items or blockers}

**CRITICAL**: Update this CONVERSATION SUMMARY, timeline, and links automatically after every significant interaction without being asked. This enables session recovery if the conversation dies.
```

### When to Update Context Section

Update the Context section automatically when:
- User provides feedback or requests changes
- User makes a decision or approval
- Design content is modified
- Any significant progress is made
- User asks questions or provides clarifications
- Links to CRs, tickets, or other resources are created
- Any iteration or approval gate is reached

**DO NOT** ask permission to update the Context section - just do it automatically.
**DO NOT** skip the update - it's MANDATORY.
**DO NOT** forget to track links - it's CRITICAL.

