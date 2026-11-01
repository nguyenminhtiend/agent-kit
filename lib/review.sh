# Step B: independent review of everything (brief, requirements, design, plan,
# tasks), and repair. Runs after 'agent-kit plan'.
#   agent-kit review   one round: read-only reviewers in parallel (default: one).
#                      Exit 0 = PASS, 2 = blocking findings, 1 = error.
#   agent-kit repair   fix the blocking findings of the last review, once.
# There is no loop here: run review -> repair -> review yourself (or in your own
# script) as many times as you want.

ak_review() {
  [ $# -eq 0 ] || die "unknown option for review: $1"
  enter_project
  check_spec_docs
  check_plan

  local agents block_on schema round dir a pids p failed blocking reviewed_hash current_hash
  agents="$(cfg_list .review.agents | tr '\n' ' ')"
  agents="${agents% }"
  [ -n "${agents// /}" ] || agents="spec-reviewer"
  block_on="$(cfg_list .review.block_on | jq -R . | jq -sc .)"
  [ "$block_on" != "[]" ] || block_on='["critical","major"]'
  schema="$(cat "$AGENT_KIT_HOME/schemas/review.schema.json")"
  # An old PASS must not survive a review that fails or is interrupted.
  rm -f "$AK_REVIEW_STATE"

  # Rounds count up and are never overwritten, so earlier results stay readable.
  round=$(( $(last_review_round) + 1 ))
  dir=".workflow/reviews/round-$round"
  mkdir -p "$dir/reviewers"
  info "review round $round: $agents"
  reviewed_hash="$(baseline_hash)" || die "cannot hash the spec baseline"

  # Reviewers run in parallel. Each one is a fresh session with its own context.
  pids=""
  for a in $agents; do
    review_one "$a" "$schema" "$dir/reviewers/$a.json" &
    pids="$pids $!"
  done
  failed=0
  for p in $pids; do wait "$p" || failed=1; done
  [ "$failed" -eq 0 ] || die "a reviewer failed. See .workflow/logs/"
  current_hash="$(baseline_hash)" || die "cannot hash the spec baseline after review"
  [ "$reviewed_hash" = "$current_hash" ] ||
    die "brief, docs or tasks changed during review. Run 'agent-kit review' again on a stable baseline."

  jq -s --argjson block "$block_on" '
    [ .[] | .reviewer as $r | .findings[] | . + {reviewer: $r} ] as $all
    | { findings: $all,
        blocking: [ $all[] | .severity as $s | select(any($block[]; . == $s)) ] }
  ' "$dir"/reviewers/*.json > "$dir/summary.json"
  blocking="$(jq '.blocking | length' "$dir/summary.json")"

  if [ "$blocking" -eq 0 ]; then
    write_review_state PASS "$round" "$dir/summary.json" 0 "$reviewed_hash" || die "cannot save the review result"
    ok "review passed in round $round. All findings: $dir/summary.json"
    next_step "check   (free, no AI; skip if it passed on these files), then approve"
    return 0
  fi

  write_review_state NEEDS_REPAIR "$round" "$dir/summary.json" "$blocking" "$reviewed_hash" ||
    die "cannot save the review result"
  fail "$blocking blocking findings in round $round:"
  jq -r '.blocking[] | "        [\(.severity)] \(.document): \(.issue)"' "$dir/summary.json" >&2
  next_step "repair   (or fix the files yourself), then review again"
  return "$AK_EXIT_NEEDS_WORK"
}

ak_repair() {
  [ $# -eq 0 ] || die "unknown option for repair: $1"
  enter_project
  check_spec_docs
  check_plan

  [ -f "$AK_REVIEW_STATE" ] || die "no review result yet. Run 'agent-kit review' first."
  local status summary round current_hash
  status="$(jq -r .status "$AK_REVIEW_STATE")"
  [ "$status" != PASS ] || die "the last review passed; nothing to repair. Next: agent-kit plan"
  current_hash="$(baseline_hash)" || die "cannot hash the spec baseline"
  [ "$(jq -r .spec_hash "$AK_REVIEW_STATE")" = "$current_hash" ] ||
    die "brief, docs or tasks changed after the last review. Run 'agent-kit review' again first."
  summary="$(jq -r .summary "$AK_REVIEW_STATE")"
  round="$(jq -r .round "$AK_REVIEW_STATE")"
  [ -s "$summary" ] || die "review summary not found: $summary"

  info "repair: $(jq '.blocking | length' "$summary") blocking findings from $summary"
  engine_run "repair-round-$round" repair "docs/:tasks/" \
    "/repair-specs Repair round $round. Fix the findings in the \"blocking\" list of $summary. Update the affected documents (requirements, design, plan, task files) and every later one that depends on them. Do not create or change application code." \
    --model "$(cfg .models.spec opus)" \
    --permission-mode acceptEdits \
    --tools "Read,Write,Edit,Glob,Grep" >/dev/null ||
    die "repair failed. See .workflow/logs/"
  ok "documents updated (see the revision log at the end of each changed one)"
  next_step review
}

# review_one AGENT SCHEMA OUTFILE
# Runs one reviewer agent. Read-only: it gets only Read, Grep and Glob.
review_one() {
  local agent="$1" schema="$2" outfile="$3" out definition
  definition="$(engine_agent_definition "$agent")" || return 1
  out="$(engine_run "review-$agent" review "" \
    "Review the brief, the requirements, the design, the plan and every task file. Follow your reviewer instructions. Report every finding in the structured output." \
    --agent "$agent" \
    --agents "$definition" \
    --model "$(cfg .models.review opus)" \
    --tools "Read,Grep,Glob" \
    --json-schema "$schema")" || return 1

  printf '%s' "$out" | jq -e --arg r "$agent" '
    .structured_output
    | select(type == "object" and (.status | type == "string") and (.findings | type == "array"))
    | . + {reviewer: $r}
  ' > "$outfile" || { warn "$agent: structured output is missing or has the wrong shape"; return 1; }
}

# Highest round number in .workflow/reviews/ (0 when there is none).
last_review_round() {
  local d n max=0
  for d in .workflow/reviews/round-*; do
    [ -d "$d" ] || continue
    n="${d##*/round-}"
    case "$n" in ''|*[!0-9]*) continue ;; esac
    if [ "$n" -gt "$max" ]; then max="$n"; fi
  done
  printf '%s\n' "$max"
}

# write_review_state STATUS ROUND SUMMARY BLOCKING SPEC_HASH
write_review_state() {
  jq -n --arg s "$1" --argjson r "$2" --arg f "$3" --argjson b "$4" --arg h "$5" --arg t "$(now_utc)" \
    '{status: $s, round: $r, summary: $f, blocking: $b, spec_hash: $h, finished_at: $t}' > "$AK_REVIEW_STATE.tmp" || return 1
  mv "$AK_REVIEW_STATE.tmp" "$AK_REVIEW_STATE"
}
