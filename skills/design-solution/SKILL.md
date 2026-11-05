---
name: design-solution
description: Design how to build the requirements in one design document (decisions, parts, data, contracts, screens if any, security, risks, tests).
disable-model-invocation: true
---

## Ground rules

- Every fact cites a source (path:line, quote or command output); anything else is an assumption. Never invent names, values, APIs or results; mark outside facts (versions, limits, prices) `unverified`.
- A guess that would change scope, a contract or data: ask, or record it as an open decision.

## Input and output

- Reads: the requirements; the brief's Decisions section, if any (the owner's answers); for an existing project, its code, schema and API files, and decision records.
- Writes only the design document. Sections: Approach · Decisions (`ADR-001`) · Parts and data flow · Data · Contracts · Screens · Security · Config · Risks · Tests · Traceability · Open decisions. A section that doesn't apply: `None: <why>`.

## Method

1. Existing code fixes the stack, structure, names, error shape and test tools. Describe only what the change adds or touches; mark each contract new or changed; a breaking change names who is affected.
2. Start simple: one deployable unit and only the storage, auth and hosting the requirements need. Add a part (service, queue, cache), option or seam only for a named requirement.
3. Each hard-to-reverse choice (stack, store, auth, hosting) is an ADR citing its REQ IDs, with real alternatives and why not. A choice only the owner can make is a `DEC` (next number unused in the brief and every document) and its ADR stays Proposed. A `DEC` answered in the brief's Decisions is closed: apply it with source `DEC-001` and drop it from Open decisions. Rerun: keep numbers; a replaced ADR is `Superseded by ADR-00N`.
4. Contracts, per call (endpoint, function, command, event): method and path or name, auth (role or "public"), typed inputs with limits, typed outputs, every error code and when, one short example, the REQ it serves. One error shape and one naming style. Lists that can grow are paged. A retryable write has an idempotency key or says "not safe to retry".
5. Outside calls: timeout; retry only documented transient failures, bounded, with backoff; what the user sees when it fails. A timeout means "outcome unknown": say how it resolves. Responses are untrusted.
6. Data: per entity its fields, types, nullability, keys and delete behavior. Personal data: why it's kept, for how long, how it's deleted.
7. Screens, only if the product has a UI: per screen its job, main action, and what shows when empty, loading, failed and done; one flow per user journey; WCAG 2.2 AA unless the requirements say otherwise.
8. Security: trust boundaries (requests, uploads, webhooks, outside and LLM responses); every protected action checks identity and ownership; secrets by name only.
9. Risks: every `unverified` fact and assumption, with impact and a mitigation or spike (question, time box, pass signal, fallback). One the design depends on is a `DEC`. Deadline given: say whether the must-haves fit; if not, the cuts are a `DEC`.
10. Tests: per requirement the level (unit, integration, end-to-end) and what it proves; fake only outside systems.
11. Traceability: every REQ and AC -> parts / contracts / screens / tests, or "n/a" with a reason.

## Rules

- No application code (tables and short example payloads are fine).
- A conflict with the requirements is written down, never settled silently. No two active ADRs conflict.
