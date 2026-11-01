# Strict review of skills and agents

Date: 2026-11-01. Reviewer: Claude (Opus 5.5), asked to be strict and fair.

Scope: the 15 skills, 4 agents and `rules/engineering.md`, judged against the six
cases in [USE-CASES.md](USE-CASES.md). I read every file in full, plus the runner
code that calls them (`lib/spec.sh`, `lib/review.sh`, `lib/engine.sh`,
`install.sh`). No live `claude -p` run was done, so nothing here is measured
proof. It is a careful reading.

An earlier review is in [SKILLS-AND-AGENTS-REVIEW.md](SKILLS-AND-AGENTS-REVIEW.md).
I wrote this one without leaning on it. Where we agree or disagree is at the end.

---

## 1. Short verdict

The kit is well made. The skills are short, clear and careful. The build skills
(`fix-bug`, `fix-review`, `optimize`, `build-task`) and `code-reviewer` are as good
as the best public kits in 2026. `plan-idea` is the most useful skill for everyday work.

The weak part is not the writing. It is the **shape of the pipeline**:

1. **Too many documents.** Eight documents and 11+ model calls before you can
   build. Popular spec tools in 2026 use three (requirements, design, tasks).
2. **Questions come too late.** `discover` must guess. Its open questions travel
   through 10 more calls before `readiness` finally says NOT_READY and sends you
   back to the start.
3. **No way to check facts.** Spec stages only get `Read, Write, Edit, Glob, Grep`.
   No web, no shell. So prices, limits and versions stay `unverified` forever, and
   they turn into open decisions that block readiness.
4. **The two front doors don't meet.** `plan-idea` (case 6) can't feed the pipeline
   (cases 1–4), and `plan-tasks` can't split a `plan-idea` plan into tasks.
5. **No proof that any skill helps.** The tests use a fake Claude. They check the
   runner, not the skills.

Two things the kit already does right, and the 2026 research backs them:

- The runner loads each skill's text directly. Studies show skills help most when
  they are loaded for the agent, and much less when the agent must find them (9.2).
- The skills are short, focused and hand-written. Focused skills beat big bundles,
  and model-written skills made results slightly worse (9.2).

So: **fix the flow before adding many skills.** Add only 3–4 new skills, and drop
or merge 3.

---

## 2. How I judged

For each skill and agent I asked six questions:

| # | Question | Why it matters in 2026 |
|---|----------|------------------------|
| 1 | Does it beat a strong model with **no** skill? | Frontier models already know TDD, debugging and refactoring. A skill must add a method, a contract or knowledge they skip. |
| 2 | Which use case needs it, and how often? | A skill no case uses is dead weight to maintain. |
| 3 | What does it cost? | Model calls, tokens, time, and the user's attention. |
| 4 | Does it overlap another skill, agent or a built-in command? | Overlap means double cost and mixed results. |
| 5 | Could code do it better? | Counting IDs or checking numbering is a job for a script, not a model. |
| 6 | Is there any evidence it works? | Today: none, for every skill. |

Score: **5** = clear, large gain; **3** = useful in some cases; **1** = a strong
model does it as well without the skill.

---

## 3. Scorecard

