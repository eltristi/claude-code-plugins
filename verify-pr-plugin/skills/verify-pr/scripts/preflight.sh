#!/bin/bash
# Pre-flight checks for verify-pr skill
# Exits with non-zero status and error message if any check fails
# Usage: bash preflight.sh [pr-number-or-url]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}!${NC} $1"; }

echo "[verify-pr] Pre-flight: Checking prerequisites..."
echo ""

# 1. Check jq (needed for JSON parsing throughout)
if ! command -v jq &>/dev/null; then
  fail "jq not installed. Install: brew install jq"
fi
pass "jq installed"

# 2. Check gh CLI
if ! command -v gh &>/dev/null; then
  fail "gh CLI not installed. Install: https://cli.github.com/"
fi
if ! gh auth status &>/dev/null; then
  fail "gh CLI not authenticated. Run: gh auth login"
fi
pass "gh CLI installed and authenticated"

# 2. Check PR exists
PR_ARG="${1:-}"
if [ -n "$PR_ARG" ]; then
  PR_JSON=$(gh pr view "$PR_ARG" --json number,title,url,headRefOid 2>/dev/null) || fail "PR not found: $PR_ARG"
else
  PR_JSON=$(gh pr view --json number,title,url,headRefOid 2>/dev/null) || fail "No open PR found for current branch. Specify a PR number or URL."
fi

PR_NUMBER=$(echo "$PR_JSON" | jq -r '.number')
PR_TITLE=$(echo "$PR_JSON" | jq -r '.title')
PR_URL=$(echo "$PR_JSON" | jq -r '.url')
PR_HEAD=$(echo "$PR_JSON" | jq -r '.headRefOid')

pass "PR found: #${PR_NUMBER} — ${PR_TITLE}"

# 3. Detect project type
PROJECT_TYPE="unknown"
if [ -f "app.json" ] && jq -e '.expo' app.json &>/dev/null; then
  PROJECT_TYPE="expo"
elif [ -f "artisan" ] && [ -f "composer.json" ]; then
  if [ -f "docker-compose.yml" ] || [ -f "compose.yaml" ]; then
    PROJECT_TYPE="laravel"
  else
    fail "Laravel project detected but no docker-compose.yml or compose.yaml found."
  fi
fi

if [ "$PROJECT_TYPE" = "unknown" ]; then
  fail "Could not detect project type. Supported: Expo (app.json with expo key) or Laravel (artisan + composer.json + docker-compose)."
fi
pass "Project type: ${PROJECT_TYPE}"

# 4. Check testing tool
if [ "$PROJECT_TYPE" = "expo" ]; then
  if ! command -v maestro &>/dev/null; then
    fail "Maestro not installed. Install: https://maestro.mobile.dev"
  fi
  pass "Maestro installed: $(maestro --version 2>/dev/null || echo 'version unknown')"
elif [ "$PROJECT_TYPE" = "laravel" ]; then
  if ! npx playwright --version &>/dev/null 2>&1; then
    fail "Playwright not installed. Install: npx playwright install"
  fi
  pass "Playwright installed"
fi

# 5. Check branch sync
LOCAL_HEAD=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
if [ "$LOCAL_HEAD" != "unknown" ] && [ "$LOCAL_HEAD" != "$PR_HEAD" ]; then
  warn "Local HEAD ($LOCAL_HEAD) differs from PR HEAD ($PR_HEAD). Results may not match the PR."
fi

# 6. Check platform availability (Expo only)
if [ "$PROJECT_TYPE" = "expo" ]; then
  IOS_AVAILABLE="false"
  ANDROID_AVAILABLE="false"

  if command -v xcrun &>/dev/null && xcrun simctl list devices available 2>/dev/null | grep -q "iPhone"; then
    IOS_AVAILABLE="true"
    pass "iOS Simulator available"
  else
    warn "iOS Simulator not available — will skip iOS testing"
  fi

  if command -v adb &>/dev/null && (adb devices 2>/dev/null | grep -q "emulator\|device$"); then
    ANDROID_AVAILABLE="true"
    pass "Android Emulator available"
  else
    warn "Android Emulator not available — will skip Android testing"
  fi

  if [ "$IOS_AVAILABLE" = "false" ] && [ "$ANDROID_AVAILABLE" = "false" ]; then
    fail "No iOS Simulator or Android Emulator available. At least one is required."
  fi
fi

echo ""
echo "[verify-pr] Pre-flight: All checks passed"
echo ""

# Output results as JSON for the skill to consume
cat <<EOF
{
  "pr_number": ${PR_NUMBER},
  "pr_title": $(echo "$PR_TITLE" | jq -R .),
  "pr_url": $(echo "$PR_URL" | jq -R .),
  "pr_head": $(echo "$PR_HEAD" | jq -R .),
  "project_type": "${PROJECT_TYPE}",
  "local_head": "${LOCAL_HEAD}",
  "platforms": {
    "ios_available": "${IOS_AVAILABLE:-n/a}",
    "android_available": "${ANDROID_AVAILABLE:-n/a}"
  }
}
EOF
