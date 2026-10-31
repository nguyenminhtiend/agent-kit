# Stage A: write the spec documents. One skill per stage, in a fixed order.
# Each stage may write only its own document (the guard hook enforces this).

ak_spec() {
  local from="" started=1 entry skill output
  while [ $# -gt 0 ]; do
    case "$1" in
      --from) [ $# -ge 2 ] || die "--from needs a stage name"; from="$2"; shift 2 ;;
      *) die "unknown option for spec: $1" ;;
    esac
  done

  enter_project
  check_brief

  if [ -n "$from" ]; then
    stage_exists "$from" ||
      die "unknown stage '$from'. Stages: $(printf '%s\n' "$AK_SPEC_STAGES" | cut -d: -f1 | tr '\n' ' ')"
    started=0
  fi

  for entry in $AK_SPEC_STAGES; do
    skill="${entry%%:*}"
    output="${entry#*:}"
    if [ "$started" -eq 0 ]; then
      [ "$skill" = "$from" ] || continue
      started=1
    fi

    info "spec: $skill -> $output"
    engine_run "$skill" spec "$output" \
      "/$skill Read the brief and the earlier documents you need. Write $output. Do not create or change application code." \
      --model "$(cfg .models.spec opus)" \
      --permission-mode acceptEdits \
      --tools "Read,Write,Edit,Glob,Grep" >/dev/null ||
      die "stage $skill failed. Fix the cause, then run: agent-kit spec --from $skill"

    [ -s "$output" ] ||
      die "stage $skill finished but $output is missing or empty. Run: agent-kit spec --from $skill"
    ok "$output"
  done
}

stage_exists() {
  local e
  for e in $AK_SPEC_STAGES; do [ "${e%%:*}" = "$1" ] && return 0; done
  return 1
}