| Skill / agent | Cases | Score | Verdict | One-line reason |
|---|---|:-:|---|---|
| `plan-idea` | 6 (and could serve 1, 3) | **5** | Keep, small fixes | Best everyday skill. Facts first, one question at a time, explicit yes. |
| `code-reviewer` (agent) | 1–6 | **5** | Keep, fix the input | Fresh-context review against the task and contracts. Built-in `/code-review` does not check the spec. |
| `fix-bug` | 5 | **4** | Keep | "Red loop before any fix" stops the guess-and-patch habit. |
| `fix-review` | 1–6 | **4** | Keep | Valid / decline / needs-decision verdicts stop polite agreement with bad advice. |
| `optimize` | 5 | **4** | Keep | Baseline, noise and "no gain is a valid result". Models skip measuring without it. |
| `build-task` | 1–4, 6 | **4** | Keep, relax 2 rules | Good contract and proof report. Two rules hurt in big repos (see 5.3). |
| `design-technical` | 1–4 | **4** | Keep | Contracts, errors, idempotency, retries: what builders need most. |
| `plan-tasks` | 1–4 | **4** | Keep, fix 2 issues | Strong task files. Has a self-contradiction and can't take a `plan-idea` plan. |
| `design-architecture` | 1–4 | **3** | Keep, give it evidence | Good "start simple" rules. Weak because it can't check any fact. |
| `architecture-reviewer` | 2, 4 | **4** | Keep, make optional | Valuable with a backend, data or integrations. Wasted on a static site or CLI. |
| `qa-reviewer` | 1–4 | **3** | Keep, trim overlap | Good testability focus. Overlaps `product-reviewer` on acceptance criteria. |
| `product-reviewer` | 1–4 | **3** | Keep, trim overlap | Good brief → REQ → FR tracing. Same overlap. |
| `repair-specs` | 1–4 | **3** | Keep | Needed only because of the review loop, but does that job well. |
| `discover` | 1–4 | **3** | Change | Good output (stable REQ IDs). Bad position: it guesses instead of asking. |
| `define-product` | 1–4 | **2** | Merge for small work | For small and medium work it repeats `discover` with a second ID layer (REQ → FR). |
| `assess-readiness` | 1–4 | **2** | Split: script + small skill | Most of its checklist is counting and grepping. A script does that exactly. |
| `design-ux` | 1–4 | **2** (UI: 4) | Make optional | Strong for real UIs. For a CLI, API or backend it is a document full of "n/a". |
| `validate-feasibility` | 1–4 | **2** | Drop as a fixed stage | An LLM guessing effort from text, with no evidence. Its checks are done again by `architecture-reviewer` and `assess-readiness`. |
| `refactor` | 5 | **2** | Keep as optional, don't invest | Mostly general advice a strong model knows. Built-in `/simplify` covers much of it. |
| `rules/engineering.md` | all | **4** | Keep | Short, clear, Karpathy-style. Always loaded, so its size matters, and it is small. |

---

## 4. The skills that are not really useful (the strict list)

"Not useful" here means **low value for its cost**, not "badly written". All of
these are written well.

### 4.1 `validate-feasibility`: drop it as a fixed stage

- It asks a model to estimate days and team fit from documents. Models are poor at
  effort estimates, and the skill itself says "use only what the docs say". So the
  numbers are guesses with a confident format.
- Its useful parts already live elsewhere:
  - `architecture-reviewer` check 5 reviews the feasibility verdict.
  - `assess-readiness` checks feasibility, cuts and spikes again.
  - `design-architecture` already lists `unverified` facts as risks.
- It cannot check any fact (no web, no shell). So "riskiest unknowns" stay unknown.
- **Do instead:** move "spikes for the riskiest unknowns" into `plan-tasks` (it
  already puts spikes first) and "required cuts vs contingency cuts" into
  `design-architecture` Risks. Keep the skill only as an opt-in stage for hard
  deadlines (contests, launch dates), where a scope-vs-time check pays off.

### 4.2 `design-ux` for products without a real UI: make it optional

- The skill handles CLI and API products honestly ("never invent a GUI"). But the
  runner still forces the stage: `design-architecture` refuses to run until the UX
  document exists. A CLI tool pays for a full model call that writes mostly "n/a".
- **Do instead:** let `agent-kit.toml` list the stages a workspace uses, and let
  later stages treat a skipped document as "none". Keep `design-ux` fully for
  products with screens. There, it is good (states, copy, WCAG 2.2 checks).

### 4.3 `define-product` as a separate step for small work: merge it

- `discover` writes REQ-001…; `define-product` turns each into FR-001… with a
  traceability table between them. In a small or medium feature this is close to
  one-to-one. You pay a model call, a document and a review area for a renaming.
- Separate documents make sense when business requirements and product design are
  owned by different people (case 2, 4). They don't for case 1 and 3.
- **Do instead:** for a "light" profile, one skill writes one requirements
  document with goals, users, FRs, NFRs, acceptance criteria and open decisions.
  Keep the two-step version for the "full" profile.

### 4.4 `assess-readiness`: most of it should be a script

- Checklist items like "every FR has a task", "every ID a task names exists",
  "Depends on points lower", "no TODO/TBD", "seven sections in each task file"
  are exact checks. A model doing them by reading and grepping will sometimes
  miss one, and costs a full call each time.
- The part only a model can do is the **cold start check**: "read the 3 riskiest
  tasks with only their linked docs; would a builder have to guess?" That is real
  value.
- **Do instead:** add a deterministic check (bash + `rg`/`jq`, like the rest of the
  runner) for the mechanical items. Feed its result to a much shorter
  `assess-readiness` that does the cold start check and gathers open decisions.

