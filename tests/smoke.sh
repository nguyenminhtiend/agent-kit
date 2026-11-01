#!/usr/bin/env bash
# Smoke tests for agent-kit. No API calls: the pipeline runs against tests/fake-claude.
# Usage: tests/smoke.sh      (exit 0 = all passed)
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/agent-kit-smoke.XXXXXX")"
WORK="$(cd -P "$WORK" && pwd)"
trap 'rm -rf "$WORK"' EXIT

PASSED=0
FAILED=0
pass() { PASSED=$((PASSED + 1)); printf '  pass  %s\n' "$1"; }
flunk() { FAILED=$((FAILED + 1)); printf '  FAIL  %s\n' "$1"; }
# check NAME CMD...      passes when CMD succeeds
check() { local n="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$n"; else flunk "$n"; fi; }
# check_fails NAME CMD... passes when CMD fails
check_fails() { local n="$1"; shift; if "$@" >/dev/null 2>&1; then flunk "$n"; else pass "$n"; fi; }
# check_rc NAME WANT CMD...
check_rc() {
  local n="$1" want="$2" rc=0
  shift 2
  "$@" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq "$want" ]; then pass "$n"; else flunk "$n (exit $rc, wanted $want)"; fi
}

# A clean environment for the installer (ignore the caller's own config dirs).
clean_env() {
  env -u CLAUDE_CONFIG_DIR -u CODEX_HOME -u AGENT_KIT_STAGE -u AGENT_KIT_WRITE_ALLOW -u AGENT_KIT_PROJECT_DIR \
    -u AGENT_KIT_WORKSPACE -u AGENT_KIT_WORKSPACE_DIR "$@"
}

# ---------------------------------------------------------------------------
echo "== syntax"
for f in "$KIT"/install.sh "$KIT"/bin/agent-kit "$KIT"/lib/*.sh "$KIT"/hooks/guard.sh "$KIT"/tests/*.sh "$KIT"/tests/fake-claude; do
  check "bash -n ${f#"$KIT"/}" bash -n "$f"
done
for f in "$KIT"/install.sh "$KIT"/bin/agent-kit "$KIT"/hooks/guard.sh "$KIT"/tests/fake-claude; do
  check "executable ${f#"$KIT"/}" test -x "$f"
done

# ---------------------------------------------------------------------------
echo "== kit content"
fm() { yq -p yaml -oy --front-matter=extract "$1" "$2" 2>/dev/null; }
for d in "$KIT"/skills/*/; do
  s="$(basename "$d")"
  check "skill $s: name matches folder" test "$(fm .name "$d/SKILL.md")" = "$s"
  check "skill $s: has description" test -n "$(fm '.description // ""' "$d/SKILL.md")"
  # Note: "false // x" gives x in yq, so read the raw value and treat null as the default.
  claude_off="$(fm '."disable-model-invocation"' "$d/SKILL.md")"
  codex_on="$(yq -oy '.policy.allow_implicit_invocation' "$d/agents/openai.yaml" 2>/dev/null || echo null)"
  [ "$codex_on" != null ] || codex_on=true
  if [ "$claude_off" = true ]; then want=false; else want=true; fi
  check "skill $s: Claude and Codex auto-use settings match" test "$codex_on" = "$want"
