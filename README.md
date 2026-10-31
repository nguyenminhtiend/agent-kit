# agent-kit

A kit that turns a short brief into reviewed, approved specs and a task plan,
before any code is written. It installs skills, agents and a guard hook into
**Claude Code**, **Codex**, or both, either **globally** or **per project**.

Main idea:

- **One command = one step.** Each `agent-kit` command runs one step, checks its
  inputs first, saves its outputs as files, and exits. Nothing runs the next step
  for you: you run the steps by hand, or chain them in your own script.
- **Bash** keeps the state, the hashes and the approval.
- **Skills** hold the method for each step; the runner loads their contents directly.
- **Subagents** review the work with a fresh, separate context.
- **Claude** does the thinking inside one step. No single conversation runs the whole project.

> Status: steps 1–3 are built (brief → specs → review → plan → readiness → approval → gate).
> The build stage (worktrees, coding, code review) is not built yet. Its skills
> (`build-task`, `fix-review`, `fix-bug`, `refactor`, `optimize`) and `code-reviewer`
> are written but not used by the runner yet. Where each file's ideas come from:
> [CREDITS.md](CREDITS.md).

Works in new and existing projects, small or big, solo or team. See
[USE-CASES.md](USE-CASES.md) for example folders, what to run in each case, and
example prompts.

## Pipeline

