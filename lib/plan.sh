# Stage C: break the reviewed specs into small tasks, then assess readiness.

ak_plan() {
  enter_project
  check_spec_docs
  require_review_pass
  archive_old_tasks
  rm -f "$AK_READINESS_STATE"

  info "plan: plan-tasks -> $AK_PLAN_DOC and tasks/"
  engine_run plan-tasks plan "$AK_PLAN_DOC:tasks/" \
    "/plan-tasks Read the reviewed spec documents. Write $AK_PLAN_DOC and one task file per task ($AK_TASK_FILE). Do not create or change application code." \
    --model "$(cfg .models.plan opus)" \
    --permission-mode acceptEdits \
    --tools "Read,Write,Edit,Glob,Grep" >/dev/null ||
    die "plan-tasks failed. See .workflow/logs/"
  [ -s "$AK_PLAN_DOC" ] || die "$AK_PLAN_DOC is missing or empty"
  [ "$(count_tasks)" -gt 0 ] || die "no tasks/*/task.md files were written"
  ok "$AK_PLAN_DOC and $(count_tasks) task files"
  require_review_pass

  info "plan: assess-readiness -> $AK_READINESS_DOC"
  local out base input_hash current_hash summary
  summary="$(jq -r .last_review "$AK_REVIEW_STATE")/summary.json"
  input_hash="$(readiness_input_hash)" || die "cannot hash the readiness inputs"
  out="$(engine_run assess-readiness readiness "$AK_READINESS_DOC" \
    "/assess-readiness Check if the specs, the plan and the task files are ready for implementation. The last spec review passed; its findings are in $summary. Write $AK_READINESS_DOC. Return the verdict in the structured output." \
    --model "$(cfg .models.plan opus)" \
    --permission-mode acceptEdits \
    --tools "Read,Write,Edit,Glob,Grep" \
    --json-schema "$(cat "$AGENT_KIT_HOME/schemas/readiness.schema.json")")" ||
    die "assess-readiness failed. See .workflow/logs/"
  [ -s "$AK_READINESS_DOC" ] || die "$AK_READINESS_DOC is missing or empty"
  current_hash="$(readiness_input_hash)" || die "cannot hash the readiness inputs after assessment"
  [ "$input_hash" = "$current_hash" ] ||
    die "specs or tasks changed during readiness assessment. Run 'agent-kit plan' again on a stable baseline."

  # The runner writes the state file, not Claude. The hash ties the verdict
  # to the exact files that were assessed.
  base="$(baseline_hash)" || die "cannot hash the readiness baseline"
  printf '%s' "$out" | jq -e --arg h "$base" --arg t "$(now_utc)" '
    .structured_output
    | select(type == "object"
             and (.status | type == "string")
             and (.critical | type == "number")
             and (.major | type == "number")
             and (.unresolved_decisions | type == "number")
             and (.decisions | type == "array")
             and .unresolved_decisions == (.decisions | length)
             and (if .status == "READY" then .critical == 0 and .major == 0 and .unresolved_decisions == 0 else .status == "NOT_READY" end))
    | . + {spec_hash: $h, assessed_at: $t}
  ' > "$AK_READINESS_STATE.tmp" || { rm -f "$AK_READINESS_STATE.tmp"; die "assess-readiness returned no valid structured output"; }
  mv "$AK_READINESS_STATE.tmp" "$AK_READINESS_STATE"

  jq -r '"  \(.status): \(.critical) critical, \(.major) major, \(.unresolved_decisions) open decisions"' "$AK_READINESS_STATE" >&2
}

require_review_pass() {
  [ -f "$AK_REVIEW_STATE" ] || die "no review result yet. Run 'agent-kit review' first."
  jq -e '.status == "PASS"' "$AK_REVIEW_STATE" >/dev/null ||
    die "the last review did not pass. Run 'agent-kit review'."
  local current_hash
  current_hash="$(spec_hash)" || die "cannot hash the spec baseline"
  [ "$(jq -r .spec_hash "$AK_REVIEW_STATE")" = "$current_hash" ] ||
    die "spec documents changed after the last review. Run 'agent-kit review' again."
}

# Old tasks are moved away (never deleted) so a new plan starts clean.
archive_old_tasks() {
  local dest
  if [ -n "$(find tasks -mindepth 1 -maxdepth 1 ! -name .gitkeep -print -quit 2>/dev/null)" ]; then
    dest=".workflow/archive/tasks-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$dest"
    find tasks -mindepth 1 -maxdepth 1 ! -name .gitkeep -exec mv {} "$dest/" \;
    info "moved old tasks to $dest"
  fi
}
