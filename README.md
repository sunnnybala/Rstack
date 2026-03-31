# RStack — GStack for Research

Research automation skills for Claude Code. Type `/research` and go from idea to
submittable paper. Each skill works standalone but chains together.

## Skills

| Skill | What it does |
|-------|-------------|
| `/lit-review` | Find relevant papers, structured summary, gap analysis |
| `/novelty-check` | Compare your idea against literature, assess novelty, refine hypothesis |
| `/experiment` | Generate experiment code, run on cloud GPU (Modal), iterate |
| `/analyze-results` | Turn raw results into publication-ready figures and tables |
| `/write-paper` | Generate venue-formatted LaTeX with real results and citations |
| `/research` | Orchestrator: chains all skills, idea to paper in one session |
| `/setup` | Configure compute providers and tools |

## Install (30 seconds)

```bash
git clone --single-branch --depth 1 https://github.com/dhruv/rstack.git ~/.claude/skills/rstack
cd ~/.claude/skills/rstack && ./setup
```

Then in Claude Code, run `/setup` to configure Modal and install tectonic (LaTeX compiler).

## Quick Start

```
/research "Investigate whether mixture-of-experts improves efficiency of small language models on code generation tasks"
```

Or use individual skills:

```
/lit-review "transformer efficiency for code generation"
/experiment     # generates and runs experiments on Modal
/write-paper    # writes arXiv-formatted paper from results
```

## How it Works

Each skill is a SKILL.md file that Claude Code reads and follows. No backend, no database,
no custom agents. State persists in `.rstack/` JSONL files in your project directory.

Cloud compute happens through Modal CLI commands that Claude runs directly, same pattern
as GStack running `git push` or `gh pr create`.

## Requirements

- Claude Code (or Codex)
- Python 3.8+
- Modal account (for cloud GPU experiments): `pip install modal && modal token new`
- tectonic (for LaTeX compilation): install via `/setup`

## Project State

All research state lives in `.rstack/` in your project directory:

```
.rstack/
├── idea.md                 # Your research idea
├── lit-review.jsonl        # Papers found (structured records)
├── lit-review.md           # Human-readable literature review
├── refined-idea.md         # Sharpened hypothesis (from /novelty-check)
├── novelty-assessment.md   # Novelty analysis
├── experiments.jsonl       # Experiment log (append-only)
├── results/run-001/        # Raw experiment outputs from cloud
├── analysis/figures/       # Publication-ready figures
├── paper.tex               # The paper
├── paper.bib               # Citations
└── paper.pdf               # Compiled paper
```

## License

MIT
