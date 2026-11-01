# Step C: break the requirements and design into small tasks.
#   agent-kit plan   plan-tasks: the plan document and tasks/
# Then run 'agent-kit check' (free, no AI) and 'agent-kit review'.

ak_plan() {
  [ $# -eq 0 ] || die "unknown option for plan: $1"
  enter_project
  check_spec_docs
  archive_old_tasks

  info "plan: plan-tasks -> $AK_PLAN_DOC and tasks/"
  engine_run plan-tasks plan "$AK_PLAN_DOC:tasks/" \
    "/plan-tasks Read the requirements and the design. Write $AK_PLAN_DOC and one task file per task ($AK_TASK_FILE). Do not create or change application code." \
    --model "$(cfg .models.plan opus)" \
    --permission-mode acceptEdits \
    --tools "Read,Write,Edit,Glob,Grep" >/dev/null ||
    die "plan-tasks failed. See .workflow/logs/"
  [ -s "$AK_PLAN_DOC" ] || die "$AK_PLAN_DOC is missing or empty"
  [ "$(count_tasks)" -gt 0 ] || die "no tasks/*/task.md files were written"
  ok "$AK_PLAN_DOC and $(count_tasks) task files"
  next_step "check   (free, no AI), then review"
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
