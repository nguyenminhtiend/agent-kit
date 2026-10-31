# Step A: write one spec document. 'agent-kit spec STAGE' runs one skill once.
# Run the stages yourself, in order; each one needs the documents of the stages
# before it. Each stage may write only its own document (the guard hook enforces this).

ak_spec() {
  [ $# -eq 1 ] || die "spec needs one stage name. Stages, in order: $(stage_names)"
  local stage="$1" entry skill output
  stage_exists "$stage" || die "unknown stage '$stage'. Stages, in order: $(stage_names)"

  enter_project
  check_brief

  # Inputs: every document of the earlier stages.
  for entry in $AK_SPEC_STAGES; do
    skill="${entry%%:*}"
    output="${entry#*:}"
    [ "$skill" = "$stage" ] && break
    [ -s "$output" ] || die "$output is missing. Run 'agent-kit spec $skill' first."
  done

  info "spec: $skill -> $output"
  engine_run "$skill" spec "$output" \
    "/$skill Read the brief and the earlier documents you need. Write $output. Do not create or change application code." \
    --model "$(cfg .models.spec opus)" \
    --permission-mode acceptEdits \
    --tools "Read,Write,Edit,Glob,Grep" >/dev/null ||
    die "stage $skill failed. See .workflow/logs/"

  [ -s "$output" ] || die "stage $skill finished but $output is missing or empty"
  ok "$output"
  next_step "$(next_spec_step "$skill")"
}

stage_exists() {
  local e
  for e in $AK_SPEC_STAGES; do [ "${e%%:*}" = "$1" ] && return 0; done
  return 1
}

stage_names() { printf '%s\n' "$AK_SPEC_STAGES" | cut -d: -f1 | paste -sd ' ' -; }

# The step after STAGE: the next stage, or the review after the last one.
next_spec_step() {
  local e found=0
  for e in $AK_SPEC_STAGES; do
    if [ "$found" -eq 1 ]; then printf 'spec %s\n' "${e%%:*}"; return 0; fi
    [ "${e%%:*}" = "$1" ] && found=1
  done
  printf 'review\n'
}
