---
name: validate-feasibility
description: Spec stage 6. Check the specs fit the time and constraints (the validation document).
disable-model-invocation: true
---

## Reads

Documents are named by role. Paths: from the request; else find the project's matching files.

- The brief
- The requirements, PRD, UX design, architecture and technical spec

## Writes

- The validation document only

## Required sections

- Feasibility per requirement
- Fit with the deadline and team
- Riskiest unknowns, and how to test them early (spikes)
- What to cut first if time runs short
- Verdict: feasible / feasible with cuts / not feasible

## Method

Check the plan; don't improve it. Use only what the docs say; a claim without evidence is an unknown.

1. Budget: deadline, team size and skills, required tech, external rules (missing → assumption, lower confidence). Convert to build time (days or sessions).
2. Table for every FR and NFR: ID | priority | size | depends on | hardest part | rating | why. Size XS–XL is a scope label (XL must split), not time; never add sizes. Rating: OK, Risky (needs an unknown to go well), Blocked. An NFR with no way to measure it is Risky.
3. List claims the specs rely on but don't prove ("the API allows X", "the free tier is enough", "the model can do Y"), plus hidden coupling, all-at-once dependencies and gaps between docs. Each goes under "Problems found" with doc and section.
4. Assumptions: must be true (else it fails), should be true (else change approach), might be true (extras).
5. Sort each unproven must-be-true:
   - Build-time unknown: both outcomes fit approved contracts and ADRs, and the fallback cost is budgeted → spike.
   - Pre-approval blocker: an outcome would change scope, a needed provider feature, security, an ADR or a contract → `### Open decisions` under Verdict (ID, options, recommendation). Readiness then holds the gate.
   Ordinary risks need not be solved before approval. For the 3–5 riskiest build-time unknowns, write a spike: one sharp question; type (research, prototype, setup); time box; pass signal; fallback and its cost; evidence delivered. Spikes give answers, not feature code. Unsharp questions go under "Not yet clear".
6. Fit: estimate distinct work packages (shared work counted once) as ranges in days or sessions, with assumptions. Add setup, integration, spikes, deploy and demo prep. Compare the critical path and total with capacity. Red flags: months of work, many parts that must all work at once, missing skills.
7. Cuts, two lists:
   - Required cuts: needed to fit at all. IDs, time saved, user loss, remaining scope, new total. Each is an owner decision in `### Open decisions` until the PRD, UX design, architecture and technical spec reflect it.
   - Contingency cuts: optional, ordered (extras, low-priority FRs, polish); may stay scheduled last.
   Never cut a brief must-have or external rule; if one must go, the verdict changes.
8. Verdict, after reading as a skeptic (simpler way?), pragmatist (ships on time?) and critic (what fails?):
   - feasible: every must-have OK, or Risky with a budgeted build-time spike and fallback; fits with no required cuts.
   - feasible with cuts: fits only after the required cuts, which the owner must approve.
   - not feasible: a must-have is Blocked, or it doesn't fit even after cuts.
   Give the main reason, confidence (high/medium/low) and the strongest objection. With an open pre-approval blocker, say the verdict assumes its recommended option and lower confidence.

## Rules

- No application code.
- Don't fix other docs; report problems here.
- Name every cut and why; never drop a requirement quietly.

## Done when

- Budget stated or assumed; every FR and NFR rated with a reason.
- Every unproven must-be-true is a spike or an Open decision.
- Effort given as ranges, with critical path vs capacity.
- Required and contingency cuts separate; required ones are Open decisions.
- Exactly one verdict, with reason, confidence and strongest objection.
