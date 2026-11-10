---
name: code-mode
description: >
  Apply the reduced engineering principles when changing code: First Make it
  Work, Then Make it Right, and Follow Practice. Use when the user invokes
  code-mode or asks for these principles.
---

# code-mode

For the requested code change:

* First Make it Work.
* Then Make it Right.
* Follow Practice.

Follow repository instructions and the user's scope and authorization.
Preserve unrelated work. Select the checkout with [worktree](../worktree/SKILL.md)
before editing, reusing choices already made for this task.

# First Make it Work

## Laziness Protocol

* Keep each decision in a single place.
* Choose the smallest edit that delivers the requested behavior.

## Foundational Thinking

* Shape the data before implementing the logic.
* Resolve prerequisites that make later work simpler.
* Give concurrent writers independent state wherever possible.

## TDD

* Add a test for the next missing behavior before implementing it.
* Confirm that the failure demonstrates that missing behavior.
* Implement only what is needed to pass.
* When a meaningful test is impractical, explain the validation limit instead
  of adding a test that proves nothing.

## Redesign From First Principles

* Consider the design with the new requirement included from the beginning.
* Implement the necessary design change incrementally, within the task's scope.

## Attack the Premise

* After two fixes based on the same assumption fail the same check, state that
  assumption and inspect how state and responsibility are assigned.
* Correct the assignment or assumption causing the imbalance before another attempt.

## Subtract Before You Add

* Simplify the affected code before adding more machinery.

## Outcome-Oriented Execution

* Define an observable finish condition.
* Temporary local breakage must be planned, reversible, and resolved before completion.

## Build the Lever

* For repetitive or difficult work, build a small tool when it simplifies the task.
* Validate one case manually, then check the tool against that result.

## Architecture

### Model the Domain

* Encode valid states in the domain structure.
* Keep the project's glossary aligned with its terminology.
* Leave clear, local code alone.

### Boundary Discipline

* Validate external inputs at their boundary.
* Work with validated values internally.
* Express business rules as pure functions.

### Type System Discipline

* Represent constraints in types so invalid values cannot be constructed.
* Convert external data into domain values once, at entry.
* Fix type errors rather than suppressing them.

### Make Operations Idempotent

* Repeated execution, including recovery after interruption, should reach the
  intended state without duplicate effects.

### Separate Before Serializing Shared State

* Separate actors' mutable data unless sharing is necessary.
* For genuinely shared mutable state, assign one writer and enforce that ownership.

# Then Make it Right

## Fix Root Causes

* Reproduce the failure and trace its cause.
* Correct the responsible behavior.
* Distinguish hiding a symptom from fixing its cause.

## Sequence Work into Verifiable Units

* Complete and check one small increment before starting the next.

## Test Behavior, Not Implementation

* Exercise the interface as its caller does and assert the observable result.
* A test that accepts missing or empty behavior needs stronger assertions.

For the tools below, follow the [shared policy](../quality-gates/references/quality-gates.md)
and [change-scope rules](../quality-gates/references/change-scope.md) for limits,
exceptions, affected code, and mutation recovery. Use the tools directly;
broader workflows require a separate user request.

## CRAP

* Use `crapper` for supported languages, including Python, Go, and Java.
* Improve tests or simplify responsibilities to meet the shared per-function limit.
* Assess single-question conditionals under the documented exception.

## DRY

* Use `dryer` for supported languages, including Python, Go, and Java.
* Review matches and consolidate duplicated knowledge or responsibilities.

## Mutation

* Use `mutator` for supported languages, including Python, Go, and Java.
* Test uncovered behavior and strengthen assertions against surviving mutants.
* Resolve execution errors; an unrun check is not a pass.
* Remove code made obsolete by this task.

## Refactoring

* Establish the current observable behavior.
* Restructure the code.
* Verify that the same behavior still holds.

# Practice

## Keep a Log

* Record actions and reasons in the feature directory resolved by
  [the artifact rule](../../rules/ai-artifacts.md).
* Summarize the work and validation results on completion.

## Guard the Context Window

* Retain essential decisions and evidence in the main thread.
* Delegate bulky independent work when useful and authorized; bring back a summary.

## Worktree Cleanup

* Follow [worktree](../worktree/SKILL.md) for authorized cleanup after verifying
  that the work is retained and no active task needs the checkout.
* Preserve uncommitted work pending the user's decision.

## Commit

* When authorized, delegate cohesive commits through [commit](../commit/SKILL.md)
  after the build and applicable checks pass.
* Each commit should explain its purpose, change, and validation.
* Never run `git push`.
