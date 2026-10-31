---
name: optimize
description: Make code faster or cheaper, guided by before-and-after measurements.
disable-model-invocation: true
---

## When to use

- A measured problem: an unmet performance requirement, a benchmark or test showing a slowdown, or reported slowness or cost (time, memory, CPU, queries, money).
- Not without evidence, and not for wrong output (`fix-bug` first).

## Method

1. Before touching code, write down: the operation; the objective metric and target (from the requirement or report) with unit and better direction; the workload (input size, load, number of runs); guardrails (other metrics with allowed regression, e.g. "p95 may rise ≤10%"); the correctness gate (test command from AGENTS.md, CLAUDE.md, README, build scripts or CI; an empty command is no gate); the attempt or time budget.
2. Baseline: one repeatable command (benchmark, harness, load test, `EXPLAIN ANALYZE`) measuring the objective itself (p95 means p95, not median; memory or cost means that). Fix workload and conditions (data; warm or cold cache, stated). Run several times; record the metric, guardrails and run-to-run spread (noise).
3. Find the hot spot with a profiler, query log or trace, not a guess. Usual suspects: N+1 queries, unbounded fetches, missing or unused indexes, repeated work in loops, blocking I/O on hot paths, recomputed expensive results.
4. Change one thing: the simplest fix for that hot spot.
5. Re-measure identically and compare the objective. Keep only if better beyond noise, guardrails hold and tests pass (cheaper at equal speed counts when cost is the objective). Otherwise revert: neutral, worse, guardrail broken, or a failing test (a bug, not a win).
6. Log every attempt: `idea | baseline → result | kept/reverted | why`.
7. Repeat from 3 until the target is met, the budget is spent, or gains are within noise.
8. Keep the benchmark or a budget test where the project allows. Report one outcome: improved (target met); target unmet (gain kept, why short); no demonstrated improvement (all reverted; a valid result). Always give baseline and final numbers, exact commands and the attempt log.

## Rules

- No optimization without a baseline and a named hot spot.
- Correctness first: skipping needed work (validation, an `await`, fresh data) is a bug.
- One change per measurement; keep only measured wins.
- Cache keys include every input that changes the result (user, tenant, locale, permissions); state allowed staleness; never cache what must be fresh.
- Say "best measured", not "optimal".

## Done when

- Metric, workload and guardrails set before the baseline; baseline and final use the same command.
- Outcome stated; any claimed gain exceeds noise; every kept change has its own numbers.
- The correctness gate and checks passed or are reported not run.
