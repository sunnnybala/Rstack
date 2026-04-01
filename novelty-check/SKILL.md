---
name: novelty-check
version: 0.1.0
description: |
  Compare your research idea against existing literature, assess novelty,
  and refine the hypothesis. Produces refined-idea.md that downstream
  skills consume. Use when asked to "check novelty", "is this novel",
  "compare against existing work", or "refine my idea".
  Proactively invoke after /lit-review completes.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - WebSearch
  - AskUserQuestion
---

## Preamble (run first)

```bash
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
mkdir -p ~/.rstack/sessions ~/.rstack/analytics "$_PROJECT_ROOT/.rstack"
touch ~/.rstack/sessions/"$PPID"
find ~/.rstack/sessions -mmin +120 -type f -delete 2>/dev/null || true
_RSTACK_CONFIG="$(dirname "$(dirname "$0")")/bin/rstack-config"
_UPD=$("$HOME/.claude/skills/rstack/bin/rstack-update-check" 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
_VENUE=$("$_RSTACK_CONFIG" get venue 2>/dev/null || echo "arxiv")
_COMPUTE=$("$_RSTACK_CONFIG" get compute_preferred 2>/dev/null || echo "modal")
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "PROJECT_ROOT: $_PROJECT_ROOT"
echo "BRANCH: $_BRANCH"
echo "VENUE: $_VENUE"
if [ ! -f ~/.rstack/.setup-complete ]; then
  echo "NEEDS_SETUP"
fi
echo '{"skill":"novelty-check","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
```

If output shows `UPGRADE_AVAILABLE <old> <new>`: read `rstack-upgrade/SKILL.md` and follow the "Inline Upgrade Flow". Then continue with this skill.
If output shows `JUST_UPGRADED <from> <to>`: tell user "Running RStack v{to} (just updated!)" and continue.

If output shows `NEEDS_SETUP`: tell user "RStack not configured yet. Run `/setup` to configure compute providers." Then read `setup-skill/SKILL.md` and follow it inline before continuing.

**Important:** Note the `PROJECT_ROOT` value from the preamble output. All file paths below are relative to this project root directory. Work products (idea.md, refined-idea.md, etc.) go at the project root. Plumbing (.rstack/lit-review.jsonl) goes in the `.rstack/` subdirectory.

## When to Use

Run this after `/lit-review` to assess whether your research idea is novel. Can also run standalone — if no literature review exists, it runs a lightweight search first (top 10 papers only).

## Step 0: Load Context

1. Read `idea.md` at the project root. If it does not exist, ask the user for their research idea and save it.
2. Check if `.rstack/lit-review.jsonl` exists.
   - If YES: read it. This is the primary source for comparison.
   - If NO: run a lightweight search. Use WebSearch to find the top 10 most relevant papers for this idea. Record them as temporary context. Note: "Running lightweight novelty check without full literature review. Run /lit-review first for higher confidence."

## Step 1: Paper-by-Paper Comparison

For each highly relevant paper (relevance >= 7 from lit-review.jsonl, or all papers from lightweight search):

Compare the research idea against the paper on these dimensions:
- **Method overlap**: Does the paper use the same approach? Same model architecture, training method, loss function?
- **Application overlap**: Does the paper target the same domain/task?
- **Dataset overlap**: Does the paper use the same benchmarks?
- **Contribution overlap**: Does the paper make the same claim about what works and why?

For each paper, classify the relationship:
- `direct_competitor` — same method, same domain
- `partial_overlap` — shares method OR domain but not both
- `complementary` — different approach to the same problem (potential baseline)
- `foundational` — builds the theory our work extends
- `unrelated` — low relevance, skip

## Step 2: Novelty Assessment

Synthesize the paper comparisons into a novelty assessment:

1. **What is genuinely novel** about this idea? (Be specific — not "we apply X to Y" but "we combine X's loss function with Y's architecture, which no existing work has tried because...")
2. **What overlaps** with existing work? (Name specific papers)
3. **What gaps** in existing work does this idea address?
4. **Novelty score**: 1-10 where:
   - 1-3: Significant overlap with existing work, marginal contribution
   - 4-6: Incremental improvement over existing methods
   - 7-8: Genuine novelty in method, application, or insight
   - 9-10: Paradigm-shifting new approach

Write assessment to `novelty-assessment.md` at the project root.

## Step 3: Idea Refinement

Based on the novelty assessment, produce a refined research statement. This is critical — `/experiment` consumes `refined-idea.md`, not the raw `idea.md`.

Write `refined-idea.md` at the project root with these sections (extracted from Ignis refine-idea-agent.ts):

```markdown
# Refined Research Idea

## Problem Statement
[One paragraph: what problem are we solving and why it matters]

## Proposed Approach
[2-3 paragraphs: what we will do, technically specific]

## What is Novel
[Bullet list: exactly what contributions are new vs existing work]

## Key Assumptions
[What must be true for this approach to work]

## Evaluation Plan
[What metrics, what datasets, what baselines to compare against]

## Risks
[What could go wrong, what might not work]

## Next Actions
[Concrete next steps for /experiment]
```

## Step 4: Human Checkpoint

Use AskUserQuestion:

> **Project:** {project name}, branch: {branch}
>
> Novelty assessment complete. Your idea scores {score}/10 for novelty.
> {one sentence summary of the main novel contribution}.
> {one sentence about the main overlap concern, if any}.
>
> The refined hypothesis is saved to `refined-idea.md`.
>
> RECOMMENDATION: Choose A to proceed with experiments.

Options:
- A) Proceed to experiments — the idea is novel enough
- B) Refine further — I want to adjust the approach (loops back to Step 3)
- C) Deepen literature — search for more papers in area X (loops back to /lit-review)
- D) Pivot — the idea needs fundamental rethinking (loops back to idea.md)

If B: ask what to change, update `refined-idea.md`, re-assess novelty.
If C: suggest running /lit-review with more specific queries.
If D: ask for the new direction, update `idea.md`, re-run from Step 0.

## Important Rules

- Never tell the user their idea is novel when it clearly overlaps with existing work. Be honest.
- Always name specific papers when discussing overlap. "Your approach resembles Smith et al. (2024)" not "there is some overlap."
- If novelty score is below 4, strongly recommend pivoting or finding a sharper angle before spending GPU hours.
- `refined-idea.md` is the most important output. It must be specific enough that /experiment can generate code from it.
