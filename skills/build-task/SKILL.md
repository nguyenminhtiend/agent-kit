---
name: build-task
description: Implement one approved task from tasks/ with tests, following the spec contracts. Used by the agent-kit build stage.
disable-model-invocation: true
---

## When to use

- One `tasks/NNN-name/` to build; `agent-kit gate` exits 0 and its Depends on tasks are done.
- Not for later bugs (`fix-bug`), review findings (`fix-review`) or structure-only changes (`refactor`).

## Method

1. Read the whole task file, then only what it points to: its FRs/ACs in docs/02, contracts in docs/05, ADRs in docs/04, screens in docs/03. Work from files, not memory.
2. Checks: `[verify]` in `agent-kit.toml` (test, lint, typecheck, build); fill empty ones from AGENTS.md, README, build scripts or CI and note the source. Find how to run one test file. An empty command never passes.
3. Read `Kind` in the Goal. Spike/setup: see below and skip steps 5–6.
4. Run the full test suite first; if it fails, stop and report.
5. Test list: each AC → behaviors tested at a public interface. Name the mistake each test catches; if none, it's too weak. ACs whose approved check is manual or config wait for step 8, not forced into tests.
6. Per item, in order (never all tests first):
   - RED: one small test that fails because the feature is missing, not a typo or import. Passes at once? Find why: fix a wrong test; if the behavior exists and the test is right, keep it and report what makes it pass. Never break code or test to force RED.
   - GREEN: least code to pass. Run that file and nearby tests; on failure fix code, not test.
   - CLEAN: tidy only while green.
7. Use docs/05 names, fields, types, codes and error shapes exactly. Unspecified small detail: simplest fit, listed under Decisions. Task vs contract conflict, or a choice that changes a contract or ADR: stop BLOCKED with both quotes.
8. Run every check and the full suite; read output and exit codes. Do and record the manual/config checks. Match each AC to its proof: RED→GREEN test, existing passing test (with why), or approved manual/config check.
9. Self-review the diff: every line traces to the task; nothing outside Scope without reason; no debug prints, commented code or skipped tests; tests check real behavior; no new warnings.
10. Report in your output: DONE, DONE_WITH_CONCERNS or BLOCKED; files changed; each FR/AC with its proof; one-line RED and GREEN evidence; each check's result and command source; checks not run and why; decisions; things noticed but untouched.

Spike/setup tasks answer a question or make something ready (account, key, scaffold). Within the time box, deliver the named evidence and a pass/fail answer; no feature code or invented RED. If the answer means the approved design must change (contract, ADR, scope), stop BLOCKED with evidence; don't switch to the fallback yourself.

## Rules

- No new or changed behavior without a failing test first; delete code written before its test. Exceptions, named in the report: config, generated code, behavior-free wiring, manual-check ACs, spike/setup deliverables.
- Build only the task; note other problems.
- Never skip, weaken or delete a test to get green.
- Never edit `brief/`, `docs/` or any `tasks/` file, including this one: they are approved and hashed.
- Stop BLOCKED instead of guessing: an architecture choice no ADR covers, an unfinished dependency, or reading without getting clearer.
- Report failing tests you didn't cause, by name.

## Done when

- Every AC has a proof; every check passed after your last change or is reported not run.
- Full suite passes with clean output; the diff stays in Scope or extras are explained.
- No `brief/`, `docs/` or `tasks/` file changed.