### 4.5 `refactor`: keep, but it is the weakest standalone skill

- Its moves list (extract, guard clauses, inline wrappers, deletion test) is
  textbook. A 2026 frontier model already knows it.
- Claude Code now ships `/simplify` (reviews changed code and applies clean-ups).
- Its real value is the **safety contract**: tests green before and after every
  move, no expected value may change, characterization tests first. That is worth
  keeping, and it costs nothing while unused (manual-only skills load nothing).
- **Do instead:** keep it as is. Don't spend more time on it. If you want to shrink
  the catalog, its safety contract could become 3 lines in `rules/engineering.md`.

---

## 5. Problems inside the good skills

These are real bugs or contradictions. Each is small to fix.

### 5.1 The review handoff can send an empty diff

[USE-CASES.md, Build prompts](USE-CASES.md#build-prompts) tells the user to give
the reviewer `git diff main...HEAD`, and to commit **after** the review passes.
`main...HEAD` compares commits only. Uncommitted work is not in it. So the first
review of a task can get an empty or partial diff. `code-reviewer` handles this
well ("review input missing"), but the user loses a round.

**Fix:** a small helper that writes the full change to a file: committed changes
since the merge base, plus staged, unstaged and new files, with a file list. Use the
same helper for Claude Code and Codex. (A Claude-only option: give the agent `Bash`
plus an agent-scoped `hooks` rule that allows only read-only git commands. The
`tools:` field cannot hold patterns like `Bash(git diff:*)`.)

### 5.2 `plan-idea` contradicts itself

- Rules: "The user may stop the interview any time: mark open items as your calls."
- Done when: "Every choice that changes scope, a contract, data, security or
  acceptance criteria came from the user."

Both can't be true when the user stops early. **Fix:** "came from the user, or the
user stopped early and it is marked as your call in Decisions."

Also, "on a big choice 'whatever you think' is no answer" is a good default, but
add: "if they repeat it, decide, mark it as your call, and say what it changes."
Otherwise the skill can loop on a user who really wants to delegate.

### 5.3 `build-task` has two rules that hurt in big repos

- "Run the full test suite first; if it fails, stop and report." In a monorepo the
  full suite can take very long, and may have known failures that have nothing to
  do with the task. **Fix:** run the tests around the task's area first; record
  any failure that exists before you start, and stop only if it touches the task.
- "Delete code written before its test." This is the strict TDD rule from
  superpowers. It wastes good work and agents often ignore it anyway.
  **Fix:** "Code written before its test: write the test, then break the code on
  purpose to see the test go red, then restore it."
- It never mentions git. USE-CASES says "commit and go to the next task", but no
  skill says how (one commit per task, message with task and REQ IDs).

### 5.4 `plan-tasks` contradicts itself, and only accepts the full spec set

- Step 2: "Foundations first: schema, then API, then UI." Step 3: "Slice
  vertically." These pull in opposite directions. **Fix:** delete step 2's layer
  order; keep the "small contract task first when several tasks share a shape"
  exception from step 3.
- `plan-idea` ends with "offer the next step (build it, or split it into tasks)",
  but `plan-tasks` reads only the six spec documents. **Fix:** let `plan-tasks`
  accept one agreed plan as input. Then case 6 can grow into several tasks without
  the full pipeline.

### 5.5 `discover` mixes two kinds of facts

- Step 1: what you read in existing code is fact. Step 2: "Only the brief is fact."
- **Fix:** name them: **business facts** come only from the brief; **code facts**
  (current behavior, stack) come from the code with a path. Everything else is an
  assumption.

### 5.6 The spec stages cannot check facts

`lib/spec.sh` gives spec stages `--tools "Read,Write,Edit,Glob,Grep"`. That is a
safe choice. But `design-architecture` is then told to compare real options and
mark every price, limit and version `unverified`. Those become open decisions,
and readiness can't pass until a person goes and checks them by hand. See the new
`research-unknown` skill in section 7.

### 5.7 All skills are manual-only, so their descriptions do almost nothing

Every skill has `disable-model-invocation: true`. In Claude Code this keeps the
description out of the model's context, and the model can never call the skill.
That is right for pipeline skills (the runner loads them) and for `plan-idea` and
`build-task` (heavy, should be a choice).

For `fix-bug` and `fix-review` it is a missed chance. In case 5 the user types
"checkout returns 500"; a strong description would let Claude pick `fix-bug` by
itself. If you turn one on, rewrite its description as "what + when", for
example: "Find and fix a bug's root cause with a failing test first. Use when
something is broken: an error, a failing test or build, or a bug report."

### 5.8 The three spec reviewers overlap

- `product-reviewer` check 4 and `qa-reviewer` check 1 both grade acceptance
  criteria and NFRs.
- `architecture-reviewer` check 5 grades the feasibility verdict, which
  `assess-readiness` grades again.

Some overlap is fine (two fresh views catch more). But measure it: count unique
valid findings per reviewer on a few real spec sets. For case 1 and 3, one
combined spec reviewer is likely enough.

### 5.9 Codex reviewers are only "read only" by instruction

`install.sh` (`gen_codex_agents`) writes Codex agents with name, description and
instructions only. The `tools: Read, Grep, Glob` line is lost. So in Codex,
"read only" is a request, not a limit. The current Codex docs confirm there is no
per-agent tool limit (see 9.5). Say this in the README "Safety" section.

### 5.10 Test for over-verification

`rules/engineering.md` and `build-task` ask for fresh proof for every claim, the
full suite at the end, and (in `plan-idea`) a fresh subagent to check the plan.
For headless runs this is right. But Anthropic's Opus 5 guide warns that
"verify with a subagent" style instructions can make the model check too much,
which costs time and tokens. Don't remove these rules on a guess. Measure them
in the evals (section 7, Tooling): same task, with and without the extra checks.

### 5.11 `refactor` misses the part people use most

The popular refactor-type skill in 2026 is mattpocock's
improve-codebase-architecture: it *finds* what is worth improving. The kit's
`refactor` assumes you already know the problem. If you keep it, its value is the
safe procedure, not the finding.

---

## 6. Fit with the six use cases

| Case | What works today | What is missing or too heavy |
|---|---|---|
| **1. New, small, solo** | All skills exist. Low-cost settings help. | 8 documents and 11+ calls for a weekend app. Guessed answers in `discover`. A light profile (3 documents) plus an up-front interview would fit far better. |
| **2. New, big, team** | Full pipeline, hash gate, approval file, CI gate. This is where the kit shines. | No way to resolve unknowns with evidence. No path to update specs after build ("living specs"), so docs go stale after the first release. |
| **3. Existing, small, solo** | Workspaces keep your own `docs/` safe. "Existing code" lines in skills. | Rebuilding a PRD for one feature is heavy. Most such features fit case 6 better. No codebase map shared by all stages, so each stage re-reads the code. |
| **4. Existing, big, monorepo** | Per-service `agent-kit.toml`, CI gate, read-only reviewers. | No change-impact step (who uses the contract you change). No privacy/security review for sensitive data at spec time. Full suite rule in `build-task` (5.3). |
| **5. Small change** | `fix-bug`, `optimize`, `fix-review` are strong. | `refactor` adds little. Manual-only means the user must know the names. |
| **6. Talk it through** | `plan-idea` is excellent. | Can't split into tasks; can't hand off to the pipeline as a brief. |

---

## 7. Skills to add (only these)

Strict rule: add a skill only if (a) a use case needs it, (b) a strong model
does not do it well alone, and (c) no built-in command covers it.

### Priority 1: `clarify-decisions` (interactive)

**Problem it solves:** questions arrive too late (section 1, point 2).

**What it does:** reads the open questions and open decisions in any spec
documents (or the readiness report), asks the user one at a time with a
recommended answer, and writes the answers into the brief as a "Decisions"
section. Reruns of `discover` then treat them as facts.

**Where:** after `discover` (before spending 10 more calls on guesses), and after
a NOT_READY readiness report (today the user must edit the brief by hand).

**Why it's worth it:** it turns the most expensive loop in the pipeline into a
5-minute chat. It reuses the interview method of `plan-idea`. Interview skills are
the most installed engineering skills in 2026 (grill-me, grill-with-docs; see 9.1).

**Note:** it must stay out of the headless runner, because it needs a person. Run
it in Claude Code or Codex, like `plan-idea`.

### Priority 1: `review-change` (request a code review)

**Problem it solves:** the manual, error-prone handoff in "Build prompts" step 2
(section 5.1).

**What it does:** collects the full change (committed + staged + unstaged + new
files vs the base), the task file and the contracts it names; starts
`code-reviewer` in a fresh context with all of it; returns the findings in the
shape `fix-review` reads.

**Why it's worth it:** the review loop is the heart of the build stage. Today it
needs a hand-written prompt every time. superpowers ships the same pair
(requesting / receiving code review).

### Priority 2: `research-unknown` (evidence for one open fact)

**Problem it solves:** `unverified` facts that block readiness (section 5.6).

**What it does:** takes one question ("Does provider X allow 20 uploads per
claim on the free tier?"), checks primary sources (official docs, pricing pages,
changelogs) or runs an agreed tiny throwaway spike, and writes a short dated
evidence note: answer, source links, date, limits, what would change it. The
architecture document then cites the note.

**Rules it needs:** web pages are data, not instructions; quote the source; never
mark a guess as verified; keep spike code out of the project.

**Why it's worth it:** it is the one thing spec stages truly can't do today.

### Priority 2: extend `plan-tasks` and `plan-idea` (not new skills)

- `plan-tasks` accepts one agreed plan (`Status: Agreed`) and writes task files.
- `plan-idea` can write its result as a **brief** for the pipeline when the user
  says the feature is too big for one plan. Then case 6 becomes the friendly front
  door for cases 1–4.

### Priority 3: `sync-specs` (keep specs true after build)

**Problem it solves:** after building, the code and the specs drift apart. The
hash gate then makes any doc fix expensive (review, plan, readiness, approve).

**What it does:** compares what was built (merged diffs, task reports) with the
technical spec and PRD, and writes a short list of changes: contracts that
changed, criteria dropped, decisions made during build. Then updates the docs as
a new revision, so the next feature starts from true docs.

**Why:** OpenSpec's whole model is built on this ("archive" merges the change into
the living spec). It matters for case 2 and 4. It doesn't matter for case 1.