done
for f in "$KIT"/agents/*.md; do
  a="$(basename "$f" .md)"
  check "agent $a: name matches file" test "$(fm .name "$f")" = "$a"
  check "agent $a: read-only tools" test "$(fm .tools "$f")" = "Read, Grep, Glob"
done
for f in "$KIT"/skills/*/SKILL.md "$KIT"/agents/*.md; do
  # Documents are named by role; only the runner knows paths (lib/common.sh doc_map).
  check_fails "no workspace paths in ${f#"$KIT"/}" grep -nE '(^|[^A-Za-z])(docs|brief|tasks|schemas)/|\.workflow|requirements\.md' "$f"
done
for f in "$KIT"/skills/*/SKILL.md "$KIT"/agents/*.md "$KIT"/rules/engineering.md; do
  # Each file must work alone when copied into another project.
  check_fails "no kit or runner names in ${f#"$KIT"/}" grep -niE 'agent-kit|runner|(^|[^a-z-])kit([^a-z-]|$)|spec stage' "$f"
done
for f in "$KIT"/schemas/*.json; do check "valid JSON ${f#"$KIT"/}" jq empty "$f"; done
check "template agent-kit.toml parses" yq -p toml -oy . "$KIT/templates/project/agent-kit.toml"

# ---------------------------------------------------------------------------
echo "== guard hook"
G="$KIT/hooks/guard.sh"
GP="$WORK/guard-project"
mkdir -p "$GP/docs" "$GP/.workflow/approvals"

# guard TOOL INPUT_JSON [STAGE ALLOW]
guard() {
  local stage="${3:-}" allow="${4:-}"
  jq -nc --arg t "$1" --arg c "$GP" --argjson i "$2" '{tool_name: $t, cwd: $c, tool_input: $i}' |
    clean_env AGENT_KIT_PROJECT_DIR="$GP" ${stage:+AGENT_KIT_STAGE="$stage"} ${allow:+AGENT_KIT_WRITE_ALLOW="$allow"} "$G"
}
check_rc "normal session: edit src/ allowed"            0 guard Write "{\"file_path\":\"$GP/src/app.ts\"}"
check_rc "normal session: edit approvals blocked"        2 guard Write "{\"file_path\":\"$GP/.workflow/approvals/spec-approved.json\"}"
check_rc "normal session: edit state blocked"            2 guard Edit "{\"file_path\":\"$GP/.workflow/state/review.json\"}"
check_rc "bash: 'agent-kit approve' blocked"             2 guard Bash '{"command":"agent-kit approve"}'
check_rc "bash: write to state blocked"                  2 guard Bash '{"command":"echo {} > .workflow/state/review.json"}'
check_rc "bash: plain command allowed"                   0 guard Bash '{"command":"ls -la"}'
check_rc "stage: own document allowed"                   0 guard Write "{\"file_path\":\"$GP/docs/02-design.md\"}" spec docs/02-design.md
check_rc "stage: other document blocked"                 2 guard Write "{\"file_path\":\"$GP/docs/01-requirements.md\"}" spec docs/02-design.md
check_rc "stage: application code blocked"               2 guard Write "{\"file_path\":\"$GP/src/app.ts\"}" spec docs/
check_rc "stage: outside the project blocked"            2 guard Write '{"file_path":"/etc/hosts"}' spec docs/
check_rc "stage: ../ escape blocked"                     2 guard Write "{\"file_path\":\"$GP/docs/../../evil.md\"}" spec docs/
check_rc "stage: reviewer (no allow list) blocked"       2 guard Write "{\"file_path\":\"$GP/docs/02-design.md\"}" review ""
check_rc "stage: multiple allowed paths"                 0 guard Write "{\"file_path\":\"$GP/tasks/001-a/task.md\"}" plan "docs/03-plan.md:tasks/"
check_rc "codex apply_patch: allowed file"               0 guard apply_patch '{"command":"*** Begin Patch\n*** Update File: docs/02-design.md\n@@\n-a\n+b\n*** End Patch"}' spec docs/02-design.md
check_rc "codex apply_patch: app code blocked in stage"  2 guard apply_patch '{"command":"*** Begin Patch\n*** Add File: src/x.ts\n+x\n*** End Patch"}' spec docs/
check_rc "codex apply_patch: approvals blocked"          2 guard apply_patch '{"command":"*** Begin Patch\n*** Add File: .workflow/approvals/x.json\n+{}\n*** End Patch"}'
check_rc "unknown tool allowed"                          0 guard Read "{\"file_path\":\"$GP/.workflow/approvals/x\"}"

# ---------------------------------------------------------------------------
echo "== global install (fake HOME)"
H="$WORK/home"
mkdir -p "$H/.claude/skills/fix-bug"           # something already in the way
echo "mine" > "$H/.claude/skills/fix-bug/SKILL.md"
mkdir -p "$H/.claude/skills" "$H/.codex/agents"
ln -s "$KIT/skills/discover" "$H/.claude/skills/discover"                   # a removed kit skill
ln -s "$KIT/dist/codex/agents/qa-reviewer.toml" "$H/.codex/agents/qa-reviewer.toml"
ln -s "$WORK/not-the-kit" "$H/.claude/skills/someone-elses"                 # not ours: keep
gi() { clean_env HOME="$H" AGENT_KIT_BIN_DIR="$H/.local/bin" "$KIT/install.sh" "$@"; }

check_rc "install skips what is in the way (exit 3)" 3 gi --target both --scope global
check "claude skill linked"         test -L "$H/.claude/skills/design-solution"
check "claude agent linked"         test -L "$H/.claude/agents/spec-reviewer.md"
check "own skill kept"              grep -q mine "$H/.claude/skills/fix-bug/SKILL.md"
check "removed kit skill unlinked"  test ! -L "$H/.claude/skills/discover"
check "removed kit agent unlinked"  test ! -L "$H/.codex/agents/qa-reviewer.toml"
check "other links kept"            test -L "$H/.claude/skills/someone-elses"
check "codex skill linked"          test -L "$H/.agents/skills/plan-tasks"
check "codex agent linked"          test -L "$H/.codex/agents/spec-reviewer.toml"
check "codex agent is valid TOML"   yq -p toml -oy .developer_instructions "$H/.codex/agents/spec-reviewer.toml"
check "codex agent has name"        test "$(yq -p toml -oy .name "$H/.codex/agents/spec-reviewer.toml")" = spec-reviewer
check "agent-kit command linked"    test -L "$H/.local/bin/agent-kit"
check "agent-kit command runs"      "$H/.local/bin/agent-kit" version
check "no settings files created"   test ! -e "$H/.claude/settings.json" -a ! -e "$H/.codex/hooks.json"
check_rc "re-install is stable (still 1 skip)" 3 gi --target both --scope global
check "--force replaces with backup" gi --target both --scope global --force
check "replaced skill is a link"    test -L "$H/.claude/skills/fix-bug"
check "backup kept"                 grep -rq mine "$H/.agent-kit-backup"
check "uninstall"                   gi --target both --scope global --uninstall
check "links removed"               test ! -e "$H/.claude/skills/design-solution" -a ! -e "$H/.codex/agents/spec-reviewer.toml" -a ! -e "$H/.local/bin/agent-kit"
check "backup still there"          grep -rq mine "$H/.agent-kit-backup"

# ---------------------------------------------------------------------------
echo "== project install"
P="$WORK/project"
mkdir -p "$P/.claude"
echo '{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"echo existing"}]}]}}' > "$P/.claude/settings.json"
pi() { clean_env HOME="$WORK/home2" "$KIT/install.sh" --target both --scope project --project "$P" "$@"; }

check "project install"                 pi
check "runner copied"                   test -x "$P/.agent-kit/bin/agent-kit"
check "wrapper scripts"                 test -x "$P/scripts/spec.sh" -a -x "$P/scripts/check.sh" -a -x "$P/scripts/repair.sh" -a -x "$P/scripts/approve.sh"
check "no old readiness wrapper"        test ! -e "$P/scripts/readiness.sh"
check "claude skills copied"            test -f "$P/.claude/skills/define-requirements/SKILL.md"
check "claude agents copied"            test -f "$P/.claude/agents/spec-reviewer.md"
check "codex skills copied"             test -f "$P/.agents/skills/define-requirements/agents/openai.yaml"
check "codex agents generated"          test -f "$P/.codex/agents/code-reviewer.toml"
check "existing claude hook kept"       jq -e '[.hooks.PreToolUse[].hooks[].command] | index("echo existing")' "$P/.claude/settings.json"
check "claude guard hook added"         jq -e '[.hooks.PreToolUse[].hooks[].command] | any(contains("agent-kit/hooks/guard.sh"))' "$P/.claude/settings.json"
check "codex guard hook added"          jq -e '[.hooks.PreToolUse[].hooks[].command] | any(contains("agent-kit/hooks/guard.sh"))' "$P/.codex/hooks.json"
check "init: agent-kit.toml"            test -f "$P/agent-kit.toml"
check "init: brief template"            grep -q agent-kit:brief-template "$P/brief/requirements.md"
check "init: AGENTS.md rules block"     grep -q "## Engineering rules" "$P/AGENTS.md"
check "init: CLAUDE.md imports AGENTS"  grep -q '@AGENTS.md' "$P/CLAUDE.md"
check "init: gitignore"                 grep -qxF '**/.workflow/logs/' "$P/.gitignore"
check "re-install is clean"             pi
check "rules block not duplicated"      test "$(grep -c 'agent-kit:rules:start' "$P/AGENTS.md")" -eq 1
check "guard hook not duplicated"       test "$(jq '[.hooks.PreToolUse[].hooks[].command | select(contains("guard.sh"))] | length' "$P/.claude/settings.json")" -eq 1
echo "local change" >> "$P/.claude/skills/define-requirements/SKILL.md"
check_rc "changed project skill is not overwritten (exit 3)" 3 pi
check "local change kept"               grep -q "local change" "$P/.claude/skills/define-requirements/SKILL.md"
mkdir -p "$P/.claude/skills/discover"
echo "old" > "$P/.claude/skills/discover/SKILL.md"
pi > /dev/null 2> "$WORK/pi-warnings.log" || true
check "reinstall names old kit files to remove" grep -q '.claude/skills/discover' "$WORK/pi-warnings.log"
check "old kit files are not deleted"   test -f "$P/.claude/skills/discover/SKILL.md"
rm -rf "$P/.claude/skills/discover"

