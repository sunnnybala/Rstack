---
name: lit-review
version: 0.1.0
description: |
  Find relevant papers across major indices, structured summary, gap analysis.
  Use when asked to "find papers", "literature review", "what's been done",
  "related work", or "survey the field".
  Proactively invoke when the user describes a research idea and needs to
  understand existing work.
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
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "PROJECT_ROOT: $_PROJECT_ROOT"
echo "BRANCH: $_BRANCH"
if [ ! -f ~/.rstack/.setup-complete ]; then
  echo "NEEDS_SETUP"
fi
echo '{"skill":"lit-review","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
```

If output shows `NEEDS_SETUP`: tell user "RStack not configured yet. Run `/setup` first."
Then read `setup-skill/SKILL.md` and follow it inline before continuing.

**Important:** Note the `PROJECT_ROOT` value from the preamble output. All file paths below are relative to this project root directory. When instructions say "write to `idea.md`", write to `{PROJECT_ROOT}/idea.md`. When they say `.rstack/lit-review.jsonl`, write to `{PROJECT_ROOT}/.rstack/lit-review.jsonl`.

---

## Step 0: Understand the Research Area

1. Read `idea.md` at the project root if it exists. This is the research idea to survey.
2. If `idea.md` does not exist, ask the user: "What research area should I survey? Describe your idea or topic."
3. Save the idea to `idea.md` at the project root if not already saved.
4. Extract 3-5 key concepts from the idea for search.

---

## Step 1: Generate Search Queries

Convert the research idea into academic search terms. Generate 2-3 queries with different angles:

**Query construction rules** (from Ignis query-builder-agent pattern):
- Each query should be 8-20 terms
- Include: key technical terms, synonyms, core task/domain
- Vary across queries: one broad, one specific to the method, one specific to the application

**Examples:**
- Broad: "mixture of experts language model efficiency scaling"
- Method-specific: "sparse MoE gating mechanism load balancing transformer"
- Application-specific: "code generation small language model parameter efficient"

---

## Step 2: Search for Papers

Use two search methods:

**Method A — WebSearch (Claude's built-in tool):**
Search for each query. Focus on finding academic papers, not blog posts or news articles.
Good search prefixes: "site:arxiv.org", "site:semanticscholar.org", "NeurIPS 2024", "ICML 2025"

**Method B — Semantic Scholar API:**
For each query, call the S2 API to get structured metadata:

```bash
QUERY="mixture+of+experts+language+model+efficiency"
curl -s "https://api.semanticscholar.org/graph/v1/paper/search?query=$QUERY&limit=10&fields=title,authors,year,venue,abstract,externalIds,url,citationCount"
```

**Rate limit handling:** Wait 3 seconds between S2 API calls. The free tier allows 100 requests per 5 minutes. If you get a 429 response, wait 60 seconds and retry.

**If S2 API fails entirely:** Fall back to WebSearch only and note "Structured metadata unavailable — using web search results only."

**Target:** Find 15-25 relevant papers across both methods. Deduplicate by title.

---

## Step 3: Assess and Record Each Paper

For each paper found, assess it and write a JSONL record to `.rstack/lit-review.jsonl` (in the project's `.rstack/` plumbing directory).

**Assessment criteria:**
- **Relevance** (0-10): How directly does this paper relate to the research idea?
  - 9-10: Directly addresses the same problem with the same or competing approach
  - 7-8: Closely related method or application
  - 5-6: Related but different angle (useful for context)
  - 1-4: Tangentially related (skip recording if below 5)
- **Key findings**: 1-2 sentences on what the paper contributes
- **Relationship to idea**: How does this paper relate to our specific idea?

**JSONL record format** (one per line, append to file):
```json
{"v":1,"id":"s2-abc123","title":"Mixture of Experts for Efficient Language Models","authors":["Alice Smith","Bob Jones"],"year":2025,"venue":"NeurIPS","abstract":"We propose...","url":"https://arxiv.org/abs/2025.12345","source":"semantic_scholar","relevance":8,"key_findings":"Sparse MoE reduces compute by 4x with 2% accuracy loss","relationship_to_idea":"Direct competitor — same method, different domain","citation_count":42}
```

**Write each record as you go.** Do not accumulate all papers in context — write to the JSONL file after assessing each paper. This keeps context manageable.

If a paper lacks some fields (no abstract from S2, missing venue), fill what's available and mark missing fields as empty strings.

---

## Step 4: Consolidate Literature Review

After all papers are recorded, write a human-readable literature review to `lit-review.md` at the project root.

**Structure** (from Ignis consolidate-lit-review-agent pattern):

```markdown
# Literature Review: {topic}

Generated by /lit-review on {date}

## Background
{2-3 paragraphs: field context, why this area matters, recent trends}

## Key Themes
{Major research directions identified across the papers. Group related papers.}

## Methods Landscape
{What approaches are people using? Compare methodologies across papers.}

## Datasets and Benchmarks
{What evaluation benchmarks are standard? What datasets are commonly used?}

## Limitations and Open Questions
{What gaps exist in the current literature? What hasn't been tried?
This is the most important section — it directly feeds /novelty-check.}

## Implications for Our Work
{How does this literature inform our research idea? What should we build on?
What should we avoid? What baselines should we compare against?}

## References
{Numbered list of all papers with title, authors, year, venue, URL}
```

**Length:** 800-1500 words. Only cite papers that are actually in `.rstack/lit-review.jsonl` (plumbing).

**Important:** When writing the consolidation, read from the JSONL file rather than relying on context memory. This ensures accuracy.

---

## Step 5: Human Checkpoint

Count papers: total found, highly relevant (relevance >= 7), and the main gap identified.

Use AskUserQuestion:

> **Project:** {project name}, branch: {branch}
>
> Literature review complete. Found {total} papers, {relevant} highly relevant.
>
> **Main finding:** {one sentence about the key theme}
> **Main gap:** {one sentence about what's missing in the literature}
>
> Saved to `.rstack/lit-review.jsonl` ({total} records) and `lit-review.md`.
>
> RECOMMENDATION: Choose A to proceed to novelty assessment.

Options:
- A) Proceed to /novelty-check
- B) Deepen search — look for more papers about {specific subtopic}
- C) Revise idea — the literature suggests a different direction
- D) Done — I just needed the literature review

If B: generate new search queries focused on the subtopic, repeat Steps 2-4, append new papers to the existing JSONL file, and update the lit-review.md.

If C: update `idea.md` with the new direction, then re-run from Step 1.

---

## Important Rules

- **Never hallucinate papers.** Every paper must come from WebSearch or the S2 API. If you're not sure a paper exists, search for it first.
- **Never fabricate citation counts, venues, or authors.** If the data isn't available, leave the field empty.
- **Write incrementally.** Append each paper to the JSONL as you assess it, don't batch.
- **Deduplicate.** If the same paper appears in both WebSearch and S2 results, record it once (prefer the S2 version for structured data).
- **Be honest about coverage.** If the search only found 5 papers, say so. Don't pad with marginally relevant work.
- **Zero results?** Widen search terms. Try different combinations. If still zero after 3 query variations, ask user to refine the research idea.

---

## Failure Modes

- **S2 API rate limit (429):** Wait 60 seconds, retry. If persistent, switch to WebSearch only.
- **S2 API down:** Use WebSearch exclusively. Note "S2 unavailable" in lit-review.md.
- **Zero results from all sources:** Ask user to refine or broaden the research idea.
- **Too many results (>50):** Filter by relevance >= 7 and citation count. Prioritize recent papers (last 3 years) and highly cited papers.
