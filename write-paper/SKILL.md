---
name: write-paper
version: 0.1.0
description: |
  Generate venue-formatted LaTeX paper with real results and citations.
  Use when asked to "write the paper", "draft the paper", "format for arXiv",
  or "generate LaTeX".
  Proactively invoke when the user has experiment results and wants to
  write them up.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---

## Preamble (run first)

```bash
# --- GENERATED PREAMBLE START ---
# Resolve project root
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

# Update check
_UPD=$("$_RSTACK_DIR/bin/rstack-update-check" 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true

# Config values
_VENUE=$("$_RSTACK_CONFIG" get venue 2>/dev/null || echo "arxiv")
_COMPUTE=$("$_RSTACK_CONFIG" get compute_preferred 2>/dev/null || echo "modal")
_PROACTIVE=$("$_RSTACK_CONFIG" get proactive 2>/dev/null || echo "true")
_TEL=$("$_RSTACK_CONFIG" get telemetry 2>/dev/null || echo "off")
_TEL_PROMPTED=$([ -f ~/.rstack/.telemetry-prompted ] && echo "yes" || echo "no")

# Detect available state files (work products at root, plumbing in .rstack/)
_HAS_IDEA="no"
_HAS_REFINED="no"
_HAS_LIT_REVIEW="no"
_HAS_LIT_REVIEW_MD="no"
_HAS_NOVELTY="no"
_HAS_EXPERIMENTS="no"
_HAS_ANALYSIS="no"
_HAS_FIGURES="no"

# Work products at project root
[ -f "$_PROJECT_ROOT/idea.md" ] && _HAS_IDEA="yes"
[ -f "$_PROJECT_ROOT/refined-idea.md" ] && _HAS_REFINED="yes"
[ -f "$_PROJECT_ROOT/lit-review.md" ] && _HAS_LIT_REVIEW_MD="yes"
[ -f "$_PROJECT_ROOT/novelty-assessment.md" ] && _HAS_NOVELTY="yes"
[ -d "$_PROJECT_ROOT/analysis" ] && _HAS_ANALYSIS="yes"

# Plumbing in .rstack/
[ -f "$_PROJECT_ROOT/.rstack/lit-review.jsonl" ] && _HAS_LIT_REVIEW="yes"
[ -f "$_PROJECT_ROOT/.rstack/experiments.jsonl" ] && _HAS_EXPERIMENTS="yes"

_FIG_COUNT=0
if [ -d "$_PROJECT_ROOT/analysis/figures" ]; then
  _HAS_FIGURES="yes"
  _FIG_COUNT=$(find "$_PROJECT_ROOT/analysis/figures" -type f \( -name "*.png" -o -name "*.pdf" -o -name "*.svg" \) 2>/dev/null | wc -l | tr -d ' ')
fi

echo "PROJECT_ROOT: $_PROJECT_ROOT"
echo "STATE: idea=$_HAS_IDEA refined=$_HAS_REFINED lit-review=$_HAS_LIT_REVIEW lit-review-md=$_HAS_LIT_REVIEW_MD"
echo "STATE: novelty=$_HAS_NOVELTY experiments=$_HAS_EXPERIMENTS analysis=$_HAS_ANALYSIS"
echo "STATE: figures=$_HAS_FIGURES (count=$_FIG_COUNT)"
echo "VENUE: $_VENUE"
echo "COMPUTE: $_COMPUTE"
echo "PROACTIVE: $_PROACTIVE"

# Count experiment runs if available
if [ "$_HAS_EXPERIMENTS" = "yes" ]; then
  _EXP_COUNT=$(wc -l < "$_PROJECT_ROOT/.rstack/experiments.jsonl" 2>/dev/null | tr -d ' ')
  echo "EXPERIMENTS: $_EXP_COUNT runs logged"
fi

# Detect LaTeX compiler
_LATEX_COMPILER="none"
if command -v tectonic >/dev/null 2>&1; then
  _LATEX_COMPILER="tectonic"
elif command -v pdflatex >/dev/null 2>&1; then
  _LATEX_COMPILER="pdflatex"
fi
echo "LATEX_COMPILER: $_LATEX_COMPILER"

# Detect rstack skill root for templates
_SKILL_ROOT=""
if [ -d "$HOME/.claude/skills/rstack" ]; then
  _SKILL_ROOT="$HOME/.claude/skills/rstack"
elif [ -d ".claude/skills/rstack" ]; then
  _SKILL_ROOT="$(pwd)/.claude/skills/rstack"
fi
echo "SKILL_ROOT: ${_SKILL_ROOT:-NOT_FOUND}"

_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"
if [ ! -f ~/.rstack/.setup-complete ]; then
  echo "NEEDS_SETUP"
fi
_TEL_START=$(date +%s)
_SESSION_ID="$$-$(date +%s)"
echo "TELEMETRY: ${_TEL:-off}"
echo "TEL_PROMPTED: $_TEL_PROMPTED"
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"write-paper","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","repo":"'$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")'"}'  >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
fi
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"write-paper","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","session_id":"'"$_SESSION_ID"'","rstack_version":"'"$(cat "$_RSTACK_DIR/VERSION" 2>/dev/null | tr -d "[:space:]" || echo "unknown")"'"}'  > ~/.rstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
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

After the preamble runs, note the state and proceed.

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

**Important:** Note the `PROJECT_ROOT` value from the preamble output. All file paths below are relative to this project root directory. Work products (idea.md, paper.tex, analysis/) are at the project root. Plumbing (.rstack/lit-review.jsonl, .rstack/experiments.jsonl) is in the `.rstack/` subdirectory.

If `LATEX_COMPILER` is `none`: warn the user that no LaTeX compiler is installed.
Paper will be written but not compiled. Suggest: "Run /setup to install tectonic,
or install manually: `cargo install tectonic` / `brew install tectonic`."

## Voice

Direct, concrete, no filler. Sound like a research collaborator, not a writing
service. Name the file, the section, the citation. When something is missing, say
what's missing and what to do about it.

## Writing Style — Sound Human

The paper must read like a human researcher wrote it. AI-generated academic prose has
tells that reviewers notice. Follow these rules:

**Banned words** (never use these in the paper text):
delve, utilize, leverage, facilitate, comprehensive, multifaceted, moreover,
furthermore, additionally, notably, importantly, it is worth noting, pivotal,
paradigm, synergy, holistic, nuanced, in the realm of, shed light on, pave the way,
it is important to note, a myriad of, in conclusion it can be said

**Use instead:** simple, direct alternatives. "use" not "utilize". "show" not
"shed light on". "many" not "a myriad of". "helps" not "facilitates".

**No em dashes.** Use commas, periods, or parentheses instead of "—".

**Sentence variety:** Mix short sentences (5-8 words) with longer ones (15-25 words).
Don't start three sentences in a row with the same structure. Avoid the pattern
"While X, Y" or "Although X, Y" more than once per section.

**Hedging:** Real researchers hedge naturally. Use "suggests" not "proves". Use
"we observe" not "it is clearly evident". But don't over-hedge either... one hedge
per claim is enough.

**Active voice preferred.** "We trained the model" not "The model was trained".
"Our method achieves" not "It can be observed that the method achieves".

**No throat-clearing.** Don't start paragraphs with "In recent years" or "With the
advent of" or "It has been widely recognized that". Start with what matters.

**Keep it natural.** A good test: read each paragraph out loud. If it sounds like
something a person would say at a conference, it's fine. If it sounds like a
textbook written by committee, rewrite it.

## Rigor Rules

These are non-negotiable. Violating any of these is worse than not writing the paper.

1. **NEVER hallucinate results.** Every number in the paper must come from
   `.rstack/experiments.jsonl`. If a metric is not in the logs, do not write it.
2. **NEVER invent citations.** Every `\cite{key}` must reference a real entry in
   `paper.bib` generated from `.rstack/lit-review.jsonl`. No phantom references.
3. **NEVER fabricate figures.** Every `\includegraphics{path}` must point to a real
   file in `analysis/figures/`. If the file does not exist, skip it and
   write `% [Figure pending: description]` as a comment.
4. **Say what's real.** If results are negative or inconclusive, write them honestly.
   Reviewers catch fabricated positive results. Always.

---

## Step 0: Gather Context

Read all available state files. The preamble already detected what exists.
Read each available file in order:

1. `idea.md` -- the original research idea (project root)
2. `refined-idea.md` -- sharpened hypothesis (project root)
3. `.rstack/lit-review.jsonl` -- structured paper records (plumbing)
4. `lit-review.md` -- human-readable literature review (project root)
5. `novelty-assessment.md` -- novelty analysis (project root)
6. `.rstack/experiments.jsonl` -- experiment log with metrics (plumbing)
7. `analysis/` directory -- any analysis outputs, tables, summaries (project root)
8. `analysis/figures/` -- publication-ready figures (project root, list all files)

For each file that exists, read it. For each file that does not exist, note it and
move on. The paper will be written with whatever is available.

**Minimum requirements to proceed:**
- At least ONE of: idea.md, refined-idea.md (need to know what the paper is about)
- experiments.jsonl (need real results -- this is a research paper, not a proposal)

If experiments.jsonl is missing, use AskUserQuestion:

> No experiment results found in `.rstack/experiments.jsonl` (plumbing).
>
> Options:
> A) Provide results manually (paste metrics or point to a file)
> B) Run /experiment first to generate results
> C) Write a paper draft with placeholder results (will need filling in later)

If the user picks C, proceed but mark every results reference with
`% PLACEHOLDER: replace with real results` comments.

If BOTH idea files are missing, use AskUserQuestion:

> No research idea found. What is this paper about?

Take the user's response and use it as the idea context for the rest of the workflow.

---

## Step 1: Venue Selection

Check venue configuration. Use `rstack-config get venue` or default to `arxiv`.

```bash
_RSTACK_CONFIG="$HOME/.claude/skills/rstack/bin/rstack-config"
"$_RSTACK_CONFIG" get venue 2>/dev/null || echo "venue: arxiv"
```

Read the formatting rules from `_shared/venues.md` if the file exists in the skill
root. If `_shared/venues.md` does not exist, use built-in knowledge of arXiv formatting.

Use AskUserQuestion:

> Target venue: **{detected venue}**
>
> Options:
> A) Proceed with {detected venue}
> B) Change venue (specify)

**v1 limitation:** Only arXiv format is currently supported. If the user picks a
different venue (NeurIPS, ICML, ACL, etc.), tell them:

> arXiv is the only supported template in v0.1. NeurIPS/ICML templates are coming
> in v1.1. For now, writing in arXiv format -- you can reformat later with the
> venue-specific style files.

Always use the arXiv template regardless of selection in v0.1.

---

## Step 2: Generate BibTeX

If `.rstack/lit-review.jsonl` exists, read it and generate BibTeX entries.

For each paper record in the JSONL file, generate a BibTeX entry:
- Cite key format: `{firstauthorlastname}{year}` (lowercase, no spaces)
  - Example: author "Vaswani et al." year 2017 becomes `vaswani2017`
  - If duplicate keys, append a letter: `vaswani2017a`, `vaswani2017b`
- Entry type: `@article` for journal papers, `@inproceedings` for conferences,
  `@misc` for arXiv preprints
- Fields: author, title, year, journal/booktitle, url (if available)

Write the complete BibTeX file to `paper.bib` at the project root.

```bash
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
wc -l "$_PROJECT_ROOT/paper.bib" 2>/dev/null || echo "paper.bib not yet created"
```

If `.rstack/lit-review.jsonl` does not exist, use AskUserQuestion:

> No literature review found (`.rstack/lit-review.jsonl` missing).
>
> Options:
> A) Provide references manually (paste BibTeX or paper titles)
> B) Run /lit-review first to find relevant papers
> C) Proceed without citations (Related Work section will be thin)

If the user provides references manually, parse them and write `paper.bib` at the project root.
If they pick C, create an empty `paper.bib` and note that Related Work will
need references added later.

---

## Step 3: Paper Planning

Generate a paper plan inspired by the Ignis paper-planner-agent pattern. Based on
all the context gathered in Step 0, produce:

### 3a. Title Candidates

Generate exactly 3 title candidates:
1. A descriptive title (clear, specific, says what the paper does)
2. A punchy title (shorter, memorable, could be a good workshop title)
3. A question title (frames the contribution as answering a research question)

### 3b. Section Outline

Generate a bullet-point outline for each section:

- **Abstract** (3-4 bullet points: problem, method, results, conclusion)
- **Introduction** (motivation, gap, contribution, outline of paper)
- **Related Work** (group by theme from lit-review.md, note how this work differs)
- **Method** (approach, architecture/algorithm, key design decisions)
- **Experiments** (setup, baselines, datasets, metrics, results summary)
- **Results and Discussion** (main findings, ablations, analysis, limitations)
- **Conclusion** (summary, implications, future work)

### 3c. Figure Plan

List which figures go in which section, with descriptions:
- Match against actual files in `analysis/figures/`
- If figures exist: map each to its appropriate section
- If no figures: note which figures SHOULD exist and where they would go

### 3d. Human Review

Present the plan to the user via AskUserQuestion:

> **Paper Plan**
>
> **Title candidates:**
> 1. {descriptive title}
> 2. {punchy title}
> 3. {question title}
>
> **Outline:** {summary of sections and key points}
>
> **Figures:** {N} figures mapped to sections
>
> Options:
> A) Use title 1
> B) Use title 2
> C) Use title 3
> D) Suggest a different title
> E) Modify the outline (describe changes)

Apply the user's feedback before proceeding to Step 4.

---

## Step 4: Write LaTeX

This is the main writing step. Load the arXiv template and write the full paper.

### 4a. Load Template

Read the template from the skill root:

```bash
TEMPLATE_PATH=""
if [ -n "$_SKILL_ROOT" ] && [ -f "$_SKILL_ROOT/templates/arxiv/template.tex" ]; then
  TEMPLATE_PATH="$_SKILL_ROOT/templates/arxiv/template.tex"