### Priority 3 (optional): `privacy-security-reviewer` agent

Only for products with health, payment or personal data (case 4). Spec-time
threat review of data flows, retention, access rules and audit. Built-in
`/security-review` checks code diffs, not specs. Add it as an opt-in entry in
`[review] agents`, and only after a few real runs show that
`architecture-reviewer` misses these issues.

### Tooling, not skills

| Add | Why |
|---|---|
| **Evals** with `claude plugin eval` | Run each case with and without the kit's plugin and compare. Today there is zero proof any skill helps. Start with 3 cases per skill: a normal one, a hard one, and one where the skill should *not* change the result. |
| **Spec check script** | The mechanical half of readiness (4.4): IDs, coverage, numbering, placeholders. Exact, free and instant. |
| **Change-collect script** | Used by `review-change` and CI (5.1). |
| **Plugin packaging** | A Claude Code plugin gives one install for skills, agents and hooks, a marketplace for teams, and names like `/agent-kit:fix-bug` that can't clash with other kits. Generic names like `discover`, `refactor` and `optimize` are likely to clash. Keep the symlink install for Codex. |

---

## 8. What NOT to add

Being strict also means saying no. These are popular in other kits, but don't
belong here:

| Skill idea | Why not |
|---|---|
| TDD skill | Already inside `build-task`, `fix-bug` and `fix-review`. |
| Git worktrees skill | Claude Code has worktree support built in (worktree isolation for agents). |
| Generic code review / security review | Built in: `/code-review` (with levels and `--fix`) and `/security-review`. The kit's `code-reviewer` is worth keeping only for its spec and contract checks. |
| Simplify / clean-up | Built in: `/simplify`. |
| AGENTS.md / CLAUDE.md writer | Built in: `/init`. Point users to it to fill the "Commands" TODO in the template. |
| Run / verify the app | Built in: `/run` and `/verify`. A `verify-feature` skill would mostly wrap them. |
| Persona agents (frontend-dev, backend-dev, DBA…) | The 2025 "100 agents" trend. Low value: one strong model with a clear task beats role-play. |
| Skill-writing skill | Anthropic's skill-creator and superpowers' writing-skills already exist. |
| Session handoff skill | Popular (mattpocock's handoff), but here task files and `build-task` reports already carry the state from one session to the next. |
| Codebase map / onboarding skill | Use `/init` to write the project map into AGENTS.md once; every skill already reads AGENTS.md. |
| Release / migration skill | Not needed until the build stage exists and real releases happen. |

---

## 9. The 2026 skills landscape, and where this kit stands

Research done on 2026-11-01. Star counts are from that day. Links are in section 12.

### 9.1 What the field looks like

| Project | Stars | What it is | Shape |
|---|--:|---|---|
| obra/superpowers | ~310k | Engineering workflow skills | brainstorming → writing-plans → executing-plans / subagent-driven-development; TDD, systematic-debugging, verification-before-completion, requesting + receiving code review, git worktrees, finishing a branch, writing-skills |
| mattpocock/skills | ~308k | Small, sharp skills | grill-me, grill-with-docs (the most popular), to-spec, to-tickets, tdd, diagnosing-bugs, research, prototype, code-review, pr, handoff, improve-codebase-architecture |
| affaan-m/everything-claude-code (ECC) | ~294k | Huge bundle | 71 agents, 314 skills, 98 commands, plus a skill security scanner |
| forrestchang/andrej-karpathy-skills | ~228k | One skill, 4 rules | Think first, simplicity, surgical changes, goal-driven work |
| anthropics/skills | ~186k | Official examples | Office files, skill-creator, frontend-design, web app testing |
| github/spec-kit | ~145k | Spec-driven tool | constitution → specify → plan → tasks → implement; bug and assess extensions |
| addyosmani/agent-skills | ~112k | 25 skills in 6 phases | Define, Plan, Build, Verify, Review, Ship; 4 reviewer agents |
| Fission-AI/OpenSpec | ~73.5k | Change-based specs | explore → propose → apply → archive (merges the change into living specs); verify, onboard |
| BMAD method | ~55k | Heavy role-based method | Many role agents; v7, built on skills, expected mid-November 2026 |
| Kiro (AWS) | n/a | IDE with specs | requirements.md (or bugfix.md) → design.md → tasks.md; Feature, Bugfix and Quick Spec types |

On the skills.sh install chart, the top engineering skills are interview skills
(grill-me 1.5M installs, grill-with-docs 1.3M), then
improve-codebase-architecture, tdd and handoff (1.1–1.2M each).

**What this tells us:**

- **Interview-first wins.** The most installed skills do what `plan-idea` does.
  This supports `plan-idea` as the main door and supports `clarify-decisions`.
- **Three documents is the norm.** Kiro, Spec Kit and OpenSpec all use about three
  main files (requirements or spec, design or plan, tasks). This kit uses eight.
  BMAD is the only popular method as heavy as this kit.
- **Separate light paths are normal.** Kiro has Bugfix and Quick Spec types.
  Spec Kit has bug and assess extensions. A light profile here matches the field.
- **Living specs are a real pattern.** OpenSpec's `archive` step is the model for
  `sync-specs`.
- **Big bundles are not the goal.** ECC has 314 skills. The research below says
  focused skills beat big bundles.

### 9.2 What the evidence says about skills

- **Curated skills help, on average.** SkillsBench (arXiv v4, 14 June 2026): pass
  rate went from 33.9% to 50.5% with curated skills. Focused skills (3 parts or
  fewer) beat long, complete bundles. The NeurIPS 2026 version: +16.4 points, but
  **18 of 84 tasks got worse**, and **skills the model wrote for itself scored
  −1.3 points**.
- **Gains shrink when the agent must find the skill.** Liu et al. (April 2026):
  Opus 4.6 scored 55.4% with curated skills loaded for it, 40.1% when it had to
  search a big pool for them, and 35.4% with no skills.
- **What this means for this kit:**
  - Good: the runner loads each skill's text directly. That is the "loaded for it"
    case, the one that works best. The skills are short and focused, which also matches.
  - Good: the kit's skills were written by hand from strong sources, not
    generated by a model.
  - Risk: about one task in five got *worse* with skills in SkillsBench. Without
    evals you can't know which of your 15 skills are in that group.

### 9.3 What experts warn about

- **Spec-driven development is "Assess", not "Adopt".** Thoughtworks Radar (Vol 34,
  April 2026) puts spec-driven development, Spec Kit, OpenSpec and Superpowers in
  Assess. It puts **"agent instruction bloat" in Caution**. Agent Skills is in Trial.
- **Too much markdown.** Birgitta Böckeler (martinfowler.com, October 2025) found
  Kiro a "sledgehammer to crack a nut" for a small bug, and said of Spec Kit's many
  files: "I'd rather review code than all these markdown files". This is the same
  risk as this kit's eight documents.
- **Prefer deterministic checks.** Böckeler's "harness engineering" article: use
  both guides (instructions) and sensors (checks), prefer checks that code runs,
  and run fast checks early. This supports moving half of `assess-readiness` into a script.
- **Every rule is an assumption about what the model can't do.** Anthropic (March
  2026) removed a planning step for Opus 4.6 because the model no longer needed it.
  Anthropic's Opus 5 prompting guide says instructions like "use a subagent to
  verify" can cause **over-verification**. Worth testing for the kit's
  heavy "verify everything" lines (see 5.10).
