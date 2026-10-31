---
name: discover
description: Spec stage 1. Turn the brief into docs/01-requirements.md.
disable-model-invocation: true
---

## Reads

- `brief/requirements.md`

## Writes

- `docs/01-requirements.md` only

## Required sections

- Problem statement
- Goals and success measures
- Users
- Constraints (deadline, contest or submission rules, required tech)
- Requirements with stable IDs (`REQ-001`, ...)
- Assumptions (apart from facts)
- Open questions, critical ones marked

## Method

No one can be asked: every question goes in the doc with your best guess.

1. Read the whole brief and any project file it points to. Don't ask what they already answer.
2. Only the brief is fact. Anything you add is an assumption with a reason. Never state a business rule (price, limit, legal duty, target user) as fact unless the brief does.
3. Problem statement, 1–2 sentences from the user's side: who, what problem, what they do today.
4. Find or mark missing: the specific user; why now; success (number or visible result); hard limits (deadline, rules, tech, budget); non-goals.
5. Rewrite vague words ("fast", "easy", "secure", "scalable") as observable checks. No number in the brief: propose one as an assumption.
6. One `REQ` = one user need, one sentence, with its source (quote or section; or "implied" plus a matching assumption). Split compound lines. Keep the brief's priority word.
   - First run: number in brief order.
   - Rerun: read the old docs/01; matching REQs keep their IDs; new ones go above the old max; removed ones are marked `retired`; never reuse or renumber. Add a short "Changes since last run" note.
7. One name per thing. For an ambiguous word, give both readings and pick one as an assumption.
8. Quote both sides of every conflict (incompatible needs, must-have also out of scope, scope vs deadline) under Open questions.
9. Sort each gap: a sensible default that doesn't change the build → Assumptions with reason; only the owner can answer and it changes the build → Open questions; a later stage owns it (stack, data model, layout) → leave out.
10. Open question: one idea, plus "Why it matters" and "Default". Mark **critical** if a wrong default breaks a REQ, constraint or deadline; critical first.

## Rules

- No application code, stack, data model or screen design.
- Don't invent major requirements; record gaps as assumptions or open questions.
- Point out contradictions in the brief.

## Done when

- All required sections present.
- Every brief must-have, deadline and submission rule is a REQ, constraint or open question.
- No success measure rests on a vague word.
- On a rerun, surviving REQs keep their IDs.