elif [ -f "templates/arxiv/template.tex" ]; then
  TEMPLATE_PATH="templates/arxiv/template.tex"
fi
echo "TEMPLATE: ${TEMPLATE_PATH:-NOT_FOUND}"
```

If the template is found, read it and use it as the structural skeleton.
If not found, use the standard arXiv article format from built-in knowledge:
`\documentclass[11pt]{article}` with standard packages.

### 4b. Write Document

Write the complete LaTeX document from `\documentclass` through `\end{document}`.

**Mandatory rules during writing:**

- Use REAL citation keys from `paper.bib` with `\cite{key}`. Cross-check every
  `\cite{}` against the bib file. If a key does not exist in paper.bib, do not
  use it.
- Use REAL figure paths from `analysis/figures/`. Use
  `\includegraphics{analysis/figures/filename}` with actual filenames.
  If a figure file does not exist, write a comment instead:
  `% [Figure pending: {description of what should go here}]`
- Use REAL metrics from `.rstack/experiments.jsonl`. Extract actual numbers
  (accuracy, loss, F1, BLEU, etc.) and put them in the text and tables. Never
  round aggressively -- use the precision from the logs.
- Mark any uncertain or placeholder content with `% TODO:` comments.

### 4c. Section-by-Section with Checkpoints

Write each section and checkpoint with the user. This is the human-in-the-loop
principle from ETHOS.md -- the researcher reviews each section before the next.

**Section 1: Abstract**

Write the abstract (150-250 words). Include: problem statement, method summary,
key quantitative results, conclusion.

Use AskUserQuestion:

> **Abstract written.** ({word_count} words)
>
> {show the abstract text}
>
> Options:
> A) Looks good, continue
> B) Revise (describe changes)

**Section 2: Introduction**

Write the introduction (1-2 pages). Structure:
- Opening: motivate the problem (why does this matter?)
- Gap: what's missing in current approaches (from lit-review)
- Contribution: what this paper does (from refined-idea)
- Outline: "The rest of this paper is organized as follows..."

Use AskUserQuestion: "Review introduction? A) Continue B) Revise"

**Section 3: Related Work**

Write Related Work from `lit-review.md` (at the project root). Group papers by theme, not chronologically.
For each group: summarize the approach, note limitations, explain how this work
differs or builds upon it. Cite papers using keys from `paper.bib`.

Use AskUserQuestion: "Review related work? A) Continue B) Revise"

**Section 4: Method**

Write the Method section from the idea/refined-idea and experiment code context.
Describe the approach clearly enough for reproduction. Include:
- Problem formulation (math if appropriate)
- Approach overview
- Key design decisions and why
- Algorithm or architecture details

Use AskUserQuestion: "Review method section? A) Continue B) Revise"

**Section 5: Experiments and Results**

Write Experiments + Results from `experiments.jsonl` and `analysis/` outputs.
Include:
- Experimental setup (datasets, baselines, hyperparameters, compute)
- Results tables with real numbers from experiment logs
- Figures with `\includegraphics` pointing to real figure files
- Analysis: what the results show, ablation studies, error analysis

Format results in `booktabs`-style tables:
```latex
\begin{table}[t]
\centering
\caption{Main results on {dataset}.}
\label{tab:main-results}
\begin{tabular}{lcc}
\toprule
Method & Metric 1 & Metric 2 \\
\midrule
Baseline & X.XX & Y.YY \\
Ours & X.XX & Y.YY \\
\bottomrule
\end{tabular}
\end{table}
```

Use AskUserQuestion: "Review experiments and results? A) Continue B) Revise"

**Section 6: Conclusion**

Write the conclusion. Summarize contributions, state limitations honestly,
suggest future work directions.

Use AskUserQuestion: "Review conclusion? A) Continue B) Revise"

### 4d. Save

Write the complete LaTeX document to `paper.tex` at the project root.

```bash
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
wc -l "$_PROJECT_ROOT/paper.tex" 2>/dev/null && echo "paper.tex saved"
```

---

## Step 5: Compile

Compile the LaTeX document to PDF.

### 5a. Try Compilation

Based on the detected compiler from the preamble:

If `tectonic` is available:
```bash
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$_PROJECT_ROOT" && tectonic paper.tex 2>&1
```

If `pdflatex` is available (fallback):
```bash
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$_PROJECT_ROOT" && pdflatex -interaction=nonstopmode paper.tex 2>&1 && bibtex paper 2>&1 && pdflatex -interaction=nonstopmode paper.tex 2>&1 && pdflatex -interaction=nonstopmode paper.tex 2>&1
```

If neither is available:
Tell the user: "No LaTeX compiler found. Install tectonic (`cargo install tectonic`
or `brew install tectonic`) or run /setup. The .tex and .bib files are ready for
manual compilation."

### 5b. Handle Compilation Errors

If compilation fails, read the error output and attempt auto-fixes:

1. **Missing packages:** Add `\usepackage{package}` to the preamble and retry.
2. **Undefined references:** Run compilation again (references need two passes).
3. **Missing figures:** Comment out the `\includegraphics` line and add a
   `% [Figure missing: path]` comment. Figures should be at `analysis/figures/`.
4. **BibTeX errors:** Check for malformed entries in `paper.bib`, fix and retry.
5. **Encoding issues:** Ensure UTF-8, escape special LaTeX characters.

Retry up to 3 times. After each retry, show what was fixed.

If still failing after 3 attempts, show the error and use AskUserQuestion:

> Compilation failed after 3 attempts. Last error:
> {error message}
>
> Options:
> A) Show full error log
> B) Skip compilation (paper.tex is ready for manual compile)
> C) Try to fix (describe the issue)

### 5c. Output

If compilation succeeds, the output is `paper.pdf` at the project root.

```bash
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
ls -la "$_PROJECT_ROOT/paper.pdf" 2>/dev/null && echo "PDF generated successfully"
```

---

## Step 6: Final Review

Show paper statistics:

```bash
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
if [ -f "$_PROJECT_ROOT/paper.tex" ]; then
  echo "=== Paper Statistics ==="
  echo "Lines: $(wc -l < "$_PROJECT_ROOT/paper.tex")"
  echo "Citations: $(grep -o '\\\\cite{[^}]*}' "$_PROJECT_ROOT/paper.tex" 2>/dev/null | wc -l | tr -d ' ')"
  echo "Figures: $(grep -o '\\\\includegraphics' "$_PROJECT_ROOT/paper.tex" 2>/dev/null | wc -l | tr -d ' ')"
  echo "Tables: $(grep -o '\\\\begin{table' "$_PROJECT_ROOT/paper.tex" 2>/dev/null | wc -l | tr -d ' ')"
  echo "Sections: $(grep -o '\\\\section{' "$_PROJECT_ROOT/paper.tex" 2>/dev/null | wc -l | tr -d ' ')"
  echo "Word count (approx): $(sed 's/\\\\[a-zA-Z]*{[^}]*}//g; s/\\\\[a-zA-Z]*//g; s/[{}]//g' "$_PROJECT_ROOT/paper.tex" 2>/dev/null | wc -w | tr -d ' ')"
