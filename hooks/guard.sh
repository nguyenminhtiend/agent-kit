#!/usr/bin/env bash
# agent-kit guard: a PreToolUse hook for Claude Code and Codex.
#
# Exit 0 = allow. Exit 2 = block, with the reason on stderr. Both tools
# understand this.
#
# Always:
#   - block edits to runner-owned files in any workspace's .workflow/approvals/
#     and .workflow/state/
#   - block shell commands that touch those folders or run 'agent-kit approve'
# During a runner stage (the runner sets AGENT_KIT_STAGE and AGENT_KIT_WORKSPACE_DIR):
#   - allow edits only under AGENT_KIT_WRITE_ALLOW
#     (paths relative to the workspace, separated by ":", e.g. "docs/07-plan.md:tasks/")
#
# This is a safety net, not a wall. The runner and the gate check results too.
set -uo pipefail

in_stage=0
[ -n "${AGENT_KIT_STAGE:-}" ] && in_stage=1

block() { printf 'agent-kit guard: %s\n' "$*" >&2; exit 2; }

if ! command -v jq >/dev/null 2>&1; then
  # Fail closed inside a runner stage, fail open in normal sessions.
  [ "$in_stage" -eq 1 ] && block "jq is not installed, so this stage cannot be checked"
  exit 0
fi

input="$(cat)"
field() { printf '%s' "$input" | jq -r "$1" 2>/dev/null; }

tool="$(field '.tool_name // ""')"
cwd="$(field '.cwd // ""')"
[ -n "$cwd" ] || cwd="$(pwd)"
root="${AGENT_KIT_WORKSPACE_DIR:-${AGENT_KIT_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$cwd}}}"
root="$(cd -P "$root" 2>/dev/null && pwd)" || root="$cwd"

# Resolve every path component, including the final file and relative or
# dangling symlink chains. Bound the walk so symlink loops fail closed.
# With CHECK, reject protected paths as they are traversed, before following
# aliases that might point out of a protected directory.
canon() {
  local pending="${1#/}" check="${2:-}" resolved="/" part candidate target links=0
  while [ -n "$pending" ]; do
    case "$pending" in
      */*) part="${pending%%/*}"; pending="${pending#*/}" ;;
      *) part="$pending"; pending="" ;;
    esac
    case "$part" in
      ""|.) continue ;;
      ..) resolved="${resolved%/*}"; [ -n "$resolved" ] || resolved="/"; continue ;;
    esac
    candidate="${resolved%/}/$part"
    if [ "$check" = check ]; then
      case "$candidate" in
        */.workflow/state|*/.workflow/state/*|*/.workflow/approvals|*/.workflow/approvals/*|\
        "$state_root"|"$state_root/"*|"$approval_root"|"$approval_root/"*) return 1 ;;
      esac
    fi
    if [ -L "$candidate" ]; then
      links=$((links + 1))
      [ "$links" -le 40 ] || return 1
      target="$(readlink "$candidate")" || return 1
      case "$target" in /*) resolved="/"; target="${target#/}" ;; esac
      pending="$target${pending:+/$pending}"
    else
      resolved="$candidate"
    fi
  done
  printf '%s\n' "$resolved"
}

state_root="$(canon "$root/.workflow/state")" || block "cannot resolve the runner state directory"
approval_root="$(canon "$root/.workflow/approvals")" || block "cannot resolve the approval directory"

# Path relative to the project root, or absolute when it is outside the project.
relpath() {
  local p="$1"
  case "$p" in /*) ;; *) p="$cwd/$p" ;; esac
  p="$(canon "$p" check)" || return 1
  case "$p" in
    "$root"/*) printf '%s\n' "${p#"$root"/}" ;;
    *)         printf '%s\n' "$p" ;;
  esac
}

# 1) Shell commands (Claude: Bash; Codex: Bash / exec_command)
case "$tool" in
  Bash|exec_command|shell|local_shell)
    cmd="$(field '.tool_input.command // "" | if type == "array" then join(" ") else . end')"
    case "$cmd" in
      *.workflow/approvals*|*.workflow/state*)
        block "shell commands may not touch .workflow/approvals or .workflow/state. Only the runner and people change them." ;;
      *"agent-kit approve"*|*approve.sh*)
        block "only a person may approve the spec, in their own terminal" ;;
    esac
    exit 0
    ;;
esac

# 2) File edits: collect the target paths
case "$tool" in
  Write|Edit|MultiEdit)
    paths="$(field '.tool_input.file_path // empty')" ;;
  NotebookEdit)
    paths="$(field '.tool_input.notebook_path // empty')" ;;
  apply_patch)
    # Codex sends the patch text in tool_input.command.
    paths="$(field '.tool_input.command // "" | if type == "array" then join("\n") else . end' |
             sed -n -e 's/^\*\*\* Add File: //p' -e 's/^\*\*\* Update File: //p' \
                    -e 's/^\*\*\* Delete File: //p' -e 's/^\*\*\* Move to: //p')" ;;
  *)
    exit 0 ;;
esac

if [ -z "$paths" ]; then
  [ "$in_stage" -eq 1 ] && [ "$tool" = apply_patch ] && block "could not read the file paths in this patch"
  exit 0
fi

allow_list="$(printf '%s' "${AGENT_KIT_WRITE_ALLOW:-}" | tr ':' '\n')"

while IFS= read -r p; do
  [ -n "$p" ] || continue
  r="$(relpath "$p")" || block "cannot safely resolve $p, or it targets runner-owned state or approvals"

  case "$r" in
    .workflow/approvals/*|.workflow/state/*|*/.workflow/approvals/*|*/.workflow/state/*)
      block "$r belongs to the agent-kit runner. Agents may not change it." ;;
  esac

  if [ "$in_stage" -eq 1 ]; then
    case "$r" in
      /*|..|../*|*/../*|*/..)
        block "stage $AGENT_KIT_STAGE may not write outside the workspace: $p" ;;
    esac
    allowed=0
    while IFS= read -r a; do
      [ -n "$a" ] || continue
      case "$a" in
        */) case "$r" in "$a"*) allowed=1 ;; esac ;;
        *) [ "$r" != "$a" ] || allowed=1 ;;
      esac
    done <<EOF
$allow_list
EOF
    [ "$allowed" -eq 1 ] ||
      block "stage $AGENT_KIT_STAGE may only write: ${AGENT_KIT_WRITE_ALLOW:-nothing}. Blocked: $r"
  fi
done <<EOF
$paths
EOF

exit 0
