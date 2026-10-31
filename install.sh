#!/usr/bin/env bash
# Install agent-kit for Claude Code, Codex, or both.
#
#   ./install.sh --target claude|codex|both --scope global
#   ./install.sh --target claude|codex|both --scope project --project DIR
#   ./install.sh --target claude|codex|both --scope global --uninstall
#
# Global:  symlinks skills, agents and the 'agent-kit' command into your home
#          folders, so edits in this repo show up right away. No settings
#          files are changed and no hooks are added.
# Project: copies everything into the project so it can be committed, adds
#          the guard hook to the project settings, then runs 'agent-kit init'.
#
# Options:
#   --force             replace things that are in the way (old ones are backed up)
#   --dry-run           only print what would happen
#   --workspace DIR     project: folder for brief/, docs/, tasks/ (default: project root)
#   --scripts-dir DIR   project: where the wrapper scripts go (default: scripts; none = skip)
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TS="$(date +%Y%m%d-%H%M%S)"
TARGET="" SCOPE="" PROJECT="" FORCE=0 DRY=0 UNINSTALL=0 CONFLICTS=0 BACKUP_ROOT=""
WORKSPACE="" SCRIPTS_DIR="scripts"

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
AGENTS_SKILLS_DIR="$HOME/.agents/skills"
BIN_DIR="${AGENT_KIT_BIN_DIR:-$HOME/.local/bin}"

# What the runner needs at run time. Copied to <project>/.agent-kit/.
RUNTIME_ITEMS="VERSION bin lib hooks schemas rules templates skills agents"
# Commands that get a wrapper in <project>/scripts/.
WRAPPER_COMMANDS="prepare review plan gate approve"

CLAUDE_HOOK_MATCHER="Write|Edit|MultiEdit|NotebookEdit|Bash"
CLAUDE_HOOK_COMMAND='"$CLAUDE_PROJECT_DIR"/.agent-kit/hooks/guard.sh'
CODEX_HOOK_MATCHER="Bash|apply_patch"
CODEX_HOOK_COMMAND='sh -c '\''r=$(pwd -P); while [ ! -f "$r/agent-kit.toml" ]; do [ "$r" != / ] || { echo "agent-kit: project root not found" >&2; exit 2; }; r=$(dirname "$r"); done; [ -x "$r/.agent-kit/hooks/guard.sh" ] || { echo "agent-kit: guard hook not found" >&2; exit 2; }; AGENT_KIT_PROJECT_DIR="$r" exec "$r/.agent-kit/hooks/guard.sh"'\'''

