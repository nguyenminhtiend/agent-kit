# Regression cases for review/approval and installation. Sourced by smoke.sh;
# all files and settings live under its disposable WORK directory.

echo "== guard aliases and exact paths"
mkdir -p "$GP/.workflow/state" "$GP/src"
printf '{}\n' > "$GP/.workflow/state/review.json"
ln -s ../.workflow/state/review.json "$GP/docs/state-alias.md"
ln -s state-alias.md "$GP/docs/state-chain.md"
ln -s ../.workflow/approvals/future.json "$GP/docs/future-alias.md"
ln -s ../.workflow/state "$GP/docs/state-dir"
ln -s loop-b "$GP/docs/loop-a"
ln -s loop-a "$GP/docs/loop-b"
for alias in state-alias.md state-chain.md future-alias.md state-dir/review.json loop-a; do
  check_rc "guard blocks alias $alias" 2 guard Write "{\"file_path\":\"$GP/docs/$alias\"}"
done
check_rc "stage cannot follow an allowed document into state" 2 guard Edit "{\"file_path\":\"$GP/docs/state-alias.md\"}" spec docs/state-alias.md
check_rc "guard blocks apply_patch aliases" 2 guard apply_patch '{"command":"*** Begin Patch\n*** Update File: docs/state-chain.md\n@@\n-a\n+b\n*** End Patch"}'
check_rc "single-file allow does not allow a suffix" 2 guard Write "{\"file_path\":\"$GP/docs/02-design.md.backup\"}" spec docs/02-design.md
ln -s "$GP/src" "$GP/.workflow/state/escape"
check_rc "guard blocks paths leaving a protected directory via a symlink" 2 guard Write "{\"file_path\":\"$GP/.workflow/state/escape/app.ts\"}"
check_rc "directory allow still permits nested files" 0 guard Write "{\"file_path\":\"$GP/tasks/001-setup/task.md\"}" plan tasks/
mkdir -p "$GP/state-storage"
mv "$GP/.workflow/state/review.json" "$GP/state-storage/review.json"
rm "$GP/.workflow/state/escape"
rmdir "$GP/.workflow/state"
ln -s ../state-storage "$GP/.workflow/state"
check_rc "guard protects the resolved state directory" 2 guard Write "{\"file_path\":\"$GP/state-storage/review.json\"}"

echo "== codex-only nested project and existing instructions"
RP="$WORK/monorepo/services/app"
mkdir -p "$RP"
git init -q "$WORK/monorepo"
printf '# My project rules\nKeep this custom instruction.\n' > "$RP/AGENTS.md"
ri() { clean_env HOME="$WORK/codex-home" "$KIT/install.sh" --target codex --scope project --project "$RP" "$@"; }
check "codex-only install" ri
check "codex-only runtime contains skills" test -s "$RP/.agent-kit/skills/define-requirements/SKILL.md"
check "codex-only runtime contains reviewer instructions" test -s "$RP/.agent-kit/agents/spec-reviewer.md"
check "codex-only runtime has no old skills" test ! -e "$RP/.agent-kit/skills/discover"
check "codex-only install does not require a Claude integration" test ! -e "$RP/.claude"
check "existing AGENTS keeps user content" grep -q 'Keep this custom instruction' "$RP/AGENTS.md"
check "existing AGENTS receives the gate rule" grep -q 'agent-kit gate' "$RP/AGENTS.md"
check "existing AGENTS receives state protections" grep -q '.workflow/state/' "$RP/AGENTS.md"
check "existing AGENTS receives the human-approval rule" grep -q 'Never run `agent-kit approve`' "$RP/AGENTS.md"

# Upgrade an old hook alongside an unrelated hook in the same matcher entry.
jq '.hooks.PreToolUse[0].hooks = [
  {type:"command",command:"echo keep-me"},
  {type:"command",command:"sh -c old/.agent-kit/hooks/guard.sh"}
]' "$RP/.codex/hooks.json" > "$WORK/old-hooks.json"
cp "$WORK/old-hooks.json" "$RP/.codex/hooks.json"
check "reinstall upgrades an old guard hook" ri
check "hook upgrade preserves unrelated commands" jq -e '[.hooks.PreToolUse[].hooks[].command] | index("echo keep-me") != null' "$RP/.codex/hooks.json"
check "hook upgrade removes the old command" jq -e '[.hooks.PreToolUse[].hooks[].command | select(contains("sh -c old/"))] | length == 0' "$RP/.codex/hooks.json"
check "reinstall keeps one workflow block" test "$(grep -c '## Agent-kit workflow' "$RP/AGENTS.md")" -eq 1
check "updated hook reinstall stays stable" ri
check "guard stays unique after update" test "$(jq '[.hooks.PreToolUse[].hooks[].command | select(contains("agent-kit/hooks/guard.sh"))] | length' "$RP/.codex/hooks.json")" -eq 1

