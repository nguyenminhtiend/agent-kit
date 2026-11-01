---
name: design-solution
description: Design how to build the requirements in one design document (decisions, parts, data, contracts, screens if any, security, risks, tests).
disable-model-invocation: true
---

## Ground rules

- A fact needs a source: path:line, a quote or command output. Mark anything else as an assumption or your call.
- Never invent names, values, APIs or results. Mark outside facts (versions, limits, prices) `unverified`.
- A check you didn't run is "not run". A guess that would change scope, a contract or data: ask, or record it as an open decision.

## Reads

Documents are named by role. Paths: from the request; else find the project's matching files.

- The requirements
- The brief's Decisions section, if any: the owner's answers
- Existing project: its code, schema and API files, and decision records (read only)

## Writes

- The design document only

## Sections

Approach · Decisions (`ADR-001`) · Parts and data flow · Data · Contracts · Screens · Security · Config · Risks · Tests · Traceability · Open decisions

A section that doesn't apply: one line, `None: <why>`.

## Method

1. Existing code is given: its stack, structure, names, error shape and test tools. Describe only what the change adds or touches; mark each contract new or changed; a breaking change names who is affected.
2. Start simple: one deployable unit and only the storage, auth and hosting the requirements need. Add a part (service, queue, cache) only for a named requirement.
3. Decisions: each hard-to-reverse choice (stack, store, auth, hosting) is `ADR-001`: context with REQ IDs, decision, 2–3 real alternatives and why not, consequences. A choice only the owner can make is a `DEC` (next number unused in the brief and every document), and its ADR stays Proposed. A `DEC` answered in the brief's Decisions is closed: apply it with source `DEC-001` and drop it from Open decisions. Rerun: keep numbers; a replaced ADR is `Superseded by ADR-00N`.
4. Contracts, per call (endpoint, function, command, event): method and path or name, auth (role or "public"), inputs with types, required and limits, outputs with types, every error code and when, one short example, the REQ it serves. One error shape and one naming style. Lists that can grow are paged. A retryable write (payment, send, create) has an idempotency key or says "not safe to retry".
5. Outside calls: timeout; retry only documented transient failures, bounded, with backoff; what the user sees when it fails. A timeout means "outcome unknown": say how it resolves. Responses are untrusted.
6. Data: per entity its fields, types, nullability, keys and delete behavior. Personal data: why it's kept, for how long, how it's deleted.
7. Screens, only if the product has a UI (never invent one): per screen its job, main action, and what shows when empty, loading, failed and done; one flow per user journey; accessibility target WCAG 2.2 AA unless the requirements say otherwise.
8. Security: trust boundaries (requests, uploads, webhooks, outside and LLM responses); every protected action checks identity and ownership; secrets by name only.
9. Risks: every `unverified` fact and assumption, with impact and a mitigation or spike (one question, time box, pass signal, fallback). One the design depends on is a `DEC`. Deadline given: say whether the must-haves fit; if not, the cuts are a `DEC`.
10. Tests: per requirement the level (unit, integration, end-to-end) and what it proves; fake only outside systems.
11. Traceability: `REQ -> parts / contracts / screens / tests`, every REQ and AC.

## Rules

- No application code (tables and short example payloads are fine).
- No part, option or seam without a requirement.
- A conflict with the requirements is written down, never settled silently.

## Done when

- Every REQ and AC has a place in the design, or "n/a" with a reason.
- Every contract has auth, typed inputs and outputs, errors and an example; every outside call has a timeout and failure behavior.
- Every `unverified` fact is in Risks; ones the design depends on are open decisions.
- No secret value anywhere; no two active ADRs conflict.
