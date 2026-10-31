# Engine adapter: the only place that calls an AI CLI.
# Claude Code only for now. A Codex adapter (codex exec) can be added here later.

# Load runner inputs from the kit, independently of which editor integrations
# were installed. Project installs carry these files in .agent-kit/.
engine_markdown_body() {
  awk 'NR == 1 && $0 == "---" { fm = 1; next } fm && $0 == "---" { fm = 0; next } !fm' "$1"
}

engine_agent_definition() {
  local name="$1" file description body
  file="$AGENT_KIT_HOME/agents/$name.md"
  [ -f "$file" ] || { warn "reviewer instructions not found: $file"; return 1; }
  description="$(yq -p yaml -oy --front-matter=extract '.description' "$file")" || return 1
  body="$(engine_markdown_body "$file")" || return 1
  jq -nc --arg n "$name" --arg d "$description" --arg p "$body" \
    '{($n): {description: $d, prompt: $p, tools: ["Read", "Grep", "Glob"]}}'
}

# Hook settings passed to every runner call. A global install does not touch
# your settings files, so the runner turns the guard hook on by itself.
engine_settings() {
  jq -nc --arg cmd "\"$AGENT_KIT_HOME/hooks/guard.sh\"" '{
    hooks: {PreToolUse: [{
      matcher: "Write|Edit|MultiEdit|NotebookEdit|Bash",
      hooks: [{type: "command", command: $cmd}]
    }]}
  }'
}

# engine_run NAME STAGE WRITE_ALLOW PROMPT [more claude flags...]
#   NAME         name for the log file in .workflow/logs/
#   STAGE        stage name; the guard hook uses it to know a stage is running
#   WRITE_ALLOW  paths this stage may write, separated by ":" ("" = nothing)
# Prints Claude's result JSON on stdout. Returns 1 if Claude reports an error.
engine_run() {
  local name="$1" stage="$2" allow="$3" prompt="$4"
  shift 4
  local log out rc=0 turns budget skill="" method
  log=".workflow/logs/$(date +%Y%m%d-%H%M%S)-$name.json"
  turns="$(cfg .limits.max_turns 30)" || return 1
  budget="$(cfg .limits.max_budget_usd 0)" || return 1

  case "$prompt" in
    /*)
      skill="${prompt%% *}"
      skill="${skill#/}"
      [ -f "$AGENT_KIT_HOME/skills/$skill/SKILL.md" ] || {
        warn "skill instructions not found: $skill"
        return 1
      }
      method="$(engine_markdown_body "$AGENT_KIT_HOME/skills/$skill/SKILL.md")" || return 1
      prompt="Follow the agent-kit skill instructions below.

$method

Stage request: ${prompt#* }"
      ;;
  esac

  set -- --output-format json \
         --permission-prompts none \
         --max-turns "$turns" \
         --settings "$(engine_settings)" \
         "$@"
  case "$budget" in 0|0.0|"") ;; *) set -- "$@" --max-budget-usd "$budget" ;; esac

  out="$(AGENT_KIT_STAGE="$stage" AGENT_KIT_WRITE_ALLOW="$allow" AGENT_KIT_SKILL="$skill" claude -p "$prompt" "$@" < /dev/null)" || rc=$?
  printf '%s\n' "$out" > "$log"

  if [ "$rc" -ne 0 ]; then
    warn "$name: claude exited with code $rc (log: $log)"
    return 1
  fi
  if ! printf '%s' "$out" | jq -e '.is_error == false and .subtype == "success"' >/dev/null 2>&1; then
    warn "$name: claude did not finish cleanly (log: $log)"
    return 1
  fi
  printf '%s' "$out" | jq -r --arg n "$name" '"  cost  \($n): $\(.total_cost_usd // 0)"' >&2 || true
  printf '%s\n' "$out"
}
