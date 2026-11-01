---
name: define-requirements
description: Turn a brief into the requirements document (numbered requirements with testable acceptance criteria, assumptions, open decisions), without asking anyone.
disable-model-invocation: true
---

## Ground rules

- A fact needs a source: path:line, a quote or command output. Mark anything else as an assumption or your call.
- Never invent names, values, APIs or results. Mark outside facts (versions, limits, prices) `unverified`.
- A check you didn't run is "not run". A guess that would change scope, a contract or data: ask, or record it as an open decision.

## Reads

Documents are named by role. Paths: from the request; else find the project's matching files.

- The brief. Its Decisions section holds the owner's answers.
- Existing project: its code and docs (read only)

## Writes

- The requirements document only

## Sections

Problem · Users · Requirements · Scope and non-goals · Assumptions · Open decisions

## Method

No one can be asked: every question goes in the document with your best default.

1. Business facts (users, prices, limits, legal duties) come only from the brief. Code facts (current behavior, stack) come from the code, with path. Anything you add is an assumption with a reason.
2. One requirement per need: `REQ-001 (<brief section or quote>): ...`; "implied" needs a matching assumption. Add quality needs (speed, privacy, accessibility) only when the brief or the product clearly needs them. Existing product: only the change.
3. Each requirement gets pass/fail criteria: `REQ-001-AC1: Given <state>, when <action>, then <checkable result>`, with real values. Behavior that must stay: `Must not: ...`. Vague words (fast, easy, secure, correct) become a number or visible result; no number in the brief: propose one as an assumption.
4. Gaps: a small default that changes nothing big goes to Assumptions. Only the owner can answer and a wrong default changes the build: `DEC-001: <question>`, why it matters, 2–3 options, your recommendation. Quote both sides of every contradiction in the brief there. A `DEC` answered in the brief's Decisions is closed: apply it with source `DEC-001` and drop it from Open decisions.
5. Rerun: keep IDs; new ones take the next number; removed ones are marked `retired`, never reused.

## Rules

- No stack, data model, screens or code.
- Don't invent major requirements.

## Done when

- Every brief must-have, deadline and outside rule is a requirement, a non-goal with a reason, or an open decision.
- Every requirement has a source and a pass/fail criterion; no vague word without a number or visible result.
- On a rerun, surviving IDs are unchanged.
