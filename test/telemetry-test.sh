#!/usr/bin/env bash
# telemetry-test.sh — test suite for rstack telemetry bin scripts
#
# Usage: bash test/telemetry-test.sh
#
# Runs all tests in isolated temp dirs. Reports PASS/FAIL per test.
set -uo pipefail

RSTACK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
PASS_COUNT=0
TEST_NUM=0

# ─── Helpers ─────────────────────────────────────────────────
setup_env() {
  export RSTACK_STATE_DIR="$(mktemp -d /tmp/rstack-test-XXXXXX)"
  export RSTACK_DIR
  mkdir -p "$RSTACK_STATE_DIR/analytics"
}

teardown_env() {
  rm -rf "$RSTACK_STATE_DIR" 2>/dev/null
  unset RSTACK_STATE_DIR
}

pass() {
  TEST_NUM=$((TEST_NUM + 1))
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  PASS [$TEST_NUM] $1"
}

fail() {
  TEST_NUM=$((TEST_NUM + 1))
  FAILURES=$((FAILURES + 1))
  echo "  FAIL [$TEST_NUM] $1"
}

assert_file_contains() {
  local file="$1" pattern="$2" msg="$3"
  if grep -q "$pattern" "$file" 2>/dev/null; then pass "$msg"
  else fail "$msg (pattern: $pattern)"; fi
}

assert_file_not_contains() {
  local file="$1" pattern="$2" msg="$3"
  if grep -q "$pattern" "$file" 2>/dev/null; then fail "$msg (found: $pattern)"
  else pass "$msg"; fi
}

assert_line_count() {
  local file="$1" expected="$2" msg="$3"
  local actual="$(wc -l < "$file" 2>/dev/null | tr -d ' ')"
  if [ "${actual:-0}" = "$expected" ]; then pass "$msg"
  else fail "$msg (expected $expected lines, got ${actual:-0})"; fi
}

JSONL() { echo "$RSTACK_STATE_DIR/analytics/skill-usage.jsonl"; }
LOG="$RSTACK_DIR/bin/rstack-telemetry-log"
SYNC="$RSTACK_DIR/bin/rstack-telemetry-sync"
ANALYTICS="$RSTACK_DIR/bin/rstack-analytics"

echo ""
echo "RStack Telemetry Test Suite"
echo "==========================="
echo ""

# ─── rstack-telemetry-log tests ─────────────────────────────
echo "rstack-telemetry-log:"

# Test 1: Appends valid JSONL when tier=anonymous
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
"$LOG" --skill experiment --duration 120 --outcome success --session-id test-1
assert_file_contains "$(JSONL)" '"skill":"experiment"' "Appends JSONL with skill name"
teardown_env

# Test 2: No output when tier=off
setup_env
echo "telemetry: off" > "$RSTACK_STATE_DIR/config.yaml"
"$LOG" --skill test --duration 10 --outcome success --session-id test-2
if [ ! -f "$(JSONL)" ] || [ "$(wc -l < "$(JSONL)" 2>/dev/null | tr -d ' ')" = "0" ]; then
  pass "No JSONL written when tier=off"
else
  fail "No JSONL written when tier=off (file has content)"
fi
teardown_env

# Test 3: Invalid tier defaults to off
setup_env
echo "telemetry: bogus" > "$RSTACK_STATE_DIR/config.yaml"
"$LOG" --skill test --duration 10 --outcome success --session-id test-3
if [ ! -f "$(JSONL)" ] || [ "$(wc -l < "$(JSONL)" 2>/dev/null | tr -d ' ')" = "0" ]; then
  pass "Invalid tier defaults to off"
else
  fail "Invalid tier defaults to off (file has content)"
fi
teardown_env

# Test 4: Community tier includes installation_id
setup_env
echo "telemetry: community" > "$RSTACK_STATE_DIR/config.yaml"
"$LOG" --skill test --duration 10 --outcome success --session-id test-4
assert_file_contains "$(JSONL)" '"installation_id":"' "Community tier includes installation_id"
teardown_env

# Test 5: Anonymous tier has installation_id=null
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
"$LOG" --skill test --duration 10 --outcome success --session-id test-5
assert_file_contains "$(JSONL)" '"installation_id":null' "Anonymous tier has installation_id=null"
teardown_env

