#!/usr/bin/env bash
set -euo pipefail

# Validate a single repo against enterprise governance policies
# Usage: ./scripts/check-repo.sh ORG/REPO

REPO="${1:?Usage: check-repo.sh ORG/REPO}"
PASS=0
WARN=0
FAIL=0

echo "=== Policy Check: $REPO ==="

# Check required files
for file in CODEOWNERS .github/dependabot.yml AGENTS.md copilot-instructions.md CLAUDE.md; do
    if gh api "/repos/$REPO/contents/$file" --silent 2>/dev/null; then
        PASS=$((PASS+1))
    else
        echo "  FAIL: Missing required file: $file"
        FAIL=$((FAIL+1))
    fi
done

# Check repo settings
DESC=$(gh api "/repos/$REPO" --jq '.description // ""' 2>/dev/null)
if [ -z "$DESC" ]; then
    echo "  FAIL: No description set"
    FAIL=$((FAIL+1))
else
    PASS=$((PASS+1))
fi

DELETE_ON_MERGE=$(gh api "/repos/$REPO" --jq '.delete_branch_on_merge' 2>/dev/null)
if [ "$DELETE_ON_MERGE" != "true" ]; then
    echo "  WARN: delete_branch_on_merge not enabled"
    WARN=$((WARN+1))
else
    PASS=$((PASS+1))
fi

# Check branch protection
DEFAULT_BRANCH=$(gh api "/repos/$REPO" --jq '.default_branch' 2>/dev/null)
PROTECTION=$(gh api "/repos/$REPO/branches/$DEFAULT_BRANCH/protection" 2>/dev/null)
if [ $? -eq 0 ]; then
    PASS=$((PASS+1))
else
    echo "  WARN: No branch protection on $DEFAULT_BRANCH"
    WARN=$((WARN+1))
fi

# Check workflows exist
CI=$(gh api "/repos/$REPO/contents/.github/workflows/ci.yml" --silent 2>/dev/null && echo "yes" || echo "no")
SEC=$(gh api "/repos/$REPO/contents/.github/workflows/security.yml" --silent 2>/dev/null && echo "yes" || echo "no")

if [ "$CI" = "yes" ]; then
    PASS=$((PASS+1))
else
    echo "  WARN: No ci.yml caller workflow"
    WARN=$((WARN+1))
fi

if [ "$SEC" = "yes" ]; then
    PASS=$((PASS+1))
else
    echo "  WARN: No security.yml caller workflow"
    WARN=$((WARN+1))
fi

# Check environments
ENVS=$(gh api "/repos/$REPO/environments" --jq '.environments | length' 2>/dev/null || echo "0")
if [ "$ENVS" -gt 0 ]; then
    PASS=$((PASS+1))
else
    echo "  WARN: No environments configured"
    WARN=$((WARN+1))
fi

echo ""
echo "Result: $PASS pass, $WARN warn, $FAIL fail"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
