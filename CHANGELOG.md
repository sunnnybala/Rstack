# Changelog

## [0.1.3] - 2026-04-01 — Auto-Update Check

### Added

- **Auto-update notifications.** Every skill preamble now checks for new RStack versions (cached, 60-minute TTL). When an update is available, offers to upgrade with 4 options: upgrade now, always auto-upgrade, snooze (24h/48h/7d escalation), or disable checks.
- **`/rstack-upgrade` skill** for standalone upgrade management.
- **`bin/rstack-update-check`** script with cache, snooze, and version validation.
- **Config keys:** `update_check` (default true) and `auto_upgrade` (default false).

## [0.1.2] - 2026-04-01 — Multi-File Experiments

### Changed

- **Experiment skill now supports multiple code files.** Claude can create helper modules (models.py, data.py, utils.py) alongside train.py instead of cramming everything into one file. train.py remains the entry point for preflight and Modal execution.

## [0.1.1] - 2026-04-01 — File Storage Refactor

### Changed

- **Work products now live at the project root** as normal, visible files (idea.md, paper.tex, analysis/, results/, etc.) instead of being hidden inside `.rstack/`.
- **`.rstack/` now only holds plumbing** — structured JSONL logs (lit-review.jsonl, experiments.jsonl).
- **All preambles resolve the git root** via `git rev-parse --show-toplevel`, fixing a bug where files could land in the wrong directory if Claude's CWD wasn't the project root.
- Updated all 8 SKILL.md files, shared references, templates, and documentation.

## [0.1.0] - 2026-03-31 — First Release

RStack is here. Type `/research` and go from idea to submittable paper. Each skill works standalone or chains together.

### Added

- **7 research skills** that automate the ML research pipeline:
  - `/lit-review` — search Semantic Scholar + WebSearch, structured JSONL output, consolidated literature review
  - `/novelty-check` — compare idea against papers, novelty scoring (1-10), produce refined hypothesis
  - `/experiment` — generate experiment code, local preflight dry-run, run on Modal GPU, iterative improvement loop
  - `/analyze-results` — matplotlib figures, LaTeX tables, statistical summary from experiment data
  - `/write-paper` — venue-formatted LaTeX with real results and citations, section-by-section human review, tectonic compilation
  - `/research` — orchestrator that chains all skills with iterative revision loops at every checkpoint
  - `/setup` — interactive Modal auth, tectonic install, venue configuration

- **CLI utilities** adapted from GStack:
  - `bin/rstack-config` — YAML config read/write (same interface as gstack-config)
  - `bin/rstack-slug` — project slug from git remote
  - `bin/rstack-compute-detect` — Modal + local GPU + LaTeX availability check
  - `bin/rstack-preflight` — 30-second CPU dry-run before cloud submission

- **Setup script** — one command install: `git clone ... && ./setup`. Platform detection (Linux, macOS, Windows Git Bash), Python check, symlink creation, config initialization.

- **arXiv LaTeX template** with section markers for skill insertion points.

- **Documentation** — README, ARCHITECTURE, CONTRIBUTING, CLAUDE.md, ETHOS, CHANGELOG.

### Architecture decisions

- Pure SKILL.md files on Claude Code. No backend, no database, no compiled binaries.
- Work products at project root, plumbing in `.rstack/` JSONL files (versioned records, append-only).
- Cloud compute via Modal CLI directly (Claude runs commands, same as GStack with git).
- Two-phase install: offline bootstrap (`./setup`) + interactive provider auth (`/setup` skill).
- Credentials in native CLI auth stores, not RStack config.

### Known limitations (v0.1)

- Modal only (RunPod support in v1.1)
- arXiv template only (NeurIPS/ICML when 2026 .sty files are published)
- Claude Code only (Codex support in v1.1)
- Sequential experiments only (parallel swarm in v2)
- Preambles inlined per-skill (template generation system in v1.1)
