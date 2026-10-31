---
name: design-technical
description: Spec stage 5. Write the technical spec with API, data and auth contracts.
disable-model-invocation: true
---

## Reads

Documents are named by role. Paths: from the request; else find the project's matching files.

- The requirements, PRD, UX design and architecture
- Existing project: its code, API and schema files (read only)

## Writes

- The technical spec only

## Required sections

- API contracts (endpoints, requests, responses, errors)
- Data schema
- Events and messages
- Auth and permissions
- Error handling
- Configuration and secrets (no secret values)
- Test strategy
- Traceability to `FR-xxx` IDs

## Method

1. List every FR. Take components, stack, auth and active ADRs from the architecture as given. If the architecture is wrong, write "Conflict with the architecture: ..." where it matters, follow the architecture, and go on. Existing code: reuse its contracts, error shape, naming and test tools; mark each contract new or changed; a breaking change names who is affected and the migration.
2. Contracts, starting from each caller (a UX design screen or other): what must it show or do? Prefer one task-shaped call; never return a raw database row. Per endpoint, or function/command/tool call when there is no HTTP:
   - HTTP method and path, or name and invocation; auth: role, "public" or "none"
   - request fields or arguments: type, required, limits, enums
   - response fields or results with types; meaning of null, missing, empty
   - HTTP success status and every error code, or native result and every error/exit code
   - FR served; one short example request and response
   Paginate lists that can grow without limit. One naming style: plural nouns in paths, one case for fields.
   Retryable writes (payment, send, create) need an idempotency key or "not safe to retry". With a key, state: scope and retention; same key + different payload → which error; repeat while the first runs → which response; repeat after success → same result or not. Storage and locking are the builder's choice unless an ADR decides.
3. Errors: one shape, e.g. `{ "error": { "code", "message", "details" } }`. Map statuses once (400, 401, 403, 404, 409, 422, 429, 500). Each code: cause and user message; never stack traces. Per external call: timeout, retry rule, fallback; a timeout means "outcome unknown", so say how it resolves. Retry rule per operation from the provider's contract: only documented transient failures (e.g. 429, 503), bounded attempts, backoff with jitter, honor `Retry-After`. Never retry validation or permission errors unchanged. Replay a write only when idempotency or reconciliation makes it safe. "No retry" is valid; never blanket-retry every 429.
4. Schema (or "None" and why): per entity fields, types, nullability, defaults, keys, unique rules, foreign keys with on-delete, indexes the API needs. Money as decimal; times with time zone. Carry data classes and retention from the architecture. Plan the first migration and demo seed data.
5. Events (or "None" and why): name, producer, consumers, payload, retry/dead-letter. Consumers handle duplicates.
6. Auth (or "None" and why when there are no accounts): roles; role × action matrix; every protected action checks identity and ownership. If present: session/token lifetime, cookie flags, login rate limit, webhook signature check.
7. Config table: name | purpose | required | default | secret. Secrets: name only, no default. Non-secrets may have a safe default. Never write a real key, password or token.
8. Tests: unit for pure logic, integration across boundaries, E2E only for critical flows. Mock only at edges (external APIs, time). Check responses against contracts, including errors, empty lists and nulls. Each abuse case in the architecture becomes a test. Tools from the stack ADR or the existing project; its test commands when known.
9. Traceability table: FR | endpoints/calls/events | tables | tests, one row per FR. No contract needed: "n/a" and why; never invent one.

## Rules

- No application code (tables and short example payloads are fine).
- Contracts exact enough to build and test against.
- One error shape and one naming style everywhere.
- Errors are contract: list every code a caller can get.

## Done when

- Every FR has a traceability row with contract and test, or n/a with a reason.
- Every endpoint/call has auth, typed request/response, errors and an example.
- Every external call has a timeout and a provider-based retry rule.
- No secret value anywhere; conflicts with the architecture written down.
