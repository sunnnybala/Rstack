---
name: setup
version: 0.1.0
description: |
  Configure compute providers and research tools for RStack.
  Use when asked to "setup rstack", "configure modal", "install tectonic",
  or when any skill prints NEEDS_SETUP.
  Run this once after installation, or again to reconfigure providers.
allowed-tools:
  - Bash
  - Read
  - Write
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
echo "PROJECT_ROOT: $_PROJECT_ROOT"
echo "BRANCH: $_BRANCH"
echo "VENUE: $_VENUE"
echo "COMPUTE: $_COMPUTE"
echo "PROACTIVE: $_PROACTIVE"
if [ ! -f ~/.rstack/.setup-complete ]; then
  echo "NEEDS_SETUP"
fi
_TEL_START=$(date +%s)
_SESSION_ID="$$-$(date +%s)"
echo "TELEMETRY: ${_TEL:-off}"
echo "TEL_PROMPTED: $_TEL_PROMPTED"
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"setup","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","repo":"'$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")'"}'  >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
fi
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"setup","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","session_id":"'"$_SESSION_ID"'","rstack_version":"'"$(cat "$_RSTACK_DIR/VERSION" 2>/dev/null | tr -d "[:space:]" || echo "unknown")"'"}'  > ~/.rstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
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
echo "=== RStack Setup ==="
# --- GENERATED PREAMBLE END ---
```

If output shows `UPGRADE_AVAILABLE <old> <new>`: read `rstack-upgrade/SKILL.md` and follow the "Inline Upgrade Flow". Then continue with this skill.
If output shows `JUST_UPGRADED <from> <to>`: tell user "Running RStack v{to} (just updated!)" and continue.

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

## Step 1: Detect Environment

Run the compute detection script:

```bash
~/.claude/skills/rstack/bin/rstack-compute-detect
```

Note the output. This shows what's installed and what's authenticated.

## Step 2: Configure Modal (Primary Compute)

Check if Modal is installed and authenticated from the detection output.

**If Modal NOT installed:**
Tell user: "Modal is the primary compute provider for running experiments on cloud GPUs."

Use AskUserQuestion:
> Modal is not installed. It's needed for /experiment to run training on cloud GPUs.
> Install now?
>
> A) Yes — install Modal (`pip install modal`)
> B) Skip — I'll use local GPU only
> C) Skip — I'll install it later

If A: Run `pip install modal`. Then run `modal token new` — this opens a browser for authentication. Wait for user to complete. Verify with `modal token info`.

**If Modal installed but NOT authenticated:**
Tell user: "Modal is installed but not authenticated."
Run: Tell the user to execute `modal token new` in their terminal (or type `! modal token new` in Claude Code's prompt to run it in-session). Verify with `modal token info`.

**If Modal installed AND authenticated:**
Tell user: "Modal is configured. Default GPU will be A100."

Save status:
```bash
~/.claude/skills/rstack/bin/rstack-config set modal_installed true
~/.claude/skills/rstack/bin/rstack-config set modal_authenticated true
~/.claude/skills/rstack/bin/rstack-config set modal_default_gpu A100
```

## Step 3: Configure LaTeX Compiler

Check if tectonic or pdflatex is available from the detection output.

**If neither installed:**
Use AskUserQuestion:
> No LaTeX compiler found. Tectonic is recommended (single binary, auto-downloads packages).
> Install now?
>
> A) Yes — install tectonic
> B) Skip — I'll install it later (/write-paper will remind you)

If A:
- macOS: `brew install tectonic`
- Linux: Download binary from https://tectonic-typesetting.github.io/
- Windows/WSL: Download binary or `cargo install tectonic` if Rust is installed

Save status:
```bash
~/.claude/skills/rstack/bin/rstack-config set latex_compiler tectonic
```

**If already installed:**
Note which compiler and save to config.

## Step 4: Set Default Venue

Use AskUserQuestion:
> Default venue for paper formatting?
>
> A) arXiv (preprint, no page limit) — recommended for v1
> B) I'll choose per paper

Save choice:
```bash
~/.claude/skills/rstack/bin/rstack-config set venue arxiv
```

## Step 5: Mark Complete

```bash
touch ~/.rstack/.setup-complete
touch ~/.rstack/.providers-configured
```

Show summary:
```
=== RStack Setup Complete ===
Compute:  Modal (authenticated, default GPU: A100)
LaTeX:    tectonic
Venue:    arXiv
Config:   ~/.rstack/config.yaml

Run /research to start your first project.
Run /lit-review, /experiment, or /write-paper individually.
```

## Re-running Setup

If the user runs `/setup` again:
- Re-detect everything (providers may have changed)
- Show current config and ask if they want to change anything
- Don't re-prompt for things already configured unless the user asks

---

## Telemetry (run last)

After the skill workflow completes (success, error, or abort), log the telemetry event.

```bash
# --- GENERATED EPILOGUE START ---
_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
rm -f ~/.rstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"setup","duration_s":"'"$_TEL_DUR"'","outcome":"OUTCOME","session":"'"$_SESSION_ID"'","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
fi
if [ "$_TEL" != "off" ] && [ -x "$_RSTACK_DIR/bin/rstack-telemetry-log" ]; then
  "$_RSTACK_DIR/bin/rstack-telemetry-log" \
    --skill "setup" --duration "$_TEL_DUR" --outcome "OUTCOME" \
    --session-id "$_SESSION_ID" 2>/dev/null &
fi
# --- GENERATED EPILOGUE END ---
```

Replace `OUTCOME` with success/error/abort based on the workflow result.
