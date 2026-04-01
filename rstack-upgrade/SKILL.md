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
mkdir -p ~/.rstack/analytics
echo '{"skill":"rstack-upgrade","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
_RSTACK_DIR="$HOME/.claude/skills/rstack"
[ -d "$_RSTACK_DIR" ] || _RSTACK_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)"
_LOCAL_VER="$(cat "$_RSTACK_DIR/VERSION" 2>/dev/null | tr -d '[:space:]')"
echo "RSTACK_DIR: $_RSTACK_DIR"
echo "LOCAL_VERSION: ${_LOCAL_VER:-unknown}"
```

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
