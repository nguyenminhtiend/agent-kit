# Use cases

Install agent-kit once, globally. Then use it in any project: new or existing,
small or big, solo or company. This page shows, for six common cases, what the
folders look like, what to run, and what to write.

## One-time setup

```bash
git clone <your agent-kit repo> ~/tools/agent-kit
cd ~/tools/agent-kit
./install.sh --target both --scope global   # Claude Code and Codex; or --target claude / codex
agent-kit doctor                            # checks claude, jq, yq
```

What this gives every project on your machine:

| Where | What |
|-------|------|
| `~/.claude/skills/`, `~/.agents/skills/` | all skills (Claude Code, Codex) |
| `~/.claude/agents/`, `~/.codex/agents/` | `spec-reviewer` and `code-reviewer` |
| `~/.local/bin/agent-kit` | the runner command |

Your settings files are not changed. These are links back to the kit folder, so
`git pull` in the kit updates every project at once. Run the installer again only
after you add a skill or agent, or edit an agent.

## Per project: `agent-kit init`

Only needed when you use the pipeline (cases 1 to 4). Run it in the project folder:

```bash
agent-kit init                      # workspace = project root (new projects)
agent-kit -w specs/<feature> init   # workspace = its own folder (existing projects, teams)
```

It adds `agent-kit.toml`, `AGENTS.md`, `CLAUDE.md` (or adds a block to yours),
three `.gitignore` lines, and the workspace: `brief/`, `docs/`, `tasks/`,
`.workflow/`. Commit all of them except what `.gitignore` lists.

## The steps

