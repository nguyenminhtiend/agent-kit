# Use cases

Install agent-kit once, globally. Then use it in any project: new or existing,
small or big, solo or company. This page shows, for five common cases, what the
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
| `~/.claude/agents/`, `~/.codex/agents/` | the reviewer agents and `code-reviewer` |
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
agent-kit spec discover               # brief            -> docs/01-requirements.md
agent-kit spec define-product         # + docs/01        -> docs/02-prd.md
agent-kit spec design-ux              # + docs/02        -> docs/03-ux-design.md
agent-kit spec design-architecture    # + docs/03        -> docs/04-architecture.md
agent-kit spec design-technical       # + docs/04        -> docs/05-technical-spec.md
agent-kit spec validate-feasibility   # + docs/05        -> docs/06-validation.md
# B. review (exit 2 = blocking findings)
agent-kit review                      # docs/01-06       -> .workflow/reviews/round-N/summary.json
agent-kit repair                      # only after exit 2, then review again
# C. plan
agent-kit plan                        # docs/01-06       -> docs/07 + tasks/
agent-kit readiness                   # docs + tasks     -> docs/08 (exit 2 = NOT_READY)
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

Rule of thumb: use the pipeline when the work needs a plan (a new product, or a
feature of a few days or more). For a change you can explain in two sentences,
skip the pipeline and use one skill (case 5).

## The parts, in short

| Part | What it does | Who starts it |
|------|--------------|---------------|
| `agent-kit spec <stage>`: spec skills `discover`, `define-product`, `design-ux`, `design-architecture`, `design-technical`, `validate-feasibility` | Each stage writes one of `docs/01` to `docs/06` | you, one command per stage |
| `agent-kit review`: reviewer agents `product-reviewer`, `architecture-reviewer`, `qa-reviewer` | One review round of the specs, read only | you |
| `agent-kit repair`: skill `repair-specs` | Fixes the blocking findings of the last review | you, after `review` exits 2 |
| `agent-kit plan`: skill `plan-tasks` | Writes `docs/07` and `tasks/` | you |
| `agent-kit readiness`: skill `assess-readiness` | Writes `docs/08` and the READY / NOT_READY verdict | you |
| `agent-kit approve` | You accept the specs and tasks | you, in a terminal |
| `agent-kit gate` | Says if coding may start (exit 0 = yes) | you or CI |
| Build skills: `build-task`, `fix-review`, `fix-bug`, `refactor`, `optimize` | Write and fix code | you, in Claude Code or Codex |
| `code-reviewer` agent | Reviews a code change, read only | you, in Claude Code or Codex |

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
├── docs/01 … 08           # written by the steps
├── tasks/001-setup/task.md
│   tasks/002-add-expense/task.md …
└── .workflow/             # review results, readiness, approval, logs
```

**Run:**

```bash
mkdir trip-splitter && cd trip-splitter && git init
agent-kit init
# write brief/requirements.md (delete the template marker line), then run
# the steps one by one (see "The steps" above):
agent-kit spec discover
agent-kit spec define-product
# ... and so on, until:
agent-kit readiness
```

**Low-cost settings** in `agent-kit.toml` (`opus` gives better specs; `sonnet` costs less):

```toml
[models]
spec = "sonnet"
review = "sonnet"
plan = "sonnet"

[limits]
max_budget_usd = 2      # per Claude call (each step makes one; review makes one per reviewer)

[review]
agents = ["product-reviewer", "qa-reviewer"]   # add "architecture-reviewer" if it has a backend
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

1. Read `docs/08-readiness.md`. If it says `NOT_READY` (`readiness` exits 2),
   answer the open decisions: add your answers to the brief and run the steps
   again from `agent-kit spec discover`.
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
│   │   ├── docs/01 … 08
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
agent-kit spec discover                # ... through agent-kit readiness
# a tech lead reads docs/ and tasks/, then:
agent-kit approve

# later, a new feature (not the default workspace, so add -w to every step):
agent-kit -w specs/document-upload init
# write its brief, then:
agent-kit -w specs/document-upload spec discover   # ... through readiness
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
agents = ["product-reviewer", "architecture-reviewer", "qa-reviewer"]
block_on = ["critical", "major"]

[verify]
test = "npm test"
lint = "npm run lint"
typecheck = "npm run typecheck"
build = "npm run build"
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
Files must go to the existing object store; see ADR-003 in specs/foundation/docs/04-architecture.md.

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
        ├── docs/01 … 08
        ├── tasks/
        └── .workflow/
