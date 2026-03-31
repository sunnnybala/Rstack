# Architecture

This document explains **why** RStack is built the way it is. For setup and commands, see CLAUDE.md. For contributing, see CONTRIBUTING.md.

## The core idea

RStack gives Claude Code research superpowers through pure SKILL.md files. No backend, no database, no compiled binaries. Just Markdown that Claude reads and follows.

The key insight: Claude Code in 2026 is strong enough to handle the entire research pipeline, from searching papers to running cloud experiments to writing LaTeX, when given clear, step-by-step instructions. You don't need 13 specialized Mastra agents (like Ignis had). You need 7 well-written SKILL.md files.

```
Researcher types /research "my idea"
        │
        ▼
Claude Code reads research/SKILL.md
        │
        ▼
Orchestrator chains skills with human checkpoints:
        │
        ├── /lit-review    → WebSearch + Semantic Scholar API
        ├── /novelty-check → compare against literature
        ├── /experiment    → generate code + run on Modal
        ├── /analyze       → matplotlib figures + LaTeX tables
        └── /write-paper   → venue-formatted LaTeX + compile
        │
        ▼
Output: .rstack/paper.pdf
```

## Why SKILL.md files (not a custom backend)

The predecessor, Ignis, used Express.js + React + PostgreSQL + Modal + Supabase + 13 Mastra agents on Google Vertex AI. It worked, but the infrastructure overhead killed iteration speed. Adding a new research step meant: write an agent, register it with Mastra, add a route, update the frontend, test the workflow, deploy to Railway.

RStack's approach: write a Markdown file. That's it.

GStack proved this pattern works at scale, 31 skills covering the full engineering lifecycle, all as SKILL.md files. RStack follows the exact same architecture:

- **Frontmatter** declares the skill name, version, and which tools Claude can use
- **Preamble bash** loads config and checks setup state
- **Prose workflow** tells Claude step-by-step what to do
- **AskUserQuestion** checkpoints keep the human in the loop

## Why no wrappers around cloud CLIs

GStack runs `git push` and `gh pr create` directly. It doesn't have a `gstack-git-push` wrapper. Same pattern here: Claude runs `modal run train.py` directly.

The only helper scripts are for things bash does better than prose:
- `rstack-config`: YAML config read/write (same as gstack-config)
- `rstack-slug`: project slug generation (same as gstack-slug)
- `rstack-compute-detect`: checks what's installed (modal, GPU, tectonic)
- `rstack-preflight`: 30-second CPU dry-run before cloud submission

## State management

All research state lives in `.rstack/` in the project directory. No database.

```
.rstack/
├── idea.md                 # Raw research idea (user input)
├── lit-review.jsonl        # Papers found (structured, append-only)
├── lit-review.md           # Human-readable literature review
├── refined-idea.md         # Sharpened hypothesis (from /novelty-check)
├── novelty-assessment.md   # Novelty analysis
├── experiment-plan.md      # Experiment design
├── experiments.jsonl       # Experiment log (append-only, versioned records)
├── results/run-NNN/        # Raw outputs from cloud (metrics, figures, logs)
├── analysis/               # Publication-ready figures + tables
├── paper.tex               # The paper
├── paper.bib               # Citations
└── paper.pdf               # Compiled output
```

JSONL files use versioned records (`"v": 1`) for forward compatibility. Each record is one line, append-only. Skills write incrementally to avoid context bloat.

## Two-phase installation

Adapted from GStack's `setup` script pattern:

1. **Bootstrap** (`./setup`, 30 seconds, offline): creates `~/.rstack/`, symlinks skill directories into `~/.claude/skills/`, writes default config. Creates `.install-complete` marker.

2. **Provider setup** (`/setup` skill, interactive): configures Modal auth, installs tectonic, sets venue preference. Creates `.setup-complete` marker. Triggered automatically on first skill invocation if not done.

This separation means the install script never crosses a network boundary. The interactive auth happens inside Claude Code where the user can run commands.

## Config system

Global config at `~/.rstack/config.yaml`, managed by `bin/rstack-config`:

```yaml
compute_preferred: modal
venue: arxiv
experiment_checkpoint: 3
proactive: true
telemetry: off
```

Flat keys only (not nested YAML). Same `get`/`set`/`list` interface as GStack's `gstack-config`. Credentials stay in native CLI auth stores (Modal's `~/.modal.toml`, etc.), never in RStack config.

## Skill chaining

Skills are standalone but composable. The `/research` orchestrator reads each sub-skill's SKILL.md file and follows it inline. Every phase transition is a human checkpoint with revision loops:

```
IDEA → /lit-review → /novelty-check → /experiment → /analyze → /write-paper → PAPER
  ↑         ↑              ↑               ↑            ↑            ↑
  └─────────┴──────────────┴───────────────┴────────────┴────────────┘
                        (revision loops at every checkpoint)
```

Skills discover prior outputs by checking `.rstack/` files. If `/novelty-check` finds `lit-review.jsonl`, it uses it. If not, it runs a lightweight search. Each skill degrades gracefully when upstream outputs are missing.

## What RStack does NOT do

- **Full autopilot.** Sakana's AI Scientist has a 42% experiment failure rate. RStack keeps the human in the loop at every decision point.
- **Hallucinate results.** Every number traces to `experiments.jsonl`. Every citation traces to `lit-review.jsonl`.
- **Replace thinking.** RStack compresses the 70% of research time spent on infrastructure. The 30% that's actual research thinking stays with the researcher.
