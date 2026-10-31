---
name: design-ux
description: Spec stage 3. Design flows, screens and states (docs/03-ux-design.md) from the PRD.
disable-model-invocation: true
---

## Reads

- `docs/01-requirements.md`
- `docs/02-prd.md`

## Writes

- `docs/03-ux-design.md` only

## Required sections

- User flows (one per PRD journey)
- Screens and their states (empty, loading, error, success)
- Navigation map
- Key interactions
- Content and copy notes
- Accessibility
- Traceability to PRD IDs

## Method

1. List docs/02's journeys, FRs, edge cases and NFRs. Take users, devices and platform from docs/01–02. Platform not stated: write a provisional direction as an assumption; if it changes scope, deployment or contracts (web vs native vs CLI), also add it to an `Open decisions` subsection (ID, options, recommendation). No GUI (CLI, API, agent tool): map journeys to commands or calls and mark screen-only parts n/a with a reason. Never invent a GUI.
   Rerun: keep screen IDs; new ones get the next number; removed ones are `retired`.
2. Direction, 3–5 lines: main job, who and how often, what they see first, tone, target screen sizes. The first screen is the task, not a marketing page.
3. Flows: one per journey, same name. Steps like "On S-02 user does X, sees Y, goes to S-03", tagged with FRs. Mark start, goal, error and no-data branches.
4. Screens (`S-01`, ...): one-line job, one primary action, content by importance, FRs served. Merge screens with the same job.
5. States per screen, each with trigger, what shows and safe next step: loading (no layout jump), empty (first use vs no results; next action), error (what failed, how to recover, keep input), success (confirm; next step or undo), plus partial data and no permission where they apply. Inapplicable: n/a with a reason. Every PRD edge case appears as a state or flow branch.
6. Navigation map: how users move between screens (menu, links, back, deep links). Every screen reachable; every flow has a way back.
7. Each data-changing action: feedback right after, failure path, double-click guard, confirm or undo if destructive. The result matches the label.
8. Real copy for key screens: labels, buttons named for the action, empty states, errors saying what happened and what to do. PRD names; long labels wrap. No lorem ipsum.
9. Accessibility, WCAG 2.2 AA unless the brief says otherwise. A minimum design checklist, not proof of conformance:
   - Per flow: keyboard order; focus on dialog open/close and after errors; screen-reader announcements for status and errors.
   - Global: labels on inputs and icon buttons; never color alone; contrast 4.5:1 (3:1 large text and controls); targets ≥24×24 CSS px (AA), 44×44 on touch (kit preference); text resizes to 200%; reflow at 320 CSS px without sideways scroll; no drag-only actions; respect reduced motion.
   - For an AA target, list the other applicable A/AA criteria and how each is checked, scoped to this product.
10. Traceability table `screen -> flows -> FR/NFR IDs`; then confirm every user-facing FR has a screen. List gaps.

## Rules

- No application code.
- Every screen traces to a PRD requirement.
- Add no features beyond the PRD; note a needed one as a PRD gap under Traceability.

## Done when

- One flow per journey; every screen has an ID, job, primary action and FR.
- Every applicable state covered or n/a with a reason; every edge case placed.
- Every user-facing FR on a reachable screen.
- Accessibility covers keyboard, focus, labels, announcements, contrast, targets and reflow.
