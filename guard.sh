#!/usr/bin/env bash
set -euo pipefail

# ─── Install Causari if missing ───
if ! command -v re &> /dev/null; then
  echo "::group::Installing Causari from source..."
  cargo install --git https://github.com/croviatrust/causari --locked
  echo "::endgroup::"
fi

# ─── Run guard ───
echo "::group::re guard --summary"
SUMMARY=$(re guard --summary -n "${INPUT_LIMIT:-20}" 2>&1 || true)
echo "$SUMMARY"
echo "::endgroup::"

# ─── Parse counts ───
ALERTS=$(echo "$SUMMARY" | grep -c '🔴' || echo "0")
WARNINGS=$(echo "$SUMMARY" | grep -c '🟡' || echo "0")

# ─── Build status line ───
if [ "$ALERTS" -gt 0 ]; then
  STATUS="❌ failing"
  COLOR="#EF4444"
elif [ "$WARNINGS" -gt 0 ]; then
  STATUS="⚠️ warnings"
  COLOR="#F59E0B"
else
  STATUS="✅ passing"
  COLOR="#22C55E"
fi

# ─── Post PR comment ───
if [ -n "${PR_NUMBER:-}" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
  BODY="## Causari Guard — ${STATUS}

${SUMMARY}

<sub>Powered by [Causari Guard](https://github.com/croviatrust/causari-guard-action)</sub>"

  # Check if jq is available; fall back to Python if not
  if command -v jq &> /dev/null; then
    JSON_BODY=$(printf '%s' "$BODY" | jq -s -R .)
  elif command -v python3 &> /dev/null; then
    JSON_BODY=$(python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' <<< "$BODY")
  else
    echo "::warning::Neither jq nor python3 available. Skipping PR comment."
    JSON_BODY=""
  fi

  if [ -n "$JSON_BODY" ]; then
    curl -sSL \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      -X POST \
      -d "{\"body\":$JSON_BODY}" \
      "https://api.github.com/repos/$REPO/issues/$PR_NUMBER/comments" \
      > /dev/null
    echo "Posted guard summary to PR #$PR_NUMBER"
  fi
fi

# ─── Fail CI if alerts found ───
if [ "${INPUT_FAIL_ON_ALERT:-true}" = "true" ] && [ "$ALERTS" -gt 0 ]; then
  echo "::error::Guard found $ALERTS alert(s). Review with: re show <id>  re diff <id>  re trace <file>:<line>"
  exit 1
fi

echo "Guard completed: $ALERTS alert(s), $WARNINGS warning(s)."
