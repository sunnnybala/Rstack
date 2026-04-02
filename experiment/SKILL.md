---
name: experiment
version: 0.1.0
description: |
  Design and run ML experiments on cloud GPUs. Generates experiment code,
  runs on Modal, tracks results in JSONL. Use when asked to "run experiments",
  "train a model", "test this hypothesis", or "benchmark this approach".
  Proactively invoke when the user has a refined research idea and needs
  to validate it experimentally.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - WebSearch
  - AskUserQuestion
---

## Preamble (run first)

```bash
# --- GENERATED PREAMBLE START ---
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "WARNING: Not inside a git repository. Files will be written to $(pwd)."
fi
mkdir -p ~/.rstack/sessions ~/.rstack/analytics "$_PROJECT_ROOT/.rstack" "$_PROJECT_ROOT/results"
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
_CHECKPOINT=$("$_RSTACK_CONFIG" get experiment_checkpoint 2>/dev/null || echo "3")
_TEL=$("$_RSTACK_CONFIG" get telemetry 2>/dev/null || echo "off")
_TEL_PROMPTED=$([ -f ~/.rstack/.telemetry-prompted ] && echo "yes" || echo "no")
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "PROJECT_ROOT: $_PROJECT_ROOT"
echo "BRANCH: $_BRANCH"
echo "VENUE: $_VENUE"
echo "COMPUTE: $_COMPUTE"
echo "PROACTIVE: $_PROACTIVE"
echo "CHECKPOINT_INTERVAL: $_CHECKPOINT"
if [ ! -f ~/.rstack/.setup-complete ]; then
  echo "NEEDS_SETUP"
fi
_TEL_START=$(date +%s)
_SESSION_ID="$$-$(date +%s)"
echo "TELEMETRY: ${_TEL:-off}"
echo "TEL_PROMPTED: $_TEL_PROMPTED"
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"experiment","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","repo":"'$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")'"}'  >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
fi
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"experiment","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","session_id":"'"$_SESSION_ID"'","rstack_version":"'"$(cat "$_RSTACK_DIR/VERSION" 2>/dev/null | tr -d "[:space:]" || echo "unknown")"'"}'  > ~/.rstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
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

If output shows `NEEDS_SETUP`: tell user "Modal not configured. Running /setup first..."
Read `setup-skill/SKILL.md` and follow it inline.

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

**Important:** Note the `PROJECT_ROOT` value from the preamble output. All file paths below are relative to this project root directory. Work products (idea.md, experiment-plan.md, results/, train.py) go at the project root. Plumbing (.rstack/experiments.jsonl) goes in the `.rstack/` subdirectory.

---

## Step 0: Check Compute

Verify Modal is available and authenticated:

```bash
command -v modal >/dev/null 2>&1 && echo "MODAL_INSTALLED" || echo "MODAL_MISSING"
modal token info >/dev/null 2>&1 && echo "MODAL_AUTH_OK" || echo "MODAL_AUTH_FAIL"
```

- If `MODAL_MISSING`: tell user "Modal not installed. Run `pip install modal`" and STOP.
- If `MODAL_AUTH_FAIL`: tell user "Modal not authenticated. Run `! modal token new`" and STOP.
- If both OK: proceed.

---

## Step 1: Understand the Research Goal

Read context in this priority order:
1. `refined-idea.md` (best — from /novelty-check, has sharp hypothesis)
2. `idea.md` (good — raw idea)
3. Ask user directly (if neither file exists)

Also read if available:
- `novelty-assessment.md` — tells us what baselines to compare against
- `experiment-plan.md` — previous plan from a prior run
- `.rstack/experiments.jsonl` — prior experiment results (we're continuing)

---

## Step 2: Experiment Planning

Design the experiment before writing any code. Use WebSearch to find:
- Appropriate datasets for this research area (HuggingFace datasets preferred)
- Standard baselines to compare against
- Common evaluation metrics for this task

Write an experiment plan to `experiment-plan.md` at the project root:

```markdown
# Experiment Plan

