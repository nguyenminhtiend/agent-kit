---
name: assess-readiness
description: Last stage before the human gate. Judge whether specs and tasks are ready (the readiness report plus a structured verdict).
disable-model-invocation: true
---

## Reads

Documents are named by role. Paths: from the request.

- The brief, the spec documents (requirements to validation), the plan and all task files
- The review summary named in the request

## Writes

- The readiness report only
- A structured verdict as output, in the shape the request asks for: `status`, `critical`, `major`, `unresolved_decisions`, `summary`, `decisions`.

## Required sections (readiness report)

- Verdict
- Scope summary
- Checklist results
- Blockers (critical and major)
- Open decisions for a person (ID, question, options, recommendation)

## Method

Question: can a fresh agent build every task from its file and linked docs without asking? Reviewers checked the spec documents; you check the plan and task files. An old readiness report is past output: never use it as evidence or a source of blockers or decisions. The runner checks hashes.

1. Collect: list all task files; read the review summary the request names, never another round's. Grep the specs, plan and task files for REQ, FR, NFR, ADR and AC IDs.
2. Checklist, one line each: PASS/FAIL, severity, evidence (path + section, ID or quote). Recount yourself; trust no earlier table or PASS.
   - Placeholders (`TODO`, `TBD`, `FIXME`, `???`, empty sections): major; critical in a contract or AC a task needs.
   - Trace: every REQ leads to an FR, NFR, constraint or out-of-scope; every FR links a real REQ; every in-scope FR has a task (critical); every in-scope AC and NFR, incl. negative and manual, has a task and verification method (major); excluded IDs have a deciding section; every ID a task names exists (major).
   - Consistency: names and values match the technical spec; no task contradicts an active ADR (major).
   - Feasibility: "not feasible" is critical. Required cuts are reflected in the specs and unplanned, or are open decisions; contingency cuts may stay. Each riskiest build-time unknown has an early spike task (major).
   - Tasks: seven sections, `Kind`, pass/fail ACs with exact values; feature tasks name an FR/NFR; setup/spike tasks name what they enable; Depends on points lower (major). A clearly oversized task (well over ~5 files) is a minor warning unless it mixes independent behaviors.
   - Cold start: read the 3 riskiest tasks with only their linked docs; any guessed name, value or behavior is major.
   - Plan: five sections, a real demo chain, task list matches the task folders.
   - Review: the named summary has an empty `blocking` list, else critical (also if missing). List remaining minors, uncounted.
3. Open decisions: gather from every Open decisions section in the specs and plan, the requirements' open questions, Proposed ADRs, risks marked "check before approval", task `Open:` lines and the plan's Gaps. Open = unanswered and changes scope, a contract, data, security or ACs; a design relying on an unverified capability, quota or price stays open until verified or decided. Deduplicate by owning doc and ID. Give each an ID (reuse, else `DEC-001`), question, 2–3 options and a recommendation with reason. Items settled by an assumption that changes none of these are PASS lines.
4. Severity: critical = can't start or product wrong; major = rework or failed requirement likely; minor = doesn't block.
5. Readiness report: verdict first (`READY`/`NOT_READY` with the three counts), 2–3 sentence scope summary, checklist, blockers (severity, location, what must change), open decisions.
6. Return the same counts, decisions and summary.

## Rules

- Fix nothing; report.
- `READY` only with 0 critical, 0 major and 0 open decisions.
- Structured counts must match the readiness report.
- Every line names evidence; an unrun check is FAIL.

## Done when

- The readiness report has the five sections, verdict first.
- Review read from the named summary; nothing taken from an old readiness report.
- Coverage recounted for every in-scope FR, AC and NFR.
- Only the readiness report changed.
