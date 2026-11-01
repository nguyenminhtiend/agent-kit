---
name: build-task
description: Build one task test-first, with proof for each acceptance criterion. The task can be a task file, an agreed plan, an issue or ticket, or a clear request.
disable-model-invocation: true
---

## Ground rules

- A fact needs a source: path:line, a quote or command output. Mark anything else as an assumption or your call.
- Never invent names, values, APIs or results. Mark outside facts (versions, limits, prices) `unverified`.
- A check you didn't run is "not run". A guess that would change scope, a contract or data: ask, or record it as an open decision.

## When

- One task: a task file (its Depends on tasks done), a plan marked `Status: Agreed`, an issue, or a clear request.
- Not for bugs (`fix-bug`), review findings (`fix-review`) or speed (`optimize`).

## Method

1. Read the task, then only what it links: criteria, contracts, decisions, designs. Work from files, not memory. No criteria: write pass/fail ones and list them as assumptions; ask first if a wrong guess changes a contract or what users see.
2. Find the test, lint, typecheck and build commands (AGENTS.md, CLAUDE.md, README, build scripts, CI) and how to run one test file. No test setup: ask before adding one.
3. Run the tests for the area you'll touch. Record failures that exist before you start; stop only if they touch the task.
4. Per criterion, one at a time:
   - RED: one small test at a public interface that fails because the behavior is missing, not a typo or import. Passes at once: find out why; never break code to force red.
   - GREEN: least code to pass. On failure fix the code, not the test.
   - CLEAN: tidy only while green.
   Code written before its test: break it on purpose, see the test go red, restore it.
5. Use the contract's names, fields, types and errors exactly; no contract: match the existing code. Task vs contract conflict, or a choice that changes a contract or decision record: stop BLOCKED with both quotes.
6. Spike or setup task: deliver the named evidence and a pass/fail answer within the time box; no feature code. An answer that changes the design: stop BLOCKED with the evidence.
7. Run every check and the full suite; read output and exit codes. Read your diff: every line traces to the task; no debug prints, skipped tests or new warnings.
8. Report: DONE, DONE_WITH_CONCERNS or BLOCKED; files changed; each criterion with its proof (test name or manual check); checks run with command source and result; checks not run and why; decisions you made; problems noticed but untouched.

## Rules

- Never skip, weaken or delete a test to get green.
- Build only the task; never edit the task or its specs.

## Done when

- Every criterion has a proof; every check passed after your last change or is reported not run.
