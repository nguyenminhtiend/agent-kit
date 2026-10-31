# 'agent-kit doctor': check the tools the runner needs.

ak_doctor() {
  local bad=0 root
  info "agent-kit $(cat "$AGENT_KIT_HOME/VERSION") at $AGENT_KIT_HOME"

  if command -v claude >/dev/null 2>&1; then ok "claude $(claude --version 2>/dev/null | head -1)"
  else fail "claude not found (Claude Code CLI)"; bad=1; fi

  if command -v jq >/dev/null 2>&1; then ok "jq"
  else fail "jq not found (brew install jq)"; bad=1; fi

  if command -v yq >/dev/null 2>&1 && printf 'a = 1\n' | yq -p toml -oy '.a' >/dev/null 2>&1; then ok "yq (reads TOML)"
  else fail "yq with TOML support not found (brew install yq; needs mikefarah/yq v4)"; bad=1; fi

  if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then ok "sha256 tool"
  else fail "sha256sum or shasum not found"; bad=1; fi

  if command -v git >/dev/null 2>&1; then ok "git"
  else warn "git not found (not needed yet; the build stage will use worktrees)"; fi

  if root="$(find_project_root)"; then
    ok "project: $root"
    if command -v jq >/dev/null 2>&1 && command -v yq >/dev/null 2>&1; then
      if (cd "$root" && load_config && ok "$AK_CONFIG_FILE" && ws="$(workspace_rel)" &&
          if [ -d "$ws" ]; then ok "workspace: $ws"; else warn "workspace $ws does not exist yet (run 'agent-kit init --workspace $ws')"; fi)
      then :; else bad=1; fi
    fi
  else warn "no agent-kit.toml here or above (run 'agent-kit init' in your project)"; fi

  return "$bad"
}
