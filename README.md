# agent-kit

A kit that turns a short brief into reviewed, approved specs and a task plan,
before any code is written. It installs skills, agents and a guard hook into
**Claude Code**, **Codex**, or both, either **globally** or **per project**.

Main idea:

- **Bash** owns the order of stages, retries, state and approval.
- **Skills** hold the method for each stage; the runner loads their contents directly.
- **Subagents** review the work with a fresh, separate context.
- **Claude** does the thinking inside one stage. No single conversation runs the whole project.

> Status: steps 1–3 are built (brief → specs → review → plan → gate → approval).
> The build stage (worktrees, coding, code review) is not built yet. Its skills
> (`build-task`, `fix-review`, `fix-bug`, `refactor`, `optimize`) and `code-reviewer`
> are written but not used by the runner yet. Where each file's ideas come from:
> [CREDITS.md](CREDITS.md).

Works in new and existing projects, small or big, solo or team. See
[USE-CASES.md](USE-CASES.md) for example folders, what to run in each case, and
example prompts.

## Pipeline

All paths below are inside the **workspace** (see [Workspaces](#workspaces)).

```
brief/requirements.md
  │
  ▼  A. spec       skills: discover → define-product → design-ux →
  │                        design-architecture → design-technical → validate-feasibility
  │                writes docs/01 … docs/06 (each stage may write only its own file)
  ▼  B. review     agents in parallel: product-reviewer, architecture-reviewer, qa-reviewer
  │                blocking findings → repair-specs → review again (max 3 rounds) → else BLOCKED
  ▼  C. plan       skills: plan-tasks → docs/07 + tasks/NNN-name/task.md
  │                        assess-readiness → docs/08 + .workflow/state/readiness.json
  ▼  D. gate       Bash only: files exist, review passed, READY, hashes match, approved
                   approve: a person types APPROVE in a terminal
```

The gate binds everything to content hashes. If the workspace's `brief/`, `docs/`
or `tasks/` change after review, readiness or approval, the gate fails until you
run that step again. Files outside the workspace never affect the gate.

The baseline must use regular files and directories: symlinks, including dangling
links and directory aliases, are rejected. Edits during a review invalidate that
round instead of receiving a passing stamp. Readiness assessment also rejects
changes to its inputs while it runs.

## Install

Needs: `claude`, `jq`, `yq` (mikefarah v4), and `git` later on. Check with `agent-kit doctor`.

The automated pipeline uses Claude for every install target, including `codex`.
The target selects the editor integrations; it does not select the pipeline engine.

Main way: install once, globally, and use it in every project. Each project then
only needs `agent-kit init` (it adds `agent-kit.toml`, `AGENTS.md`, `CLAUDE.md` and
the workspace). Small fixes with a build skill need no init at all.

```bash
# Global (once): symlinks into ~/.claude, ~/.agents/skills, ~/.codex/agents and ~/.local/bin
./install.sh --target both --scope global          # or --target claude / codex
cd ~/any-project && agent-kit init                 # per project, when you use the pipeline

# Optional: copy the kit into one project instead, so it can be committed there
./install.sh --target both --scope project --project ~/my-project

# Options
./install.sh ... --dry-run      # only print what would happen
./install.sh ... --force        # replace things in the way (backups go to .agent-kit-backup/)
./install.sh ... --workspace specs        # project: keep brief/docs/tasks in specs/
./install.sh ... --scripts-dir tools/ak   # project: wrapper scripts there (none = skip)
./install.sh --target both --scope global --uninstall   # remove the global links
```

|                    | Global                                   | Project                                          |
|--------------------|------------------------------------------|--------------------------------------------------|
| Skills             | symlinks (edits here show up right away) | copies in `.claude/skills/`, `.agents/skills/`   |
| Agents             | symlinks (Codex TOML is generated)       | copies in `.claude/agents/`, `.codex/agents/`    |
| Guard hook         | not added; the runner passes it per call | added to `.claude/settings.json`, `.codex/hooks.json` |
| Runner             | `agent-kit` command in `~/.local/bin`    | `.agent-kit/` + wrappers (`--scripts-dir`, default `scripts/`) |
| Your settings files| never changed                            | only the project's, guard entry added            |

Notes:

- Global links point back to this folder: `git pull` or edits here reach every
  project at once. Run the installer again after you add a skill or agent, or edit
  an agent (Codex agents are TOML built from `agents/*.md`).
- A global install changes no settings file, so the guard hook runs only inside
  runner stages. To also guard your normal sessions, see "Optional: guard in normal
  sessions" in [USE-CASES.md](USE-CASES.md).
- Codex project hooks only run after you trust them: open Codex in the project and run `/hooks`.
- The runner carries its own skills and reviewer instructions (in `.agent-kit/`
  for project installs). It supplies them explicitly to Claude, so Codex-only
  installs work without adding a Claude editor integration. Update the kit's
  source skills or agents and reinstall to refresh a project's runner inputs.
- Project hooks locate the nearest `agent-kit.toml`, including inside monorepos.
  Reinstalling refreshes an older guard command while preserving unrelated hooks.
- Reinstalling refreshes `.agent-kit/` with a backup of the previous runtime.
  Integration files that differ are kept unless you pass `--force`; skipped files
  cause exit code 3.

## Use

```bash
agent-kit prepare            # A + B + C   (or ./scripts/prepare.sh)
agent-kit spec --from design-ux   # re-run from one stage
agent-kit review             # B only
agent-kit plan               # C only
agent-kit gate               # D: exit 0 only when READY and approved
agent-kit approve            # D: a person approves the current baseline
agent-kit -w specs/search prepare   # any command, in another workspace
```

Settings per project are in `agent-kit.toml` (workspace, models, max review
rounds, turn and budget limits, reviewer list, blocking severities, and the
`[verify]` commands for your stack).

## Workspaces

A workspace is the folder that holds one piece of work: `brief/`, `docs/`,
`tasks/` and `.workflow/` (review results, readiness, approval, logs). The runner
and Claude work inside it; Claude may still read the rest of the project.

- New project: the default `workspace = "."` (the project root) is fine.
- Existing project: use a new folder, e.g. `workspace = "specs"`. `init` refuses
  to use a folder whose `docs/` or `tasks/` already hold your own files, because
  the gate hashes those folders and `plan` archives old tasks.
- Many features or many people: one workspace per feature, e.g.
  `agent-kit -w specs/checkout init`, then `agent-kit -w specs/checkout prepare`.
  Each one has its own review, gate and approval, so they never block each other.

Order: `--workspace` (or `-w`, anywhere on the line; also `AGENT_KIT_WORKSPACE`),
then `[paths] workspace` in `agent-kit.toml`, then the project root. It must be a
relative folder inside the project.

Invalid TOML or invalid setting types stop the command before any stage runs.
Review cycles and turn limits must be positive integers; budgets must be
nonnegative numbers (`0` means unlimited). Configured reviewer and severity lists
must be nonempty. The gate requires an empty open-decisions list as well as zero
blocker and decision counts.

## Kit layout

```
agent-kit/
├── install.sh                 # install / uninstall, global or project
├── bin/agent-kit              # the runner command
├── lib/                       # runner stages: spec, review, plan, gate, init, doctor, engine
├── hooks/guard.sh             # PreToolUse guard for Claude Code and Codex
├── schemas/                   # JSON schemas for review and readiness results
├── rules/                     # workflow + engineering rules in each AGENTS.md managed block
├── skills/<name>/SKILL.md     # one skill per folder; agents/openai.yaml = Codex settings
├── agents/<name>.md           # reviewer agents (Claude format; Codex TOML is generated)
├── templates/project/         # agent-kit.toml, AGENTS.md, CLAUDE.md, brief template
├── tests/                     # smoke.sh, regressions.sh and fake-claude (no API calls)
├── USE-CASES.md               # example folders, what to run, example prompts
└── CREDITS.md                 # sources of each skill, agent and rule; license notices
```

## Where to put content

Edit the method sections. Skills and agents name documents by role ("the PRD",
"the technical spec"), never by path: the runner sends a role-to-path list with
every call, built from the names in `lib/common.sh` (change file names only there).
Keep the roles in **Reads / Writes** as they are; other stages depend on them.
Build skills and `code-reviewer` work in any project and use agent-kit files only
when they exist. Keep the text short: agents load every word. Record any new
source in `CREDITS.md`. `tests/smoke.sh` fails if a skill or agent names a workspace path.

| File                               | What goes there                                         |
|------------------------------------|---------------------------------------------------------|
| `rules/engineering.md`             | Coding rules every agent follows in every project       |
| `skills/discover`                  | Turning a rough brief into clear requirements, asking the right questions |
| `skills/define-product`            | Writing a PRD                                           |
| `skills/design-ux`                 | User flows, screens, states                             |
| `skills/design-architecture`       | Architecture and decision records                       |
| `skills/design-technical`          | API, data and auth contracts                            |
| `skills/validate-feasibility`      | Scope and risk checks against the deadline              |
| `skills/repair-specs`              | Fixing review findings without breaking other docs      |
| `skills/plan-tasks`                | Slicing work into small, ordered, testable tasks        |
| `skills/assess-readiness`          | The "ready to build?" checklist                         |
| `skills/build-task`                | Building one task, test-first, with verification        |
| `skills/fix-review`                | Handling code review feedback                           |
| `skills/fix-bug`                   | Root-cause debugging                                    |
| `skills/refactor`, `skills/optimize` | Safe refactoring; measured optimization               |
| `agents/*-reviewer.md`             | Review checklists                                       |

All skills are **switched off for automatic use** (`disable-model-invocation: true`
for Claude, `allow_implicit_invocation: false` for Codex). The spec skills stay
off (the runner loads their instructions directly). Switch an engineering skill
on once the build stage uses it, in both places; `tests/smoke.sh` checks that
the two settings match.

## Safety

- Reviewer agents only get `Read, Grep, Glob`.
- Each spec stage may write only its own document. `guard.sh` blocks other writes
  while a runner stage is active.
- Agents may never write any workspace's `.workflow/approvals/` or `.workflow/state/`,
  or run `agent-kit approve`. The guard blocks this in every session where it is installed.
- During a runner stage, writes outside the workspace are blocked.
- `approve` needs a real terminal and refuses to run inside Claude Code or Codex.
- Workflow and engineering rules are managed together, so an existing `AGENTS.md`
  receives the gate and human-approval instructions while keeping its own content.
  The gate rule covers only a workspace's tasks; other work in the project is not blocked.
- These are safety nets, not walls. The gate checks the results again with hashes.

## Tests

```bash
tests/smoke.sh     # syntax, kit content, guard rules, installs, full pipeline with a fake claude
```

No API calls. A live run with real `claude -p` has not been done yet; do one small
run once the skills have content.
