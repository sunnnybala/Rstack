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
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
mkdir -p ~/.rstack/sessions ~/.rstack/analytics "$_PROJECT_ROOT/.rstack"
touch ~/.rstack/sessions/"$PPID"
_RSTACK_CONFIG="$(dirname "$0")/bin/rstack-config"
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "PROJECT_ROOT: $_PROJECT_ROOT"
echo "BRANCH: $_BRANCH"
if [ ! -f ~/.rstack/.setup-complete ]; then
  echo "NEEDS_SETUP"
else
  echo "READY"
fi
echo '{"skill":"rstack","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
```

If `NEEDS_SETUP`: tell user to run `/setup` to configure compute providers.

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
