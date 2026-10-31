---
name: assess-readiness
description: Last stage before the human gate. Judge whether specs and tasks are ready (docs/08-readiness.md plus a structured verdict).
disable-model-invocation: true
---

## Reads

- `brief/requirements.md`, `docs/01` to `docs/07`, all of `tasks/`
- `.workflow/state/review.json` and the summary in its `last_review` folder

## Writes

- `docs/08-readiness.md` only
- A structured verdict as output, shaped by `schemas/readiness.schema.json`: `status`, `critical`, `major`, `unresolved_decisions`, `summary`, `decisions`.

## Required sections (docs/08)

- Verdict
- Scope summary
- Checklist results
- Blockers (critical and major)
- Open decisions for a person (ID, question, options, recommendation)

## Method

Question: can a fresh agent build every task from its file and linked docs without asking? Reviewers checked docs/01–06; you check docs/07 and tasks/. An old docs/08 is past output: never use it as evidence or a source of blockers or decisions. The runner checks hashes.

1. Collect: glob `tasks/*/task.md`; read `review.json` (status must be PASS) and `<last_review>/summary.json`. Never pick a review by round number. Grep docs/01–07 and tasks/ for REQ, FR, NFR, ADR and AC IDs.
2. Checklist, one line each: PASS/FAIL, severity, evidence (path + section, ID or quote). Recount yourself; trust no earlier table or PASS.
   - Placeholders (`TODO`, `TBD`, `FIXME`, `???`, empty sections): major; critical in a contract or AC a task needs.
   - Trace: every REQ leads to an FR, NFR, constraint or out-of-scope; every FR links a real REQ; every in-scope FR has a task (critical); every in-scope AC and NFR, incl. negative and manual, has a task and verification method (major); excluded IDs have a deciding section; every ID a task names exists (major).
   - Consistency: names and values match docs/05; no task contradicts an active ADR (major).
   - Feasibility: "not feasible" is critical. Required cuts are reflected in docs/02–05 and unplanned, or are open decisions; contingency cuts may stay. Each riskiest build-time unknown has an early spike task (major).
   - Tasks: seven sections, `Kind`, pass/fail ACs with exact values; feature tasks name an FR/NFR; setup/spike tasks name what they enable; Depends on points lower (major). A clearly oversized task (well over ~5 files) is a minor warning unless it mixes independent behaviors.
   - Cold start: read the 3 riskiest tasks with only their linked docs; any guessed name, value or behavior is major.
   - Plan: five sections, a real demo chain, task list matches folders.
   - Review: PASS with an empty `blocking` list, else critical (also if missing). List remaining minors, uncounted.
3. Open decisions: gather from every Open decisions section in docs/01–07, docs/01 open questions, Proposed ADRs, risks marked "check before approval", task `Open:` lines and docs/07 Gaps. Open = unanswered and changes scope, a contract, data, security or ACs; a design relying on an unverified capability, quota or price stays open until verified or decided. Deduplicate by owning doc and ID. Give each an ID (reuse, else `DEC-001`), question, 2–3 options and a recommendation with reason. Items settled by an assumption that changes none of these are PASS lines.
4. Severity: critical = can't start or product wrong; major = rework or failed requirement likely; minor = doesn't block.
5. docs/08: verdict first (`READY`/`NOT_READY` with the three counts), 2–3 sentence scope summary, checklist, blockers (severity, location, what must change), open decisions.
6. Return the same counts, decisions and summary.

## Rules

- Fix nothing; report.
- `READY` only with 0 critical, 0 major and 0 open decisions.
- Structured counts must match `docs/08-readiness.md`.
- Every line names evidence; an unrun check is FAIL.

## Done when

- docs/08 has the five sections, verdict first.
- Review read via `review.json`; nothing taken from an old docs/08.
- Coverage recounted for every in-scope FR, AC and NFR.
- Only docs/08 changed.