## Objective
{What we're testing, in one sentence}

## Dataset
{Name, source (HuggingFace/URL), size, format}

## Model Architecture
{What we're building/modifying}

## Training Protocol
{Optimizer, learning rate, batch size, epochs, schedule}

## Baselines
{What we compare against — at minimum, one existing method}

## Evaluation Metrics
{Primary metric + secondary metrics}

## Ablations (if applicable)
{What components to test individually}
```

Use AskUserQuestion:
> Here's the experiment plan. Review and approve before I generate code?
>
> A) Looks good — generate the code
> B) Modify — I want to change something
> C) Use a different dataset / approach

---

## Step 3: Code Generation

Generate experiment code in the project directory. The entry point must be `train.py` (this is what preflight and `modal run` execute). Create additional modules as needed for clean code organization (e.g., `models.py`, `data.py`, `utils.py`, `evaluate.py`). Also generate `requirements.txt`.

Helper modules don't need Modal decorators or argparse. They're imported by `train.py`. Only the entry point needs the mandatory rules below.

**Mandatory rules for `train.py`** (the entry point):

1. **argparse interface:**
   ```python
   parser = argparse.ArgumentParser()
   parser.add_argument("--data_dir", type=str, default="./data")
   parser.add_argument("--smoke_test", action="store_true")
   parser.add_argument("--output_dir", type=str, default="/output")
   ```

2. **Smoke test mode:** When `--smoke_test` is passed:
   - Use only 10% of data or 1000 samples (whichever smaller)
   - Max 2 epochs
   - Skip expensive operations (large evaluations, visualization generation)
   - Still produce output files so the pipeline can be tested end-to-end

3. **Output contract:** ALL outputs go to the `--output_dir` (default `/output/`):
   ```python
   os.makedirs(args.output_dir, exist_ok=True)
   # Save metrics
   with open(os.path.join(args.output_dir, "metrics.json"), "w") as f:
       json.dump(metrics, f, indent=2)
   # Save figures
   plt.savefig(os.path.join(args.output_dir, "loss_curve.png"))
   ```

4. **Reproducibility:**
   ```python
   import random, numpy as np, torch
   SEED = 42
   random.seed(SEED)
   np.random.seed(SEED)
   torch.manual_seed(SEED)
   if torch.cuda.is_available():
       torch.cuda.manual_seed_all(SEED)
   ```

5. **Data validation:** At the start, print what's in the data directory and verify files exist:
   ```python
   print(f"Data directory: {args.data_dir}")
   print(f"Contents: {os.listdir(args.data_dir)}")
   assert os.path.exists(args.data_dir), f"Data dir not found: {args.data_dir}"
   ```

6. **Progress logging:** Print metrics to stdout so they appear in the run log:
   ```python
   print(f"Epoch {epoch}/{num_epochs} | Loss: {loss:.4f} | Acc: {acc:.4f}")
   ```

7. **Modal decorator** (for cloud execution):
   ```python
   import modal
   app = modal.App("rstack-experiment")
   
   @app.function(gpu="A100", timeout=600)
   def train():
       # ... training code ...
   ```

8. **requirements.txt:** Include only what's needed. Always include:
   ```
   torch
   numpy
   matplotlib
   datasets  # if using HuggingFace
   ```

---

## Step 4: Local Dry-Run

Before spending cloud GPU money, test locally:

```bash
rstack-preflight train.py
```

This runs `train.py --smoke_test` on CPU for 30 seconds. It catches:
- Import errors (missing packages)
- Data format issues
- Path bugs
- Syntax errors

**If preflight fails:**
- Show the error output
- Classify the error:
  - `ModuleNotFoundError` → suggest adding to requirements.txt
  - `FileNotFoundError` → check data paths
  - `SyntaxError` → fix the generated code
- Fix the issue and re-run preflight
- Max 3 fix attempts before asking user for help

**If preflight passes:** Proceed to cloud submission.

---

## Step 5: Human Confirmation

Use AskUserQuestion:

> **Project:** {project name}, branch: {branch}
>
> Code generated and preflight passed. Ready to submit to Modal.
> **GPU:** A100 | **Estimated duration:** ~{X} minutes | **Estimated cost:** ~${Y}
>
> RECOMMENDATION: Submit to Modal.

Options:
- A) Submit to Modal
- B) Modify code first — I want to change something
- C) Run locally instead (requires local GPU)
- D) Skip — don't run this experiment

If the user has previously said "auto" or is in `--auto` mode, skip this confirmation.

---

## Step 6: Cloud Execution

Run the experiment on Modal. Claude runs the command directly (same as GStack runs `git push`):

```bash
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
# Determine run ID
RUN_NUM=0
[ -f "$_PROJECT_ROOT/.rstack/experiments.jsonl" ] && RUN_NUM=$(wc -l < "$_PROJECT_ROOT/.rstack/experiments.jsonl" | tr -d ' ')
RUN_NUM=$((RUN_NUM + 1))
RUN_ID=$(printf "run-%03d" $RUN_NUM)
mkdir -p "$_PROJECT_ROOT/results/$RUN_ID"

# Execute on Modal (blocks until complete)
cd "$_PROJECT_ROOT" && modal run train.py 2>&1 | tee "$_PROJECT_ROOT/results/$RUN_ID/stdout.log"
```

After completion, download artifacts from Modal to `results/$RUN_ID/`.

**Error handling** (from Ignis run-experiment.ts classifyError):

If the run fails, read stderr and classify:

- If stderr contains `ModuleNotFoundError`: Import error. Suggest adding the package to requirements.txt. This is retryable.
- If stderr contains `OutOfMemoryError` or `CUDA out of memory`: Memory error. Suggest reducing batch_size or model size. This is retryable.
- If stderr contains `FileNotFoundError`: Data path error. Check that the dataset downloaded correctly and paths are right. This is retryable.
- If the process was killed by timeout: Training took too long. Suggest reducing epochs, dataset size, or model size. This is retryable.
- For any other non-zero exit: Show the last 50 lines of output. Ask user for guidance.

Max 3 retry attempts per experiment. After each failure, fix the identified issue before retrying.

---

## Step 7: Log Results

Extract metrics from the run output and `results/$RUN_ID/metrics.json`.

Append a record to `.rstack/experiments.jsonl`:

```json
{"v":1,"id":"run-001","ts":"2026-03-31T15:00:00Z","hypothesis":"Adding RMSNorm before attention improves convergence","metric_name":"val_loss","metric_value":0.342,"metric_improved":true,"status":"completed","cloud_provider":"modal","duration_s":312,"error_message":null,"artifacts":["results/run-001/metrics.json","results/run-001/figures/loss_curve.png"]}
```

**Run ID format:** `run-{NNN}` where NNN is the line count of experiments.jsonl + 1, zero-padded to 3 digits.

**Status values:** `completed`, `failed`, `reverted`

**For failed runs:** Still log them with `status: "failed"` and the error message. Every run gets logged.

---

## Step 8: Assess and Iterate

Compare this run's metric against the previous best (if any prior runs exist).

**Assessment** (from AutoResearch program.md pattern):

- **If improved:** "Run {id} improved {metric} from {old} to {new} ({improvement}%). The modification worked."
- **If worse or equal:** "Run {id} did not improve. {metric} went from {old} to {new}. Consider reverting this change."
- **Simplicity criterion:** A tiny improvement (< 1%) that requires a complex code change is probably not worth keeping. Note this tradeoff.

**After every N runs** (default 3, from config `experiment_checkpoint`), use AskUserQuestion:

> **Experiment progress:** {N} runs complete.
> **Best result:** {metric_name} = {best_value} (run-{best_id})
> **Trend:** {improving / plateauing / degrading}
>
> A) Continue experimenting — try next hypothesis
> B) Change direction — different approach
> C) Revise hypothesis — go back to /novelty-check
> D) Stop — results are good enough for the paper

If A: suggest the next experiment modification based on what's been tried and what worked. Go back to Step 3.
If B: ask what new direction, update `experiment-plan.md`, go back to Step 2.
If C: go back to /novelty-check.
If D: proceed. Suggest running /analyze-results next.

---

## Step 9: Loop

If the user wants to continue, generate a new hypothesis based on:
1. What has been tried (read experiments.jsonl)
2. What worked vs what didn't
3. The original research idea and plan

Then go back to Step 3 with the new hypothesis. Each iteration should try something meaningfully different, not just random hyperparameter tweaks.

---

## Important Rules

- **NEVER run cloud experiments without human confirmation** (unless in --auto mode).
- **NEVER skip the preflight dry-run.** It catches 80% of bugs for free.
- **ALWAYS log every run** to experiments.jsonl, even failures. The log IS the lab notebook.
- **ALL generated code must write to /output/.** This is the artifact contract.
- **If Modal auth expires mid-session,** tell user to run `! modal token new`.
- **Be honest about results.** If the experiment didn't improve, say so clearly.
- **Don't chase noise.** Small random fluctuations are not improvements. With a single seed, be cautious about claiming improvements smaller than 2-3%.

---

## Standalone Mode

If `/experiment` is invoked without prior /lit-review or /novelty-check:
- Ask user for the research goal directly
- Skip reading `refined-idea.md` (won't exist)
- Proceed from Step 2 (experiment planning)
- Note: "Running without literature review. Consider /lit-review first for better experiment design."

---

## Telemetry (run last)

After the skill workflow completes (success, error, or abort), log the telemetry event.

```bash
# --- GENERATED EPILOGUE START ---
_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
rm -f ~/.rstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"experiment","duration_s":"'"$_TEL_DUR"'","outcome":"OUTCOME","session":"'"$_SESSION_ID"'","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
fi
if [ "$_TEL" != "off" ] && [ -x "$_RSTACK_DIR/bin/rstack-telemetry-log" ]; then
  "$_RSTACK_DIR/bin/rstack-telemetry-log" \
    --skill "experiment" --duration "$_TEL_DUR" --outcome "OUTCOME" \
    --session-id "$_SESSION_ID" --pipeline-stage "experiment" --compute-provider "$_COMPUTE" --gpu-type "$(_RSTACK_CONFIG get modal_default_gpu 2>/dev/null || echo A100)" 2>/dev/null &
fi
# --- GENERATED EPILOGUE END ---
```

Replace `OUTCOME` with success/error/abort based on the workflow result.
