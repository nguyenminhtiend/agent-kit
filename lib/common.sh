# Shared helpers for the agent-kit runner. Sourced by bin/agent-kit.
# Written for bash 3.2 (the macOS default): no associative arrays, no mapfile.

AK_CONFIG_FILE="agent-kit.toml"

# Document paths inside the workspace. Skills and agents name documents only by
# role ("the design"); doc_map tells Claude where each one is. Change names here only.
AK_BRIEF="brief/requirements.md"
AK_BRIEF_MARKER="agent-kit:brief-template"
AK_DOC_REQUIREMENTS="docs/01-requirements.md"
AK_DOC_DESIGN="docs/02-design.md"
AK_PLAN_DOC="docs/03-plan.md"
AK_TASK_FILE="tasks/NNN-short-name/task.md"

# Spec stages in run order: "<skill>:<document it writes>".
AK_SPEC_STAGES="define-requirements:$AK_DOC_REQUIREMENTS
design-solution:$AK_DOC_DESIGN"

# Sent with every runner call: which path holds which document.
doc_map() {
  cat <<EOF
Documents (paths from the current folder):
- brief: $(dirname "$AK_BRIEF")/ (start with $AK_BRIEF)
- requirements: $AK_DOC_REQUIREMENTS
- design: $AK_DOC_DESIGN
- plan: $AK_PLAN_DOC
- task files: $AK_TASK_FILE, one folder per task, numbered in build order
EOF
}

# Files only the runner (or a person) may write. The guard hook protects them.
AK_REVIEW_STATE=".workflow/state/review.json"
AK_APPROVAL=".workflow/approvals/spec-approved.json"

