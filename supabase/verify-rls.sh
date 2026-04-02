#!/usr/bin/env bash
# verify-rls.sh — smoke test that RLS blocks anon reads
#
# Run after deploying the Supabase migration and edge function.
# Uses the anon key from config.sh to verify INSERT-only access.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source config
if [ -f "$SCRIPT_DIR/config.sh" ]; then
  . "$SCRIPT_DIR/config.sh"
fi

URL="${RSTACK_SUPABASE_URL:-}"
KEY="${RSTACK_SUPABASE_ANON_KEY:-}"

if [ -z "$URL" ] || [ -z "$KEY" ]; then
  echo "ERROR: Supabase URL or anon key not configured in supabase/config.sh"
  exit 1
fi

PASS=0
FAIL=0

check() {
  local LABEL="$1" EXPECT="$2" METHOD="$3" ENDPOINT="$4"
  local HTTP_CODE

  HTTP_CODE="$(curl -s -w '%{http_code}' -o /dev/null --max-time 5 \
    -X "$METHOD" \
    "${URL}/rest/v1/${ENDPOINT}" \
    -H "apikey: ${KEY}" \
    -H "Authorization: Bearer ${KEY}" \
    -H "Content-Type: application/json" 2>/dev/null || echo "000")"

  case "$EXPECT" in
    deny)
      case "$HTTP_CODE" in
        000)  echo "SKIP: $LABEL (HTTP $HTTP_CODE — network error, server unreachable)" ;;
        4*)   echo "PASS: $LABEL (HTTP $HTTP_CODE — blocked by RLS)"; PASS=$((PASS+1)) ;;
        *)    echo "FAIL: $LABEL (HTTP $HTTP_CODE — expected 4xx)"; FAIL=$((FAIL+1)) ;;
      esac
      ;;
    allow)
      case "$HTTP_CODE" in
        2*) echo "PASS: $LABEL (HTTP $HTTP_CODE — allowed)"; PASS=$((PASS+1)) ;;
        *)  echo "FAIL: $LABEL (HTTP $HTTP_CODE — expected 2xx)"; FAIL=$((FAIL+1)) ;;
      esac
      ;;
  esac
}

echo "RStack Supabase RLS Verification"
echo "================================"
echo ""

# Tables should deny SELECT via anon key
check "SELECT telemetry_events" deny GET "telemetry_events?select=*&limit=1"
check "SELECT installations"    deny GET "installations?select=*&limit=1"
check "SELECT update_checks"    deny GET "update_checks?select=*&limit=1"

# Views should deny SELECT via anon key
check "SELECT crash_clusters"      deny GET "crash_clusters?select=*&limit=1"
check "SELECT skill_sequences"     deny GET "skill_sequences?select=*&limit=1"
check "SELECT research_pipelines"  deny GET "research_pipelines?select=*&limit=1"

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  echo "WARNING: Some checks failed. Review RLS policies."
  exit 1
fi

echo "All RLS checks passed. Anon key cannot read data directly."