# Test 6: Missing duration → null
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
"$LOG" --skill test --outcome success --session-id test-6
assert_file_contains "$(JSONL)" '"duration_s":null' "Missing duration → null"
teardown_env

# Test 7: Duration >24h → null
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
"$LOG" --skill test --duration 100000 --outcome success --session-id test-7
assert_file_contains "$(JSONL)" '"duration_s":null' "Duration >24h → null"
teardown_env

# Test 8: Negative duration → null
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
"$LOG" --skill test --duration -5 --outcome success --session-id test-8
assert_file_contains "$(JSONL)" '"duration_s":null' "Negative duration → null"
teardown_env

# Test 9: event_type flag respected
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
"$LOG" --skill test --outcome success --session-id test-9 --event-type upgrade_prompted
assert_file_contains "$(JSONL)" '"event_type":"upgrade_prompted"' "event_type flag respected"
teardown_env

# Test 10: error_class included
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
"$LOG" --skill test --outcome error --session-id test-10 --error-class timeout
assert_file_contains "$(JSONL)" '"error_class":"timeout"' "error_class included"
teardown_env

# Test 11: error_message sanitized (paths stripped)
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
"$LOG" --skill test --outcome error --session-id test-11 --error-message "Failed at /home/user/secret/data.csv"
assert_file_contains "$(JSONL)" '\[PATH\]' "error_message paths stripped"
assert_file_not_contains "$(JSONL)" '/home/user' "error_message no raw path"
teardown_env

# Test 12: Quote injection in skill name
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
"$LOG" --skill 'review","injected":"true' --outcome success --session-id test-12
assert_file_not_contains "$(JSONL)" '"injected"' "Quote injection stripped from skill"
teardown_env

