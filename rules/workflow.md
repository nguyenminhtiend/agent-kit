## Agent-kit workflow

Each piece of work has a workspace: the folder set by `[paths] workspace` in `agent-kit.toml` (default: project root) or by `--workspace`. It holds `brief/`, `docs/`, `tasks/` and `.workflow/`; agent-kit skills mean that workspace's folders.

- Do not write code for a workspace's tasks before `agent-kit gate` passes for it. Other work follows the normal project rules.
- Never create or change files in any `.workflow/approvals/` or `.workflow/state/`. Only the runner and people do that.
- Never run `agent-kit approve`. Only a person approves.
