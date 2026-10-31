# Stage B: independent review by read-only reviewer agents, then a bounded
# repair loop: review -> repair -> review again, at most max_review_cycles rounds.

ak_review() {
  enter_project
  check_spec_docs

  local max agents block_on schema round dir a pids p failed blocking reviewed_hash current_hash
  max="$(cfg .workflow.max_review_cycles 3)"
  agents="$(cfg_list .review.agents | tr '\n' ' ')"
  agents="${agents% }"
  [ -n "${agents// /}" ] || agents="product-reviewer architecture-reviewer qa-reviewer"
  block_on="$(cfg_list .review.block_on | jq -R . | jq -sc .)"
  [ "$block_on" != "[]" ] || block_on='["critical","major"]'
  schema="$(cat "$AGENT_KIT_HOME/schemas/review.schema.json")"
  rm -f "$AK_REVIEW_STATE"

  round=1
  while :; do
    dir=".workflow/reviews/round-$round"
    rm -rf "$dir"
    mkdir -p "$dir/reviewers"
    info "review round $round of $max: $agents"
    reviewed_hash="$(spec_hash)" || die "cannot hash the spec baseline"

    # Reviewers run in parallel. Each one is a fresh session with its own context.
    pids=""
    for a in $agents; do
      review_one "$a" "$schema" "$dir/reviewers/$a.json" &
      pids="$pids $!"
    done
    failed=0
    for p in $pids; do wait "$p" || failed=1; done
    [ "$failed" -eq 0 ] || die "a reviewer failed. See .workflow/logs/"
    current_hash="$(spec_hash)" || die "cannot hash the spec baseline after review"
    [ "$reviewed_hash" = "$current_hash" ] ||
      die "specs changed during review. Run 'agent-kit review' again on a stable baseline."

    jq -s --argjson block "$block_on" '
      [ .[] | .reviewer as $r | .findings[] | . + {reviewer: $r} ] as $all
      | { findings: $all,
          blocking: [ $all[] | .severity as $s | select(any($block[]; . == $s)) ] }
    ' "$dir"/reviewers/*.json > "$dir/summary.json"
    blocking="$(jq '.blocking | length' "$dir/summary.json")"

    if [ "$blocking" -eq 0 ]; then
      write_review_state PASS "$round" "$dir" "$reviewed_hash" || die "cannot save the review result"
      ok "review passed in round $round. All findings: $dir/summary.json"
      return 0
    fi

    if [ "$round" -ge "$max" ]; then
      write_review_state BLOCKED "$round" "$dir" "$reviewed_hash" || die "cannot save the review result"
      fail "$blocking blocking findings are still open after $max rounds:"
      jq -r '.blocking[] | "        [\(.severity)] \(.document): \(.issue)"' "$dir/summary.json" >&2
      return 1
    fi

    info "repair: $blocking blocking findings"
    engine_run "repair-round-$round" repair "docs/" \
      "/repair-specs Fix the findings in the \"blocking\" list of $dir/summary.json. Update the affected documents in docs/ and every later document that depends on them. Do not create or change application code." \
      --model "$(cfg .models.spec opus)" \
      --permission-mode acceptEdits \
      --tools "Read,Write,Edit,Glob,Grep" >/dev/null ||
      die "repair failed. See .workflow/logs/"
    round=$((round + 1))
  done
}

# review_one AGENT SCHEMA OUTFILE
# Runs one reviewer agent. Read-only: it gets only Read, Grep and Glob.
review_one() {
  local agent="$1" schema="$2" outfile="$3" out definition
  definition="$(engine_agent_definition "$agent")" || return 1
  out="$(engine_run "review-$agent" review "" \
    "Review the spec documents: brief/ and docs/01 to docs/06. Follow your reviewer instructions. Report every finding in the structured output." \
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

write_review_state() {
  jq -n --arg s "$1" --argjson r "$2" --arg d "$3" --arg h "$4" --arg t "$(now_utc)" \
    '{status: $s, rounds: $r, last_review: $d, spec_hash: $h, finished_at: $t}' > "$AK_REVIEW_STATE.tmp" || return 1
  mv "$AK_REVIEW_STATE.tmp" "$AK_REVIEW_STATE"
}
