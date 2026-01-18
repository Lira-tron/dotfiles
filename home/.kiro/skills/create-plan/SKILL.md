---
name: create-plan
description: Create implementation plans with requirements, design, and tasks. Use when planning new features or components. Generates three files with approval gates at each phase.
compatibility: Designed for Kiro CLI
---

# Plan Generation Skill

When the user invokes this skill or asks to create a plan, follow a structured workflow with explicit approval gates. Generate three files following AWS and coding best practices:

## ⚠️ CRITICAL REQUIREMENT: Context Section Updates

**ALL three files (requirements.md, design.md, implementation.md) MUST:**
1. Include a Context section at the end with Timeline and Conversation Summary
2. Have this Context section updated AUTOMATICALLY after EVERY significant interaction
3. Updates happen WITHOUT asking for permission - just do it automatically
4. This enables session recovery if the conversation dies

**Update Context section automatically when:**
- User provides feedback, requests changes, or makes decisions
- Requirements, design, or implementation is modified
- Tasks are completed or progress is made
- User asks questions or provides clarifications
- Any iteration or approval gate is reached

## File Structure
Store files in: `~/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/plans/{YY}/{MM}/{component}/{feature}/`

Generate:
1. `requirements.md` - User stories and acceptance criteria
2. `design.md` - Architecture and technical design
3. `implementation.md` - Implementation steps with status tracking

## Workflow Phases

### Phase 1: Requirements Gathering
1. Generate `requirements.md` based on user's feature idea
2. Present requirements for review
3. **GATE**: Get explicit user approval before proceeding
4. Iterate based on feedback until approved

### Phase 2: Design Creation
1. Generate `design.md` based on approved requirements
2. Present design for review
3. **GATE**: Get explicit user approval before proceeding
4. Iterate based on feedback until approved

### Phase 3: Implementation Planning
1. Generate `implementation.md` based on approved design
2. Present implementation plan for review
3. **GATE**: Get explicit user approval before proceeding
4. Execute tasks with status tracking

## requirements.md Format
```markdown
# Requirements: {Feature Name}

## Introduction
[Summary of the feature/system]

## Glossary
- **System/Term**: [Definition]
- **Another_Term**: [Definition]

## Requirements

### Requirement 1: [Requirement Name]

**User Story:** As a [role], I want [feature], so that [benefit]

#### Acceptance Criteria

1. WHEN [event], THE [System_Name] SHALL [response]
2. WHILE [state], THE [System_Name] SHALL [response]
3. IF [undesired event], THEN THE [System_Name] SHALL [response]
4. WHERE [optional feature], THE [System_Name] SHALL [response]
5. THE [System_Name] SHALL [response] (ubiquitous)

### Requirement 2: [Requirement Name]

**User Story:** As a [role], I want [feature], so that [benefit]

#### Acceptance Criteria

1. THE [System_Name] SHALL [response]
2. WHEN [event], THE [System_Name] SHALL [response]

[Continue with additional requirements...]

## EARS Patterns Reference
- **Ubiquitous**: THE <system> SHALL <response>
- **Event-driven**: WHEN <trigger>, THE <system> SHALL <response>
- **State-driven**: WHILE <condition>, THE <system> SHALL <response>
- **Unwanted event**: IF <condition>, THEN THE <system> SHALL <response>
- **Optional feature**: WHERE <option>, THE <system> SHALL <response>

## INCOSE Quality Rules
- **Clarity**: Use active voice, no vague terms, no pronouns
- **Testability**: Explicit conditions, measurable criteria
- **Completeness**: No escape clauses, no absolutes unless true
- **Positive Statements**: Use "SHALL" not "SHALL NOT" when possible

## Non-Functional Requirements
- Performance targets
- Security requirements
- Scalability needs
- Reliability expectations
- Maintainability goals

## Constraints
- Technical limitations
- Business constraints
- Timeline considerations
- Resource availability
```