- **A separate evaluator beats self-grading.** Same Anthropic article. This supports
  the kit's fresh-context reviewers and the rule that `fix-review` can never pass itself.
- **Hooks for rules that must always hold.** Claude Code docs: a rule that must
  never break belongs in a hook, not in text. The kit already does this (`guard.sh`).

### 9.4 Skill authoring rules in 2026, and how the kit scores

| Rule (Anthropic, agentskills.io, Codex docs) | Kit |
|---|---|
| Add only what the model lacks: "Would the agent get this wrong without this instruction? If no, cut it." | Mostly yes. `refactor` and parts of `rules/engineering.md` repeat what a strong model knows. |
| Body under 500 lines / 5,000 tokens | Yes. 34–71 lines each. |
| Description says what it does **and when to use it** | No. Descriptions say only what. This matters only for skills you switch to auto use (5.7). |
| Put the most important rules at the top (after compaction only the first 5,000 tokens come back) | Fine, all skills are short. |
| Scripts for steps that must be exact | Not yet. Readiness tracing and the review diff should be scripts. |
| Write evals **before** long instructions; test with and without the skill | Missing. |
| One default, not a menu of options | Yes. Skills give one recommended path. |
| A "gotchas" section is often the most useful part | Partly. The "Rules" sections do this job. |