installed_codex_hook() {
  local where="$1" cmd
  cmd="$(jq -r '.hooks.PreToolUse[].hooks[].command | select(contains("agent-kit/hooks/guard.sh"))' "$RP/.codex/hooks.json")" || return 1
  (cd "$where" && jq -nc --arg c "$RP" '{tool_name:"apply_patch",cwd:$c,tool_input:{command:"*** Begin Patch\n*** Add File: .workflow/state/x.json\n+{}\n*** End Patch"}}' |
    clean_env /bin/sh -c "$cmd")
}
check_rc "nested Git project executes its own guard" 2 installed_codex_hook "$RP"
check_rc "hook finds the project from a child directory" 2 installed_codex_hook "$RP/docs"
check_rc "hook fails closed when no project root exists" 2 installed_codex_hook "$WORK/monorepo"
mv "$RP/.agent-kit/hooks/guard.sh" "$WORK/saved-guard.sh"
check_rc "hook fails closed when its script is missing" 2 installed_codex_hook "$RP"
mv "$WORK/saved-guard.sh" "$RP/.agent-kit/hooks/guard.sh"

mkdir -p "$WORK/regression-state"
RK_LOG="$WORK/regression-claude.log"
rk() {
  (cd "$RP" && clean_env HOME="$WORK/codex-home" PATH="$FB:$PATH" FAKE_CLAUDE_LOG="$RK_LOG" \
    FAKE_STATE_DIR="$WORK/regression-state" "$@")
}
printf '# Brief\nBuild a small todo app.\n' > "$RP/brief/requirements.md"
printf '\nBUNDLED_REQUIREMENTS_INSTRUCTIONS\n' >> "$RP/.agent-kit/skills/define-requirements/SKILL.md"
rk_steps() { rk env FAKE_EXPECT_SKILL=define-requirements FAKE_EXPECT_TEXT=BUNDLED_REQUIREMENTS_INSTRUCTIONS .agent-kit/bin/agent-kit "$@"; }
check "codex-only steps use bundled skill and agent instructions" run_steps rk_steps

before_approval_gate() {
  (cd "$RP" && source "$KIT/lib/common.sh" && source "$KIT/lib/check.sh" && source "$KIT/lib/gate.sh" &&
    gate_checks before-approval)
}
hash_baseline() { (cd "$RP" && source "$KIT/lib/common.sh" && baseline_hash); }
check "regular baseline is ready before approval" before_approval_gate

echo "== symlink baselines"
mv "$RP/docs/02-design.md" "$WORK/real-design.md"
ln -s "$WORK/real-design.md" "$RP/docs/02-design.md"
check_fails "hash rejects a symlinked document" hash_baseline
check_fails "review refuses a symlinked baseline" rk .agent-kit/bin/agent-kit review
check_fails "approval checks refuse a symlinked baseline" before_approval_gate
rm "$RP/docs/02-design.md"
mv "$WORK/real-design.md" "$RP/docs/02-design.md"
mv "$RP/tasks" "$WORK/real-tasks"
ln -s "$WORK/real-tasks" "$RP/tasks"
check_fails "hash rejects a symlinked baseline directory" hash_baseline
rm "$RP/tasks"
mv "$WORK/real-tasks" "$RP/tasks"
ln -s "$WORK/no-such-file" "$RP/docs/dangling.md"
check_fails "hash rejects a dangling symlink" hash_baseline
rm "$RP/docs/dangling.md"
check "regular baseline still passes after removing aliases" before_approval_gate

echo "== open decisions block approval"
cp "$RP/docs/02-design.md" "$WORK/design-before-decision.md"
printf '\n## Open decisions\n\n### DEC-001: Which auth provider?\n\nRecommendation: email links.\n' >> "$RP/docs/02-design.md"
check_fails "an open decision blocks approval checks" before_approval_gate
cp "$WORK/design-before-decision.md" "$RP/docs/02-design.md"
check "the baseline is ready again once the decision is gone" before_approval_gate

