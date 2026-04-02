---
name: rstack
version: 0.1.0
description: |
  Research automation skills for Claude Code. Full pipeline from idea to
  submittable paper. Skills: /lit-review, /novelty-check, /experiment,
  /analyze-results, /write-paper, /research (orchestrator), /setup.
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
  echo '{"skill":"rstack","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","repo":"'$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")'"}'  >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
fi
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"rstack","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","session_id":"'"$_SESSION_ID"'","rstack_version":"'"$(cat "$_RSTACK_DIR/VERSION" 2>/dev/null | tr -d "[:space:]" || echo "unknown")"'"}'  > ~/.rstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
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

If output shows `UPGRADE_AVAILABLE <old> <new>`: tell user "RStack update available: v{old} → v{new}." Then read `rstack-upgrade/SKILL.md` and follow the "Inline Upgrade Flow".

If output shows `JUST_UPGRADED <from> <to>`: tell user "Running RStack v{to} (just updated!)" and continue.

If `NEEDS_SETUP`: tell user to run `/setup` to configure compute providers.

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

## RStack — Research Automation

Available skills:

| Skill | What it does | When to use |
|-------|-------------|------------|
| `/research` | Full pipeline: idea to paper | "Write a paper about...", "research this topic" |
| `/lit-review` | Find and review relevant papers | "Find papers about...", "literature review" |
| `/novelty-check` | Assess novelty, refine hypothesis | "Is this novel?", "check existing work" |
| `/experiment` | Run ML experiments on cloud GPU | "Run experiments", "train a model" |
| `/analyze-results` | Generate figures and tables | "Make figures", "analyze results" |
| `/write-paper` | Write venue-formatted LaTeX paper | "Write the paper", "format for arXiv" |
| `/setup` | Configure compute and tools | "Setup Modal", "configure RStack" |

## Routing

When the user's request matches a skill, invoke it using the Skill tool. Match rules:

- Research idea + wants full pipeline → `/research`
- Wants to find papers, survey a field → `/lit-review`
- Wants to check if idea is novel → `/novelty-check`
- Wants to run experiments, train models → `/experiment`
- Has results, wants figures/tables → `/analyze-results`
- Has results, wants to write paper → `/write-paper`
- Needs to configure Modal, tectonic → `/setup`

If unclear what the user wants, ask:

> What would you like to do?
> A) Full research pipeline (idea to paper)
> B) Literature review
> C) Run experiments
> D) Write/format a paper
> E) Something else

---

## Telemetry (run last)

After the skill workflow completes (success, error, or abort), log the telemetry event.

```bash
# --- GENERATED EPILOGUE START ---
_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
rm -f ~/.rstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"rstack","duration_s":"'"$_TEL_DUR"'","outcome":"OUTCOME","session":"'"$_SESSION_ID"'","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
fi
if [ "$_TEL" != "off" ] && [ -x "$_RSTACK_DIR/bin/rstack-telemetry-log" ]; then
  "$_RSTACK_DIR/bin/rstack-telemetry-log" \
    --skill "rstack" --duration "$_TEL_DUR" --outcome "OUTCOME" \
    --session-id "$_SESSION_ID" 2>/dev/null &
fi
# --- GENERATED EPILOGUE END ---
```

Replace `OUTCOME` with success/error/abort based on the workflow result.
