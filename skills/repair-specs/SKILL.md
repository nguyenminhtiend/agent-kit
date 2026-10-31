---
name: repair-specs
description: Fix blocking review findings in docs/01-06 and keep later docs consistent. Used by the review loop.
disable-model-invocation: true
---

## Reads

- The findings file named in the prompt (`.workflow/reviews/round-N/summary.json`, `blocking` list)
- `brief/requirements.md`, `docs/01` to `docs/06`

## Writes

- Only the docs in `docs/01` to `docs/06` that need a change

## Method

Next round's reviewers are fresh and see only the docs: every fix must be visible in the text.

1. Read all findings first; group by root cause and fix each cause once.
2. Check each against the text (a recommendation is a suggestion, not an order) and give one outcome:
   - Fixed: a real problem you can fix without an owner's choice.
   - Disputed: the text already covers it; make that easy to find (pointer, sentence, clearer word) and say why in the log.
   - Awaiting owner decision: needs a call on scope, budget, legal or direction, or conflicts with the brief. Add it under "Open decisions" in the owning doc (docs/02 if unsure) with ID, 2–3 options and recommendation. This records the choice but doesn't fix the defect: it keeps its real severity, the next review reports it, and the loop may end BLOCKED. Never reword to make it look smaller.
3. Fix at the owner: REQs docs/01; FR/NFR/AC docs/02; screens docs/03; ADRs docs/04; contracts docs/05; feasibility docs/06. Others point to it, not copy. Critical before major, earlier docs first. Smallest full fix; no features the brief doesn't need. Never renumber or reuse IDs; new items get the next number.
4. Grep `docs/` for each changed ID, name or value and update every later active hit (03 screens, 04 active ADRs, 05 contracts/tests/traceability, 06). Leave history alone: revision logs, quoted evidence, superseded ADRs.
5. Revision log at the end of each changed doc, one line per change: `Round N | <reviewer> <severity>: <issue> | <change, or "awaiting owner decision <ID>"> | <sections>` (N from the findings path). A changed decision states old and new value.
6. Re-read each fix: would a fresh reviewer still raise it? Then it isn't fixed.

Batch all edits per document.

## Rules

- No application code; `brief/` untouched.
- Never hide a finding by deleting or weakening a requirement or talking down severity. Human decisions go under "Open decisions".
- Change only what the findings need.

## Done when

- Every blocking finding is fixed, disputed in the text, or an Open decision with ID.
- Every finding has a log line.
- No old value remains in active text; the ID chain still holds.