echo "== configuration validation"
cp "$RP/agent-kit.toml" "$WORK/valid-config.toml"
calls_before="$(wc -l < "$RK_LOG" | tr -d ' ')"
printf '[limits\nmax_budget_usd = 2\n' > "$RP/agent-kit.toml"
check_fails "malformed TOML stops before a stage runs" rk .agent-kit/bin/agent-kit spec define-requirements
for value in 'max_budget_usd = -1' 'max_budget_usd = "2"' 'max_turns = 0' 'max_turns = 1.5'; do
  printf '[limits]\n%s\n' "$value" > "$RP/agent-kit.toml"
  check_fails "invalid limit: $value" rk .agent-kit/bin/agent-kit spec define-requirements
done
printf '[review]\nblock_on = ["typo"]\n' > "$RP/agent-kit.toml"
check_fails "invalid blocking severity stops the review" rk .agent-kit/bin/agent-kit review
check "invalid configuration never calls Claude" test "$(wc -l < "$RK_LOG" | tr -d ' ')" = "$calls_before"
printf '[limits]\nmax_budget_usd = 2.5\n' > "$RP/agent-kit.toml"
read_settings() {
  (cd "$RP" && source "$KIT/lib/common.sh" && load_config &&
    test "$(cfg .limits.max_budget_usd 0)" = 2.5 && test "$(cfg .limits.max_turns 30)" = 30)
}
check "valid partial configuration keeps budget and defaults" read_settings
cp "$WORK/valid-config.toml" "$RP/agent-kit.toml"

echo "== edits during assessment"
stage_race() {
  local variable="$1" command="$2" readers="$3" path="$4" message="$5"
  local barrier="$WORK/$command-barrier" pid attempt count rc=0
  rm -rf "$barrier"
  mkdir -p "$barrier"
  rk env "$variable=$barrier" .agent-kit/bin/agent-kit "$command" > "$WORK/$command-race.log" 2>&1 &
  pid=$!
  attempt=0
  while :; do
    count="$(find "$barrier" -name '*.read' -type f | wc -l | tr -d ' ')"
    [ "$count" -lt "$readers" ] || break
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 100 ]; then
      touch "$barrier/release"
      wait "$pid" || true
      return 1
    fi
    sleep 0.05
  done
  printf '\nChanged after the assessors read the original.\n' >> "$RP/$path"
  touch "$barrier/release"
  wait "$pid" || rc=$?
  [ "$rc" -ne 0 ] && grep -q "$message" "$WORK/$command-race.log"
}
check "review rejects edits made after the reviewer read" stage_race FAKE_REVIEW_BARRIER review 1 docs/02-design.md 'changed during review'
check "interrupted review removes the previous PASS stamp" test ! -e "$RP/.workflow/state/review.json"
check_fails "approval checks refuse an unreviewed changed baseline" before_approval_gate
check "a stable rerun can review the changed baseline" rk .agent-kit/bin/agent-kit review
check "a task edited during review is caught too" stage_race FAKE_REVIEW_BARRIER review 1 tasks/001-setup/task.md 'changed during review'
check "a stable rerun reviews it again" rk .agent-kit/bin/agent-kit review

