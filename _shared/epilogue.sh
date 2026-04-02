#!/usr/bin/env bash
# rstack shared epilogue — REFERENCE FILE
# Each SKILL.md inlines its own copy in a "## Telemetry (run last)" section.
# This file is the single source of truth for what the epilogue should look like.
# Run bin/rstack-gen-preambles to sync changes to all SKILL.md files.

_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
rm -f ~/.rstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
# Local analytics (always available, no binary needed)
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"SKILL_NAME","duration_s":'"$_TEL_DUR"',"outcome":"OUTCOME","session":"'"$_SESSION_ID"'","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
fi
# Remote telemetry (opt-in, requires binary)
if [ "$_TEL" != "off" ] && [ -x "$_RSTACK_DIR/bin/rstack-telemetry-log" ]; then
  "$_RSTACK_DIR/bin/rstack-telemetry-log" \
    --skill "SKILL_NAME" --duration "$_TEL_DUR" --outcome "OUTCOME" \
    --session-id "$_SESSION_ID" 2>/dev/null &
fi
