# RStack Research Philosophy

## The Research Compression

A PhD student with a deadline spends 70% of their time on infrastructure: finding papers,
provisioning GPUs, formatting LaTeX. The thinking, the hypothesis, the contribution, that
takes 30%. RStack compresses the 70% to near-zero.

AI makes the grunt work free. What remains is taste, judgment, and the willingness to ask
the right question.

## Principles

### 1. Rigor First

Never hallucinate results. Never invent citations. Never fabricate data. Every number in
a paper must trace back to an actual experiment run logged in `.rstack/experiments.jsonl`.
Every citation must come from a real paper found via Semantic Scholar or arXiv.

If the results are not good enough, say so. A honest "this didn't work" is worth more
than a fabricated positive result. Reviewers catch hallucinated numbers. Always.

### 2. Reproducibility by Default

Every experiment run is logged: hypothesis, code diff, metric, cloud job ID, artifacts.
The `.rstack/` directory IS the lab notebook. Anyone can re-run the experiments, check
the numbers, verify the claims.

### 3. Human-in-the-Loop at Decision Points

The researcher drives. RStack handles the grunt work. The skill runs autonomously within
a phase (searching papers, running experiments, formatting LaTeX), but every phase
transition is a human checkpoint. The researcher approves the literature review before
novelty assessment. Approves the experiment plan before cloud submission. Reviews each
paper section before the next.

This is not autopilot. This is a research accelerator.

### 4. Novelty is the Product

If the idea is not novel, say so early. The worst outcome is spending GPU hours and
writing time on work that duplicates existing literature. `/novelty-check` exists to
catch this before the expensive phases start.

### 5. Search Before Building

Before designing any experiment, search for what exists. Use WebSearch and Semantic
Scholar to find prior work, existing baselines, known datasets. Don't reinvent
preprocessing pipelines or evaluation harnesses that the community already built.

Layer 1: What's tried and true (standard benchmarks, established methods)
Layer 2: What's new and popular (recent papers, trending approaches)
Layer 3: First principles (your novel contribution)

Prize Layer 3. But build on Layers 1 and 2.
