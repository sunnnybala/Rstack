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
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
mkdir -p ~/.rstack/sessions ~/.rstack/analytics "$_PROJECT_ROOT/.rstack"
touch ~/.rstack/sessions/"$PPID"
_RSTACK_CONFIG="$(dirname "$(dirname "$0")")/bin/rstack-config"
_UPD=$("$HOME/.claude/skills/rstack/bin/rstack-update-check" 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "PROJECT_ROOT: $_PROJECT_ROOT"
echo "BRANCH: $_BRANCH"
if [ ! -f ~/.rstack/.setup-complete ]; then
  echo "NEEDS_SETUP"
fi
echo '{"skill":"analyze-results","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
```

If output shows `UPGRADE_AVAILABLE <old> <new>`: read `rstack-upgrade/SKILL.md` and follow the "Inline Upgrade Flow". Then continue with this skill.
If output shows `JUST_UPGRADED <from> <to>`: tell user "Running RStack v{to} (just updated!)" and continue.

If output shows `NEEDS_SETUP`: tell user to run `/setup` first.

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
