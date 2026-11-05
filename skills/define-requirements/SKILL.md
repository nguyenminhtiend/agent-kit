---
name: define-requirements
description: Turn a brief into the requirements document (numbered requirements with testable acceptance criteria, assumptions, open decisions), without asking anyone.
disable-model-invocation: true
---

## Ground rules

- Every fact cites a source (path:line, quote or command output); anything else is an assumption. Never invent names, values, APIs or results; mark outside facts (versions, limits, prices) `unverified`.
- A guess that would change scope, a contract or data: ask, or record it as an open decision.

## Input and output

- Reads: the brief (its Decisions section holds the owner's answers); for an existing product, its code and docs.
- Writes only the requirements document. Sections: Problem · Users · Requirements · Scope and non-goals · Assumptions · Open decisions

## Method

No one can be asked: every question goes in the document with your best default.

1. Business facts (users, prices, limits, legal duties) come only from the brief; code facts from the code, with path. Existing product: only the change.
2. One requirement per need: `REQ-001 (<brief section or quote>): ...`; an implied need gets a matching assumption. Add quality needs (speed, privacy, accessibility) only when the brief or the product clearly needs them.
3. Each requirement gets pass/fail criteria with real values: `REQ-001-AC1: Given <state>, when <action>, then <checkable result>`. Behavior that must stay: `Must not: ...`. Vague words (fast, easy, secure) become a number or visible result; no number in the brief: propose one as an assumption.
4. Every brief must-have, deadline and outside rule becomes a requirement, a non-goal with a reason, or an open decision.
5. Gaps: a small default goes to Assumptions. Only the owner can answer and a wrong default changes the build: `DEC-001: <question>` (next number unused in the brief and every document), why it matters, 2–3 options, your recommendation. Quote both sides of every contradiction in the brief there. A `DEC` answered in the brief's Decisions is closed: apply it with source `DEC-001` and drop it from Open decisions.
6. Rerun: keep IDs; new ones take the next number; removed ones are marked `retired`, never reused.

## Rules

- No stack, data model, screens or code.
