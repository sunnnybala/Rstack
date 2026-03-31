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
mkdir -p ~/.rstack/analytics
echo '{"skill":"setup","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
echo "=== RStack Setup ==="
```

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

If A: Run `pip install modal`. Then run `modal token new` — this opens a browser for authentication. Wait for user to complete. Verify with `modal token show`.

**If Modal installed but NOT authenticated:**
Tell user: "Modal is installed but not authenticated."
Run: Tell the user to execute `modal token new` in their terminal (or type `! modal token new` in Claude Code's prompt to run it in-session). Verify with `modal token show`.

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