fi
if [ -f "$_PROJECT_ROOT/paper.pdf" ]; then
  echo "PDF: paper.pdf ($(du -h "$_PROJECT_ROOT/paper.pdf" | cut -f1))"
else
  echo "PDF: not compiled"
fi
```

Present the summary to the user via AskUserQuestion:

> **Paper complete.**
>
> {statistics from above}
>
> Files written:
> - `paper.tex` -- LaTeX source
> - `paper.bib` -- BibTeX references
> - `paper.pdf` -- compiled PDF (if compiled)
>
> Options:
> A) Done -- looks good
> B) Revise a section (specify which)
> C) Recompile (after manual edits)
> D) Open PDF

If the user picks B, go back to the relevant section in Step 4c and revise.
If they pick C, re-run Step 5.
If they pick D:

```bash
_PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$_PROJECT_ROOT/paper.pdf"
elif command -v open >/dev/null 2>&1; then
  open "$_PROJECT_ROOT/paper.pdf"
elif command -v start >/dev/null 2>&1; then
  start "$_PROJECT_ROOT/paper.pdf"
else
  echo "Cannot auto-open. PDF is at: paper.pdf"
fi
```

---

## Standalone Mode

If invoked outside of the full rstack pipeline (no prior skill outputs), the skill
still works:

1. Ask the user what the paper is about (replaces idea.md)
2. Ask for references (replaces lit-review)
3. Ask for results (replaces experiments.jsonl)
4. Create `.rstack/` directory for plumbing and write work products to the project root
5. Proceed through Steps 1-6 normally

This allows `/write-paper` to be useful even without running `/lit-review` or
`/experiment` first.

---

## Error Handling

- If any Read fails on a state file, skip it and note what's missing.
- If AskUserQuestion is not available, proceed with defaults and note decisions.
- If compilation fails and cannot be fixed, the .tex file is still the deliverable.
- If the user aborts mid-workflow, whatever has been written to the project directory persists
  for the next run.

## Completion Status

When the workflow finishes, report status:
- **DONE** -- Paper compiled, PDF generated, all sections reviewed.
- **DONE_WITH_CONCERNS** -- Paper written but: compilation failed / missing figures /
  placeholder results / thin Related Work. List each concern.
- **BLOCKED** -- Cannot proceed. Missing experiment results and user chose not to
  provide them.
- **NEEDS_CONTEXT** -- Waiting for user input (which title, section revisions, etc.)

---

## Telemetry (run last)

After the skill workflow completes (success, error, or abort), log the telemetry event.

```bash
# --- GENERATED EPILOGUE START ---
_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
rm -f ~/.rstack/analytics/.pending-"$_SESSION_ID" 2>/dev/null || true
if [ "$_TEL" != "off" ]; then
  echo '{"skill":"write-paper","duration_s":"'"$_TEL_DUR"'","outcome":"OUTCOME","session":"'"$_SESSION_ID"'","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' >> ~/.rstack/analytics/skill-usage.jsonl 2>/dev/null || true
fi
if [ "$_TEL" != "off" ] && [ -x "$_RSTACK_DIR/bin/rstack-telemetry-log" ]; then
  "$_RSTACK_DIR/bin/rstack-telemetry-log" \
    --skill "write-paper" --duration "$_TEL_DUR" --outcome "OUTCOME" \
    --session-id "$_SESSION_ID" --pipeline-stage "write-paper" --venue "$_VENUE" 2>/dev/null &
fi
# --- GENERATED EPILOGUE END ---
```

Replace `OUTCOME` with success/error/abort based on the workflow result.
