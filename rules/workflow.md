## Agent-kit workflow

The brief is in `brief/`, specs are in `docs/`, and tasks are in `tasks/`.

- Do not write application code before `agent-kit gate` passes.
- Never create or change files in `.workflow/approvals/` or `.workflow/state/`. Only the runner and people do that.
- Never run `agent-kit approve`. Only a person approves.
