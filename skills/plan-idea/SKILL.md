---
name: plan-idea
description: Turn a new feature, requirement or idea into an agreed plan by interviewing the user; nothing gets built before an explicit yes. Also gets the owner's answers to open decisions in spec documents.
disable-model-invocation: true
---

## Ground rules

- A fact needs a source: path:line, a quote or command output. Mark anything else as an assumption or your call.
- Never invent names, values, APIs or results. Mark outside facts (versions, limits, prices) `unverified`.
- A check you didn't run is "not run". A guess that would change scope, a contract or data: ask, or record it as an open decision.

## When

- A feature or idea whose goal, scope or approach is still open. Not for bugs (`fix-bug`), speed (`optimize`) or a clear small change (just do it).
- Needs a person. No one to answer: list your questions, each with a recommended answer, and stop.

## Method

Facts are your job; decisions are the user's.

1. Look first: the request, AGENTS.md, README, decision records, and the code the feature touches, until you can say how it works today (path:line). Never ask what code, docs or git history answer.
2. Open with: the idea in your words, what you found, anything that changes the ask (it partly exists, a conflict, a cheaper path), then the one question that most changes what gets built.
3. One question per message (or up to 3 quick, independent ones), each with your recommended answer so "yes" accepts it. Cover only what's unclear: problem, user, success check, scope, behavior that must not change, contracts, data, edge cases, constraints, how to test. Decide small reversible details and say so. Stop when you can predict their next answers.
4. Give 2–3 approaches with trade-offs; recommend one, preferring existing patterns. They pick.
5. Write the plan, sized to the work. Show it with your calls and open items; revise until an explicit yes ("sounds good" with open items: ask what to change). Set `Status: Agreed <date>` and stop.

Open decisions (`DEC-...`) in a spec document or review: ask them the same way, then write each answer into the brief under `## Decisions` as `DEC-001: <answer> (<date>)`. Change nothing else.

## Plan

Where the user says; else where the project keeps plans; else ask. When the user wants full specs, write it as the brief.

- Status, problem, goal, success check
- Current state: related code with path:line, or "no code yet"
- Decisions: question → answer, marked user or your call
- Scope: in, out, must not change
- Approach and why; alternatives and why not
- Changes: files; contracts with exact names, fields, types and errors
- Acceptance criteria: `AC1: Given / when / then` with real values, incl. error and "must not" cases
- Steps: `step -> verify: check`
- Checks: commands and their source
- Risks and open items

## Rules

- Build nothing before the yes: no code, installs or migrations. Reading and an agreed throwaway spike are fine.
- Smallest version that meets the goal. Push back when the idea fights the code or is bigger than needed.
- The user may stop any time: mark open items as your calls and say so.

## Done when

- Explicit yes; `Status: Agreed <date>`.
- Every choice that changes scope, a contract, data or acceptance criteria came from the user, or is marked as your call after they stopped.
- A builder could work from the plan alone.