# ---------------------------------------------------------------------------
echo "== pipeline (fake claude)"
FB="$WORK/fakebin"
mkdir -p "$FB" "$WORK/fake-state"
ln -s "$KIT/tests/fake-claude" "$FB/claude"
LOG="$WORK/fake-claude.log"
ak() {
  (cd "$P" && clean_env PATH="$FB:$PATH" FAKE_CLAUDE_LOG="$LOG" FAKE_STATE_DIR="$WORK/fake-state" \
    FAKE_REVIEW_CRITICAL=spec-reviewer "$@")
}

# run_steps RUN: every step from brief to a passed review and check, the way a
# user's own script would chain them. RUN is a function that runs one agent-kit command.
run_steps() {
  local run="$1" s rc round=1
  for s in define-requirements design-solution; do
    "$run" spec "$s" || return 1
  done
  "$run" plan && "$run" check || return 1
  while :; do
    rc=0
    "$run" review || rc=$?
    [ "$rc" -eq 0 ] && break
    [ "$rc" -eq 2 ] && [ "$round" -lt 3 ] || return 1
    "$run" repair || return 1
    round=$((round + 1))
  done
  "$run" check
}

check_fails "spec refuses the template brief"   ak ./scripts/spec.sh define-requirements
printf '# Brief\n\nA tiny todo app for a weekend hackathon.\n' > "$P/brief/requirements.md"
check_fails "spec needs a stage name"           ak ./scripts/spec.sh
check_fails "spec rejects an unknown stage"     ak ./scripts/spec.sh nope
check_fails "spec rejects an old stage name"    ak ./scripts/spec.sh discover
check_fails "spec rejects more than one stage"  ak ./scripts/spec.sh define-requirements design-solution
check_fails "a stage needs the earlier documents" ak ./scripts/spec.sh design-solution
check_fails "a failing stage exits non-zero"    ak env FAKE_FAIL_SKILL=define-requirements ./scripts/spec.sh define-requirements
check "one stage runs"                          ak ./scripts/spec.sh define-requirements
check "it writes only its own document"         test -s "$P/docs/01-requirements.md" -a ! -e "$P/docs/02-design.md"
check_fails "plan needs the design first"       ak ./scripts/plan.sh
check "spec design-solution"                    ak ./scripts/spec.sh design-solution
check "a stage can run again"                   ak ./scripts/spec.sh design-solution
check_fails "check needs the plan first"        ak ./scripts/check.sh
check_fails "review needs the plan first"       ak ./scripts/review.sh
check_fails "repair needs a review first"       ak ./scripts/repair.sh
check "plan writes the plan and tasks"          ak ./scripts/plan.sh
check "tasks written"                           test -s "$P/tasks/001-setup/task.md" -a -s "$P/docs/03-plan.md"
check "check passes on a complete plan"         ak ./scripts/check.sh
check_rc "review: blocking findings exit 2"   2 ak ./scripts/review.sh
check "review runs one round only"              test ! -e "$P/.workflow/reviews/round-2"
check "round 1 had the blocking finding"        test "$(jq '.blocking | length' "$P/.workflow/reviews/round-1/summary.json")" -eq 1
check "review state asks for a repair"          jq -e '.status == "NEEDS_REPAIR" and .round == 1 and .blocking == 1' "$P/.workflow/state/review.json"
check "repair fixes the findings"               ak ./scripts/repair.sh
check "repair does not review"                  test ! -e "$P/.workflow/reviews/round-2"
check_fails "repair needs a new review first"   ak ./scripts/repair.sh
check "review round 2 passes"                   ak ./scripts/review.sh
check "review passed in round 2"                jq -e '.status == "PASS" and .round == 2 and .summary == ".workflow/reviews/round-2/summary.json"' "$P/.workflow/state/review.json"
check "round 1 is kept"                         test -s "$P/.workflow/reviews/round-1/summary.json"
check_fails "repair refuses a passed review"    ak ./scripts/repair.sh
check "check passes after the review"           ak ./scripts/check.sh
check "every call had the guard settings"       sh -c "! grep -q 'settings=0' '$LOG'"
check "spec stages may write one doc only"      grep -q 'skill=design-solution agent= stage=spec allow=docs/02-design.md ' "$LOG"
check "plan may write the plan and tasks only"  grep -q 'skill=plan-tasks agent= stage=plan allow=docs/03-plan.md:tasks/ ' "$LOG"
check "repair may write docs and tasks only"    grep -q 'skill=repair-specs agent= stage=repair allow=docs/:tasks/ ' "$LOG"
check "the reviewer is read-only"               grep -q 'agent=spec-reviewer stage=review allow= settings=1 schema=1 tools=Read,Grep,Glob' "$LOG"
check "check, gate and approve never call Claude" test "$(grep -c 'stage=check\|stage=gate\|stage=approve' "$LOG")" -eq 0

