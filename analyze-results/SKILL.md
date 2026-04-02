---
name: analyze-results
version: 0.1.0
description: |
  Turn raw experiment outputs into publication-ready figures, tables,
  and statistical analysis. Use when asked to "analyze results",
  "make figures", "create tables", or "visualize experiments".
  Proactively invoke after /experiment produces results.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
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
  echo '{"skill":"analyze-results","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","repo":"'$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")'"}'  >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
fi
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"analyze-results","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","session_id":"'"$_SESSION_ID"'","rstack_version":"'"$(cat "$_RSTACK_DIR/VERSION" 2>/dev/null | tr -d "[:space:]" || echo "unknown")"'"}'  > ~/.rstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
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

If output shows `UPGRADE_AVAILABLE <old> <new>`: read `rstack-upgrade/SKILL.md` and follow the "Inline Upgrade Flow". Then continue with this skill.
If output shows `JUST_UPGRADED <from> <to>`: tell user "Running RStack v{to} (just updated!)" and continue.

If output shows `NEEDS_SETUP`: tell user to run `/setup` first.

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

**Important:** Note the `PROJECT_ROOT` value from the preamble output. All file paths below are relative to this project root directory. Work products (analysis/, figures) go at the project root. Plumbing (.rstack/experiments.jsonl) goes in the `.rstack/` subdirectory.

## Step 0: Load Experiment Data

First, create output directories:
```bash
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
mkdir -p "$_PROJECT_ROOT/analysis/figures" "$_PROJECT_ROOT/analysis/tables" "$_PROJECT_ROOT/analysis/scripts"
```

1. Read `.rstack/experiments.jsonl`. If it does not exist or is empty, tell user: "No experiment results found. Run /experiment first or provide results manually."
2. Read `results/` directory to find raw outputs (metrics.json, figures/, stdout.log for each run).
3. Count completed runs. If fewer than 2, warn: "Only {N} completed runs. Results may not be meaningful. Consider running more experiments."

## Step 1: Generate Comparison Table

Create a LaTeX-formatted comparison table comparing all experiment runs:

| Run | Hypothesis | Metric | Value | Improved? | Duration |
|-----|-----------|--------|-------|-----------|----------|

Read from experiments.jsonl. Include baseline (first run or user-specified baseline) and all subsequent runs. Highlight the best result.

Write table source to `analysis/tables/comparison.tex`.

## Step 2: Generate Figures

For each visualization needed, generate a self-contained Python matplotlib script and run it locally:

**Training curves** (if metrics.json contains per-epoch data):
```python
import matplotlib.pyplot as plt
import json
# Read metrics, plot loss/accuracy curves, save to analysis/figures/
```

**Ablation chart** (if multiple experiment variants exist):
- Bar chart comparing metric across runs
- Error bars if multiple seeds were used

**Other figures** as appropriate for the experiment type (confusion matrix, attention maps, etc.).

For each figure:
1. Write a Python script to `analysis/scripts/fig_{name}.py`
2. Run it: `python analysis/scripts/fig_{name}.py`
3. Output PNG + PDF to `analysis/figures/`

If matplotlib is not installed, run `pip install matplotlib` first.

## Step 3: Statistical Summary

Write `analysis/stats.json` with:
```json
{
  "total_runs": 5,
  "completed_runs": 4,
  "failed_runs": 1,
  "best_run": "run-003",
  "best_metric": {"name": "val_loss", "value": 0.342},
  "baseline_metric": {"name": "val_loss", "value": 0.456},
  "improvement": "25.0%",
  "figures_generated": ["loss_curve.png", "ablation.png"],
  "tables_generated": ["comparison.tex"]
}
```

## Step 4: Human Checkpoint

Show the user:
- Summary table (text format)
- List of generated figures (read and display the PNGs)
- Key finding: "Best result: {metric} = {value} (run-{N}), {X}% improvement over baseline"

Use AskUserQuestion:
> Figures and tables generated. {N} figures, {M} tables.
> Best result: {metric_name} = {value} ({improvement}% vs baseline).
>
> A) Looks good — proceed to paper writing
> B) Re-run analysis with different parameters
> C) Need more experiments first

## Important Rules

- Never invent data points. Every number comes from experiments.jsonl or results/ files.
- Always generate both PNG and PDF versions of figures (PNG for preview, PDF for LaTeX).
- Use clean, publication-quality style: no gridlines, readable fonts, proper axis labels.
- If only one experiment run exists, skip ablation charts and note "single run, no comparison possible."

---

## Telemetry (run last)

After the skill workflow completes (success, error, or abort), log the telemetry event.

```bash
# --- GENERATED EPILOGUE START ---
_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
rm -f ~/.rstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"analyze-results","duration_s":"'"$_TEL_DUR"'","outcome":"OUTCOME","session":"'"$_SESSION_ID"'","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
fi
if [ "$_TEL" != "off" ] && [ -x "$_RSTACK_DIR/bin/rstack-telemetry-log" ]; then
  "$_RSTACK_DIR/bin/rstack-telemetry-log" \
    --skill "analyze-results" --duration "$_TEL_DUR" --outcome "OUTCOME" \
    --session-id "$_SESSION_ID" --pipeline-stage "analyze-results" 2>/dev/null &
fi
# --- GENERATED EPILOGUE END ---
```

Replace `OUTCOME` with success/error/abort based on the workflow result.