say()  { printf '%s\n' "$*"; }
info() { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }
usage() { sed -n '2,19p' "$KIT/install.sh" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

# Run a command, or only print it with --dry-run.
run() { if [ "$DRY" -eq 1 ]; then printf '  would: %s\n' "$*"; else "$@"; fi; }

want() { [ "$TARGET" = both ] || [ "$TARGET" = "$1" ]; }

skill_names() { for d in "$KIT"/skills/*/; do basename "$d"; done; }
agent_names() { for f in "$KIT"/agents/*.md; do basename "$f" .md; done; }

# Move something out of the way into a backup folder. Nothing is deleted.
backup() {  # path base
  local path="$1" base="$2" dest
  dest="$BACKUP_ROOT/${path#"$base"/}"
  run mkdir -p "$(dirname "$dest")"
  run mv "$path" "$dest"
  say "  backup  $path -> $dest"
}

# Global: make DEST a symlink to SRC.
link_item() {  # src dest
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    say "  ok      $dest"
    return 0
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      backup "$dest" "$HOME"
    else
      warn "skipped $dest: something is already there (use --force to replace it; a backup is kept)"
      CONFLICTS=$((CONFLICTS + 1))
      return 0
    fi
  fi
  run mkdir -p "$(dirname "$dest")"
  run ln -s "$src" "$dest"
  say "  linked  $dest"
}

# Global uninstall: remove DEST only if it is a symlink into this kit.
unlink_item() {  # dest
  local dest="$1"
  [ -L "$dest" ] || return 0
  case "$(readlink "$dest")" in
    "$KIT"/*) run rm "$dest"; say "  removed $dest" ;;
  esac
}

# Project: copy SRC (file or folder) to DEST.
copy_item() {  # src dest
  local src="$1" dest="$2"
  if [ -e "$dest" ]; then
    if diff -rq "$src" "$dest" >/dev/null 2>&1; then
      say "  ok      $dest"
      return 0
    fi
    if [ "$FORCE" -eq 1 ]; then
      backup "$dest" "$PROJECT"
    else
      warn "skipped $dest: it differs from the kit (use --force to replace it; a backup is kept)"
      CONFLICTS=$((CONFLICTS + 1))
      return 0
    fi
  fi
  run mkdir -p "$(dirname "$dest")"
  run cp -R "$src" "$dest"
  say "  copied  $dest"
}

# Codex agents are TOML. Build them from the Markdown sources in agents/.
gen_codex_agents() {
  local out="$KIT/dist/codex/agents" src name desc body
  [ "$DRY" -eq 1 ] && { say "  would generate Codex agents in $out"; return 0; }
  rm -rf "$out"
  mkdir -p "$out"
  for src in "$KIT"/agents/*.md; do
    name="$(yq -p yaml -oy --front-matter=extract '.name' "$src")"
    desc="$(yq -p yaml -oy --front-matter=extract '.description' "$src")"
    { [ -n "$name" ] && [ "$name" != null ] && [ -n "$desc" ] && [ "$desc" != null ]; } ||
      die "$src: frontmatter needs name and description"
    body="$(awk 'NR == 1 && $0 == "---" { fm = 1; next } fm && $0 == "---" { fm = 0; next } !fm' "$src")"
    {
      printf '# Generated by agent-kit install.sh from agents/%s. Do not edit this file.\n' "$(basename "$src")"
      jq -n --arg n "$name" --arg d "$desc" --arg b "$body" \
        '{name: $n, description: $d, developer_instructions: $b}' | yq -p json -o toml .
    } > "$out/$(basename "$src" .md).toml"
  done
}

gen_wrappers() {
  local out="$KIT/dist/wrappers" c up
  [ "$DRY" -eq 1 ] && return 0
  # One "../" per folder level of SCRIPTS_DIR leads back to the project root.
  up="$(printf '%s\n' "$SCRIPTS_DIR" | awk -F/ '{ for (i = 1; i <= NF; i++) printf "../" }')"
  up="${up%/}"
  rm -rf "$out"
  mkdir -p "$out"
  for c in $WRAPPER_COMMANDS; do
    cat > "$out/$c.sh" <<EOF
#!/usr/bin/env bash
# Added by agent-kit. Same as: agent-kit $c
exec "\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/$up" && pwd)/.agent-kit/bin/agent-kit" $c "\$@"
EOF
    chmod +x "$out/$c.sh"
  done
}

# Add the guard hook to a JSON settings file (Claude settings.json or Codex hooks.json).
merge_hook() {  # file matcher command
  local file="$1" matcher="$2" command="$3" entry
  entry="$(jq -nc --arg m "$matcher" --arg c "$command" '{matcher: $m, hooks: [{type: "command", command: $c}]}')"
  if [ -f "$file" ]; then
    jq empty "$file" 2>/dev/null || die "$file is not valid JSON. Fix it and run again."
    if jq -e --argjson e "$entry" '.hooks.PreToolUse // [] | index($e) != null' "$file" >/dev/null; then
      say "  ok      $file (guard hook is there)"
      return 0
    fi
    if [ "$DRY" -eq 1 ]; then say "  would add the guard hook to $file"; return 0; fi
    jq --argjson e "$entry" '
      .hooks.PreToolUse = ([ (.hooks.PreToolUse // [])[]
        | .hooks |= map(select((.command // "" | contains("agent-kit/hooks/guard.sh")) | not))
        | select(.hooks | length > 0) ] + [$e])
    ' "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
    say "  updated $file (added guard hook)"
  else
    if [ "$DRY" -eq 1 ]; then say "  would create $file"; return 0; fi
    mkdir -p "$(dirname "$file")"
    jq -n --argjson e "$entry" '{hooks: {PreToolUse: [$e]}}' > "$file"
    say "  created $file"
  fi
}

install_global() {
  local s a
  BACKUP_ROOT="$HOME/.agent-kit-backup/$TS"

  if want claude; then
    info "Claude Code (global): $CLAUDE_DIR"
    for s in $(skill_names); do link_item "$KIT/skills/$s" "$CLAUDE_DIR/skills/$s"; done
    for a in $(agent_names); do link_item "$KIT/agents/$a.md" "$CLAUDE_DIR/agents/$a.md"; done
  fi

  if want codex; then
    info "Codex (global): $AGENTS_SKILLS_DIR and $CODEX_DIR/agents"
    for s in $(skill_names); do link_item "$KIT/skills/$s" "$AGENTS_SKILLS_DIR/$s"; done
    gen_codex_agents
    for a in $(agent_names); do link_item "$KIT/dist/codex/agents/$a.toml" "$CODEX_DIR/agents/$a.toml"; done
  fi

  info "agent-kit command: $BIN_DIR/agent-kit"
  link_item "$KIT/bin/agent-kit" "$BIN_DIR/agent-kit"
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) warn "$BIN_DIR is not on your PATH. Add it to use the 'agent-kit' command." ;;
  esac

  say ""
  say "No settings files were changed. The runner turns the guard hook on for its own runs."
  want codex && say "Codex agents are generated: run this installer again after you edit agents/*.md."
  say "Next: cd into a project and run 'agent-kit init'."
}

uninstall_global() {
  local s a
  if want claude; then
    info "Claude Code (global): removing links into $KIT"
    for s in $(skill_names); do unlink_item "$CLAUDE_DIR/skills/$s"; done
    for a in $(agent_names); do unlink_item "$CLAUDE_DIR/agents/$a.md"; done
  fi
  if want codex; then
    info "Codex (global): removing links into $KIT"
    for s in $(skill_names); do unlink_item "$AGENTS_SKILLS_DIR/$s"; done
    for a in $(agent_names); do unlink_item "$CODEX_DIR/agents/$a.toml"; done
  fi
  if [ "$TARGET" = both ]; then
    unlink_item "$BIN_DIR/agent-kit"
  else
    say "  kept    $BIN_DIR/agent-kit (removed only with --target both)"
  fi
}

install_project() {
  local s a c item dest
  [ -n "$PROJECT" ] || die "--scope project needs --project DIR"
  [ -d "$PROJECT" ] || die "project folder not found: $PROJECT"
  PROJECT="$(cd "$PROJECT" && pwd -P)"
  [ "$PROJECT" != "$KIT" ] || die "the project must not be the kit folder itself"
  BACKUP_ROOT="$PROJECT/.agent-kit-backup/$TS"

  info "runner: $PROJECT/.agent-kit"
  dest="$PROJECT/.agent-kit"
  if [ -e "$dest" ] && [ ! -f "$dest/VERSION" ]; then
    die "$dest exists but is not an agent-kit folder. Move it away first."
  fi
  local need_copy=1
  if [ -e "$dest" ]; then
    # The folder belongs to the kit: refresh it, but keep the old copy if it changed.
    need_copy=0
    for item in $RUNTIME_ITEMS; do diff -rq "$KIT/$item" "$dest/$item" >/dev/null 2>&1 || need_copy=1; done
    if [ "$need_copy" -eq 1 ]; then backup "$dest" "$PROJECT"; else say "  ok      $dest"; fi
  fi
  if [ "$need_copy" -eq 1 ]; then
    run mkdir -p "$dest"
    for item in $RUNTIME_ITEMS; do run cp -R "$KIT/$item" "$dest/$item"; done
    say "  copied  $dest (runner, guard hook, schemas, rules, templates, skills, agents)"
  fi

  if [ "$SCRIPTS_DIR" != none ]; then
    info "scripts: $PROJECT/$SCRIPTS_DIR"
    gen_wrappers
    for c in $WRAPPER_COMMANDS; do copy_item "$KIT/dist/wrappers/$c.sh" "$PROJECT/$SCRIPTS_DIR/$c.sh"; done
  fi

  if want claude; then
    info "Claude Code (project): $PROJECT/.claude"
    for s in $(skill_names); do copy_item "$KIT/skills/$s" "$PROJECT/.claude/skills/$s"; done
    for a in $(agent_names); do copy_item "$KIT/agents/$a.md" "$PROJECT/.claude/agents/$a.md"; done
    merge_hook "$PROJECT/.claude/settings.json" "$CLAUDE_HOOK_MATCHER" "$CLAUDE_HOOK_COMMAND"
  fi

  if want codex; then
    info "Codex (project): $PROJECT/.agents/skills and $PROJECT/.codex"
    for s in $(skill_names); do copy_item "$KIT/skills/$s" "$PROJECT/.agents/skills/$s"; done
    gen_codex_agents
    for a in $(agent_names); do copy_item "$KIT/dist/codex/agents/$a.toml" "$PROJECT/.codex/agents/$a.toml"; done
    merge_hook "$PROJECT/.codex/hooks.json" "$CODEX_HOOK_MATCHER" "$CODEX_HOOK_COMMAND"
  fi

  info "project files"
  local ws_flag=""
  [ -z "$WORKSPACE" ] || ws_flag="--workspace $WORKSPACE"
  if [ "$DRY" -eq 1 ]; then
    say "  would run: $dest/bin/agent-kit $ws_flag init --dir $PROJECT"
  else
    # shellcheck disable=SC2086  # ws_flag is empty or two words without spaces
    "$dest/bin/agent-kit" $ws_flag init --dir "$PROJECT"
  fi

  say ""
  if want codex; then
    say "Codex: open Codex in the project and run /hooks to trust the guard hook. Untrusted hooks do not run."
  fi
  local scripts=""
  [ "$SCRIPTS_DIR" = none ] || scripts="$SCRIPTS_DIR/ "
  say "Commit these: .agent-kit/ ${scripts}AGENTS.md CLAUDE.md agent-kit.toml .gitignore"
  say "              and the workspace: brief/ docs/ tasks/ .workflow/ in ${WORKSPACE:-the folder set in agent-kit.toml}"
  want claude && say "              .claude/skills/ .claude/agents/ .claude/settings.json"
  want codex && say "              .agents/skills/ .codex/agents/ .codex/hooks.json"
  return 0
}

# ---- main -------------------------------------------------------------------

while [ $# -gt 0 ]; do
  case "$1" in
    --target)    [ $# -ge 2 ] || usage 1; TARGET="$2"; shift 2 ;;
    --scope)     [ $# -ge 2 ] || usage 1; SCOPE="$2"; shift 2 ;;
    --project)   [ $# -ge 2 ] || usage 1; PROJECT="$2"; shift 2 ;;
    --force)     FORCE=1; shift ;;
    --dry-run)   DRY=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --workspace) [ $# -ge 2 ] || usage 1; WORKSPACE="$2"; shift 2 ;;
    --scripts-dir) [ $# -ge 2 ] || usage 1; SCRIPTS_DIR="${2%/}"; shift 2 ;;
    -h|--help)   usage 0 ;;
    *)           warn "unknown option: $1"; usage 1 ;;
  esac
done

case "$TARGET" in claude|codex|both) ;; *) warn "--target must be claude, codex or both"; usage 1 ;; esac
case "$SCOPE" in global|project) ;; *) warn "--scope must be global or project"; usage 1 ;; esac
command -v jq >/dev/null 2>&1 || die "jq is required (brew install jq)"
if want codex; then
  printf 'a = 1\n' | yq -p toml -oy '.a' >/dev/null 2>&1 ||
    die "yq v4 (mikefarah) is required to build Codex agents (brew install yq)"
fi
[ -z "$WORKSPACE" ] || [ "$SCOPE" = project ] ||
  die "--workspace is for project installs. After a global install run: agent-kit --workspace DIR init"
case "$SCRIPTS_DIR" in
  none) ;;
  ""|/*|..|../*|*/..|*/../*|.agent-kit|.agent-kit/*) die "--scripts-dir must be a folder inside the project, or none" ;;
esac
printf '%s\n' "$SCRIPTS_DIR" | grep -Eq '^[A-Za-z0-9._][A-Za-z0-9._/-]*$' || die "--scripts-dir may only use letters, digits, '.', '_', '-' and '/'"
[ "$DRY" -eq 1 ] && info "dry run: nothing will change"

if [ "$UNINSTALL" -eq 1 ]; then
  [ "$SCOPE" = global ] || die "--uninstall works for global installs only. In a project, remove the files with git."
  uninstall_global
elif [ "$SCOPE" = global ]; then
  install_global
else
  install_project
fi

if [ "$CONFLICTS" -gt 0 ]; then
  warn "$CONFLICTS item(s) were skipped because something was in the way. See the warnings above."
  exit 3
fi
