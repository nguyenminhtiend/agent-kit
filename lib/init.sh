# 'agent-kit init': add the files a project needs for the pipeline.
# Safe to run again: it never overwrites your files. It only refreshes the
# managed rules block inside AGENTS.md.

AK_RULES_START="<!-- agent-kit:rules:start -->"
AK_RULES_END="<!-- agent-kit:rules:end -->"

ak_init() {
  local dir="." tpl="$AGENT_KIT_HOME/templates/project" d
  while [ $# -gt 0 ]; do
    case "$1" in
      --dir) [ $# -ge 2 ] || die "--dir needs a path"; dir="$2"; shift 2 ;;
      *) die "unknown option for init: $1" ;;
    esac
  done
  [ -d "$dir" ] || die "folder not found: $dir"
  cd "$dir"
  info "init in $(pwd)"

  copy_if_missing "$tpl/agent-kit.toml" agent-kit.toml
  copy_if_missing "$tpl/brief/requirements.md" "$AK_BRIEF"
  copy_if_missing "$tpl/AGENTS.md" AGENTS.md
  copy_if_missing "$tpl/CLAUDE.md" CLAUDE.md
  refresh_rules_block AGENTS.md

  for d in docs tasks .workflow/state .workflow/reviews .workflow/logs .workflow/approvals; do
    mkdir -p "$d"
    [ -n "$(ls -A "$d")" ] || : > "$d/.gitkeep"
  done
  add_line_once .gitignore ".workflow/logs/"
  add_line_once .gitignore ".workflow/archive/"
  add_line_once .gitignore ".agent-kit-backup/"

  if ! grep -q '@AGENTS.md' CLAUDE.md; then
    warn "CLAUDE.md does not import AGENTS.md. Add a line '@AGENTS.md' so Claude sees the shared rules."
  fi
  info "next: fill in $AK_BRIEF (and agent-kit.toml), then run 'agent-kit prepare'"
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
