---
name: build-task
description: Build one task test-first, with proof for each acceptance criterion. The task can be a task file, an agreed plan, an issue or ticket, or a clear request.
disable-model-invocation: true
---

## Ground rules

- Every fact cites a source (path:line, quote or command output); anything else is an assumption. Never invent names, values, APIs or results; mark outside facts (versions, limits, prices) `unverified`.
- A guess that would change scope, a contract or data: ask, or record it as an open decision.

## Method

1. Read the task and only what it links (criteria, contracts, decisions, designs). A task file's Depends on tasks must be done; a plan must be approved by the user. No criteria: write pass/fail ones as assumptions; ask first if a wrong guess changes a contract or what users see.
2. Find the project's test, lint, typecheck and build commands, and how to run one test file. No test setup: ask before adding one.
3. Run the tests for the area you'll touch. Record failures that exist before you start; stop only if they touch the task.
4. Per criterion, one at a time:
   - RED: one small test at a public interface that fails because the behavior is missing. Passes at once: find out why.
   - GREEN: least code to pass; fix the code, not the test.
   - CLEAN: tidy only while green.
   Code written before its test: break it, see the test go red, restore it.
5. Use the contract's names, fields, types and errors exactly; no contract: match the existing code. Task vs contract conflict, or a choice that changes a contract or decision record: stop BLOCKED with both quotes.
6. Spike or setup task: deliver the named evidence and a pass/fail answer within the time box; no feature code. An answer that changes the design: stop BLOCKED with the evidence.
7. Run every check and the full suite. Read your diff: every line traces to the task; no debug prints or new warnings.
8. Independent review: start a fresh read-only reviewer (a subagent such as code-reviewer). Give it the full diff against the base, new files included, plus the task and the contracts. Per finding:
   - Valid: fix it; wrong behavior gets a failing test first.
   - Wrong: decline with evidence (file:line, a passing test, a spec quote).
   - Changes a contract, decision or scope: leave the code; report the question.
   Rerun the checks and the review until no critical or major finding is left, at most 3 rounds. Can't start a reviewer: report "review not run".
9. Report: DONE, DONE_WITH_CONCERNS or BLOCKED; files changed; each criterion with its proof (test name or manual check); checks run with result; checks not run and why; each review finding as FIXED, DECLINED or NEEDS_DECISION; decisions you made; problems noticed but untouched.

## Rules

- Never skip, weaken or delete a test to get green or to clear a finding.
- Build only the task; never edit the task or its specs.
