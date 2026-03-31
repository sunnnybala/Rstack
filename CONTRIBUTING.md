# Contributing to RStack

Thanks for wanting to make RStack better. Whether you're fixing a prompt in a skill or adding an entirely new research workflow, this guide gets you running.

## Quick start

```bash
git clone https://github.com/sunnnybala/Rstack.git
cd Rstack
./setup
```

RStack skills are Markdown files that Claude Code discovers from `~/.claude/skills/`. The setup script symlinks your repo's skill directories there, so edits take effect immediately.

## How skills work

Each skill is a SKILL.md file with three parts:

1. **YAML frontmatter** — name, version, description, allowed tools
2. **Preamble bash** — loads config, checks setup state, tracks sessions
3. **Prose workflow** — step-by-step instructions Claude follows

When a user types `/lit-review`, Claude reads `lit-review/SKILL.md` and follows it. That's the entire runtime. No compilation, no framework, no build step.

## Adding a new skill

1. Create a directory: `mkdir my-skill`
2. Create `my-skill/SKILL.md` with frontmatter:
   ```yaml
   ---
   name: my-skill
   version: 0.1.0
   description: |
     What this skill does. When to use it.
   allowed-tools:
     - Bash
     - Read
     - Write
     - WebSearch
     - AskUserQuestion
   ---
   ```
3. Add a preamble bash block (copy from any existing skill)
4. Write the workflow in prose with bash blocks where needed
5. Add the directory name to the `SKILL_DIRS` list in `setup` (line 52)
6. Run `./setup` to create the symlink

## Editing an existing skill

1. Edit the SKILL.md directly
2. Test by invoking the skill in Claude Code (e.g., `/lit-review`)
3. Changes are live immediately (symlinked)

## Conventions

**Follow GStack patterns.** RStack is modeled on GStack's architecture. If you're unsure how to structure something, check how GStack does it in the `gstack/` reference directory.

**State files go in `.rstack/`.** Skills read and write to the project-local `.rstack/` directory. Use JSONL for structured data (one record per line, versioned with `"v": 1`). Use Markdown for human-readable outputs.

**Config goes in `~/.rstack/config.yaml`.** Use `bin/rstack-config get/set` to read/write. Flat keys only. Never store credentials in config, those stay in native CLI auth stores.

**Human checkpoints at every phase boundary.** Use AskUserQuestion before any destructive or expensive action (cloud GPU submission, overwriting files, etc.).

**Never hallucinate.** Research skills must only cite papers that were actually found, use metrics from actual experiment runs, and reference figures that actually exist on disk.

**WebSearch for research tasks.** Include `WebSearch` in `allowed-tools` for any skill that needs to find papers, datasets, or baselines.

## Testing your changes

Since RStack is pure SKILL.md files (no compiled code), testing is:

1. **Frontmatter validation:**
   ```bash
   for f in */SKILL.md; do head -20 "$f" | grep "^name:" || echo "MISSING: $f"; done
   ```

2. **Config utility tests:**
   ```bash
   RSTACK_STATE_DIR=/tmp/rstack-test bin/rstack-config set venue neurips
   [ "$(RSTACK_STATE_DIR=/tmp/rstack-test bin/rstack-config get venue)" = "neurips" ] && echo PASS
   ```

3. **Integration test:** invoke each skill in Claude Code on a real research topic

4. **Setup test:** run `./setup` on a clean machine (or in a fresh directory)

## Project structure

See CLAUDE.md for the full directory layout and state file reference.

## Commit style

One logical change per commit. Bisectable history. Examples:

- `Add /my-skill: one-sentence description`
- `Fix /experiment: correct Modal auth command`
- `Update venues.md: add NeurIPS 2026 template`

## What NOT to change

- **ETHOS.md** — research philosophy is intentional, not generic
- **Reference projects** (`gstack/`, `Ignis/`, `autoresearch/`) — these are read-only references
- **Credentials** — never commit API keys, tokens, or auth state