echo "== spec checks (no AI)"
cp -R "$P/docs" "$WORK/good-docs"
cp -R "$P/tasks" "$WORK/good-tasks"
restore_specs() { rm -rf "$P/docs" "$P/tasks"; cp -R "$WORK/good-docs" "$P/docs"; cp -R "$WORK/good-tasks" "$P/tasks"; }
# spec_case NAME WANT FILE TEXT: append TEXT to FILE, run check, expect exit WANT, restore.
spec_case() {
  printf '%b' "$4" >> "$P/$3"
  check_rc "check: $1" "$2" ak ./scripts/check.sh
  restore_specs
}
spec_case "an open decision blocks"           2 docs/02-design.md '\n## Open decisions\n\n- DEC-001: Which login? Recommendation: email links.\n'
spec_case "an open decision sub-heading blocks" 2 docs/01-requirements.md '\n### DEC-002: Which currency?\n'
spec_case "a task question blocks"            2 tasks/002-core/task.md '\nOpen: Which font?\n'
spec_case "a placeholder blocks"              2 docs/01-requirements.md '\nThe limit is TBD.\n'
spec_case "an uncovered criterion blocks"     2 docs/01-requirements.md '  - REQ-002-AC2: Given a done todo, when the user undoes it, then it is open.\n'
spec_case "a requirement with no criterion blocks" 2 docs/01-requirements.md '- REQ-003 (Idea): A user can delete a todo.\n'
spec_case "an unknown ID in a task blocks"    2 tasks/002-core/task.md 'Also checks REQ-009-AC1.\n'
spec_case "an unknown ADR in a task blocks"   2 tasks/002-core/task.md 'Follows ADR-007.\n'
spec_case "a retired criterion needs no task" 0 docs/01-requirements.md '  - REQ-002-AC2 (retired): replaced by REQ-002-AC1.\n'
printf '  - REQ-002-AC3: Given 1000 todos, when the list opens, then it shows in 1 s.\n' >> "$P/docs/01-requirements.md"
spec_case "an excluded criterion needs no task" 0 docs/03-plan.md '\n## Coverage\n\n- REQ-002-AC3: excluded (out of scope for the first release)\n'
mkdir -p "$P/tasks/003-extra"
printf '## Goal\n\nKind: feature\n' > "$P/tasks/003-extra/task.md"
check_rc "check: a task with missing sections blocks" 2 ak ./scripts/check.sh
restore_specs
sed 's/^001$/003/' "$P/tasks/002-core/task.md" > "$WORK/t.md" && mv "$WORK/t.md" "$P/tasks/002-core/task.md"
check_rc "check: depending on a higher task blocks" 2 ak ./scripts/check.sh
restore_specs
check "check passes again after restore"        ak ./scripts/check.sh
check_fails "gate blocks before approval"    ak ./scripts/gate.sh
check_fails "approve refuses without a terminal" ak env -u CLAUDECODE ./scripts/approve.sh
check_fails "approve refuses inside an agent" ak env CLAUDECODE=1 ./scripts/approve.sh

