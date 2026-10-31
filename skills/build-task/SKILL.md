---
name: build-task
description: Build one task test-first, with verification. The task can be an agent-kit task file, an issue or ticket, or a described change.
disable-model-invocation: true
---

## When to use

- One task to build: an agent-kit task file (its workspace gate passes and its Depends on tasks are done), an issue or ticket, or a clear request.
- Not for later bugs (`fix-bug`), review findings (`fix-review`) or structure-only changes (`refactor`).

## Method

1. Read the whole task, then only what it points to: requirements and acceptance criteria, contracts (API spec, schema, types), decision records, designs. Agent-kit task: its PRD criteria, technical-spec contracts, ADRs and UX screens. Work from files, not memory. No acceptance criteria: write pass/fail ones from the request and list them as assumptions; ask first if a wrong guess would change a contract or what users see.
2. Checks (test, lint, typecheck, build): `[verify]` in `agent-kit.toml` if the project has one; fill missing ones from AGENTS.md, CLAUDE.md, README, build scripts or CI and note the source. Find how to run one test file. An empty or unknown command never passes. No test setup: ask before adding one.
3. Kind: an agent-kit task states `Kind` in its Goal; otherwise a question to answer or something to make ready (account, key, scaffold) is spike/setup. Spike/setup: see below and skip steps 5–6.
4. Run the full test suite first; if it fails, stop and report.
5. Test list: each acceptance criterion → behaviors tested at a public interface. Name the mistake each test catches; if none, it's too weak. Criteria whose approved check is manual or config wait for step 8, not forced into tests.
6. Per item, in order (never all tests first):
   - RED: one small test that fails because the feature is missing, not a typo or import. Passes at once? Find why: fix a wrong test; if the behavior exists and the test is right, keep it and report what makes it pass. Never break code or test to force RED.
   - GREEN: least code to pass. Run that file and nearby tests; on failure fix code, not test.
   - CLEAN: tidy only while green.
7. Use the contract's names, fields, types, codes and error shapes exactly; with no written contract, match the existing code. Unspecified small detail: simplest fit, listed under Decisions. Task vs contract conflict, or a choice that changes a contract or decision record: stop BLOCKED with both quotes.
8. Run every check and the full suite; read output and exit codes. Do and record the manual/config checks. Match each criterion to its proof: RED→GREEN test, existing passing test (with why), or approved manual/config check.
9. Self-review the diff: every line traces to the task; nothing outside its scope without reason; no debug prints, commented code or skipped tests; tests check real behavior; no new warnings.
10. Report in your output: DONE, DONE_WITH_CONCERNS or BLOCKED; files changed; each requirement and criterion with its proof; one-line RED and GREEN evidence; each check's result and command source; checks not run and why; decisions; things noticed but untouched.

Spike/setup tasks answer a question or make something ready (account, key, scaffold). Within the time box, deliver the named evidence and a pass/fail answer; no feature code or invented RED. If the answer means the agreed design must change (contract, decision record, scope), stop BLOCKED with evidence; don't switch to the fallback yourself.

## Rules

- No new or changed behavior without a failing test first; delete code written before its test. Exceptions, named in the report: config, generated code, behavior-free wiring, manual-check criteria, spike/setup deliverables.
- Build only the task; note other problems.
- Never skip, weaken or delete a test to get green.
- Never edit the task or the specs it comes from. In an agent-kit workspace, the brief, spec documents and task files are approved and hashed.
- Stop BLOCKED instead of guessing: an architecture choice nothing in the project decides, an unfinished dependency, or reading without getting clearer.
- Report failing tests you didn't cause, by name.

## Done when

- Every acceptance criterion has a proof; every check passed after your last change or is reported not run.
- Full suite passes with clean output; the diff stays in scope or extras are explained.
- The task and its specs are unchanged.
