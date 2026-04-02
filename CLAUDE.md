# RStack development

## Commands

```bash
./setup              # install: create symlinks, config, detect compute
bash setup           # same, explicit bash invocation
bin/rstack-config get venue       # read a config value
bin/rstack-config set venue icml  # write a config value
bin/rstack-config list            # show all config
bin/rstack-compute-detect         # check Modal, GPU, LaTeX availability
bin/rstack-preflight train.py     # 30s CPU dry-run of experiment code
bin/rstack-analytics              # usage dashboard (last 7 days)
bin/rstack-analytics 30d          # last 30 days
bin/rstack-analytics all          # all time
bin/rstack-telemetry-log --skill qa --duration 60 --outcome success --session-id test-1  # log event
bin/rstack-gen-preambles          # regenerate SKILL.md preamble/epilogue sections
bin/rstack-gen-preambles --check  # dry-run: exit 1 if any SKILL.md is outdated
```

## Testing

```bash
# Validate all skills have correct frontmatter
for f in */SKILL.md; do head -20 "$f" | grep "^name:" || echo "MISSING name: in $f"; done

# Test config read/write
RSTACK_STATE_DIR=/tmp/rstack-test bin/rstack-config set venue neurips
RSTACK_STATE_DIR=/tmp/rstack-test bin/rstack-config get venue  # should print: neurips

# Test setup script
bash setup  # should complete without errors

# Integration test: run /lit-review on a real topic
# (requires Claude Code session)
```

## Project structure

```
rstack/
├── setup                   # Install script (symlinks + config)
├── bin/                    # CLI utilities
│   ├── rstack-config       # YAML config read/write
│   ├── rstack-slug         # Project slug from git remote
│   ├── rstack-compute-detect  # Modal + GPU + LaTeX detection
│   ├── rstack-preflight    # 30s CPU dry-run for experiments
│   ├── rstack-telemetry-log    # Append telemetry event to local JSONL
│   ├── rstack-telemetry-sync   # Background sync to Supabase
│   ├── rstack-analytics        # Local usage dashboard
│   └── rstack-gen-preambles    # Template generator for SKILL.md sections
├── _shared/                # Shared reference files
│   ├── preamble.sh         # Reference preamble (each skill inlines its own)
│   ├── epilogue.sh         # Reference epilogue (telemetry finalization)
│   ├── compute.md          # Modal CLI reference + artifact contract
│   └── venues.md           # arXiv formatting rules (v1)
├── lit-review/SKILL.md     # Literature review skill
├── novelty-check/SKILL.md  # Novelty assessment + idea refinement
├── experiment/SKILL.md     # Cloud experiment execution (Modal)
├── analyze-results/SKILL.md # Figures, tables, statistics
├── write-paper/SKILL.md    # Venue-formatted LaTeX paper writing
├── research/SKILL.md       # Orchestrator: chains all skills
├── setup-skill/SKILL.md    # Interactive provider configuration
├── templates/arxiv/        # arXiv LaTeX template
├── SKILL.md                # Root routing skill
├── ETHOS.md                # Research philosophy
├── ARCHITECTURE.md         # Why RStack is built this way
├── CONTRIBUTING.md         # How to add skills
├── supabase/               # Telemetry backend
│   ├── config.sh           # Public Supabase project config
│   ├── migrations/         # Database schema
│   ├── functions/          # Edge functions
│   └── verify-rls.sh       # RLS smoke test
├── test/                   # Test scripts
├── CHANGELOG.md            # Release notes
└── README.md               # User guide
```

## Skill routing

When the user's request matches a research skill, invoke it:

- Research idea + full pipeline → `/research`
- Find papers, literature survey → `/lit-review`
- Check novelty of idea → `/novelty-check`
- Run ML experiments → `/experiment`
- Generate figures/tables → `/analyze-results`
- Write/format paper → `/write-paper`
- Configure providers → `/setup`

## State files

Work products go at the project root. Internal plumbing goes in `.rstack/`.

### Work products (project root)

| File | Written by | Format |
|------|-----------|--------|
| `idea.md` | user or /research | Markdown |
| `lit-review.md` | /lit-review | Markdown |
| `refined-idea.md` | /novelty-check | Markdown |
| `novelty-assessment.md` | /novelty-check | Markdown |
| `experiment-plan.md` | /experiment | Markdown |
| `train.py` | /experiment | Python |
| `requirements.txt` | /experiment | Text |
| `results/run-NNN/` | /experiment | Mixed (metrics.json, figures/, logs) |
| `analysis/` | /analyze-results | PNG, PDF, .tex, .json |
| `paper.tex` | /write-paper | LaTeX |
| `paper.bib` | /write-paper | BibTeX |
| `paper.pdf` | /write-paper | PDF |

### Plumbing (.rstack/)

| File | Written by | Format |
|------|-----------|--------|
| `lit-review.jsonl` | /lit-review | JSONL (versioned, `"v":1`) |
| `experiments.jsonl` | /experiment | JSONL (versioned, append-only) |

## Writing SKILL templates

SKILL.md files are prompt templates read by Claude, not bash scripts. Each bash code
block runs in a separate shell. Variables do not persist between blocks.

Rules (same as GStack):
- Use natural language for logic and state, not shell variables between blocks
- Keep bash blocks self-contained
- Express conditionals as English decision steps
- Use AskUserQuestion for all non-trivial decisions
- Include WebSearch in `allowed-tools` for skills that need web access

## Config keys

| Key | Default | Used by |
|-----|---------|---------|
| `compute_preferred` | `modal` | /experiment preamble |
| `venue` | `arxiv` | /write-paper, /research |
| `experiment_checkpoint` | `3` | /experiment (ask user every N runs) |
| `proactive` | `true` | root SKILL.md routing |
| `telemetry` | `off` | preamble, rstack-telemetry-log (off/anonymous/community) |
| `modal_installed` | (set by /setup) | /setup status tracking |
| `modal_authenticated` | (set by /setup) | /setup status tracking |
| `modal_default_gpu` | `A100` | /experiment cloud submission |
| `latex_compiler` | `tectonic` | /write-paper compilation |
| `update_check` | `true` | preamble (disable version check notifications) |
| `auto_upgrade` | `false` | rstack-upgrade (auto-upgrade on session start) |

## Telemetry

Three tiers: `off` (default), `anonymous`, `community`.

```bash
bin/rstack-config set telemetry community   # enable with stable device ID
bin/rstack-config set telemetry anonymous   # enable without device ID
bin/rstack-config set telemetry off         # disable all telemetry
bin/rstack-analytics                        # view local usage dashboard
```

When not `off`, skill events are logged to `~/.rstack/analytics/skill-usage.jsonl` (local, inspectable).
Events sync to Supabase in background (rate-limited, 5 min) when a URL is configured.
Local-only fields (`_repo_slug`, `_branch`) are stripped before sending.
Error messages are sanitized client-side (paths and secrets stripped) before writing to JSONL.
Installation ID (UUID) is only generated when the user chooses community tier.
