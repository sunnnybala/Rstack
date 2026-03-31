# Changelog

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
- State in `.rstack/` JSONL files (versioned records, append-only).
- Cloud compute via Modal CLI directly (Claude runs commands, same as GStack with git).
- Two-phase install: offline bootstrap (`./setup`) + interactive provider auth (`/setup` skill).
- Credentials in native CLI auth stores, not RStack config.

### Known limitations (v0.1)

- Modal only (RunPod support in v1.1)
- arXiv template only (NeurIPS/ICML when 2026 .sty files are published)
- Claude Code only (Codex support in v1.1)
- Sequential experiments only (parallel swarm in v2)
- Preambles inlined per-skill (template generation system in v1.1)