info() { printf '==> %s\n' "$*" >&2; }
ok()   { printf '  ok    %s\n' "$*" >&2; }
fail() { printf '  FAIL  %s\n' "$*" >&2; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

# Exit code of a step that ran fine but found work to do: blocking review
# findings, or failed spec checks. Errors and missing inputs exit 1.
AK_EXIT_NEEDS_WORK=2

# Print the command to run next, with the same --workspace the user gave.
next_step() { info "next: agent-kit${AGENT_KIT_WORKSPACE:+ -w $AGENT_KIT_WORKSPACE} $*"; }

now_utc() { date -u +%Y-%m-%dT%H:%M:%SZ; }

need_tools() {
  local t
  for t in "$@"; do
    command -v "$t" >/dev/null 2>&1 || die "missing tool: $t (run 'agent-kit doctor')"
  done
}

# Walk up from the current folder until we find agent-kit.toml.
find_project_root() {
  local d
  d="$(pwd -P)"
  while :; do
    if [ -f "$d/$AK_CONFIG_FILE" ]; then printf '%s\n' "$d"; return 0; fi
    [ "$d" = "/" ] && return 1
    d="$(dirname "$d")"
  done
}

# The workspace holds brief/, docs/, tasks/ and .workflow/ for one piece of work.
# Order: --workspace / AGENT_KIT_WORKSPACE, then [paths] workspace, then ".".
# Prints the path relative to the project root. Call from the project root.
workspace_rel() {
  local ws="${AGENT_KIT_WORKSPACE:-}"
  [ -n "$ws" ] || ws="$(cfg .paths.workspace .)" || return 1
  while :; do case "$ws" in ./*) ws="${ws#./}" ;; */) ws="${ws%/}" ;; *) break ;; esac; done
  [ -n "$ws" ] || ws=.
  printf '%s\n' "$ws" | grep -Eq '^[A-Za-z0-9._][A-Za-z0-9._/-]*$' || {
    fail "workspace must be a relative path of letters, digits, '.', '_', '-' and '/': $ws"
    return 1
  }
  case "/$ws/" in
    */../*|*//*) fail "workspace must stay inside the project: $ws"; return 1 ;;
  esac
  case "$ws" in
    .agent-kit|.agent-kit/*|.agent-kit-backup*|.git|.git/*|.workflow|.workflow/*|*/.workflow|*/.workflow/*)
      fail "workspace may not be inside a folder agent-kit or git manages: $ws"; return 1 ;;
  esac
  printf '%s\n' "$ws"
}

# Move to the workspace (inside the project) and make sure its folders exist.
enter_project() {
  local root ws
  root="$(find_project_root)" || die "no $AK_CONFIG_FILE here or above. Run 'agent-kit init' first."
  cd "$root"
  load_config || die "invalid $AK_CONFIG_FILE; fix it before running the pipeline"
  ws="$(workspace_rel)" || die "invalid workspace"
  [ -d "$ws" ] || die "workspace not found: $ws. Run 'agent-kit init --workspace $ws' first."
  cd -P "$ws"
  case "$(pwd -P)/" in
    "$root"/*) ;;
    *) die "workspace $ws resolves outside the project" ;;
  esac
  AK_WS="$ws"
  export AGENT_KIT_PROJECT_DIR="$root" AGENT_KIT_WORKSPACE_DIR="$(pwd -P)"
  [ "$ws" = . ] || info "workspace: $ws"
  check_no_symlinks brief docs tasks || die "the baseline must contain regular files and directories"
  mkdir -p docs tasks .workflow/state .workflow/reviews .workflow/logs .workflow/approvals
}

# Parse before each pipeline step. Missing settings get defaults; invalid settings stop
# the command before any stage runs or an existing plan is archived.
load_config() {
  AK_CONFIG_JSON="$(yq -p toml -o json '.' "$AK_CONFIG_FILE" 2>/dev/null)" || {
    fail "cannot parse $AK_CONFIG_FILE as TOML"
    return 1
  }
  printf '%s' "$AK_CONFIG_JSON" | jq -e '
    def positive_integer: type == "number" and . > 0 and floor == .;
    def nonempty_string: type == "string" and length > 0;
    type == "object"
    and (if has("paths") then .paths | type == "object"
         and (if has("workspace") then .workspace | nonempty_string else true end) else true end)
    and (if has("models") then .models | type == "object"
         and all(to_entries[] | select(.key == "spec" or .key == "review" or .key == "plan"); .value | nonempty_string) else true end)
    and (if has("limits") then .limits | type == "object"
         and (if has("max_turns") then .max_turns | positive_integer else true end)
         and (if has("max_budget_usd") then .max_budget_usd | type == "number" and . >= 0 else true end) else true end)
    and (if has("review") then .review | type == "object"
         and (if has("agents") then .agents | type == "array" and length > 0
              and all(.[]; type == "string" and test("^[a-z0-9][a-z0-9_-]*$")) else true end)
         and (if has("block_on") then .block_on | type == "array" and length > 0
              and all(.[]; . == "critical" or . == "major" or . == "minor") else true end) else true end)
  ' >/dev/null 2>&1 || {
    fail "$AK_CONFIG_FILE has invalid settings (check section types, workspace, positive turn limit, nonnegative budget, models and review lists)"
    return 1
  }
}

# Read one value from agent-kit.toml, with a default.
#   cfg .limits.max_turns 30
cfg() {
  local v
  [ -n "${AK_CONFIG_JSON:-}" ] || load_config || return 1
  v="$(printf '%s' "$AK_CONFIG_JSON" | jq -r "$1")" || return 1
  if [ -z "$v" ] || [ "$v" = "null" ]; then printf '%s\n' "${2:-}"; else printf '%s\n' "$v"; fi
}

# Read a list from agent-kit.toml, one item per line.
cfg_list() {
  [ -n "${AK_CONFIG_JSON:-}" ] || load_config || return 1
  printf '%s' "$AK_CONFIG_JSON" | jq -r "($1 // []) | .[]"
}

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -d' ' -f1
  else shasum -a 256 | cut -d' ' -f1; fi
}

# Symlinks (including dangling links and directory aliases) cannot be part of
# a reviewed baseline: file checks and hashes must refer to the same contents.
check_no_symlinks() {
  local existing=() p link
  for p in "$@"; do
    if [ -e "$p" ] || [ -L "$p" ]; then existing+=("$p"); fi
  done
  [ "${#existing[@]}" -gt 0 ] || return 0
  link="$(find "${existing[@]}" -type l -print -quit)" || return 1
  if [ -n "$link" ]; then
    fail "symlinks are not allowed in the baseline: $link"
    return 1
  fi
}

# One hash over a set of files and folders (paths relative to the project).
# Missing paths are skipped. File order is stable, so the hash is too.
content_hash() {
  local existing=() p digest exclude=""
  if [ "${1:-}" = --exclude ]; then exclude="$2"; shift 2; fi
  check_no_symlinks "$@" || return 1
  for p in "$@"; do [ -e "$p" ] && existing+=("$p"); done
  if [ "${#existing[@]}" -eq 0 ]; then printf 'empty\n'; return 0; fi
  find "${existing[@]}" -type f ! -path "$exclude" ! -name '.gitkeep' ! -name '.DS_Store' -print0 | LC_ALL=C sort -z |
    while IFS= read -r -d '' f; do
      digest="$(sha256 < "$f")" || exit 1
      printf '%s  %s\n' "$digest" "$f"
    done | sha256
}

spec_doc_paths() { printf '%s\n' "$AK_SPEC_STAGES" | cut -d: -f2; }

# Hash of the whole baseline: brief, all docs and all tasks. The review, the
# approval and the gate are all bound to it.
baseline_hash() { content_hash brief docs tasks; }

count_tasks() {
  find tasks -mindepth 2 -maxdepth 2 -type f -name task.md 2>/dev/null | wc -l | tr -d ' '
}

check_brief() {
  [ -s "$AK_BRIEF" ] || die "$AK_BRIEF is missing or empty. Write your brief first."
  if grep -q "$AK_BRIEF_MARKER" "$AK_BRIEF"; then
    die "$AK_BRIEF is still the template. Fill it in and delete the template marker line."
  fi
}

check_spec_docs() {
  local e
  for e in $AK_SPEC_STAGES; do
    [ -s "${e#*:}" ] || die "${e#*:} is missing. Run 'agent-kit spec ${e%%:*}' first."
  done
}

check_plan() {
  [ -s "$AK_PLAN_DOC" ] || die "$AK_PLAN_DOC is missing. Run 'agent-kit plan' first."
  [ "$(count_tasks)" -gt 0 ] || die "no tasks/*/task.md files. Run 'agent-kit plan' first."
}

# True when the last review passed on the files as they are now.
review_passed_now() {
  [ -f "$AK_REVIEW_STATE" ] && jq -e '.status == "PASS"' "$AK_REVIEW_STATE" >/dev/null &&
    [ "$(jq -r .spec_hash "$AK_REVIEW_STATE")" = "$(baseline_hash)" ]
}
