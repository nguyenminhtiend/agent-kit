---
name: fix-review
description: Fix findings from an independent code review one by one, decline wrong ones with evidence, and verify each fix.
disable-model-invocation: true
---

## Ground rules

- A fact needs a source: path:line, a quote or command output. Mark anything else as an assumption or your call.
- Never invent names, values, APIs or results. Mark outside facts (versions, limits, prices) `unverified`.
- A check you didn't run is "not run". A guess that would change scope, a contract or data: ask, or record it as an open decision.

## When

- A reviewer returned findings on a change you made. Fix only those; new features need a task, unrelated bugs `fix-bug`.

## Method

1. Read every finding, the task and any cited contract before changing anything; findings are often linked.
2. Check each against the code and its callers; give one verdict:
   - Valid: fix it.
   - Not valid: decline with evidence (file:line, a passing test, a spec quote). Grep before agreeing something is "missing".
   - Needs a person: the fix changes a contract, decision, task scope or product. Leave the code; write the question.
   No polite agreement: say what changes, or why not.
3. One finding at a time, critical first. Wrong behavior: write a test that fails on it, then fix. Missing test only: write it and see it pass. Fix the cause, including repeats elsewhere in the diff.
4. Run all checks; read your own fix diff.
5. Report at the top `BLOCKED` (a critical or major finding declined or needing a person) or `READY_FOR_REVIEW`; then one line per finding: `<severity> <issue> — FIXED: <change, file:line, test> | DECLINED: <evidence> | NEEDS_DECISION: <question>`; then checks run and not run.

## Rules

- Never make a finding vanish by weakening a test, removing a requirement or swallowing an error.
- Never edit the task or its specs; never mark the review passed yourself.

## Done when

- Every finding has one verdict; behavior fixes have a test that failed before and passes now.
