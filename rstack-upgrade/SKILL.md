---
name: rstack-upgrade
version: 0.1.0
description: |
  Upgrade RStack to the latest version. Detects global vs vendored install,
  runs the upgrade, and shows what's new. Use when asked to "upgrade rstack",
  "update rstack", or "get latest version".
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

## Preamble (run first)

```bash
# --- GENERATED PREAMBLE START ---
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "WARNING: Not inside a git repository. Files will be written to $(pwd)."
fi
mkdir -p ~/.rstack/sessions ~/.rstack/analytics "$_PROJECT_ROOT/.rstack"
touch ~/.rstack/sessions/"$PPID"
find ~/.rstack/sessions -mmin +120 -type f -delete 2>/dev/null || true
_SESSIONS=$(find ~/.rstack/sessions -mmin -120 -type f 2>/dev/null | wc -l | tr -d ' ')
_RSTACK_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd || echo "$HOME/.claude/skills/rstack")"
_RSTACK_CONFIG="$_RSTACK_DIR/bin/rstack-config"
_UPD=$("$_RSTACK_DIR/bin/rstack-update-check" 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
_VENUE=$("$_RSTACK_CONFIG" get venue 2>/dev/null || echo "arxiv")
_COMPUTE=$("$_RSTACK_CONFIG" get compute_preferred 2>/dev/null || echo "modal")
_PROACTIVE=$("$_RSTACK_CONFIG" get proactive 2>/dev/null || echo "true")
_TEL=$("$_RSTACK_CONFIG" get telemetry 2>/dev/null || echo "off")
_TEL_PROMPTED=$([ -f ~/.rstack/.telemetry-prompted ] && echo "yes" || echo "no")
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
_LOCAL_VER="$(cat "$_RSTACK_DIR/VERSION" 2>/dev/null | tr -d '[:space:]')"
echo "PROJECT_ROOT: $_PROJECT_ROOT"
echo "BRANCH: $_BRANCH"
echo "VENUE: $_VENUE"
echo "COMPUTE: $_COMPUTE"
echo "PROACTIVE: $_PROACTIVE"
echo "RSTACK_DIR: $_RSTACK_DIR"
echo "LOCAL_VERSION: ${_LOCAL_VER:-unknown}"
if [ ! -f ~/.rstack/.setup-complete ]; then
  echo "NEEDS_SETUP"
fi
_TEL_START=$(date +%s)
_SESSION_ID="$$-$(date +%s)"
echo "TELEMETRY: ${_TEL:-off}"
echo "TEL_PROMPTED: $_TEL_PROMPTED"
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"rstack-upgrade","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","repo":"'$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")'"}'  >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
fi
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"rstack-upgrade","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","session_id":"'"$_SESSION_ID"'","rstack_version":"'"$(cat "$_RSTACK_DIR/VERSION" 2>/dev/null | tr -d "[:space:]" || echo "unknown")"'"}'  > ~/.rstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
fi
for _PF in $(find ~/.rstack/analytics -maxdepth 1 -name '.pending-*' 2>/dev/null); do
  if [ -f "$_PF" ]; then
    _PF_BASE="$(basename "$_PF")"
    _PF_SID="${_PF_BASE#.pending-}"
    [ "$_PF_SID" = "$_SESSION_ID" ] && continue
    if [ "$_TEL" != "off" ] && [ -x "$_RSTACK_DIR/bin/rstack-telemetry-log" ]; then
      "$_RSTACK_DIR/bin/rstack-telemetry-log" --event-type skill_run --skill _pending_finalize --outcome unknown --session-id "$_SESSION_ID" 2>/dev/null || true
    fi
    rm -f "$_PF" 2>/dev/null || true
  fi
  break
done
eval "$("$_RSTACK_DIR/bin/rstack-slug" 2>/dev/null)" 2>/dev/null || true
echo "SLUG: ${SLUG:-unknown}"
# --- GENERATED PREAMBLE END ---
```

If `TEL_PROMPTED` is `no`: Ask the user about telemetry. Use AskUserQuestion:

> Help RStack get better! Community mode shares usage data (which skills you use,
> how long they take, crash info) with a stable device ID so we can track trends
> and fix bugs faster. No code, file paths, or repo names are ever sent.
> Change anytime with `rstack-config set telemetry off`.

Options:
- A) Help RStack get better! (recommended)
- B) No thanks

If A: run `rstack-config set telemetry community`

If B: ask a follow-up:
> How about anonymous mode? Just a counter that helps us know if anyone's out there.

Options:
- A) Sure, anonymous is fine
- B) No thanks, fully off

