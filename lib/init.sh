# 'agent-kit init': add the files a project needs for the pipeline.
# Safe to run again: it never overwrites your files. It only refreshes the
# managed rules block inside AGENTS.md.

AK_RULES_START="<!-- agent-kit:rules:start -->"
AK_RULES_END="<!-- agent-kit:rules:end -->"

ak_init() {
  local dir="." tpl="$AGENT_KIT_HOME/templates/project" d ws found
  while [ $# -gt 0 ]; do
    case "$1" in
      --dir) [ $# -ge 2 ] || die "--dir needs a path"; dir="$2"; shift 2 ;;
      *) die "unknown option for init: $1" ;;
    esac
  done
  [ -d "$dir" ] || die "folder not found: $dir"
  cd "$dir"
  info "init in $(pwd)"

  if [ -f "$AK_CONFIG_FILE" ]; then
    load_config || die "invalid $AK_CONFIG_FILE; fix it first"
  else
    AK_CONFIG_JSON='{}'
  fi
  ws="$(workspace_rel)" || die "invalid workspace"

  # An existing project may already use docs/ or tasks/ for its own files.
  # Hashing or archiving those would break the gate or move the project's files.
  if [ ! -d "$ws/.workflow" ]; then
    found="$(foreign_files "$ws")"
    [ -z "$found" ] || die "$ws already has files agent-kit did not make:
$found
Keep agent-kit apart from them: run again with --workspace and a new folder (e.g. --workspace specs)"
  fi

  if [ -e "$AK_CONFIG_FILE" ]; then
    ok "$AK_CONFIG_FILE (kept)"
  else
    sed "s|^workspace = \".\"|workspace = \"$ws\"|" "$tpl/agent-kit.toml" > "$AK_CONFIG_FILE"
    ok "$AK_CONFIG_FILE (created, workspace = \"$ws\")"
  fi
  copy_if_missing "$tpl/AGENTS.md" AGENTS.md
  copy_if_missing "$tpl/CLAUDE.md" CLAUDE.md
  refresh_rules_block AGENTS.md
  add_line_once .gitignore "**/.workflow/logs/"
  add_line_once .gitignore "**/.workflow/archive/"
  add_line_once .gitignore ".agent-kit-backup/"

  mkdir -p "$ws"
  (
    cd "$ws"
    copy_if_missing "$tpl/brief/requirements.md" "$AK_BRIEF"
    for d in docs tasks .workflow/state .workflow/reviews .workflow/logs .workflow/approvals; do
      mkdir -p "$d"
      [ -n "$(ls -A "$d")" ] || : > "$d/.gitkeep"
    done
  )

  if ! grep -q '@AGENTS.md' CLAUDE.md; then
    warn "CLAUDE.md does not import AGENTS.md. Add a line '@AGENTS.md' so Claude sees the shared rules."
  fi
  local brief="$ws/$AK_BRIEF" flag=""
  [ "$ws" = . ] && brief="$AK_BRIEF"
  load_config && [ "$(AGENT_KIT_WORKSPACE= workspace_rel)" = "$ws" ] || flag=" --workspace $ws"
  info "next: fill in $brief (and agent-kit.toml), then run 'agent-kit$flag prepare'"
}

# Files in WS/docs or WS/tasks that the pipeline would not write (at most 5).
foreign_files() {
  [ -d "$1" ] || return 0
  (cd "$1" && find docs tasks -type f ! -name .gitkeep ! -name .DS_Store \
     ! -path 'docs/[0-9][0-9]-*.md' ! -path 'tasks/*/task.md' 2>/dev/null | head -5 | sed 's/^/  /') || true
}

copy_if_missing() {
  if [ -e "$2" ]; then
    ok "$2 (kept)"
  else
    mkdir -p "$(dirname "$2")"
    cp "$1" "$2"
    ok "$2 (created)"
  fi
}

add_line_once() {
  touch "$1"
  grep -qxF "$2" "$1" && return 0
  # Add a newline first if the file does not end with one.
  if [ -s "$1" ] && [ -n "$(tail -c1 "$1")" ]; then printf '\n' >> "$1"; fi
  printf '%s\n' "$2" >> "$1"
}

# Put the kit's rules/*.md between the managed markers in AGENTS.md.
# Codex reads AGENTS.md; Claude reads it through '@AGENTS.md' in CLAUDE.md.
refresh_rules_block() {
  local file="$1" block r
  block="$(mktemp)"
  {
    printf '%s\n' "$AK_RULES_START"
    printf '%s\n' "<!-- Managed by agent-kit. Do not edit between these markers: edit rules/ in the kit and run 'agent-kit init' again. -->"
    for r in "$AGENT_KIT_HOME"/rules/*.md; do
      [ -f "$r" ] || continue
      printf '\n'
      cat "$r"
    done
    printf '\n%s\n' "$AK_RULES_END"
  } > "$block"

  if grep -qF "$AK_RULES_START" "$file"; then
    awk -v s="$AK_RULES_START" -v e="$AK_RULES_END" -v bf="$block" '
      $0 == s { while ((getline line < bf) > 0) print line; skip = 1; next }
      $0 == e { skip = 0; next }
      !skip   { print }
    ' "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
  else
    { printf '\n'; cat "$block"; } >> "$file"
  fi
  rm -f "$block"
  ok "$file (rules block refreshed)"
}
