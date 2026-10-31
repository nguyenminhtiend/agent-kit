---
name: plan-tasks
description: Planning stage. Break the reviewed specs into small ordered tasks (docs/07-implementation-plan.md and tasks/).
disable-model-invocation: true
---

## Reads

- `docs/01-requirements.md` to `docs/06-validation.md`

## Writes

- `docs/07-implementation-plan.md`
- `tasks/NNN-short-name/task.md`, one folder per task (`001-setup`, `002-auth`, ...)

## Plan sections (docs/07)

- Task list (ID, title, depends on)
- Dependency graph
- Build order and milestones
- Demo path (shortest route to a working demo)
- Requirement coverage (every in-scope FR, AC and NFR maps to a task)

## Task file sections (tasks/NNN-name/task.md)

- Goal
- Requirements covered
- Depends on
- Scope (areas and files likely to change)
- Acceptance criteria (testable)
- Test plan
- Definition of done

## Method

A fresh agent reads each task cold: state the decided names, values and proving tests.

1. Collect from docs/02–06: FRs, AC IDs, NFRs, screens, active ADRs, contracts, spikes, cuts, verdict. Plan only approved scope:
   - Required cuts: not planned. If docs/02–05 still include one, the owner hasn't decided; list it under "Gaps".
   - Contingency cuts: planned last, marked "cut first".
   - Out-of-scope, deferred or retired IDs: no task; list as excluded with the deciding section.
2. Foundations first: schema, then API, then UI.
3. Slice vertically: each task is a thin path through the layers it needs and makes one behavior work end to end, visible or testable. Exceptions: a small contract task first when several tasks share an API or data shape; setup folded into the first slice unless big. A separate setup or spike task must be bounded and name what it enables; a spike delivers its docs/06 evidence and pass/fail answer, not feature code.
4. Size to one agent session: guide ~1–5 files and ≤3–4 ACs (a thin full-stack slice may touch more). Split on "and" in the title or independent areas; merge what can't be tested alone.
5. Number in build order (`001`, ...); depend only on lower numbers. Spikes first, then the demo path, other happy paths, edge cases and polish; cut-first last. Milestone every 2–3 tasks: tests pass and the journey so far works.
6. Task file:
   - Goal: first `Kind: feature|setup|spike`, then one user-facing behavior (spike: its question).
   - Requirements covered: FR/NFR and PRD AC IDs delivered, plus exact doc sections (screen, endpoint, ADR). Setup/spike: the requirements and task IDs it enables.
   - Scope: areas, likely files, exact names of anything later tasks use (endpoint, type, table, event), matching docs/05.
   - Acceptance criteria: pass/fail, with the spec's exact values. Carry each delivered PRD AC with its ID. Input or service calls need at least one error/edge criterion.
   - Test plan: per criterion, the test level and what it proves, or the manual check/review the PRD names.
   - Definition of done: ACs met; tests for new behavior fail before and pass after; manual checks recorded; old tests, lint and types pass. Spike: evidence and answer recorded.
7. Don't guess past the specs: write what's known, add `Open: <question>` in the task, list it under "Gaps".
8. Self-review and fix: a coverage row per in-scope FR, AC (incl. "Must not" and manual ones) and NFR, with task and verification method; no words that decide nothing ("TBD", "handle errors", "write tests"); identical names across tasks and docs/05; the 3–5 failures the spec implies are tested somewhere.

## Rules

- No application code.
- No dependency cycles; depend only on lower-numbered tasks.
- Each task covers in-scope FR/NFR IDs or is a bounded setup/spike task linked to what it enables. Add no work the specs don't ask for.

## Done when

- docs/07 has all five sections; task folders and task list match.
- Every in-scope FR, AC and NFR has a task and verification method; excluded IDs name their deciding section.
- No required cut planned.
- Every task file has all seven sections, no "TBD"; every Depends on points lower.
- The demo path is a chain of task IDs ending in a working main journey.