# 'expect' gives approve a real terminal, like a person typing.
#   approve_in_terminal [DIR [COMMAND...]]
approve_in_terminal() {
  local dir="${1:-$P}"
  [ $# -gt 0 ] && shift
  (cd "$dir" && clean_env -u CLAUDECODE AK_APPROVE_CMD="${*:-./scripts/approve.sh}" expect -c '
    set timeout 30
    eval spawn $env(AK_APPROVE_CMD)
    expect {
      "Type APPROVE" { send "APPROVE\r" }
      timeout { exit 1 }
      eof { exit 1 }
    }
    expect eof
    catch wait result
    exit [lindex $result 3]')
}
if command -v expect >/dev/null 2>&1; then
  check "approve works in a terminal"        approve_in_terminal
  check "approval saved"                     test -s "$P/.workflow/approvals/spec-approved.json"
  check "gate passes after approval"         ak ./scripts/gate.sh
  echo "changed" >> "$P/docs/02-design.md"
  check_fails "gate blocks when docs change after approval" ak ./scripts/gate.sh
  printf '\n## Open decisions\n\n- DEC-003: Late question.\n' >> "$P/docs/02-design.md"
  check_fails "gate blocks an open decision" ak ./scripts/gate.sh
else
  echo "  skip  approve in a terminal (needs 'expect')"
fi

# ---------------------------------------------------------------------------
source "$KIT/tests/regressions.sh"

echo
echo "passed: $PASSED  failed: $FAILED"
[ "$FAILED" -eq 0 ]
