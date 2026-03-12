#!/usr/bin/env bash
# check-setup.sh — Validates prerequisites for the agent pipeline.
# Exits 0 if all checks pass, 1 if any fail.

set -euo pipefail

PASS="✓"
FAIL="✗"
all_ok=true

check() {
  local label="$1"
  local ok="$2"
  if [ "$ok" = "true" ]; then
    echo "  $PASS $label"
  else
    echo "  $FAIL $label"
    all_ok=false
  fi
}

echo ""
echo "=== Agent Pipeline Setup Check ==="
echo ""

# ── 1. gh CLI authentication ──────────────────────────────────────────────────
echo "GitHub CLI"
if gh auth status &>/dev/null; then
  check "gh is authenticated" "true"
else
  check "gh is authenticated (run: gh auth login)" "false"
fi

# ── 2. ANTHROPIC_API_KEY GitHub Actions secret ────────────────────────────────
echo ""
echo "GitHub Actions Secrets"
if gh secret list 2>/dev/null | grep -q "^ANTHROPIC_API_KEY"; then
  check "ANTHROPIC_API_KEY secret is set" "true"
else
  check "ANTHROPIC_API_KEY secret is set (run: gh secret set ANTHROPIC_API_KEY)" "false"
fi

# ── 3. Required GitHub labels ─────────────────────────────────────────────────
echo ""
echo "GitHub Labels"
required_labels=("agent:ready" "story" "priority:p0" "priority:p1" "priority:p2")
existing_labels=$(gh label list --limit 100 2>/dev/null | awk '{print $1}') || existing_labels=""

for label in "${required_labels[@]}"; do
  if echo "$existing_labels" | grep -qxF "$label"; then
    check "Label '$label' exists" "true"
  else
    check "Label '$label' exists (run: gh label create '$label')" "false"
  fi
done

# ── 4. Required workflow files ────────────────────────────────────────────────
echo ""
echo "Workflow Files"
required_workflows=("claude-dev.yml" "claude-review.yml" "claude-fix.yml")
workflows_dir=".github/workflows"

for wf in "${required_workflows[@]}"; do
  if [ -f "$workflows_dir/$wf" ]; then
    check "$workflows_dir/$wf exists" "true"
  else
    check "$workflows_dir/$wf exists" "false"
  fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
if [ "$all_ok" = "true" ]; then
  echo "All checks passed. Repository is ready to use the agent pipeline."
  exit 0
else
  echo "One or more checks failed. See above for details."
  exit 1
fi
