# 'agent-kit prepare': stages A to C in one go (spec -> review -> plan).
# Stops at the first failure. Approval (stage D) stays a separate human step.

ak_prepare() {
  ak_spec "$@"
  ak_review || exit 1
  ak_plan
  info "prepare finished. Next: read docs/ and tasks/, then run 'agent-kit gate' and 'agent-kit approve'"
}