All paths below are inside the **workspace** (see [Workspaces](#workspaces)). Each
line is one command; [Use](#use-one-step-at-a-time) lists the input and output of each.

```
brief/requirements.md                         (you write it)
  │
  ▼  A. spec       agent-kit spec discover             → docs/01
  │                agent-kit spec define-product       → docs/02
  │                agent-kit spec design-ux            → docs/03
  │                agent-kit spec design-architecture  → docs/04
  │                agent-kit spec design-technical     → docs/05
  │                agent-kit spec validate-feasibility → docs/06
  ▼  B. review     agent-kit review    read-only reviewers in parallel, one round
  │                  exit 2 (blocking findings) → agent-kit repair (or edit the docs) → review again
  ▼  C. plan       agent-kit plan      → docs/07 + tasks/NNN-name/task.md
  │                agent-kit readiness → docs/08 + verdict
  │                  exit 2 (NOT_READY) → answer the open decisions, run again from the changed doc
  ▼  D. approve    agent-kit approve   a person reads docs/ and tasks/, types APPROVE
       gate        agent-kit gate      Bash only; exit 0 = coding may start
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

The pipeline steps use Claude for every install target, including `codex`.
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
  `agent-kit` steps. To also guard your normal sessions, see "Optional: guard in normal
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

## Use: one step at a time

Run the commands inside a project, in this order. Each one does one step and
exits. In a project install, `./scripts/<command>.sh` does the same.

| Step | Command | What runs | Reads (input) | Writes (output) |
|------|---------|-----------|---------------|-----------------|
| A1 | `agent-kit spec discover` | skill `discover` | brief/, the project's code | `docs/01-requirements.md` |
| A2 | `agent-kit spec define-product` | skill `define-product` | brief, docs/01 | `docs/02-prd.md` |
| A3 | `agent-kit spec design-ux` | skill `design-ux` | docs/01–02 | `docs/03-ux-design.md` |
| A4 | `agent-kit spec design-architecture` | skill `design-architecture` | docs/01–03, the project's code | `docs/04-architecture.md` |
| A5 | `agent-kit spec design-technical` | skill `design-technical` | docs/01–04, the project's code | `docs/05-technical-spec.md` |
| A6 | `agent-kit spec validate-feasibility` | skill `validate-feasibility` | brief, docs/01–05 | `docs/06-validation.md` |
| B1 | `agent-kit review` | reviewer agents in parallel (read only) | brief, docs/01–06 | `.workflow/reviews/round-N/reviewers/<agent>.json`, `.workflow/reviews/round-N/summary.json`, `.workflow/state/review.json` |
| B2 | `agent-kit repair` | skill `repair-specs` | the `blocking` list in the last round's `summary.json`, brief, docs/01–06 | changed docs/ files, each with a revision log at the end |
| C1 | `agent-kit plan` | skill `plan-tasks` | docs/01–06, the project's code | `docs/07-implementation-plan.md`, `tasks/NNN-name/task.md` |
| C2 | `agent-kit readiness` | skill `assess-readiness` | brief, docs/01–07, tasks/, the last review summary | `docs/08-readiness.md`, `.workflow/state/readiness.json` |
| D1 | `agent-kit approve` | no AI; a person in a terminal | brief/, docs/, tasks/ | `.workflow/approvals/spec-approved.json` |
| D2 | `agent-kit gate` | no AI; Bash checks | everything above | nothing (exit code only) |

Every Claude call also saves its full result (cost, turns, errors) in
`.workflow/logs/<time>-<name>.json`. Look there first when a step fails.

**What each step checks before it starts.** If a check fails, the step stops
before calling Claude and names the command that fixes it.

- `spec STAGE`: the brief is filled in (template marker line deleted), and the
  documents of all earlier stages exist.
- `review`: docs/01–06 exist.
- `repair`: the last review found blocking findings, and docs/01–06 have not
  changed since that review. So `repair` runs once per review.
- `plan`: the last review passed, on the docs as they are now.
- `readiness`: the same as `plan`, plus docs/07 and at least one task file.
- `approve`: every gate check except approval passes, and it runs in a real terminal.
- `gate`: see [Pipeline](#pipeline); details in `lib/gate.sh`.

**Exit codes**, the same for every command:

| Code | Meaning |
|------|---------|
| 0 | Done. `review`: passed. `readiness`: READY. `gate`: ready and approved |
| 1 | Error: a missing input, a failed Claude call, bad output, or a failed gate check |
| 2 | The step ran fine but found work for you. `review`: blocking findings. `readiness`: NOT_READY |

**Good to know:**

- You can run any step again. `spec STAGE` rewrites only its own document. Later
  steps use hashes to see that an earlier file changed, and tell you what to run again.
- `review` runs one round. Rounds count up (`round-1`, `round-2`, ...) and old
  rounds are kept so you can compare them.
- After blocking findings, run `repair` or fix the docs yourself; then `review` again.
- `plan` moves old tasks to `.workflow/archive/` before it writes new ones.
- NOT_READY: `docs/08-readiness.md` lists the open decisions. Answer them in the
  brief (or the document that owns them) and run the steps again from the first
  changed document.
- Every command prints the command to run next.

### Automate with your own script

The kit has no "run everything" command on purpose. When you know the steps,
chain them in a script. The loop limit and what to do on exit 2 are yours to choose.

```bash
#!/usr/bin/env bash
# my-pipeline.sh: steps A to C for one workspace. Approval stays manual.
set -euo pipefail
ak() { agent-kit -w specs/checkout "$@"; }    # drop -w for the default workspace

for stage in discover define-product design-ux design-architecture design-technical validate-feasibility; do
  ak spec "$stage"
done

max_rounds=3
for round in $(seq 1 "$max_rounds"); do
  rc=0; ak review || rc=$?
  [ "$rc" -eq 0 ] && break                      # passed
  [ "$rc" -eq 2 ] || exit "$rc"                 # 1 = error
  [ "$round" -lt "$max_rounds" ] || { echo "still blocked after $max_rounds rounds" >&2; exit 2; }
  ak repair
done

ak plan
ak readiness       # exit 2 = NOT_READY: read docs/08-readiness.md
echo "Now read docs/ and tasks/, then run: agent-kit approve"
```

Settings per project are in `agent-kit.toml` (workspace, models, turn and budget
limits, reviewer list and blocking severities). Put your test, lint and build
commands in `AGENTS.md`; skills look for them there.

## Workspaces

A workspace is the folder that holds one piece of work: `brief/`, `docs/`,
`tasks/` and `.workflow/` (review results, readiness, approval, logs). The runner
and Claude work inside it; Claude may still read the rest of the project.

- New project: the default `workspace = "."` (the project root) is fine.
- Existing project: use a new folder, e.g. `workspace = "specs"`. `init` refuses
  to use a folder whose `docs/` or `tasks/` already hold your own files, because
  the gate hashes those folders and `plan` archives old tasks.
- Many features or many people: one workspace per feature, e.g.
  `agent-kit -w specs/checkout init`, then `agent-kit -w specs/checkout spec discover`
  and the other steps.
  Each one has its own review, gate and approval, so they never block each other.

Order: `--workspace` (or `-w`, anywhere on the line; also `AGENT_KIT_WORKSPACE`),
then `[paths] workspace` in `agent-kit.toml`, then the project root. It must be a
relative folder inside the project.

Invalid TOML or invalid setting types stop the command before any step runs.
Turn limits must be positive integers; budgets must be
nonnegative numbers (`0` means unlimited). Configured reviewer and severity lists
must be nonempty. The gate requires an empty open-decisions list as well as zero
blocker and decision counts.

## Kit layout

```
agent-kit/
├── install.sh                 # install / uninstall, global or project
├── bin/agent-kit              # the runner command
├── lib/                       # one file per step group: spec, review (+ repair),
│                              #   plan (+ readiness), gate (+ approve); init, doctor, engine
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
- Each step that calls Claude may write only its own outputs (a spec stage: its one
  document). `guard.sh` blocks other writes while the step runs.
- Agents may never write any workspace's `.workflow/approvals/` or `.workflow/state/`,
  or run `agent-kit approve`. The guard blocks this in every session where it is installed.
- While a step runs, writes outside the workspace are blocked.
- `approve` needs a real terminal and refuses to run inside Claude Code or Codex.
- Workflow and engineering rules are managed together, so an existing `AGENTS.md`
  receives the gate and human-approval instructions while keeping its own content.
  The gate rule covers only a workspace's tasks; other work in the project is not blocked.
- These are safety nets, not walls. The gate checks the results again with hashes.

## Tests

```bash
tests/smoke.sh     # syntax, kit content, guard rules, installs, every step with a fake claude
```

No API calls. A live run with real `claude -p` has not been done yet; do one small
run once the skills have content.
