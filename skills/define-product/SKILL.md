---
name: define-product
description: Spec stage 2. Write the PRD from the brief and the requirements.
disable-model-invocation: true
---

## Reads

Documents are named by role. Paths: from the request; else find the project's matching files.

- The brief
- The requirements

## Writes

- The PRD only

## Required sections

- Product goals
- Personas and user journeys
- Functional requirements (`FR-001`, ..., each linked to `REQ-xxx`)
- Non-functional requirements (`NFR-001`, ...)
- Feature priorities
- Scope and non-goals
- Edge cases and failure scenarios
- Testable acceptance criteria
- Requirements traceability
- Open decisions

## Method

Build from the requirements and the brief; no interviews.

1. Read the requirements, then check the brief for anything they dropped. Settle every open question in the requirements: by a source; by a small assumption that doesn't change scope, contracts, data, security or ACs; or as an Open decision (`DEC-001`, options, recommendation, provisional assumption). A default is not approval.
   Rerun: read the old PRD; keep FR, NFR, AC and DEC IDs; new ones get the next number; removed ones are marked `retired`, never reused.
2. Goals: one user outcome each, with its success measure from the requirements. Add anti-goals (failure even if it works).
3. One persona per user group in the requirements (who, goal, context, current tool). Journeys: numbered "user does X, sees Y" steps from trigger to goal. Use the requirements' names.
4. FRs: walk each journey step and REQ. What the user can do or see, not how it's built. One behavior each: `FR-001 (REQ-003): ...`. Existing product: FRs for the change only; current behavior it must keep goes in "Must not" ACs. Every REQ leads to an FR, an NFR, a kept constraint, or a non-goal with a reason.
5. NFRs (`NFR-001 (REQ-005): ...`): only what the sources support or the product clearly needs (speed, privacy, accessibility, uptime, retention).
6. Acceptance criteria, at least one per FR: `FR-001-AC1: Given <state>, when <one action>, then <visible or checkable result>.` Add "Must not: ..." for side effects that matter. Every AC and NFR has an objective pass/fail condition and a verification method (test, manual check, review); use a number when the need is an amount.
   - Bad: "Export works correctly." Good: "Given 3 orders, when the user clicks Export, then a CSV with 3 rows and columns id, date, total downloads."
   - Never use correct, proper, fast, easy, intuitive, secure, robust or user-friendly without a number or visible result.
7. Edge cases per FR, only kinds that apply: empty, bad input, limits, no permission, third-party failure, double submit or concurrency, slow response. Say what happens; tag the FR.
8. Priorities: Must (brief requires it or a journey breaks), Should, Could. Keep Must small; every brief must-have is Must.
9. Scope: what's in, what's out and why, including tempting features left out. Assumptions go in a `### Assumptions` subsection here.
10. Traceability table `REQ -> FR/NFR/constraint -> AC IDs`, listing every REQ and AC ID. An FR with no REQ is linked, cut, or proposed under Open decisions.
11. Builder check: read as a designer and engineer who can't ask. Where they'd guess and a wrong guess changes the build, settle small ones as "PRD call: ..." in Assumptions; the rest go to Open decisions with options and your pick.

## Rules

- No application code; no stack, database, API or file choices.
- Don't silently invent major requirements.
- Keep assumptions apart from facts.
- Point out contradictions and missing information.
- Use stable IDs for traceability.
- Unresolved critical questions go under "Open decisions".

## Done when

- All ten sections present.
- Every REQ traced; every FR links a real REQ; every acting journey step has an FR.
- Every AC and NFR has a pass/fail condition and verification method; no banned vague words.
- Every open question in the requirements is answered, assumed, or an Open decision with an ID.