echo "== guard in workspaces"
GW="$GP/specs/a"
mkdir -p "$GW/docs" "$GW/.workflow/state" "$GW/.workflow/approvals"
guard_ws() {
  local stage="${3:-}" allow="${4:-}"
  jq -nc --arg t "$1" --arg c "$GW" --argjson i "$2" '{tool_name: $t, cwd: $c, tool_input: $i}' |
    clean_env AGENT_KIT_PROJECT_DIR="$GP" AGENT_KIT_WORKSPACE_DIR="$GW" \
      ${stage:+AGENT_KIT_STAGE="$stage"} ${allow:+AGENT_KIT_WRITE_ALLOW="$allow"} "$G"
}
check_rc "normal session: a workspace's state blocked"      2 guard Write "{\"file_path\":\"$GW/.workflow/state/review.json\"}"
check_rc "normal session: a workspace's approvals blocked"  2 guard Edit "{\"file_path\":\"$GW/.workflow/approvals/spec-approved.json\"}"
check_rc "bash: a workspace's state blocked"                2 guard Bash '{"command":"rm specs/a/.workflow/state/review.json"}'
check_rc "codex: a workspace's approvals blocked"           2 guard apply_patch '{"command":"*** Begin Patch\n*** Add File: specs/a/.workflow/approvals/x.json\n+{}\n*** End Patch"}'
check_rc "workspace stage: own document allowed"            0 guard_ws Write "{\"file_path\":\"$GW/docs/02-design.md\"}" spec docs/02-design.md
check_rc "workspace stage: relative path is inside it"      0 guard_ws Write '{"file_path":"docs/02-design.md"}' spec docs/02-design.md
check_rc "workspace stage: project-root docs/ blocked"      2 guard_ws Write "{\"file_path\":\"$GP/docs/02-design.md\"}" spec docs/02-design.md
check_rc "workspace stage: project code blocked"            2 guard_ws Write "{\"file_path\":\"$GP/src/app.ts\"}" spec docs/

echo "== existing project with its own docs/ and tasks/"
EP="$WORK/existing"
mkdir -p "$EP/docs" "$EP/tasks" "$EP/src"
printf '# Our API docs\n' > "$EP/docs/api.md"
printf -- '- name: deploy\n' > "$EP/tasks/deploy.yml"
ei() {
  clean_env HOME="$WORK/existing-home" "$KIT/install.sh" --target claude --scope project \
    --project "$EP" --scripts-dir tools/agent-kit "$@"
}
check_fails "init refuses a root workspace holding the project's own docs/" ei
check "the project's docs stay as they were"     test "$(cat "$EP/docs/api.md")" = "# Our API docs"
check "no config is written when init refuses"   test ! -e "$EP/agent-kit.toml"
check "install with a separate workspace"        ei --workspace specs/checkout
check "config records the workspace"             grep -qx 'workspace = "specs/checkout"' "$EP/agent-kit.toml"
check "brief is in the workspace"                test -f "$EP/specs/checkout/brief/requirements.md"
check "nothing is added at the root"             test ! -e "$EP/brief" -a ! -e "$EP/.workflow"
check "wrappers are in the chosen folder"        test -x "$EP/tools/agent-kit/spec.sh" -a -x "$EP/tools/agent-kit/check.sh"
check "no scripts/ folder is created"            test ! -e "$EP/scripts"
check "gitignore covers logs in any workspace"   grep -qxF '**/.workflow/logs/' "$EP/.gitignore"
check "the gate rule is limited to agent-kit tasks" grep -q "Other work follows the normal project rules" "$EP/AGENTS.md"

EK_LOG="$WORK/existing-claude.log"
mkdir -p "$WORK/existing-state"
ek() {
  (cd "$EP/src" && clean_env HOME="$WORK/existing-home" PATH="$FB:$PATH" FAKE_CLAUDE_LOG="$EK_LOG" \
    FAKE_STATE_DIR="$WORK/existing-state" "$@")
}
printf '# Brief\nAdd a checkout page to the shop.\n' > "$EP/specs/checkout/brief/requirements.md"
# ek_steps CMD ARGS...: one step through the nested wrapper for CMD.
ek_steps() {
  local c="$1"
  shift
  ek env FAKE_EXPECT_SKILL=define-requirements FAKE_EXPECT_TEXT="The project's code and other docs are in $EP." \
    "../tools/agent-kit/$c.sh" "$@"
}
check "the steps run from a subfolder through nested wrappers" run_steps ek_steps
check "spec docs are written in the workspace"   test -s "$EP/specs/checkout/docs/02-design.md"
check "tasks are written in the workspace"       test -s "$EP/specs/checkout/tasks/001-setup/task.md"
check "the project's docs/ and tasks/ are untouched" test "$(ls "$EP/docs")" = api.md -a "$(ls "$EP/tasks")" = deploy.yml
check "Claude runs in the workspace"             sh -c "! grep -v 'cwd=$EP/specs/checkout\$' '$EK_LOG'"
check "Claude may read the project root"         sh -c "! grep -v 'adddir=$EP ' '$EK_LOG'"
check "stage writes are relative to the workspace" grep -q 'skill=design-solution agent= stage=spec allow=docs/02-design.md ' "$EK_LOG"

