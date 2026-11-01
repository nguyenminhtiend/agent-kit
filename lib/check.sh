# 'agent-kit check': the spec checks that code can do exactly. No AI, no cost.
# Run it any time after 'agent-kit plan'. 'approve' and 'gate' run it again.
#   Exit 0 = every check passed, 2 = problems found (listed), 1 = missing inputs.

ak_check() {
  [ $# -eq 0 ] || die "unknown option for check: $1"
  enter_project
  check_spec_docs
  check_plan
  info "spec checks (no AI)"
  if spec_checks; then
    if review_passed_now; then
      next_step "approve   (a person, in a terminal, after reading docs/ and tasks/)"
    else
      next_step review
    fi
    return 0
  fi
  info "next: fix the files, or answer the open decisions in the brief's Decisions section and run the steps again from the first changed document"
  return "$AK_EXIT_NEEDS_WORK"
}

# IDs used by the skills: REQ-001, REQ-001-AC1, ADR-001, DEC-001.
AK_ID_RE='REQ-[0-9]+(-AC[0-9]+)?'

# The first REQ or AC ID on each line that matches PATTERN (case-insensitive).
first_id_on_lines() {  # pattern file
  awk -v pat="$1" 'tolower($0) ~ pat && match($0, /REQ-[0-9]+(-AC[0-9]+)?/) { print substr($0, RSTART, RLENGTH) }' "$2" | LC_ALL=C sort -u
}

# Lines with a DEC-nnn under any "Open decisions" heading, including its sub-headings.
open_decision_lines() {  # files...
  awk '
    FNR == 1 { open = 0 }
    /^#+[ \t]/ {
      lvl = match($0, /[^#]/) - 1
      if (tolower($0) ~ /open decisions/) { open = 1; olvl = lvl; next }
      if (open && lvl <= olvl) open = 0
    }
    open && /DEC-[0-9]+/ { printf "%s:%d: %s\n", FILENAME, FNR, $0 }
  ' "$@"
}

# The lines of one section (from a heading that contains NAME to the next heading).
section_lines() {  # name file
  awk -v name="$1" '
    /^#+[ \t]/ { inside = (index(tolower($0), name) > 0); next }
    inside { print }
  ' "$2"
}

# Prints one line per problem (and ok lines for passed groups). Returns 1 on any problem.
spec_checks() {
  local bad=0 tmp t own name dep line h req
  local req_doc="$AK_DOC_REQUIREMENTS" design_doc="$AK_DOC_DESIGN" plan_doc="$AK_PLAN_DOC"
  local task_files
  task_files="$(find tasks -mindepth 2 -maxdepth 2 -type f -name task.md | LC_ALL=C sort)"
  tmp="$(mktemp -d)" || return 1

  # 1. Nothing left open: decisions, task questions, placeholders.
  # shellcheck disable=SC2086  # paths have no spaces
  open_decision_lines "$req_doc" "$design_doc" "$plan_doc" $task_files > "$tmp/open"
  # shellcheck disable=SC2086
  grep -nE '^[[:space:]]*([-*][[:space:]]*)?Open:' $task_files >> "$tmp/open" 2>/dev/null || true
  # shellcheck disable=SC2086
  grep -nwE 'TODO|TBD|FIXME' "$req_doc" "$design_doc" "$plan_doc" $task_files > "$tmp/todo" 2>/dev/null || true
  # shellcheck disable=SC2086
  grep -nF '???' "$req_doc" "$design_doc" "$plan_doc" $task_files >> "$tmp/todo" 2>/dev/null || true
  if [ -s "$tmp/open" ]; then
    bad=1
    while IFS= read -r line; do fail "open decision or question: $line"; done < "$tmp/open"
  else
    ok "no open decisions or task questions"
  fi
  if [ -s "$tmp/todo" ]; then
    bad=1
    while IFS= read -r line; do fail "placeholder: $line"; done < "$tmp/todo"
  else
    ok "no TODO, TBD, FIXME or ???"
  fi

  # 2. Requirements: every REQ has a criterion; every in-scope criterion has a task.
  { grep -oE "$AK_ID_RE" "$req_doc" || true; } | LC_ALL=C sort -u > "$tmp/ids"
  grep -E -- '-AC[0-9]+$' "$tmp/ids" > "$tmp/acs" || true
  grep -vE -- '-AC[0-9]+$' "$tmp/ids" > "$tmp/reqs" || true
  first_id_on_lines retired "$req_doc" > "$tmp/retired"
  first_id_on_lines 'excluded|out of scope' "$plan_doc" > "$tmp/excluded"
  cat "$tmp/retired" "$tmp/excluded" > "$tmp/skip"
  # shellcheck disable=SC2086
  { cat $task_files | grep -oE "$AK_ID_RE" || true; } | LC_ALL=C sort -u > "$tmp/task-ids"

  if [ ! -s "$tmp/acs" ]; then
    fail "$req_doc: no acceptance criteria (REQ-001-AC1, ...) found"; bad=1
  fi
  while IFS= read -r req; do
    [ -n "$req" ] || continue
    grep -qxF "$req" "$tmp/retired" && continue
    grep -q "^$req-AC" "$tmp/acs" || { fail "$req_doc: $req has no acceptance criterion"; bad=1; }
  done < "$tmp/reqs"
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    req="${t%-AC*}"
    grep -qxF "$t" "$tmp/skip" && continue
    grep -qxF "$req" "$tmp/skip" && continue
    grep -qxF "$t" "$tmp/task-ids" || { fail "$t is not covered by any task (or marked excluded in $plan_doc)"; bad=1; }
  done < "$tmp/acs"

  # 3. Every ID a task or the plan names exists.
  # shellcheck disable=SC2086
  { cat "$plan_doc" $task_files | grep -oE "$AK_ID_RE" || true; } | LC_ALL=C sort -u > "$tmp/named"
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    grep -qxF "$t" "$tmp/ids" || { fail "$t is named in the plan or a task, but $req_doc does not define it"; bad=1; }
  done < "$tmp/named"
  # shellcheck disable=SC2086
  { cat $task_files | grep -oE 'ADR-[0-9]+' || true; } | LC_ALL=C sort -u > "$tmp/adrs"
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    grep -qE "$t([^0-9]|$)" "$design_doc" || { fail "$t is named in a task, but $design_doc does not define it"; bad=1; }
  done < "$tmp/adrs"

  # 4. Task files: name, sections, kind, order, listed in the plan.
  for t in $task_files; do
    name="$(basename "$(dirname "$t")")"
    own="${name%%-*}"
    case "$name" in
      [0-9][0-9][0-9]-*) ;;
      *) fail "$t: folder name must start with a 3-digit number (001-setup)"; bad=1; continue ;;
    esac
    for h in "goal" "covers" "depends on" "scope" "acceptance criteria" "test plan"; do
      awk -v h="$h" '/^#+[ \t]/ && index(tolower($0), h) { found = 1 } END { exit !found }' "$t" ||
        { fail "$t: no '$h' section"; bad=1; }
    done
    grep -qE 'Kind:[[:space:]]*`?(feature|setup|spike)' "$t" ||
      { fail "$t: no 'Kind: feature|setup|spike'"; bad=1; }
    for dep in $(section_lines "depends on" "$t" | tr -c '0-9' ' '); do
      [ "${#dep}" -eq 3 ] || continue
      if [ "$((10#$dep))" -ge "$((10#$own))" ]; then
        fail "$t: depends on $dep, which is not a lower number"; bad=1
      elif [ -z "$(find tasks -mindepth 1 -maxdepth 1 -type d -name "$dep-*" -print -quit)" ]; then
        fail "$t: depends on $dep, which has no task folder"; bad=1
      fi
    done
    grep -qE "(^|[^0-9])$own([^0-9]|$)" "$plan_doc" || { fail "$t: task $own is not in $plan_doc"; bad=1; }
  done

  rm -rf "$tmp"
  [ "$bad" -eq 0 ] && ok "requirements, coverage and task files"
  return "$bad"
}