### 9.5 Codex reviewers: what the docs say now

The current Codex subagent docs say: custom agents have **no per-agent tool
allow or deny list**, and `sandbox_mode` or `approval_policy` in an agent file
**"don't override the parent configuration"**. In their words, instructions "can
ask an agent to avoid edits, but they don't create a separate read-only sandbox."

So in Codex the reviewers are read-only only if the parent session is read-only.
Older blog posts show a per-agent `sandbox_mode = "read-only"`; the current page
says this no longer works that way. Write this plainly in the README "Safety" section.

### 9.6 Skill safety

- Snyk (February 2026) scanned 3,984 public skills: 13.4% had a critical issue, and
  76 were malicious. Tessl says one in seven skills carries a critical risk.
- Liu et al. (January 2026): skills that bundle scripts were about twice as likely
  to be vulnerable.
- This kit is low-risk: it ships only its own, hand-written text skills and no
  third-party scripts. Keep it that way. When you add the spec check and
  change-collect scripts, put them in `lib/` with the runner, not inside skill folders.

---

## 10. What to do, in order

1. **Fix the small bugs** (one short session): the review diff (5.1), the
   `plan-idea` contradiction (5.2), the `plan-tasks` contradiction (5.4), the
   `discover` fact rule (5.5), the Codex "read only" note (5.9).
