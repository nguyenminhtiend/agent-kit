---
name: repair-specs
description: Fix blocking review findings in the spec documents (requirements, design, plan and task files) and keep them consistent.
disable-model-invocation: true
---

## Ground rules

- Every fact cites a source (path:line, quote or command output); anything else is an assumption. Never invent names, values, APIs or results; mark outside facts (versions, limits, prices) `unverified`.
- A guess that would change scope, a contract or data: ask, or record it as an open decision.

## Input and output

- Reads: the findings named in the request; the brief, the requirements, the design, the plan and the task files.
- Writes only the documents that need a change; never the brief.

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

- No application code. Never renumber or reuse IDs.
- Never hide a finding by weakening a requirement or talking down severity.
