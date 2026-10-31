---
name: design-architecture
description: Spec stage 4. Design the architecture and decision records (docs/04-architecture.md).
disable-model-invocation: true
---

## Reads

- `docs/01-requirements.md`
- `docs/02-prd.md`
- `docs/03-ux-design.md`

## Writes

- `docs/04-architecture.md` only

## Required sections

- Context and quality goals
- Stack choice, with reasons
- Components and what each one does
- Data flow
- Data storage
- External integrations
- Security and privacy
- Deployment and environments
- Risks
- Decision records (`ADR-001`, ...)

## Method

1. Drivers: constraints from docs/01 (deadline, tech, team, rules) and NFRs from docs/02. Rank the 3–5 quality goals that shape the design, citing IDs. List every other applicable NFR, including ones without numbers.
2. Start simple: one deployable unit plus only the storage, auth and hosting the requirements need (a CLI or static site may need none). Add a service, queue or cache only for a named requirement. For an inapplicable category, keep the heading and write "None" and why.
3. Stack: for each applicable choice (language/framework, store, hosting, auth, AI or third-party service), compare 2–3 real options and pick one with a reason tied to a constraint or ID. Prefer adopting a known tool. Mark versions, limits, quotas and prices `unverified` and copy them to Risks. If the design depends on one, or on a choice only the owner can make, also add it to `### Open decisions` under Risks (ID, options incl. fallback, recommendation, evidence that would settle it) and link the risk and ADR.
4. Components table: component | job | depends on | FRs owned. Every FR has an owner. One-way dependencies; merge mutual ones. Deletion test: if removing it only moves calls around, merge it.
5. Data flow per main journey across components: what is sent, stored, shown. One failure path each.
6. Storage: each entity, owning component, location. Classify fields non-personal, personal or sensitive. Keep only needed data. Personal data gets retention and a delete path. Nothing stored: "None" and why.
7. Integrations: purpose, auth, limits, behavior when slow or down, test fake. One adapter each; responses are untrusted.
8. Security: trust boundaries (requests, uploads, webhooks, third-party responses, LLM output) and assets (accounts, personal data, money, admin actions). Per boundary, applicable STRIDE threats with a control each. One abuse case per main feature. LLM: output untrusted, permissions in code not prompt, token and rate limits.
9. Environments: how each deploys, where config and secrets come from (names only), how to roll back.
10. Risks table: risk | impact | likelihood | mitigation or spike, covering every `unverified` fact and assumption. Mark each "info only" or "check before approval" (the latter has an Open decision).
11. ADRs for choices that are hard to reverse, surprising and real trade-offs, including each of stack, store, auth and hosting the product has. Never invent a choice to fill a section. Format: `### ADR-001: <title>`, Status (Accepted, Proposed, Superseded), Context (2–5 lines with IDs), Decision (1–3 lines), Alternatives with why not, Consequences. An ADR resting on an open decision stays Proposed. Rerun: keep numbers; mark replaced ADRs "Superseded by ADR-00N" and keep them as history; only active ADRs are the design; never renumber or reuse.

## Rules

- No application code.
- Pick the stack from the brief's constraints and say why.
- No component, service or seam without a requirement.
- No unchecked fact stated as true; mark it `unverified`.

## Done when

- Every FR has a component; every ranked goal and applicable NFR has a design choice.
- No dependency cycles; every integration states auth, limits, failure behavior and fake; every boundary has a threat and control.
- Every `unverified` fact and assumption is in Risks; ones the design depends on are Open decisions.
- No two active ADRs contradict each other or the design.
