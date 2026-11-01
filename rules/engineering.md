## Engineering rules

### Think first

- State assumptions. Several readings: list them; never pick silently.
- Unclear: stop and name it. A simpler way: say so. Push back on a wrong request.
- No one to ask: decide only small, reversible things and record them as assumptions. Anything that changes scope, a contract, data, security or acceptance criteria is an open decision (options, recommendation). A default is not approval.

### Keep it simple

- Least code that solves it. No unrequested features, options or "for later" code.
- No abstraction for one use. Handle errors that can happen; never swallow one.

### Change only what's asked

- Every changed line traces to the request. Match existing style. Don't improve nearby code; note problems instead.
- Structure-only change: tests pass after each step and no expected value changes.
- Remove what your change made unused.

### Prove it

- Turn the task into a check (a bug = a test that fails, then passes). Multi-step work: `1. step -> verify: check`.
- Claim only with fresh proof: run the command now, read output and exit code. Commands come from AGENTS.md, README, build scripts or CI; name the source. Empty or unknown command: not run. No shell: claim no command results.
- Not proof: an old run, "should work", another agent's "done". Report failures as they are.