2. **Make evals** for 4 skills first: `plan-idea`, `fix-bug`, `build-task`,
   `code-reviewer`. With and without the skill, same model. Keep only what wins.
3. **Add a light profile**: stages to skip in `agent-kit.toml`; `design-ux` and
   `validate-feasibility` off by default; `discover` + `define-product` merged
   for light work; one spec reviewer.
4. **Add `clarify-decisions` and `review-change`.**
5. **Move readiness checks into a script**, and shrink `assess-readiness`.
6. **Add `research-unknown`.** Then let `plan-tasks` read agreed plans.
7. **Later, with real use:** `sync-specs`, the privacy reviewer, plugin packaging.

This keeps the catalog about the same size (15 → 15 or 16 skills), but each one
earns its place, and the light path costs a third of today's calls.

---

## 11. Compared with the earlier review

| Topic | Earlier review | This review |
|---|---|---|
| Review diff misses uncommitted work | Found it | Agree |
| Codex read-only is instruction only | Found it | Agree |
| No evals | Found it | Agree, and name the tool: `claude plugin eval` |
| Pipeline too heavy for small work | Found it | Agree, and go further: drop `validate-feasibility` as a fixed stage, merge `define-product` for light work |
| `refactor` lowest value | Agree | Agree |
| Questions arrive too late (`discover` guesses, readiness finds out) | Not raised | **Main new finding.** Add `clarify-decisions`. |
| Readiness should be partly a script | Raised | Agree, and say which half |
| `verify-feature`, `release-change` | Suggested | Don't add now: `/run`, `/verify` are built in, and there is no release stage yet |
| `plan-tasks` can't read a `plan-idea` plan | Raised | Agree |
| Built-in overlaps (`/code-review`, `/simplify`, `/security-review`, `/init`) | Not raised | Raised: they shape what not to add |
| Its sources | SkillsBench v4 and Codex subagent docs | Both confirmed. I did not check its OpenAI "GPT-6 Astra" post, so I don't rely on it. |