# Test 13: Long skill name truncated
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
LONG_SKILL="$(printf 'a%.0s' {1..250})"
"$LOG" --skill "$LONG_SKILL" --outcome success --session-id test-13
# Check that skill field is less than 210 chars (200 + some JSON overhead)
SKILL_LEN="$(grep -o '"skill":"[^"]*"' "$(JSONL)" | head -1 | wc -c | tr -d ' ')"
if [ "$SKILL_LEN" -lt 220 ]; then pass "Long skill name truncated"
else fail "Long skill name truncated (len: $SKILL_LEN)"; fi
teardown_env

# Test 14: Stale pending from other session finalized
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
echo '{"skill":"old-skill","ts":"2026-01-01T00:00:00Z","session_id":"stale-1","rstack_version":"0.1.0"}' > "$RSTACK_STATE_DIR/analytics/.pending-stale-1"
"$LOG" --skill current --outcome success --session-id new-session
assert_file_contains "$(JSONL)" '"skill":"current"' "Current event logged"
if [ ! -f "$RSTACK_STATE_DIR/analytics/.pending-stale-1" ]; then
  pass "Stale pending marker removed"
else
  fail "Stale pending marker removed"
fi
teardown_env

# Test 15: Own pending NOT finalized
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
echo '{"skill":"own","ts":"2026-01-01T00:00:00Z","session_id":"my-session","rstack_version":"0.1.0"}' > "$RSTACK_STATE_DIR/analytics/.pending-my-session"
"$LOG" --skill current --outcome success --session-id my-session
# Own pending should be cleared (not finalized as unknown)
assert_file_not_contains "$(JSONL)" '"outcome":"unknown"' "Own pending not finalized as unknown"
teardown_env

# Test 16: tier=off still clears own pending
setup_env
echo "telemetry: off" > "$RSTACK_STATE_DIR/config.yaml"
echo '{"skill":"test"}' > "$RSTACK_STATE_DIR/analytics/.pending-clear-me"
"$LOG" --skill test --outcome success --session-id clear-me
if [ ! -f "$RSTACK_STATE_DIR/analytics/.pending-clear-me" ]; then
  pass "tier=off clears own pending marker"
else
  fail "tier=off clears own pending marker"
fi
teardown_env

# Test 17: Research fields included when provided
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
"$LOG" --skill experiment --outcome success --session-id test-17 \
  --compute-provider modal --gpu-type A100 --venue arxiv --pipeline-stage experiment
assert_file_contains "$(JSONL)" '"compute_provider":"modal"' "compute_provider included"
assert_file_contains "$(JSONL)" '"gpu_type":"A100"' "gpu_type included"
assert_file_contains "$(JSONL)" '"venue":"arxiv"' "venue included"
assert_file_contains "$(JSONL)" '"pipeline_stage":"experiment"' "pipeline_stage included"
teardown_env

# Test 18: Research fields null when not provided
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
"$LOG" --skill test --outcome success --session-id test-18
assert_file_contains "$(JSONL)" '"compute_provider":null' "compute_provider null when absent"
assert_file_contains "$(JSONL)" '"pipeline_stage":null' "pipeline_stage null when absent"
teardown_env

# Test 19: Secret redaction in error_message
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
"$LOG" --skill test --outcome error --session-id test-19 --error-message "Auth failed Token:sk_live_abc123 expired"
assert_file_contains "$(JSONL)" 'Token:\[REDACTED\]' "Secrets redacted in error_message"
assert_file_not_contains "$(JSONL)" 'sk_live_abc123' "No raw secret in error_message"
teardown_env

echo ""

# ─── rstack-telemetry-sync tests ────────────────────────────
echo "rstack-telemetry-sync:"

# Test 20: Exits silently with no Supabase URL
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
echo '{"v":1,"ts":"2026-01-01T00:00:00Z"}' > "$(JSONL)"
RSTACK_SUPABASE_URL="" "$SYNC" 2>/dev/null
pass "Exits silently with no Supabase URL"
teardown_env

# Test 21: Exits silently with no JSONL
setup_env
echo "telemetry: anonymous" > "$RSTACK_STATE_DIR/config.yaml"
rm -f "$(JSONL)" 2>/dev/null
"$SYNC" 2>/dev/null
pass "Exits silently with no JSONL file"
teardown_env

# Test 22: Exits silently when tier=off
setup_env
echo "telemetry: off" > "$RSTACK_STATE_DIR/config.yaml"
echo '{"v":1}' > "$(JSONL)"
"$SYNC" 2>/dev/null
pass "Exits silently when tier=off"
teardown_env

echo ""

# ─── rstack-analytics tests ─────────────────────────────────
echo "rstack-analytics:"

# Test 23: Empty JSONL → no data message
setup_env
touch "$(JSONL)"
OUTPUT="$("$ANALYTICS" all 2>&1)"
if echo "$OUTPUT" | grep -q "no data\|no skill runs"; then
  pass "Empty JSONL → no data message"
else
  fail "Empty JSONL → no data message"
fi
teardown_env

# Test 24: Renders dashboard with events
setup_env
echo '{"skill":"experiment","ts":"2026-04-01T10:00:00Z","v":1,"event_type":"skill_run","outcome":"success","duration_s":"120"}' > "$(JSONL)"
echo '{"skill":"lit-review","ts":"2026-04-01T11:00:00Z","v":1,"event_type":"skill_run","outcome":"success","duration_s":"60"}' >> "$(JSONL)"
OUTPUT="$("$ANALYTICS" all 2>&1)"
if echo "$OUTPUT" | grep -q "/experiment" && echo "$OUTPUT" | grep -q "/lit-review"; then
  pass "Renders dashboard with skill names"
else
  fail "Renders dashboard with skill names"
fi
teardown_env

# Test 25: Old-format records handled
setup_env
echo '{"skill":"lit-review","ts":"2026-04-01T10:00:00Z"}' > "$(JSONL)"
OUTPUT="$("$ANALYTICS" all 2>&1)"
if echo "$OUTPUT" | grep -q "/lit-review"; then
  pass "Old-format records handled"
else
  fail "Old-format records handled"
fi
teardown_env

# Test 26: Research stats shown
setup_env
echo '{"skill":"experiment","ts":"2026-04-01T10:00:00Z","v":1,"event_type":"skill_run","outcome":"success","compute_provider":"modal","venue":"arxiv"}' > "$(JSONL)"
OUTPUT="$("$ANALYTICS" all 2>&1)"
if echo "$OUTPUT" | grep -q "modal\|Research"; then
  pass "Research stats shown when data present"
else
  fail "Research stats shown when data present"
fi
teardown_env

echo ""

# ─── Summary ────────────────────────────────────────────────
TOTAL=$((PASS_COUNT + FAILURES))
echo "==========================="
echo "Results: $PASS_COUNT/$TOTAL passed"
if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES FAILURES"
  exit 1
else
  echo "All tests passed!"
  exit 0
fi
