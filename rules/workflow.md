## Agent-kit workflow

A workspace holds `brief/`, `docs/`, `tasks/` and `.workflow/` for one piece of work: the project root, or the folder set by `[paths] workspace` in `agent-kit.toml` or `--workspace`. Agent-kit skills mean that workspace's folders.

- Write no code for a workspace's tasks before `agent-kit gate` passes for it. Other work follows the normal project rules.
- Never create or change files in `.workflow/approvals/` or `.workflow/state/`.
- Never run `agent-kit approve`. Only a person approves.
