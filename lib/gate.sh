# Step D: human approval and the hard gate.
# No AI here: only files, JSON, hashes and the spec checks. The AI judged quality
# in earlier steps; this script decides whether coding may start.

# gate_checks MODE    MODE = full | before-approval
# Prints one line per check. Returns 0 only when every check passes.
gate_checks() {
  local mode="$1" bad=0 f n base
  base="$(baseline_hash)" || return 1

  for f in $AK_BRIEF $(spec_doc_paths) $AK_PLAN_DOC; do
    if [ -s "$f" ]; then ok "$f"; else fail "$f is missing or empty"; bad=1; fi
  done
  n="$(count_tasks)"
  if [ "$n" -gt 0 ]; then ok "$n task files in tasks/"; else fail "no tasks/*/task.md files"; bad=1; fi
  [ "$bad" -eq 0 ] || return 1

  if [ ! -f "$AK_REVIEW_STATE" ]; then
    fail "no review result (run 'agent-kit review')"; bad=1
  elif ! jq -e '.status == "PASS"' "$AK_REVIEW_STATE" >/dev/null; then
    fail "review status is $(jq -r .status "$AK_REVIEW_STATE")"; bad=1
  elif [ "$(jq -r .spec_hash "$AK_REVIEW_STATE")" != "$base" ]; then
    fail "brief, docs or tasks changed after the review (run 'agent-kit review')"; bad=1
  else
    ok "review passed"
  fi

  spec_checks || bad=1

  if [ "$mode" = full ]; then
    if [ ! -f "$AK_APPROVAL" ]; then
      fail "not approved yet (a person runs 'agent-kit approve')"; bad=1
    elif [ "$(jq -r .spec_hash "$AK_APPROVAL")" != "$base" ]; then
      fail "approval is stale: brief, docs or tasks changed after approval"; bad=1
    else
      ok "approved by $(jq -r .approved_by "$AK_APPROVAL") at $(jq -r .approved_at "$AK_APPROVAL")"
    fi
  fi

  return "$bad"
}

ak_gate() {
  enter_project
  info "gate"
  if gate_checks full; then
    info "READY: implementation may start"
  else
    die "BLOCKED: fix the failed checks above"
  fi
}

ak_approve() {
  enter_project

  # Best effort: an agent must not approve its own work. The guard hook also
  # blocks agents from running this command or writing the approval file.
  if [ -n "${AGENT_KIT_STAGE:-}" ] || [ -n "${CLAUDECODE:-}" ] ||
     [ -n "${CODEX_SANDBOX:-}" ] || [ -n "${CODEX_SANDBOX_NETWORK_DISABLED:-}" ]; then
    die "approve must be run by a person in their own terminal, not by an agent"
  fi
  { [ -t 0 ] && [ -t 1 ]; } || die "approve needs an interactive terminal"

  info "checking the spec baseline"
  gate_checks before-approval || die "cannot approve yet: fix the failed checks above"

  local base answer by
  base="$(baseline_hash)" || die "cannot hash the spec baseline"
  echo
  echo "Baseline: brief/, docs/ and $(count_tasks) task files in tasks/, exactly as they are now"
  echo "Hash:     $base"
  printf 'Type APPROVE to approve: '
  IFS= read -r answer || true
  [ "$answer" = "APPROVE" ] || die "not approved"
  gate_checks before-approval || die "the baseline is no longer ready for approval"
  [ "$base" = "$(baseline_hash)" ] || die "the baseline changed while awaiting approval; review it and approve again"

  by="$(git config user.name 2>/dev/null || true)"
  [ -n "$by" ] || by="$(id -un)"
  jq -n --arg h "$base" --arg by "$by" --arg t "$(now_utc)" \
    '{spec_hash: $h, approved_by: $by, approved_at: $t}' > "$AK_APPROVAL"
  ok "approved. 'agent-kit gate' passes until brief/, docs/ or tasks/ change."
}
