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
# --- GENERATED PREAMBLE START ---
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "WARNING: Not inside a git repository. Files will be written to $(pwd)."
fi
mkdir -p ~/.rstack/sessions ~/.rstack/analytics "$_PROJECT_ROOT/.rstack"
touch ~/.rstack/sessions/"$PPID"
find ~/.rstack/sessions -mmin +120 -type f -delete 2>/dev/null || true
_SESSIONS=$(find ~/.rstack/sessions -mmin -120 -type f 2>/dev/null | wc -l | tr -d ' ')
_RSTACK_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd || echo "$HOME/.claude/skills/rstack")"
_RSTACK_CONFIG="$_RSTACK_DIR/bin/rstack-config"
_UPD=$("$_RSTACK_DIR/bin/rstack-update-check" 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
_VENUE=$("$_RSTACK_CONFIG" get venue 2>/dev/null || echo "arxiv")
_COMPUTE=$("$_RSTACK_CONFIG" get compute_preferred 2>/dev/null || echo "modal")
_PROACTIVE=$("$_RSTACK_CONFIG" get proactive 2>/dev/null || echo "true")
_TEL=$("$_RSTACK_CONFIG" get telemetry 2>/dev/null || echo "off")
_TEL_PROMPTED=$([ -f ~/.rstack/.telemetry-prompted ] && echo "yes" || echo "no")
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "PROJECT_ROOT: $_PROJECT_ROOT"
echo "BRANCH: $_BRANCH"
echo "VENUE: $_VENUE"
echo "COMPUTE: $_COMPUTE"
echo "PROACTIVE: $_PROACTIVE"
if [ ! -f ~/.rstack/.setup-complete ]; then
  echo "NEEDS_SETUP"
fi
_TEL_START=$(date +%s)
_SESSION_ID="$$-$(date +%s)"
echo "TELEMETRY: ${_TEL:-off}"
echo "TEL_PROMPTED: $_TEL_PROMPTED"
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"lit-review","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","repo":"'$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")'"}'  >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
fi
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"lit-review","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","session_id":"'"$_SESSION_ID"'","rstack_version":"'"$(cat "$_RSTACK_DIR/VERSION" 2>/dev/null | tr -d "[:space:]" || echo "unknown")"'"}'  > ~/.rstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
fi
for _PF in $(find ~/.rstack/analytics -maxdepth 1 -name '.pending-*' 2>/dev/null); do
  if [ -f "$_PF" ]; then
    _PF_BASE="$(basename "$_PF")"
    _PF_SID="${_PF_BASE#.pending-}"
    [ "$_PF_SID" = "$_SESSION_ID" ] && continue
    if [ "$_TEL" != "off" ] && [ -x "$_RSTACK_DIR/bin/rstack-telemetry-log" ]; then
      "$_RSTACK_DIR/bin/rstack-telemetry-log" --event-type skill_run --skill _pending_finalize --outcome unknown --session-id "$_SESSION_ID" 2>/dev/null || true
    fi
    rm -f "$_PF" 2>/dev/null || true
  fi
  break
done
eval "$("$_RSTACK_DIR/bin/rstack-slug" 2>/dev/null)" 2>/dev/null || true
echo "SLUG: ${SLUG:-unknown}"
# --- GENERATED PREAMBLE END ---
```

If output shows `UPGRADE_AVAILABLE <old> <new>`: read `rstack-upgrade/SKILL.md` and follow the "Inline Upgrade Flow". Then continue with this skill.
If output shows `JUST_UPGRADED <from> <to>`: tell user "Running RStack v{to} (just updated!)" and continue.

If output shows `NEEDS_SETUP`: tell user "RStack not configured yet. Run `/setup` first."
Then read `setup-skill/SKILL.md` and follow it inline before continuing.

If `TEL_PROMPTED` is `no`: Ask the user about telemetry. Use AskUserQuestion:

> Help RStack get better! Community mode shares usage data (which skills you use,
> how long they take, crash info) with a stable device ID so we can track trends
> and fix bugs faster. No code, file paths, or repo names are ever sent.
> Change anytime with `rstack-config set telemetry off`.

Options:
- A) Help RStack get better! (recommended)
- B) No thanks

If A: run `rstack-config set telemetry community`

If B: ask a follow-up:
> How about anonymous mode? Just a counter that helps us know if anyone's out there.

Options:
- A) Sure, anonymous is fine
- B) No thanks, fully off

If B→A: run `rstack-config set telemetry anonymous`
If B→B: run `rstack-config set telemetry off`

Always run:
```bash
touch ~/.rstack/.telemetry-prompted
```

This only happens once. If `TEL_PROMPTED` is `yes`, skip this entirely.

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

---

## Telemetry (run last)

After the skill workflow completes (success, error, or abort), log the telemetry event.

```bash
# --- GENERATED EPILOGUE START ---
_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
rm -f ~/.rstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"lit-review","duration_s":"'"$_TEL_DUR"'","outcome":"OUTCOME","session":"'"$_SESSION_ID"'","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
fi
if [ "$_TEL" != "off" ] && [ -x "$_RSTACK_DIR/bin/rstack-telemetry-log" ]; then
  "$_RSTACK_DIR/bin/rstack-telemetry-log" \
    --skill "lit-review" --duration "$_TEL_DUR" --outcome "OUTCOME" \
    --session-id "$_SESSION_ID" --pipeline-stage "lit-review" 2>/dev/null &
fi
# --- GENERATED EPILOGUE END ---
```

Replace `OUTCOME` with success/error/abort based on the workflow result.
