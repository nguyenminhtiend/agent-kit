---
name: refactor
description: Change code structure without changing behavior, in small safe steps.
disable-model-invocation: true
---

## When to use

- Code works but its shape blocks the next change: duplication, deep nesting, long functions, unclear names, mixed jobs, dead code. Also before a task ("make the change easy") or after a structure finding.
- Not when behavior must change, you don't understand the code, it's about to be deleted, or tests can't be added.

## Method

1. One line: the structural problem, the files, what gets easier. Prefer recently changed code or code the next task touches.
2. Understand first: what it does, every caller (grep, incl. string or dynamic use), edge cases and error paths, why it's this way (`git log`, `git blame`).
3. Safety net: test and typecheck commands from `[verify]` in `agent-kit.toml` if the project has one; fill missing ones from AGENTS.md, CLAUDE.md, README, build scripts or CI, noting the source; say which don't apply and why. Tests must pass before starting and cover the code you'll move; otherwise add characterization tests with literal expected values. No runnable tests or no coverage: stop BLOCKED before any change.
4. Small named moves: extract repeated logic; guard clauses for nesting; split multi-job functions; rename misleading names; bundle values passed together; replace repeated switch/if chains with a map; inline pass-through wrappers; delete unused hooks/options; move functions to the data they use. Deletion test: if deleting an abstraction makes complexity vanish, it was a pass-through; if complexity returns in many callers, keep it.
5. After each move run tests (and typecheck if it applies). Red: undo and take a smaller step; never debug forward. Use tools (IDE rename, codemod, `sed`) for big mechanical edits.
6. Shared interfaces: add the new form beside the old, migrate callers one at a time while green, remove the old when grep finds no users.
7. Compare: easier to read, or just moved? If not better, revert. Remove what the refactor made unused.
8. Report the goal, moves, commands with results, and things noticed but untouched.

## Rules

- Behavior stays identical: outputs, errors, side effects, order. Unsure a move keeps it: don't make it.
- Existing tests keep their expected values (imports may change). Needing to change one means behavior changed: undo.
- Never mix refactoring with new behavior or bug fixes; note bugs for `fix-bug`.
- Follow existing patterns; keep error handling.

## Done when

- Tests passed before the first move and after the last; no expected values changed.
- All checks passed or are reported not applicable or not run.
- The named problem is gone; no dead code, behavior change or out-of-scope edits.
