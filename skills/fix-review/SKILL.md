---
name: fix-review
description: Fix findings from an independent code review, one by one, and verify each fix.
disable-model-invocation: true
---

## When to use

- A reviewer (`code-reviewer` or a person) returned findings on a change you made, or you choose to fix its minors.
- Fix only those findings in that change; new features need a task, unrelated bugs `fix-bug`.

## Method

1. Read every finding, the task and any cited contract before changing anything; findings are often linked.
2. Check each against the code and its callers; give one verdict:
   - Valid: fix it.
   - Not valid: decline with evidence (file:line, passing test, spec quote): it would break working behavior, a contract or a decision record; it's handled one level up; or nothing uses the "missing" support (grep first).
   - Needs a person: the fix changes a contract, decision record, task scope or product. Leave the code; write the question.
   No polite agreement or "great catch": say what changes or why not.
3. Checks: `[verify]` in `agent-kit.toml` if the project has one; fill missing ones from AGENTS.md, CLAUDE.md, README, build scripts or CI and note the source. An empty or unknown command never passes. Order: critical, major, minor; quick fixes first within each.
4. One finding at a time:
   - Wrong behavior: write a test that fails on the problem, see it fail, then fix.
   - Missing test only: it passes on correct code, so don't force RED. Write it, see it pass, and where useful prove it catches a break with a temporary controlled mutation (then undo). Manual-check behavior: do and record that check.
   - Fix the cause, not just the quoted line, including repeats elsewhere in the diff. Run the affected tests.
5. Run all checks; read your fix diff for new problems.
6. Report, one line per finding in original order: `<severity> <issue> — FIXED: <change, file:line, test> | DECLINED: <reason + evidence> | NEEDS_DECISION: <question>`, plus checks run (source, result) and not run. FIXED means gone and freshly verified.
7. Overall status at the top: `BLOCKED` while any critical/major finding is NEEDS_DECISION or DECLINED (a decline counts only once the re-review accepts it), else `READY_FOR_REVIEW`. This is not a review result; only an independent re-review can PASS.

## Rules

- Never make a finding vanish by weakening or deleting a test, removing a requirement, or swallowing an error.
- Change only what findings need; note other problems.
- Never edit the task or its specs (in agent-kit: the workspace's brief, spec documents and task files). A finding that says the spec is wrong is NEEDS_DECISION.
- Decline with evidence, not opinion; if you can't check, say what you'd need.
- Never mark the review passed yourself.

## Done when

- Every finding has exactly one verdict; behavior fixes have a test that failed before and passes now.
- All checks passed after your last change or are reported not run.
- The report starts with the overall status.
