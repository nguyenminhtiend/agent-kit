---
name: repair-specs
description: Fix blocking review findings in the spec documents (requirements, design, plan and task files) and keep them consistent.
disable-model-invocation: true
---

## Ground rules

- A fact needs a source: path:line, a quote or command output. Mark anything else as an assumption or your call.
- Never invent names, values, APIs or results. Mark outside facts (versions, limits, prices) `unverified`.
- A check you didn't run is "not run". A guess that would change scope, a contract or data: ask, or record it as an open decision.

## Reads

Documents are named by role. Paths: from the request; else find the project's matching files.

- The findings named in the request
- The brief, the requirements, the design, the plan and the task files

## Writes

- Only the documents that need a change

## Method

The next reviewer is fresh and sees only the documents: every fix must be visible in the text.

1. Read all findings; group them by root cause; fix each cause once.
2. Per finding, one outcome:
   - Fixed: a real problem you can fix without the owner.
   - Disputed: the text already covers it; make that easier to find and say why.
   - Needs the owner (scope, budget, legal, direction, or it conflicts with the brief): add a `DEC` (next number unused in the brief and every document) under Open decisions in the owning document. The defect keeps its severity.
3. Fix where it's owned (requirement, ADR, contract, task), then grep each changed ID, name or value and update every later active mention.
4. Log one line per finding at the end of each changed document: `Round N | <severity>: <issue> | <change or DEC-00N> | <sections>`.

## Rules

- Brief untouched; no application code.
- Never hide a finding by weakening a requirement or talking down severity.
- Never renumber or reuse IDs.

## Done when

- Every finding has an outcome and a log line; no old value is left in active text.