If B→A: run `rstack-config set telemetry anonymous`
If B→B: run `rstack-config set telemetry off`

Always run:
```bash
touch ~/.rstack/.telemetry-prompted
```

This only happens once. If `TEL_PROMPTED` is `yes`, skip this entirely.

## Inline Upgrade Flow

This flow is called from the preamble of any skill when `UPGRADE_AVAILABLE <old> <new>` is detected. It is also the standalone flow when the user types `/rstack-upgrade`.

### Step 1: Check for updates

If invoked standalone (not from another skill's preamble), force-check:

```bash
"$HOME/.claude/skills/rstack/bin/rstack-update-check" --force 2>/dev/null || true
```

Parse the output. If `UPGRADE_AVAILABLE <old> <new>`, proceed. If nothing (up to date), tell user: "RStack is up to date (v{version})." and stop.

### Step 2: Ask the user

Use AskUserQuestion:

> RStack update available: v{old} → v{new}.
>
> A) Upgrade now
> B) Always auto-upgrade (recommended for solo devs)
> C) Not now (remind me later)
> D) Never ask again

If A or B: proceed to Step 3.
If B: also run `~/.claude/skills/rstack/bin/rstack-config set auto_upgrade true`.
If C: write snooze state:

```bash
_SNOOZE_FILE="$HOME/.rstack/update-snoozed"
_REMOTE_VER="{new version}"
if [ -f "$_SNOOZE_FILE" ]; then
  _LEVEL=$(awk '{print $2}' "$_SNOOZE_FILE" 2>/dev/null || echo "0")
  _LEVEL=$((_LEVEL + 1))
else
  _LEVEL=1
fi
echo "$_REMOTE_VER $_LEVEL $(date +%s)" > "$_SNOOZE_FILE"
```

Tell user: "Snoozed. I'll remind you in {24h/48h/7d depending on level}." Continue with the original skill.

If D: run `~/.claude/skills/rstack/bin/rstack-config set update_check false`. Tell user: "Update checks disabled. Re-enable anytime with `bin/rstack-config set update_check true`." Continue with the original skill.

### Step 3: Run the upgrade

```bash
_RSTACK_DIR="$HOME/.claude/skills/rstack"
_OLD_VER="$(cat "$_RSTACK_DIR/VERSION" 2>/dev/null | tr -d '[:space:]')"

cd "$_RSTACK_DIR"
git stash --include-untracked 2>/dev/null || true
git fetch origin main 2>/dev/null
git reset --hard origin/main 2>/dev/null

# Re-run setup to update symlinks
./setup 2>/dev/null

_NEW_VER="$(cat "$_RSTACK_DIR/VERSION" 2>/dev/null | tr -d '[:space:]')"
```

If the upgrade fails (git fetch or reset errors), restore:

```bash
git stash pop 2>/dev/null || true
```

Tell user: "Upgrade failed. Your current version is preserved. Error: {error message}."

### Step 4: Write marker and clear cache

```bash
echo "$_OLD_VER" > "$HOME/.rstack/just-upgraded-from"
rm -f "$HOME/.rstack/last-update-check"
rm -f "$HOME/.rstack/update-snoozed"
```

### Step 5: Show what's new

Read `CHANGELOG.md` from the upgraded repo. Show the entries between the old and new versions.

Tell user: "Upgraded RStack: v{old} → v{new}. Here's what's new: {changelog summary}."

If called from another skill's preamble, continue with that skill. If standalone, stop.

## Auto-Upgrade Mode

If `auto_upgrade` config is `true`, skip the AskUserQuestion in Step 2 and go directly to Step 3. After upgrading, tell user: "RStack auto-upgraded: v{old} → v{new}." and continue.

If auto-upgrade fails, fall back to asking the user (don't silently continue with a broken install).

---

## Telemetry (run last)

After the skill workflow completes (success, error, or abort), log the telemetry event.

```bash
# --- GENERATED EPILOGUE START ---
_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
rm -f ~/.rstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"rstack-upgrade","duration_s":"'"$_TEL_DUR"'","outcome":"OUTCOME","session":"'"$_SESSION_ID"'","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
fi
if [ "$_TEL" != "off" ] && [ -x "$_RSTACK_DIR/bin/rstack-telemetry-log" ]; then
  "$_RSTACK_DIR/bin/rstack-telemetry-log" \
    --skill "rstack-upgrade" --duration "$_TEL_DUR" --outcome "OUTCOME" \
    --session-id "$_SESSION_ID" 2>/dev/null &
fi
# --- GENERATED EPILOGUE END ---
```

Replace `OUTCOME` with success/error/abort based on the workflow result.