check "a second workspace (flag after the command)" ek ../.agent-kit/bin/agent-kit init --dir .. -w specs/search
check "the config default stays"                grep -qx 'workspace = "specs/checkout"' "$EP/agent-kit.toml"
check "the second workspace has a brief template" grep -q agent-kit:brief-template "$EP/specs/search/brief/requirements.md"
check_fails "the second workspace refuses its template brief" ek ../tools/agent-kit/spec.sh define-requirements --workspace specs/search
check_fails "a missing workspace is an error, not created" ek ../tools/agent-kit/gate.sh -w specs/nope
check "a missing workspace is not created"       test ! -e "$EP/specs/nope"
mkdir -p "$WORK/outside"
ln -s "$WORK/outside" "$EP/specs/link"
for bad in ../outside /tmp specs/../../x .agent-kit/work .git 'a b' specs/link; do
  check_fails "invalid workspace rejected: $bad" ek ../.agent-kit/bin/agent-kit -w "$bad" gate
done
if command -v expect >/dev/null 2>&1; then
  check "approve one workspace"                  approve_in_terminal "$EP" tools/agent-kit/approve.sh
  check "its approval is in its own .workflow"   test -s "$EP/specs/checkout/.workflow/approvals/spec-approved.json"
  check "its gate passes"                        ek ../tools/agent-kit/gate.sh
  check_fails "another workspace keeps its own gate" ek ../tools/agent-kit/gate.sh -w specs/search
  printf 'More API notes.\n' >> "$EP/docs/api.md"
  check "editing the project's own docs keeps the approval" ek ../tools/agent-kit/gate.sh
else
  echo "  skip  approve a workspace in a terminal (needs 'expect')"
fi

echo "== one global install, many projects"
GH="$WORK/global-home"
GAK="$GH/.local/bin/agent-kit"
gk() { clean_env HOME="$GH" AGENT_KIT_BIN_DIR="$GH/.local/bin" "$KIT/install.sh" --target both --scope global "$@"; }
mkdir -p "$WORK/global-state" "$WORK/new-app" "$WORK/old-app/docs" "$WORK/old-app/src"
printf '# Old docs\n' > "$WORK/old-app/docs/readme.md"
gp() {
  local dir="$1"
  shift
  (cd "$dir" && clean_env HOME="$GH" PATH="$FB:$PATH" FAKE_CLAUDE_LOG="$WORK/global-claude.log" \
    FAKE_STATE_DIR="$WORK/global-state" "$@")
}
check "global install"                              gk
check "skills reach every project"                  test -L "$GH/.claude/skills/fix-bug" -a -L "$GH/.agents/skills/fix-bug"
check "new project: init with the global command"   gp "$WORK/new-app" "$GAK" init
printf '# Brief\nA small notes app.\n' > "$WORK/new-app/brief/requirements.md"
gp_new() { gp "$WORK/new-app" "$GAK" "$@"; }
check "new project: the steps with the global command" run_steps gp_new
check "new project: specs at the project root"      test -s "$WORK/new-app/docs/02-design.md"
check_fails "existing project: plain init refuses its own docs/" gp "$WORK/old-app" "$GAK" init
check "existing project: init a feature workspace"  gp "$WORK/old-app" "$GAK" -w specs/notes init
printf '# Brief\nAdd notes to the app.\n' > "$WORK/old-app/specs/notes/brief/requirements.md"
gp_old() { gp "$WORK/old-app/src" "$GAK" "$@"; }
check "existing project: the steps from a subfolder" run_steps gp_old
check "existing project: specs in the workspace"    test -s "$WORK/old-app/specs/notes/docs/02-design.md"
check "existing project: own docs untouched"        test "$(ls "$WORK/old-app/docs")" = readme.md
check "no kit copy, wrappers or editor settings in projects" \
  test ! -e "$WORK/new-app/.agent-kit" -a ! -e "$WORK/new-app/.claude" -a ! -e "$WORK/new-app/scripts" \
    -a ! -e "$WORK/old-app/.agent-kit" -a ! -e "$WORK/old-app/.claude" -a ! -e "$WORK/old-app/scripts"
check "every global run had the guard settings"     sh -c "! grep -q 'settings=0' '$WORK/global-claude.log'"
check_fails "--workspace is refused for a global install" gk --workspace specs