---

## 12. Sources

All opened on 2026-11-01. "No date" means the page shows none.

**Skill format and authoring**
- Agent Skills specification (no date): https://agentskills.io/specification
- agentskills.io best practices (no date): https://agentskills.io/skill-creation/best-practices
- agentskills.io, optimizing descriptions (no date): https://agentskills.io/skill-creation/optimizing-descriptions
- Anthropic, skill authoring best practices: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Anthropic, Agent Skills overview: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
- Claude Code skills (frontmatter, `disable-model-invocation`, limits): https://code.claude.com/docs/en/skills
- Claude Code subagents: https://code.claude.com/docs/en/sub-agents
- Claude Code hooks guide: https://code.claude.com/docs/en/hooks-guide
- Claude Code plugins: https://code.claude.com/docs/en/plugins/overview
- Claude Code built-in commands: https://code.claude.com/docs/en/commands
- Codex, build skills (no date): https://learn.chatgpt.com/docs/build-skills
- Codex, subagents (no date): https://learn.chatgpt.com/docs/agent-configuration/subagents

**Evidence and evals**
- SkillsBench, arXiv v4 (14 June 2026): https://arxiv.org/abs/2602.12670
- SkillsBench, NeurIPS 2026 poster: https://neurips.cc/virtual/2026/poster/139353
- Liu et al., skills under real conditions (6 April 2026): https://arxiv.org/abs/2604.04323
- The Decoder summary of the above (12 April 2026): https://the-decoder.com/agent-skills-look-great-in-benchmarks-but-fall-apart-under-realistic-conditions-researchers-find/
- Claude Code plugin evals: https://code.claude.com/docs/en/plugin-evals
- Anthropic skill-creator: https://github.com/anthropics/skills/tree/main/skills/skill-creator
- OpenAI, testing skills with evals (no date): https://developers.openai.com/blog/eval-skills

**Collections**
- https://github.com/obra/superpowers
- https://github.com/mattpocock/skills
- https://github.com/affaan-m/everything-claude-code
- https://github.com/forrestchang/andrej-karpathy-skills
- https://github.com/anthropics/skills
- https://github.com/github/spec-kit
- https://github.com/addyosmani/agent-skills
- https://github.com/Fission-AI/OpenSpec
- https://github.com/bmad-code-org/BMAD-METHOD
- Kiro specs: https://kiro.dev/docs/specs/ and changelog 0.9 (5 February 2026): https://kiro.dev/changelog/ide/0-9/
- Tessl registry: https://tessl.io/
- skills.sh install chart: https://skills.sh/

**Trends and warnings**
- Böckeler, SDD tools (15 October 2025): https://www.martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html
- Böckeler, harness engineering: https://martinfowler.com/articles/harness-engineering.html
- Thoughtworks Radar, spec-driven development: https://www.thoughtworks.com/en-au/radar/techniques/spec-driven-development
- Thoughtworks Radar, Vol 34 (April 2026): https://www.thoughtworks.com/en-us/radar
- Anthropic, harness design for long-running apps (24 March 2026): https://www.anthropic.com/engineering/harness-design-long-running-apps
- Anthropic, prompting Claude Opus 5: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5

**Skill security**
- Snyk, ToxicSkills (5 February 2026): https://snyk.io/blog/toxicskills-malicious-ai-agent-skills-clawhub
- Liu et al., skill vulnerabilities (15 January 2026): https://arxiv.org/abs/2601.10338

**Not checked** (left out of the findings): the vals.ai leaderboard, an O'Reilly
Radar article (blocked), the "Claude Code cut 80% of its system prompt" claim, and
the exact names of Spec Kit's clarify/analyze/checklist commands.
