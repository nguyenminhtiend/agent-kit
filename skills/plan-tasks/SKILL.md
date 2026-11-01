---
name: plan-tasks
description: Break the requirements and design, or one agreed plan, into small ordered tasks (the plan and one task file per task).
disable-model-invocation: true
---

## Ground rules

- A fact needs a source: path:line, a quote or command output. Mark anything else as an assumption or your call.
- Never invent names, values, APIs or results. Mark outside facts (versions, limits, prices) `unverified`.
- A check you didn't run is "not run". A guess that would change scope, a contract or data: ask, or record it as an open decision.

## Reads

Documents are named by role. Paths: from the request; else find the project's matching files.

- The requirements and the design, or one plan marked `Status: Agreed`
- The brief's Decisions section, if any: the owner's answers
- Existing project: its code (read only)

## Writes

- The plan (from an agreed plan: a new file beside it; never change the agreed plan)
- One task file per task, at the path the request gives (else one folder per task beside the plan), numbered in build order (`001-setup`, `002-...`)

## Plan sections

Tasks (ID, title, depends on, covers) · Demo path · Coverage (each AC → task) · Open decisions

## Task file sections

Goal (`Kind: feature|setup|spike`, then one behavior or question) · Covers (REQ and AC IDs, design sections) · Depends on · Scope (likely files; exact names later tasks use) · Acceptance criteria · Test plan

## Method

A fresh agent reads each task cold: give it the decided names, values and tests, not a summary.

1. Slice vertically: each task makes one behavior work end to end and testable. A small shared-contract task may come first; a separate setup task only if big.
2. Order: spikes for the riskiest unknowns first, then the shortest path to a working demo, then other paths, edge cases and polish. Depend only on lower numbers.
3. Size: about 1–5 files and up to 4 criteria. Split on "and" in a title; merge what can't be tested alone.
4. Copy each AC with its ID and exact values; add at least one error or edge criterion when a task takes input or calls out. Test plan: per criterion, the test level or manual check.
5. Spike: one question, time box, pass signal, fallback, evidence to deliver; no feature code.
6. Don't guess past the source: write what's known, add `Open: <question>` in the task and a `DEC` (next number unused in the brief and every document) in the plan. A `DEC` answered in the brief's Decisions is closed: apply it with source `DEC-001`.
7. Existing code: build on it; no setup for what exists; Scope names real files.

## Rules

- No application code; no work the source doesn't ask for.

## Done when

- Every in-scope AC is covered by a task with a test or manual check; excluded IDs say why.
- Task folders match the task list; every Depends on points lower.
- The demo path is a chain of task IDs ending in a working main journey.
- No "TBD", "handle errors" or "write tests" without specifics.
