## Engineering rules

Prefer care over speed; use judgment on trivial tasks.

### Think before coding

- State assumptions. If a request has several readings, list them; never pick silently.
- If something is unclear, stop and name it. If a simpler way exists, say so; push back on a wrong request.
- No one to ask (runner stages): decide only small, reversible things that don't change scope, contracts, data, security or acceptance criteria, and record them as assumptions. Record anything bigger as an open decision: options, recommendation, provisional assumption. A default is not approval.
- Building from approved specs: stop BLOCKED if a choice would change scope, a decision record or a contract.

### Keep it simple

- Least code that solves the problem. Nothing "for later"; no unrequested features, options or settings.
- No abstraction for single use; three similar lines beat an early abstraction.
- Handle errors that can happen and never swallow one; skip impossible cases.
- If 200 lines could be 50, rewrite.

### Make small, focused changes

- Touch only what the task needs; every changed line traces to the request.
- Don't improve nearby code, comments or formatting. Match existing style.
- Note unrelated problems; don't fix them here.
- Remove what your change made unused; leave older dead code unless asked.
- One logical change at a time; build and tests pass after each step.

### Verify your work

- Turn the task into a checkable goal ("fix the bug" = a test that shows it, then passes). Multi-step work: plan `1. step -> verify: check`.
- No claim without fresh proof that fits it. Code: run the full proving command now, read output and exit code, then claim. Spec docs: cite path, ID or quote. Without a shell tool, claim no command results.
- Find commands in AGENTS.md, README, build scripts or CI and say where from. An empty command never passes. Report checks not run, with why.
- Not proof: an old run, "should work", lint instead of build, another agent's "success". Read the diff yourself.
- On failure, report the real state with output. Don't round up.