## design.md Format
```markdown
# Design: {Feature Name}

## Overview
[Brief summary of the feature and design approach]

## Architecture

### High-Level Design
- Component overview
- System interactions
- Data flow diagrams (use Mermaid if helpful)

### AWS Best Practices (if applicable)
- Well-Architected Framework pillars
- Service selection rationale
- Security considerations
- Cost optimization

### Technical Decisions
- Technology choices
- Trade-offs considered
- Alternatives evaluated

## Components and Interfaces

### Component 1: [Component Name]
- **Purpose**: What it does
- **Responsibilities**: Key functions
- **Interfaces**: Public API/methods
- **Dependencies**: What it depends on

### Component 2: [Component Name]
- **Purpose**: What it does
- **Responsibilities**: Key functions
- **Interfaces**: Public API/methods
- **Dependencies**: What it depends on

## Data Models

### Model 1: [Model Name]
- **Fields**: Field definitions with types
- **Validation**: Validation rules
- **Relationships**: How it relates to other models

### Model 2: [Model Name]
- **Fields**: Field definitions with types
- **Validation**: Validation rules
- **Relationships**: How it relates to other models

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: [Property Title]
*For any* [input/state], [operation] should [expected behavior]
**Validates: Requirements X.Y**

### Property 2: [Property Title]
*For any* [input/state], [operation] should [expected behavior]
**Validates: Requirements X.Y**

[Continue with additional properties...]

### Common Property Patterns
- **Invariants**: Properties that remain constant (e.g., collection size, tree balance)
- **Round Trip**: Combining operation with inverse returns original (e.g., parse→print→parse)
- **Idempotence**: Doing twice = doing once (e.g., f(x) = f(f(x)))
- **Metamorphic**: Relationships between components (e.g., len(filter(x)) ≤ len(x))
- **Error Conditions**: Invalid inputs properly signal errors

## Error Handling

### Error Case 1: [Error Type]
- **Condition**: When this error occurs
- **Handling**: How system responds
- **Recovery**: How to recover if possible

### Error Case 2: [Error Type]
- **Condition**: When this error occurs
- **Handling**: How system responds
- **Recovery**: How to recover if possible

## Testing Strategy

### Unit Testing
- Test specific examples and edge cases
- Focus on individual component behavior
- Validate error conditions

### Property-Based Testing
- Test universal properties across many inputs
- Use property testing library (e.g., Hypothesis for Python, fast-check for TypeScript)
- Minimum 100 iterations per property test
- Each property test references design property

### Integration Testing
- Test component interactions
- Validate end-to-end flows
- Test with realistic data
```

## Context Section (for all files)

**CRITICAL**: This section MUST be added at the end of requirements.md, design.md, and implementation.md. It MUST be updated automatically after EVERY significant interaction without being asked.

Add this section at the end of requirements.md, design.md, and implementation.md:

```markdown
## Context

### Timeline
- **{Date/Time}**: Initial request - {brief description}
- **{Date/Time}**: Decision - {what was decided and why}
- **{Date/Time}**: Change requested - {what changed}
- **{Date/Time}**: Progress - {milestone achieved}

### CONVERSATION SUMMARY
═════════════════════════════════════════════════════════════════════

#### OBJECTIVE
{What the user is trying to accomplish}

#### USER GUIDANCE
- {Key requests and clarifications from user}
- {Important decisions made}

#### COMPLETED
- {Tasks and steps finished}
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

**CRITICAL**: Update this CONVERSATION SUMMARY and timeline automatically after every significant interaction without being asked. This enables session recovery if the conversation dies.
```

### When to Update Context Section
Update the Context section in ALL three files automatically when:
- User provides feedback or requests changes
- User makes a decision or approval
- A task is completed
- Requirements, design, or implementation is modified
- Any significant progress is made
- User asks questions or provides clarifications

**DO NOT** ask permission to update the Context section - just do it automatically.

## implementation.md Format
```markdown
# Implementation Plan: {Feature Name}

## Overview
[Brief description of the implementation approach]

## Tasks

- [ ] 1. Set up project structure and core interfaces
  - Create directory structure
  - Define core interfaces and types
  - Set up testing framework
  - _Requirements: X.Y_

- [ ] 2. Implement core functionality
  - [ ] 2.1 Implement [Component A]
    - Write implementation for core logic
    - _Requirements: X.Y, X.Z_
  
  - [ ]* 2.2 Write property test for [Component A]
    - **Property N: [Property Title]**
    - **Validates: Requirements X.Y**
  
  - [ ] 2.3 Implement [Component B]
    - Write implementation for supporting logic
    - _Requirements: X.Z_
  
  - [ ]* 2.4 Write unit tests for [Component B]
    - Test edge cases and error conditions
    - _Requirements: X.Z_

- [ ] 3. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 4. Implement data layer
  - [ ] 4.1 Create data models
    - Define data structures and validation
    - _Requirements: X.Y_
  
  - [ ]* 4.2 Write property tests for data models
    - **Property M: [Property Title]**
    - **Validates: Requirements X.Y**

- [ ] 5. Integration and wiring
  - [ ] 5.1 Wire components together
    - Connect all components
    - _Requirements: X.Y, X.Z_
  
  - [ ]* 5.2 Write integration tests
    - Test end-to-end flows
    - _Requirements: X.Y, X.Z_

- [ ] 6. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes
- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases

## Task Format Rules
- Maximum two levels of hierarchy (top-level and sub-tasks)
- Sub-tasks use decimal notation (1.1, 1.2, 2.1)
- Each item must be a checkbox format: `- [ ]` or `- [ ]*` for optional
- Test-related sub-tasks should be marked optional with `*` postfix
- Each property test must be its own separate sub-task
- Include checkpoint tasks at reasonable breaks
- Requirements referenced as: `_Requirements: X.Y_`
```

## Process

### Phase 1 - Requirements
1. Generate initial requirements.md using EARS patterns and INCOSE quality rules
   - **DO NOT** ask clarifying questions initially - generate based on user's idea
   - Use proper EARS format: "THE [System] SHALL [action]"
   - Number requirements (Requirement 1, Requirement 2, etc.)
   - Include Glossary for term definitions
   - **MUST include Context section at the end**
