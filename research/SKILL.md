---
name: research
version: 0.1.0
description: |
  Full research pipeline: idea to submittable paper in one session.
  Orchestrates /lit-review, /novelty-check, /experiment, /analyze-results,
  and /write-paper with human checkpoints at every phase boundary.
  Use when asked to "do research", "write a paper", "full pipeline",
  or "idea to paper".
  This is the flagship skill — chains all other skills together.
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
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
mkdir -p ~/.rstack/sessions ~/.rstack/analytics "$_PROJECT_ROOT/.rstack"
touch ~/.rstack/sessions/"$PPID"
_RSTACK_CONFIG="$(dirname "$(dirname "$0")")/bin/rstack-config"
_VENUE=$("$_RSTACK_CONFIG" get venue 2>/dev/null || echo "arxiv")
_COMPUTE=$("$_RSTACK_CONFIG" get compute_preferred 2>/dev/null || echo "modal")
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "PROJECT_ROOT: $_PROJECT_ROOT"
echo "BRANCH: $_BRANCH"
echo "VENUE: $_VENUE"
echo "COMPUTE: $_COMPUTE"
if [ ! -f ~/.rstack/.setup-complete ]; then
  echo "NEEDS_SETUP"
fi
echo '{"skill":"research","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
```

If output shows `NEEDS_SETUP`: tell user "RStack not configured. Running /setup first..." Then read `setup-skill/SKILL.md` and follow it inline.

**Important:** Note the `PROJECT_ROOT` value from the preamble output. All file paths below are relative to this project root directory. Work products (idea.md, paper.tex, etc.) go at the project root. Plumbing (.rstack/lit-review.jsonl, .rstack/experiments.jsonl) goes in the `.rstack/` subdirectory.

## Overview

This is the orchestrator. It chains all RStack skills together with human checkpoints at every phase boundary. The pipeline is NOT linear — every checkpoint allows looping back to earlier phases.

```
IDEA → /lit-review → /novelty-check → /experiment → /analyze-results → /write-paper → PAPER
  ↑         ↑              ↑               ↑               ↑                ↑
  └─────────┴──────────────┴───────────────┴───────────────┴────────────────┘
                        (revision loops at every checkpoint)
```

## Phase 1: Capture the Idea

Ask the user for their research idea if not provided as an argument.

Save to `idea.md` at the project root. Create the `.rstack/` plumbing directory if it doesn't exist:
```bash
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
mkdir -p "$_PROJECT_ROOT/.rstack"
```

Tell the user: "Starting the full research pipeline. I'll guide you through literature review, novelty assessment, experiments, analysis, and paper writing. You'll have a checkpoint at each phase."

## Phase 2: Literature Review

Read the `/lit-review` skill file at `~/.claude/skills/rstack/lit-review/SKILL.md` and follow it inline, skipping its preamble bash block (already run). Note: each subsequent bash block in the sub-skill re-derives `_PROJECT_ROOT` independently, so those still run normally.

After completion, check: does `.rstack/lit-review.jsonl` (plumbing) exist and have content?
- If YES: proceed to Phase 3
- If NO (lit-review failed or found nothing): AskUserQuestion — "Literature search found no relevant papers. A) Try different search terms B) Skip lit review and proceed anyway C) Abort"

## Phase 3: Novelty Assessment + Idea Refinement

Read the `/novelty-check` skill file at `~/.claude/skills/rstack/novelty-check/SKILL.md` and follow it inline, skipping its preamble.

After completion, check: does `refined-idea.md` exist at the project root?
- If YES and novelty score >= 4: proceed to Phase 4
- If YES but novelty score < 4: AskUserQuestion — "Novelty score is low ({score}/10). A) Proceed anyway B) Refine the idea C) Pivot to a different angle D) Abort"
- If NO: something went wrong, ask user how to proceed

**Revision loop**: If user chooses to refine or pivot, update `idea.md`, optionally re-run /lit-review, then re-run /novelty-check.

## Phase 4: Experiments

Read the `/experiment` skill file at `~/.claude/skills/rstack/experiment/SKILL.md` and follow it inline, skipping its preamble.

This phase is iterative. The /experiment skill runs multiple experiment cycles with its own internal checkpoints (every 3 runs by default).

After the user says "stop" or "enough experiments":
- Check: does `.rstack/experiments.jsonl` (plumbing) have at least one completed run?
- If YES: proceed to Phase 5
- If NO: AskUserQuestion — "No completed experiments. A) Try again B) Provide results manually C) Write paper without experiments (theory paper)"

**Revision loop**: If results are poor, the user can:
- Change approach → update `experiment-plan.md`, re-run experiments
- Revise hypothesis → update `refined-idea.md`, potentially re-run novelty check
- Deepen literature → run additional /lit-review queries

## Phase 5: Results Analysis

Read the `/analyze-results` skill file at `~/.claude/skills/rstack/analyze-results/SKILL.md` and follow it inline, skipping its preamble.

After completion, check: do figures exist in `analysis/figures/`?
- If YES: proceed to Phase 6
- If NO: warn user, proceed to paper writing without figures

## Phase 6: Paper Writing

Read the `/write-paper` skill file at `~/.claude/skills/rstack/write-paper/SKILL.md` and follow it inline, skipping its preamble.

After completion, check: does `paper.pdf` exist at the project root?
- If YES: proceed to Final
- If NO (compilation failed): show error, attempt to fix, retry

## Final: Summary

Present the complete research output:

```
=== RStack Research Complete ===
Idea:        idea.md
Lit Review:  lit-review.md ({N} papers found)
Novelty:     novelty-assessment.md (score: {X}/10)
Experiments: .rstack/experiments.jsonl ({N} runs, best: {metric}={value})
Figures:     analysis/figures/ ({N} figures)
Paper:       paper.pdf ({N} pages)

Work products at project root. Plumbing in .rstack/.
```

Use AskUserQuestion:
> Research pipeline complete. Paper is at `paper.pdf`.
>
> A) Done — I'm satisfied with the paper
> B) Revise — go back to a specific phase
> C) Run more experiments and update the paper

## Failure Handling

At each phase transition, if a skill fails:
1. Show the error clearly
2. Offer: Retry / Skip this phase / Abort
3. Never silently continue past a failure
4. Log the failure to `~/.rstack/analytics/skill-usage.jsonl`

If the user interrupts at any point, the project state is preserved. They can resume later by running `/research` again — it will detect existing files and ask where to pick up.

## Important Rules

- This skill READS other skill files and follows them inline. It does NOT re-implement their logic.
- Every phase boundary is a human checkpoint. No phase runs without the user's knowledge.
- State is always written to disk before checkpoints, so nothing is lost if the session ends.
- The pipeline supports any entry point: if `.rstack/lit-review.jsonl` (plumbing) already exists, skip Phase 2 and ask user if they want to re-run it or proceed.