```

**Run:**

```bash
cd ~/my-shop
agent-kit -w specs/gift-cards init    # plain "agent-kit init" refuses if docs/ or tasks/ hold your files
# write specs/gift-cards/brief/requirements.md, then run the steps.
# The first init set this workspace as the default, so no -w is needed:
agent-kit spec discover               # ... through agent-kit readiness
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
behavior kept safe by "Must not" checks and regression tests.

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

One `agent-kit.toml` per service keeps each team's settings and `[verify]`
commands apart. `agent-kit` finds the nearest `agent-kit.toml` above the folder
you run it in. If one team owns the whole repo, one `agent-kit.toml` at the root
also works, with workspaces like `specs/payments/refunds-v2`.

**Run:**

```bash
cd ~/platform/services/payments
agent-kit -w specs/refunds-v2 init
# write specs/refunds-v2/brief/requirements.md, then run the steps:
agent-kit spec discover               # ... through agent-kit readiness
# the feature owner approves; CI runs the gate (see case 2)
```

**Settings:** as in case 2, plus:

- `[verify]`: copy the exact commands your CI runs for this service.
- `max_budget_usd`: set a limit per Claude call so costs stay known.
- `[models]`: use the model names your company account allows.

**Company notes:**

- Never put real customer or patient data, secrets or keys in a brief. Use
  made-up examples. Briefs, specs and logs are stored as files and committed.
- Your existing `AGENTS.md` keeps its content. The kit adds one managed block.
  Its gate rule covers only agent-kit tasks; other work in the repo is not blocked.
- Reviewer agents are read only. While a step runs, writes outside the workspace are blocked.
- In normal sessions the guard is off unless you add it (next section).

---

## 5. Small change in any project

No pipeline, no init, no workspace, no gate. The global install already made the
skills available everywhere. Pick one skill and give it the facts. These skills
read the `[verify]` commands from `agent-kit.toml` if the project has one; if
not, they find them in your README, build scripts or CI.

| Problem | Skill | Example prompt |
|---------|-------|----------------|
| Something is broken | `fix-bug` | `/fix-bug Checkout returns 500 when the cart is empty. Steps: log in, empty the cart, click Pay. Error from the server log: <paste>` |
| Code works but is hard to change | `refactor` | `/refactor src/billing/invoice.ts repeats the tax math in 3 functions. Make adding a new tax rate easy. No behavior change.` |
| It is too slow or costs too much | `optimize` | `/optimize GET /orders takes 1.8 s at p95 with 10k orders. Target: 300 ms. Measure with: npm run bench:orders` |
| A reviewer left comments | `fix-review` | `/fix-review Fix the findings from the review above in the change on this branch.` |
| You want a second opinion on a change | `code-reviewer` agent | `Use the code-reviewer agent to review this branch. Give it the full diff against main.` |

In Codex, use `$fix-bug`, `$refactor`, and so on.

---

## Build prompts

After `agent-kit gate` passes, build one task at a time, in task number order.
Use the task folder path (inside the workspace).

**1. Build a task**

```
/build-task specs/gift-cards/tasks/002-buy-card
```

**2. Review it with a fresh agent** (the reviewer cannot run git, so give it the diff)

```
Use the code-reviewer agent to review task specs/gift-cards/tasks/002-buy-card.
Give it the full diff of this branch against main (git diff main...HEAD), the
task file, and the contracts in specs/gift-cards/docs/05-technical-spec.md.
```

**3. Fix the findings**

```
/fix-review Fix the code-reviewer findings above for specs/gift-cards/tasks/002-buy-card.
```

Repeat 2 and 3 until the review passes, then commit and go to the next task.
If a skill stops with `BLOCKED` because the spec is wrong or unclear, do not let
it guess: fix the brief or docs, then run `agent-kit review`, `agent-kit plan` and
`agent-kit readiness` again, and approve the new baseline.

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

- Use your own words. Rough notes are fine; the pipeline asks the questions.
- Say who uses it, what they must be able to do, and why.
- Give numbers instead of "fast", "secure" or "easy" when you know them.
- Fill in "Existing code" for an existing project: name the folders and the
  behavior that must not change.
- Write the limits: deadline, team size, required tech, rules (contest, legal,
  security, company policy).
- Say what is out of scope. It stops the specs from growing.
- No secrets, keys or real personal data.
