# RStack — Claude code for Research (Get to a paper 4X faster)

Research automation skills for Claude Code. Type `/research` and go from idea to submittable paper. Each skill works standalone but chains together into a full pipeline.

A PhD student with a deadline spends 70% of their time on grunt work: finding papers, provisioning GPUs, formatting LaTeX. RStack compresses that to near-zero. The thinking stays with the researcher.

## Skills

| Skill | What it does | When to use |
|-------|-------------|------------|
| `/research` | Full pipeline: idea to paper in one session | "Write a paper about...", "research this" |
| `/lit-review` | Find papers, structured summary, gap analysis | "Find papers about...", "literature review" |
| `/novelty-check` | Assess novelty, refine hypothesis | "Is this novel?", "check existing work" |
| `/experiment` | Generate code, run on cloud GPU (Modal), iterate | "Run experiments", "train a model" |
| `/analyze-results` | Publication-ready figures, tables, statistics | "Make figures", "analyze results" |
| `/write-paper` | Venue-formatted LaTeX with real results and citations | "Write the paper", "format for arXiv" |
| `/setup` | Configure Modal, tectonic, venue preferences | First-time setup |

## Install (30 seconds)

```bash
git clone --single-branch --depth 1 https://github.com/sunnnybala/Rstack.git ~/.claude/skills/rstack
cd ~/.claude/skills/rstack && ./setup
```

Then in Claude Code, run `/setup` to configure Modal and install tectonic.

For teams (vendored into project):
```bash
cp -Rf ~/.claude/skills/rstack .claude/skills/rstack
rm -rf .claude/skills/rstack/.git
cd .claude/skills/rstack && ./setup --local
```

## Quick Start

The full pipeline:
```
/research "Investigate whether mixture-of-experts improves efficiency of small language models on code generation tasks"
```

Individual skills:
```
/lit-review "transformer efficiency for code generation"
/novelty-check          # compare idea against found papers
/experiment             # generate and run experiments on Modal
/analyze-results        # create figures and tables
/write-paper            # write arXiv-formatted paper
```

## The Research Pipeline

```
IDEA → /lit-review → /novelty-check → /experiment → /analyze → /write-paper → PAPER
  ↑         ↑              ↑               ↑            ↑            ↑
  └─────────┴──────────────┴───────────────┴────────────┴────────────┘
                        revision loops at every checkpoint
```

Every phase transition is a human checkpoint. You approve the literature review before novelty assessment. Approve the experiment plan before cloud submission. Review each paper section before the next. The pipeline is iterative, not linear.

## How it Works

Each skill is a SKILL.md file that Claude Code reads and follows. No backend, no database, no custom agents. Work products live at your project root as normal files. Structured logs persist in `.rstack/`.

Cloud compute happens through Modal CLI commands that Claude runs directly, same pattern as GStack running `git push` or `gh pr create`.

### Architecture

- **Pure SKILL.md files** — no Express, no React, no Postgres. Claude Code IS the runtime.
- **Work products at project root** — visible files (paper.tex, figures, idea.md). JSONL plumbing in `.rstack/`.
- **Modal for cloud compute** — Claude runs `modal run train.py` directly. No wrappers.
- **Two-phase install** — offline bootstrap (`./setup`) + interactive auth (`/setup` skill).
- **Credentials in native stores** — Modal auth stays in `~/.modal.toml`. Never in RStack config.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full design rationale.

## Requirements

- **Claude Code** (or any Claude Code-compatible agent)
- **Python 3.8+**
- **Modal** (for cloud GPU experiments): `pip install modal && modal token new`
- **tectonic** (for LaTeX compilation): installed via `/setup`

## Project State

Work products live at the project root as normal, visible files. Internal plumbing
(structured JSONL logs) lives in `.rstack/`.

```
my-project/                     # Git root
├── idea.md                     # Your research idea
├── lit-review.md               # Human-readable literature review
├── refined-idea.md             # Sharpened hypothesis (from /novelty-check)
├── novelty-assessment.md       # Novelty analysis with score
├── experiment-plan.md          # Experiment design document
├── train.py                    # Generated experiment code
├── requirements.txt            # Experiment dependencies
├── results/                    # Raw outputs from cloud
│   └── run-001/
│       ├── metrics.json
│       ├── stdout.log
│       └── figures/
├── analysis/                   # Publication-ready figures + tables
│   ├── figures/                # PNG + PDF
│   ├── tables/                 # LaTeX source
│   └── stats.json              # Statistical summary
├── paper.tex                   # The paper
├── paper.bib                   # BibTeX citations
├── paper.pdf                   # Compiled paper
└── .rstack/                    # Internal plumbing (hidden)
    ├── lit-review.jsonl        # Structured paper records
    └── experiments.jsonl       # Append-only experiment log
```

## Configuration

Global config at `~/.rstack/config.yaml`:

```bash
bin/rstack-config get venue           # read: arxiv
bin/rstack-config set venue icml      # write
bin/rstack-config list                # show all
```

## Comparison

| | RStack | AutoResearch (Karpathy) | Sakana AI Scientist | Ignis |
|--|--------|------------------------|--------------------|----|
| Scope | Full pipeline | Experiment loop only | Full pipeline | Full pipeline |
| Infrastructure | None (SKILL.md files) | None (630 lines Python) | Custom agents | Express+React+Postgres+Modal |
| Cloud compute | Modal (direct CLI) | Local GPU only | Custom | Modal (custom runner) |
| Paper writing | Yes (venue-formatted) | No | Yes (42% failure rate) | Yes |
| Human-in-the-loop | Every phase boundary | Manual stop | Minimal | Per-phase |
| Install | 30 seconds | 30 seconds | Complex | Complex |

## Documentation

- [README.md](README.md) — this file
- [ARCHITECTURE.md](ARCHITECTURE.md) — why RStack is built this way
- [CLAUDE.md](CLAUDE.md) — development commands, project structure, config reference
- [CONTRIBUTING.md](CONTRIBUTING.md) — how to add skills and contribute
- [CHANGELOG.md](CHANGELOG.md) — release notes
- [ETHOS.md](ETHOS.md) — research philosophy (rigor, reproducibility, novelty)

## Inspired By

- **[GStack](https://github.com/garrytan/gstack)** — engineering skills for Claude Code. RStack follows its architecture exactly.
- **[AutoResearch](https://github.com/karpathy/autoresearch)** — Karpathy's autonomous experiment loop. Inspired RStack's /experiment skill.
- **Ignis** — prior research automation platform. Agent prompts extracted into SKILL.md format.

## License

MIT