The pipeline is a list of commands. Each one does one step and stops, so you can
read its output before you run the next one. Each command prints the next one.
Input and output of every step: [README: Use](README.md#use-one-step-at-a-time).

```bash
# A. specs: one command per document
agent-kit spec define-requirements    # brief            -> docs/01-requirements.md
agent-kit spec design-solution        # + docs/01        -> docs/02-design.md
# B. plan
agent-kit plan                        # docs/01-02       -> docs/03-plan.md + tasks/
# C. check (no AI, free) and review (exit 2 = problems or blocking findings)
agent-kit check                       # docs + tasks     -> a list of problems
agent-kit review                      # brief, docs, tasks -> .workflow/reviews/round-N/summary.json
agent-kit repair                      # only after review exits 2, then review again
# D. a person approves; the gate checks
agent-kit approve                     # in your own terminal, type APPROVE
agent-kit gate                        # exit 0 = coding may start
```

For a workspace that is not the default, add `-w <workspace>` to every command.
Once you know the steps, you can chain them in your own script: see
[README: Automate with your own script](README.md#automate-with-your-own-script).

## Pick your case

| # | Case | Workspace | What to use |
|---|------|-----------|-------------|
| 1 | New project, small, solo | `.` (project root) | pipeline, low-cost settings |
| 2 | New project, big, team | `specs/<feature>` | pipeline, full settings, gate in CI |
| 3 | Existing project, small, solo | `specs/<feature>` | pipeline for a feature |
| 4 | Existing project, big, company (monorepo) | `specs/<feature>`, per service | pipeline, full settings, gate in CI |
| 5 | Small change in any project (bug, clean-up, speed) | none, no init | one skill only |
| 6 | New feature or idea in any project, agreed by talking it through | none, no init | plan mode, then `build-task` |

Rule of thumb: use the pipeline when the work needs a reviewed, approved plan (a
new product, a feature of several days, or a team that signs off). For a change you can explain in two sentences,
skip the pipeline and use one skill (case 5). For a new feature or idea you want to
talk through and agree with Claude before building, use plan mode (case 6).

## The parts, in short

| Part | What it does | Who starts it |
|------|--------------|---------------|
| `agent-kit spec <stage>`: skills `define-requirements`, `design-solution` | Each stage writes one document: `docs/01-requirements.md`, `docs/02-design.md` | you, one command per stage |
| `agent-kit plan`: skill `plan-tasks` | Writes `docs/03-plan.md` and `tasks/` | you |
| `agent-kit check` | Checks in code, no AI: open decisions, coverage, task files | you (free; also inside `approve` and `gate`) |
| `agent-kit review`: agent `spec-reviewer` | One review round of everything, read only | you |
| `agent-kit repair`: skill `repair-specs` | Fixes the blocking findings of the last review | you, after `review` exits 2 |
| `agent-kit approve` | You accept the specs and tasks | you, in a terminal |
| `agent-kit gate` | Says if coding may start (exit 0 = yes) | you or CI |
| Build skills: `build-task`, `fix-bug` | Write and fix code; `build-task` also gets its change reviewed | you, in Claude Code or Codex |
| `code-reviewer` agent | Checks a code change against its task, contracts and tests, read only (in Codex: by instruction only) | `build-task`, or you |

Build skills never start on their own. Call them by name: `/build-task ...` in
Claude Code, `$build-task ...` in Codex.

---

## 1. New project, small, solo

A weekend app, a CLI tool, a contest entry.

**Folders after `init` and all steps:**

```
trip-splitter/
├── agent-kit.toml
├── AGENTS.md              # shared rules (kit block added)
├── CLAUDE.md              # imports AGENTS.md
├── brief/requirements.md  # you write this
├── docs/01 … 03           # written by the steps
├── tasks/001-setup/task.md
│   tasks/002-add-expense/task.md …
└── .workflow/             # review results, approval, logs
```

**Run:**

```bash
mkdir trip-splitter && cd trip-splitter && git init
agent-kit init
# write brief/requirements.md (delete the template marker line), alone or
# with Claude; then run the steps one by one:
agent-kit spec define-requirements
agent-kit spec design-solution
agent-kit plan
agent-kit check
agent-kit review
```

**Low-cost settings** in `agent-kit.toml` (`opus` gives better specs; `sonnet` costs less):

```toml
[models]
spec = "sonnet"
review = "sonnet"
plan = "sonnet"

[limits]
max_budget_usd = 2      # per Claude call (each step makes one; review makes one per reviewer)
```

Fewer review rounds also cost less: you decide how many times to run
`repair` and `review` again.

**Example brief** (`brief/requirements.md`):

```markdown
# Brief

## Idea
A web app to split trip costs between friends. Today we use a shared
spreadsheet and always get the totals wrong.

## Users
Me and 3-8 friends, on phones, during and after a trip.

## Must have
- Create a trip and invite friends with a link (no passwords).
- Add an expense: who paid, how much, who shares it.
- Show who owes whom, with the fewest payments.

## Existing code
(empty: new project)

## Constraints
Done in 2 weekends, one developer. TypeScript. Free hosting only.

## Out of scope
Currency conversion, real payments, native apps.

## Links
None.
```

**Then:**

1. If `check` lists open decisions (exit 2), answer them in the brief's
   `## Decisions` as `DEC-001: <answer> (<date>)` (or ask Claude to ask you them one
   by one and write the answers). Then run the steps again from `agent-kit spec define-requirements`.
2. `agent-kit approve` (type `APPROVE`), then `agent-kit gate`.
3. Build one task at a time (see [Build prompts](#build-prompts)).

---

## 2. New project, big, team

A product with several people, several features, and reviews.

**Folders:**

```
claims-portal/
├── agent-kit.toml               # workspace = "specs/foundation" (the default)
├── AGENTS.md  CLAUDE.md
├── specs/
│   ├── foundation/              # first workspace: the whole first release
│   │   ├── brief/requirements.md
│   │   ├── docs/01 … 03
│   │   ├── tasks/
│   │   └── .workflow/
│   ├── document-upload/         # one workspace per later feature
│   └── status-notifications/
└── src/ …
```

Each workspace has its own review, approval and gate. Two people can work on
two features without blocking each other or causing merge conflicts in `docs/`.

**Run:**

```bash
cd ~/claims-portal
agent-kit -w specs/foundation init     # the first init also sets the default workspace
# write specs/foundation/brief/requirements.md, then run the steps:
agent-kit spec define-requirements     # ... through agent-kit review
# a tech lead reads docs/ and tasks/, then:
agent-kit approve

# later, a new feature (not the default workspace, so add -w to every step):
agent-kit -w specs/document-upload init
# write its brief, then:
agent-kit -w specs/document-upload spec define-requirements   # ... through review
```

**Settings:**

```toml
[models]
spec = "opus"
review = "opus"
plan = "opus"

[limits]
max_turns = 50
max_budget_usd = 5

[review]
agents = ["spec-reviewer"]
block_on = ["critical", "major"]
```

**Team flow:**

1. Every teammate does the one-time setup from the same kit repo. Keep the same
   version: `agent-kit version` should match (pull the kit together).
2. One branch per feature. The PR holds the workspace folder first (brief, docs,
   tasks, and the approval file), then the code.
3. The approval file (`.workflow/approvals/spec-approved.json`) is committed, so
   reviewers see who approved and which baseline.
4. Optional CI check: block code merges for a feature until its gate passes. CI
   has no global install, so it clones the kit (pin a commit) and calls the
   runner directly. Needs `jq` and `yq`. Example step:

   ```bash
   git clone --quiet <your agent-kit repo> /tmp/agent-kit
   git -C /tmp/agent-kit checkout --quiet <pinned commit>
   for ws in $(git diff --name-only origin/main... | grep -o '^specs/[^/]*' | sort -u); do
     /tmp/agent-kit/bin/agent-kit -w "$ws" gate
   done
   ```

**Example brief** (`specs/document-upload/brief/requirements.md`):

```markdown
# Brief

## Idea
Let users upload supporting documents to an open claim, so staff stop
asking for them by email.

## Users
Claimants (web, often on phones) and claims staff (desktop, internal).

## Must have
- Upload PDF, JPG or PNG, up to 10 MB each, up to 20 per claim.
- Staff see the files on the claim page and can mark each one "accepted" or "needs a new copy".
- Claimants get an email when a file needs a new copy.

## Existing code
Built in specs/foundation: claims API (src/api/claims), claim page (src/web/claim).
Files must go to the existing object store; see ADR-003 in specs/foundation/docs/02-design.md.

## Constraints
Release in 4 weeks, 3 developers. Files must be scanned for viruses before staff
can open them. Keep files for 7 years (company policy).

## Out of scope
Editing documents, OCR, bulk download.

## Links
Design: <link to design file>
```

---

## 3. Existing project, small, solo

You have a working app and want to add a feature with a plan.

**Folders:**

```
my-shop/                      # your app, unchanged
├── docs/                     # YOUR docs: agent-kit does not touch them
├── src/ …
├── agent-kit.toml            # added (workspace = "specs/gift-cards")
├── AGENTS.md  CLAUDE.md      # added, or your own files plus a kit block
└── specs/
    └── gift-cards/           # the workspace
        ├── brief/requirements.md
        ├── docs/01 … 03
        ├── tasks/
        └── .workflow/
```

**Run:**

```bash
cd ~/my-shop
agent-kit -w specs/gift-cards init    # plain "agent-kit init" refuses if docs/ or tasks/ hold your files
# write specs/gift-cards/brief/requirements.md, then run the steps.
# The first init set this workspace as the default, so no -w is needed:
agent-kit spec define-requirements    # ... through agent-kit review
```

The next feature gets its own folder: `agent-kit -w specs/wishlist init`, then
the steps with `-w specs/wishlist`.

**Example brief:**

```markdown
# Brief

## Idea
Sell gift cards in my shop. Customers keep asking for them.

## Users
Shop customers (web), and me as the admin.

## Must have
- Buy a gift card for 20, 50 or 100 SGD and send it by email.
- Use the code at checkout; any unused amount stays on the card.
- I can see all cards and their balance in the admin page.

## Existing code
Next.js shop with Stripe checkout (src/app/checkout, src/lib/stripe.ts).
Admin pages in src/app/admin. Postgres via Prisma (prisma/schema.prisma).
Do not change how normal orders work.

## Constraints
2 weeks of evenings. Stay on the current stack.

## Out of scope
Physical cards, cards in other currencies.

## Links
Stripe docs on promotion codes: <link>
```

The "Existing code" section matters most here. The spec stages read that code
and design the change around it: same stack, same patterns, and current
behavior kept safe by "Must not" criteria and regression tests.

Small feature? Case 6 (plan mode, then `build-task`) is often enough.

**Cost:** use the low-cost settings from case 1 if the feature is small.

---

## 4. Existing project, big, company (monorepo)

Many teams, many services, an existing `AGENTS.md`, CI and review rules.

**Folders (one `agent-kit.toml` per service):**

```
platform/                         # monorepo
├── AGENTS.md                     # company rules (kept)
├── services/
│   ├── payments/
│   │   ├── agent-kit.toml        # workspace = "specs/refunds-v2"
│   │   ├── AGENTS.md  CLAUDE.md  # added for this service, with the kit block
│   │   ├── specs/
│   │   │   ├── refunds-v2/       # one workspace per feature
│   │   │   └── payout-limits/
│   │   └── src/ …
│   └── notifications/
│       ├── agent-kit.toml        # its own settings and workspaces
│       └── …
└── docs/                         # company docs: agent-kit does not touch them
```

One `agent-kit.toml` per service keeps each team's settings
apart. `agent-kit` finds the nearest `agent-kit.toml` above the folder
you run it in. If one team owns the whole repo, one `agent-kit.toml` at the root
also works, with workspaces like `specs/payments/refunds-v2`.

**Run:**

```bash
cd ~/platform/services/payments
agent-kit -w specs/refunds-v2 init
# write specs/refunds-v2/brief/requirements.md, then run the steps:
agent-kit spec define-requirements    # ... through agent-kit review
# the feature owner approves; CI runs the gate (see case 2)
```

**Settings:** as in case 2, plus:

- `max_budget_usd`: set a limit per Claude call so costs stay known.
- `[models]`: use the model names your company account allows.

**Company notes:**

- Never put real customer or patient data, secrets or keys in a brief. Use
  made-up examples. Briefs, specs and logs are stored as files and committed.
- Your existing `AGENTS.md` keeps its content. The kit adds one managed block.
  Its gate rule covers only agent-kit tasks; other work in the repo is not blocked.
- Reviewer agents are read only in Claude Code and in `agent-kit review`. In Codex
  it is only an instruction: the session's sandbox decides. While a step runs,
  writes outside the workspace are blocked.
- In normal sessions the guard is off unless you add it (next section).

---

## 5. Small change in any project

No pipeline, no init, no workspace, no gate. The global install already made the
skills available everywhere. Pick one skill and give it the facts. These skills
find the test and build commands in your AGENTS.md, CLAUDE.md, README, build
scripts or CI.

| Problem | Skill | Example prompt |
|---------|-------|----------------|
| Something is broken | `fix-bug` | `/fix-bug Checkout returns 500 when the cart is empty. Steps: log in, empty the cart, click Pay. Error from the server log: <paste>` |
| Code works but is hard to change | no kit skill: ask, or use the built-in `/simplify` | `src/billing/invoice.ts repeats the tax math in 3 functions. Make adding a new tax rate easy. No behavior change.` (the engineering rules keep tests green and expected values unchanged) |
| It is too slow or costs too much | no kit skill: give the target and how to measure | `GET /orders takes 1.8 s at p95 with 10k orders. Target: 300 ms. Measure with: npm run bench:orders. Keep a change only if the numbers show it.` |
| A reviewer left comments | no kit skill: ask | `Fix the review comments above on this branch. Decline wrong ones with evidence.` |
| You want a second opinion on a change | `code-reviewer` agent (against a task), or the built-in `/code-review` (bug hunt) | `Use the code-reviewer agent to review this branch against plans/orders-csv-export.md. Give it the full diff against main.` |

In Codex, use `$fix-bug`.

---

## 6. New feature or idea: talk it through first

No pipeline, no init. Use it when you have a new feature, a new requirement or
just an idea, and want to agree how to do it before any code is written.

Use Claude Code's plan mode (`/plan ...`, or Shift+Tab). Claude reads the code,
asks you questions and shows a plan. It edits nothing until you approve the plan.
Ask it to save the approved plan in the project so `build-task` can read it.

```
/plan Users want to export their orders as CSV from the orders page. Save the approved plan in plans/.
```

```
/plan Idea: email users when a saved cart is 3 days old. Not sure it is worth it yet.
```

In Codex, ask it to plan first and to wait for your yes.

After you approve, build from the plan (see [Build prompts](#build-prompts)):

```
/build-task plans/orders-csv-export.md
```

Use the pipeline (cases 1 to 4) instead when the work needs independent reviews
and a formal approval: a new product, a feature of several days or more, or a
team that signs off on specs. Plan mode is one person agreeing a plan with Claude.

More uses:

- Too big for one plan? Ask Claude to write the agreed plan as the brief for
  specs/<feature>, then run the pipeline from `agent-kit spec define-requirements`.
- An approved plan with many steps: `plan-tasks` can split it into task files
  (`/plan-tasks plans/orders-csv-export.md`).

---

## Build prompts

After `agent-kit gate` passes, build one task at a time, in task number order.
Use the task folder path (inside the workspace).

**1. Build a task**

```
/build-task specs/gift-cards/tasks/002-buy-card
```

It builds test-first, then starts a fresh `code-reviewer` subagent on its diff,
fixes the valid findings and declines wrong ones with evidence, for up to 3 review
rounds. Its report lists each finding as FIXED, DECLINED or NEEDS_DECISION.

**2. Read the report**

- `NEEDS_DECISION` or `BLOCKED`: the spec is wrong or unclear. Do not let it guess:
  fix the brief or docs, then run `agent-kit plan`, `agent-kit check` and
  `agent-kit review` again, and approve the new baseline.
- "review not run" (for example, in Codex): ask for the review yourself:

  ```
  Use the code-reviewer agent to review task specs/gift-cards/tasks/002-buy-card.
  Give it the full diff against main including work not yet committed (git diff main),
  the content of new files (git status --short lists them), the task file, and the
  contracts in specs/gift-cards/docs/02-design.md.
  ```

  `git diff main...HEAD` (three dots) shows commits only. Before you commit, it is
  empty, so use `git diff main` (two dots) as above.

Then commit and go to the next task.

## Optional: guard in normal sessions

The global install does not change your settings. So the guard hook runs only
inside `agent-kit` steps. In your normal Claude Code sessions, the `AGENTS.md`
rules still tell agents not to approve or touch `.workflow/`, but nothing
enforces it. For team and company work you can turn the guard on for all your
Claude Code sessions. Add this to `~/.claude/settings.json` (use your kit path):

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Write|Edit|MultiEdit|NotebookEdit|Bash",
      "hooks": [{ "type": "command", "command": "\"$HOME/tools/agent-kit/hooks/guard.sh\"" }]
    }]
  }
}
```

Outside a step it only blocks writes to any `.workflow/state/` or
`.workflow/approvals/` folder, and shell commands that mention those folders,
`agent-kit approve` or `approve.sh`. Other projects are not affected unless they
use those names.

## Tips for writing a brief

- Use your own words. Rough notes are fine; the documents list the open questions,
  and Claude can ask them or help you write the brief.
- Say who uses it, what they must be able to do, and why.
- Give numbers instead of "fast", "secure" or "easy" when you know them.
- Fill in "Existing code" for an existing project: name the folders and the
  behavior that must not change.
- Write the limits: deadline, team size, required tech, rules (contest, legal,
  security, company policy).
- Say what is out of scope. It stops the specs from growing.
- No secrets, keys or real personal data.
