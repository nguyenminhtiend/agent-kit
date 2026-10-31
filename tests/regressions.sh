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
check_rc "single-file allow does not allow a suffix" 2 guard Write "{\"file_path\":\"$GP/docs/02-prd.md.backup\"}" spec docs/02-prd.md
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
check "codex-only runtime contains skills" test -s "$RP/.agent-kit/skills/discover/SKILL.md"
check "codex-only runtime contains reviewer instructions" test -s "$RP/.agent-kit/agents/qa-reviewer.md"
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
printf '\nBUNDLED_DISCOVERY_INSTRUCTIONS\n' >> "$RP/.agent-kit/skills/discover/SKILL.md"
check "codex-only pipeline uses bundled skill and agent instructions" rk env FAKE_EXPECT_SKILL=discover FAKE_EXPECT_TEXT=BUNDLED_DISCOVERY_INSTRUCTIONS .agent-kit/bin/agent-kit prepare

before_approval_gate() {
  (cd "$RP" && source "$KIT/lib/common.sh" && source "$KIT/lib/gate.sh" && gate_checks before-approval)
}
hash_baseline() { (cd "$RP" && source "$KIT/lib/common.sh" && baseline_hash); }
check "regular baseline is ready before approval" before_approval_gate

echo "== symlink baselines"
mv "$RP/docs/02-prd.md" "$WORK/real-prd.md"
ln -s "$WORK/real-prd.md" "$RP/docs/02-prd.md"
check_fails "hash rejects a symlinked document" hash_baseline
check_fails "review refuses a symlinked baseline" rk .agent-kit/bin/agent-kit review
check_fails "approval checks refuse a symlinked baseline" before_approval_gate
rm "$RP/docs/02-prd.md"
mv "$WORK/real-prd.md" "$RP/docs/02-prd.md"
mv "$RP/tasks" "$WORK/real-tasks"
ln -s "$WORK/real-tasks" "$RP/tasks"
check_fails "hash rejects a symlinked baseline directory" hash_baseline
rm "$RP/tasks"
mv "$WORK/real-tasks" "$RP/tasks"
ln -s "$WORK/no-such-file" "$RP/docs/dangling.md"
check_fails "hash rejects a dangling symlink" hash_baseline
rm "$RP/docs/dangling.md"
check "regular baseline still passes after removing aliases" before_approval_gate

echo "== readiness consistency"
cp "$RP/.workflow/state/readiness.json" "$WORK/ready-state.json"
jq '.decisions = [{id:"D-1",question:"Which auth provider?",recommendation:"Choose one"}]' "$WORK/ready-state.json" > "$RP/.workflow/state/readiness.json"
check_fails "gate rejects READY with open decisions and a zero count" before_approval_gate
check_fails "runner rejects contradictory readiness output" rk env \
  FAKE_READINESS_RESULT='{"status":"READY","critical":0,"major":0,"unresolved_decisions":0,"summary":"Contradictory","decisions":[{"id":"D-1","question":"Which auth provider?","recommendation":"Choose one"}]}' \
  .agent-kit/bin/agent-kit plan
check "invalid readiness does not leave a saved verdict" test ! -e "$RP/.workflow/state/readiness.json"
check "runner preserves a consistent NOT_READY verdict" rk env \
  FAKE_READINESS_RESULT='{"status":"NOT_READY","critical":0,"major":0,"unresolved_decisions":1,"summary":"Choose auth first","decisions":[{"id":"D-1","question":"Which auth provider?","recommendation":"Choose one"}]}' \
  .agent-kit/bin/agent-kit plan
check_fails "open decisions block approval" before_approval_gate
check "readiness can be reassessed after resolving decisions" rk .agent-kit/bin/agent-kit plan

echo "== configuration validation"
cp "$RP/agent-kit.toml" "$WORK/valid-config.toml"
calls_before="$(wc -l < "$RK_LOG" | tr -d ' ')"
printf '[limits\nmax_budget_usd = 2\n' > "$RP/agent-kit.toml"
check_fails "malformed TOML stops before a stage runs" rk .agent-kit/bin/agent-kit prepare
for value in 'max_budget_usd = -1' 'max_budget_usd = "2"' 'max_turns = 0' 'max_turns = 1.5'; do
  printf '[limits]\n%s\n' "$value" > "$RP/agent-kit.toml"
  check_fails "invalid limit: $value" rk .agent-kit/bin/agent-kit prepare
done
printf '[review]\nblock_on = ["typo"]\n' > "$RP/agent-kit.toml"
check_fails "invalid blocking severity stops the pipeline" rk .agent-kit/bin/agent-kit prepare
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
check "review rejects edits made after every reviewer read" stage_race FAKE_REVIEW_BARRIER review 3 docs/02-prd.md 'specs changed during review'
check "interrupted review removes the previous PASS stamp" test ! -e "$RP/.workflow/state/review.json"
check_fails "planning refuses an unstamped changed baseline" rk .agent-kit/bin/agent-kit plan
check "a stable rerun can review the changed baseline" rk .agent-kit/bin/agent-kit review
check "readiness rejects a task edited while it is being assessed" stage_race FAKE_READINESS_BARRIER plan 1 tasks/001-setup/task.md 'changed during readiness assessment'
check "interrupted readiness does not leave a passing verdict" test ! -e "$RP/.workflow/state/readiness.json"
check "stable inputs can be reassessed after a concurrent edit" rk .agent-kit/bin/agent-kit plan
