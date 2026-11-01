---
name: optimize
description: Make code faster or cheaper, guided by before-and-after measurements.
disable-model-invocation: true
---

## Ground rules

- A fact needs a source: path:line, a quote or command output. Mark anything else as an assumption or your call.
- Never invent names, values, APIs or results. Mark outside facts (versions, limits, prices) `unverified`.
- A check you didn't run is "not run". A guess that would change scope, a contract or data: ask, or record it as an open decision.

## When

- A measured problem: an unmet performance target, a benchmark showing a slowdown, or reported slowness or cost.
- Not without evidence, and not for wrong output (`fix-bug` first).

## Method

1. Before touching code, write down: the operation; the metric, target and unit; the workload; guardrails (other metrics and how much they may get worse); the test command that proves correctness.
2. Baseline: one repeatable command that measures the metric itself (p95 means p95). Same data and conditions every time. Run it several times; record the spread (noise).
3. Find the hot spot with a profiler, query log or trace, not a guess.
4. Change one thing. Re-measure the same way. Keep it only if it beats the noise, guardrails hold and tests pass; else revert.
5. Log each attempt: `idea | before → after | kept/reverted | why`. Repeat until the target is met, the budget is spent, or gains are within noise.
6. Report one outcome: target met; gain kept but target unmet (why); or no demonstrated improvement (a valid result). Give baseline and final numbers, exact commands and the log.

## Rules

- Correctness first: skipping needed work (validation, an `await`, fresh data) is a bug, not a win.
- A cache key includes every input that changes the result (user, tenant, locale, permissions).
- Say "best measured", not "optimal".

## Done when

- Baseline and final come from the same command; every kept change has its own numbers, above noise.