2. Present requirements to user for review
3. **GATE**: Ask "Do the requirements look good? If so, we can move on to the design."
4. Iterate based on feedback until explicit approval received
   - **CRITICAL**: Update Context section in requirements.md after EVERY iteration automatically
5. **DO NOT** proceed to design without explicit approval

### Phase 2 - Design
1. Identify areas where research is needed (libraries, APIs, best practices)
2. Conduct research and build context (do not create separate research files)
3. Generate design.md with all sections EXCEPT Correctness Properties
   - **MUST include Context section at the end**
4. **STOP before Correctness Properties section**
5. Analyze each acceptance criterion for testability:
   - Determine if testable as property, example, edge case, or not testable
   - Think step-by-step about testing approach
   - This is internal analysis (not written to file)
6. Write Correctness Properties section based on analysis:
   - Each property must start with "For any" or "For all"
   - Each property must reference requirements: **Validates: Requirements X.Y**
   - Use common property patterns (invariants, round trip, idempotence, etc.)
7. Complete remaining sections (Error Handling, Testing Strategy)
8. Present design to user for review
9. **GATE**: Ask "Does the design look good? If so, we can move on to the implementation plan."
10. Iterate based on feedback until explicit approval received
    - **CRITICAL**: Update Context section in design.md after EVERY iteration automatically
11. **DO NOT** proceed to implementation without explicit approval

### Phase 3 - Implementation
1. Generate implementation.md with task breakdown
   - Use checkbox format: `- [ ]` for tasks
   - Use decimal notation for sub-tasks (1.1, 1.2, 2.1)
   - Mark test tasks as optional with `*`: `- [ ]* 2.2 Write property tests`
   - Each property test is its own sub-task
   - Include checkpoint tasks at reasonable breaks
   - Reference requirements: `_Requirements: X.Y_`
   - **MUST include Context section at the end**
2. Present implementation plan to user for review
3. **GATE**: Ask about optional tasks - "Keep optional tasks (faster MVP) or make all required?"
4. Iterate based on feedback until explicit approval received
   - **CRITICAL**: Update Context section in implementation.md after EVERY iteration automatically
5. **DO NOT** start executing tasks without explicit approval
6. Once approved, execute tasks one at a time:
   - Mark task status: `[ ]` → `[~]` → `[x]`
   - **CRITICAL**: Update Context section in implementation.md after EACH task completion automatically
   - Stop after each task for user review
   - Do not automatically proceed to next task

### Continuous Updates
- **CRITICAL**: Update Timeline and Context sections in ALL three files (requirements.md, design.md, implementation.md) automatically after:
  - User requests, feedback, or decisions
  - Any changes to requirements, design, or implementation
  - Task completions or progress milestones
  - User questions or clarifications
- Mark tasks complete immediately after finishing them: `[ ]` → `[x]`
- Keep all three files synchronized with current state
- **DO NOT** ask permission to update Context sections - always do it automatically
- This enables session recovery if the conversation dies

### Directory Creation
Create date-based directory structure when generating files:
`~/workplace/LimonoctNvim/src/LimonoctNvim/dotfiles/home/.kiro/knowledge/plans/{YY}/{MM}/{component}/{feature}/`

## Task Execution Guidelines

When executing tasks from implementation.md:

### Before Executing
- Always read requirements.md, design.md, and implementation.md first
- Understand the context and correctness properties
- Focus on ONE task at a time

### During Execution
- Write all required code changes before running tests
- Verify implementation against requirements specified in task
- For property tests:
  - Use the testing library specified in design
  - Run minimum 100 iterations
  - Tag with: **Feature: {feature_name}, Property {number}: {property_text}**
  - If test fails, analyze the counter-example to determine if it's a bug in code, test, or specification

### After Completing Task
- Mark task complete: `[ ]` → `[x]`
- **CRITICAL**: Update Context section in implementation.md automatically (DO NOT ask)
- Stop and let user review
- **DO NOT** automatically proceed to next task

### Testing Guidelines
- Write BOTH unit tests AND property-based tests
- Unit tests: specific examples, edge cases, error conditions
- Property tests: universal properties across all inputs
- Both types complement each other
- Make reasonable attempts to get tests passing (3-4 tries)
- If tests still fail, explain issue and ask for guidance

## How to Use This Skill

### Add to Agent Resources
Add this skill to your agent configuration:

```json
{
  "resources": [
    "skill://.kiro/skills/create-plan/SKILL.md"
  ]
}
```

### Usage in Chat
Once added to your agent, describe the feature or component you want to plan:

```bash
# Create a plan for a new feature
kiro "Create plan for user authentication with OAuth2"

# Create a plan for a component
kiro "Plan implementation of payment processing service"
```

The agent will automatically invoke this skill when it detects you want to create an implementation plan.
