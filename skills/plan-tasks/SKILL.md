---
name: plan-tasks
description: Break the requirements and design, or one agreed plan, into small ordered tasks (the plan and one task file per task).
disable-model-invocation: true
---

## Ground rules

- Every fact cites a source (path:line, quote or command output); anything else is an assumption. Never invent names, values, APIs or results; mark outside facts (versions, limits, prices) `unverified`.
- A guess that would change scope, a contract or data: ask, or record it as an open decision.

## Input and output

- Reads: the requirements and the design, or one plan the user approved; the brief's Decisions section, if any (the owner's answers); existing code.
- Writes the plan (from an approved plan: a new file beside it; never change the approved plan) and one task file per task, at the path the request gives (else one folder per task beside the plan), numbered in build order (`001-setup`, `002-...`).
- Plan sections: Tasks (ID, title, depends on, covers) · Demo path · Coverage (each AC → task, or excluded with why) · Open decisions
- Task file sections: Goal (`Kind: feature|setup|spike`, then one behavior or question) · Covers (REQ and AC IDs, design sections) · Depends on · Scope (likely files; exact names later tasks use) · Acceptance criteria · Test plan

## Method

A fresh agent reads each task cold: give it the decided names, values and tests, not a summary. No "handle errors" or "write tests" without specifics.

1. Slice vertically: each task makes one behavior work end to end and testable. A small shared-contract task may come first; a separate setup task only if big. Existing code: build on it; Scope names real files.
2. Order: spikes for the riskiest unknowns first, then the shortest path to a working demo, then other paths, edge cases and polish. Depend only on lower numbers. The demo path is a chain of task IDs ending in a working main journey.
3. Size: about 1–5 files and up to 4 criteria. Split on "and" in a title; merge what can't be tested alone.
4. Copy each AC with its ID and exact values; add at least one error or edge criterion when a task takes input or calls out. Test plan: per criterion, the test level or manual check.
5. Spike: one question, time box, pass signal, fallback, evidence to deliver; no feature code.
6. Don't guess past the source: write what's known, add `Open: <question>` in the task and a `DEC` (next number unused in the brief and every document) in the plan. A `DEC` answered in the brief's Decisions is closed: apply it with source `DEC-001`.

## Rules

- No application code; no work the source doesn't ask for.
