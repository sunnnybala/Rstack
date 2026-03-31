# Product Insights - RStack

Living document. Updated after every office hours session, user conversation, or research pass.

---

## 2026-03-31 (office hours design session)

### Target User Insights

**Insight 1: The target user is a PhD student with a publication deadline, not a researcher who "wants to go faster."**
Direct quote: "The core user base are students who want to publish as fast as possible because they have a deadline. They have to get their paper published before the graduation date." The deadline creates existential urgency. This is not a nice-to-have productivity tool. It's the difference between graduating and not graduating.

**Why this matters:** Deadline pressure changes everything about product design. The user will tolerate imperfect output if it's fast. They will pay for time compression. They won't wait for a feature roadmap. The product that ships today with 70% quality beats the product that ships in 3 months with 95% quality.

**Insight 2: The infrastructure bottleneck is the real pain, not the thinking.**
"70% of research time is grunt work: finding papers, provisioning GPUs, debugging cloud environments, formatting LaTeX. The actual research takes 30%." The researcher's intellectual contribution is the 30%. RStack compresses the 70%.

**Why this matters:** This frames the product correctly. It's not "AI does your research" (which reviewers would reject). It's "AI handles the boring parts so you can focus on the thinking." The positioning is always "compress the grunt work, preserve the human judgment."

**Insight 3: Cloud compute abstraction is the unsolved hard problem nobody else has cracked.**
"Running the training job, accessing hardware, etc., is only very tedious if you don't know how." PhD students lose weeks figuring out how to provision a GPU on Modal, GCP, or RunPod. Existing tools (AutoResearch) assume a local GPU. Sakana AI Scientist has custom infra. Nobody has made cloud GPU provisioning as simple as "the AI just does it."

**Why this matters:** This is the wedge. If RStack can make `modal run train.py` as invisible to the researcher as `git push` is to an engineer using GStack, that alone is worth the install.

### Market/Landscape Insights

**Insight 4: The automated research market is bifurcated into "full autopilot" (broken) and "narrow optimization" (limited), with nothing in between.**
- Sakana AI Scientist: full pipeline but 42% experiment failure rate, hallucinated results, published in Nature but not practically usable.
- Karpathy AutoResearch: brilliant for one thing (edit code, train 5 min, measure, repeat) but can't do lit review, cloud compute, or paper writing. 62k GitHub stars.
- Ignis (our own prior): 13-agent Mastra pipeline, full stack (Express+React+Postgres+Modal). Worked but too heavy to iterate.

**Why this matters:** The gap is "composable, human-in-the-loop skills on top of an existing AI coding agent." Nobody has built this. The conventional approach (full autopilot) fails because reviewers catch hallucinated papers. The narrow approach (AutoResearch) works but is limited. The GStack pattern (composable skills, human checkpoints, no infrastructure) is the third way that nobody has tried for research.

**Insight 5: "Composable human-in-the-loop research skills beat both full autopilot and narrow optimization loops." (EUREKA)**
Flagged as an EUREKA moment during the session. The GStack pattern for research is unoccupied territory. Every checkpoint where the researcher approves or redirects prevents the 42% failure rate of full autopilot, while the skill chaining provides the breadth that AutoResearch lacks.

**Why this matters:** This is a genuine architectural insight, not a marketing claim. If the researcher approves the lit review before novelty assessment, and approves the experiment plan before cloud submission, the failure modes that plague Sakana (hallucinated experiments, fabricated results) are structurally impossible. The human IS the quality gate.

**Insight 6: Google DeepMind says we're "5-10 years from true innovation and creativity" in AI research.**
The biggest failure mode in automated research tools is implementation capability: "inadequate multi-agent collaboration" and "insufficient coordination with external tools." (Source: arxiv.org/html/2506.01372v1)

**Why this matters:** RStack doesn't try to be creative. It tries to be fast at the boring parts. The creative thinking stays with the researcher. This is the right bet for the next 5-10 years while AI creativity is immature.

### Distribution/Positioning Insights

**Insight 7: The demo IS the product for the first 1,000 users.**
Direct quote: "It needs to be very novel so that I can brag about it on Twitter." The target demo is: type `/research "my idea"` and get a submittable paper. If that 2-minute video works, ML Twitter distributes it for free.

**Why this matters:** For dev tools, the demo video is the growth engine. AutoResearch got 62k stars from Karpathy posting a demo. GStack grew through Garry Tan's visibility. RStack needs one video showing idea-to-paper. The product and the distribution are the same thing.

**Insight 8: An independent Claude subagent identified the real product as "time compression under existential pressure."**
Quote from the cold read: "This is not about the technology. This is about the gap between 'I have an idea' and 'I have a submission-ready PDF' being measured in hours, not months. The deadline is the product."

**Why this matters:** This reframes RStack from "research automation tool" to "deadline compression engine." When the user has a deadline, the product that compresses time wins over the product that's more feature-complete but slower.

### Architecture Insights (from design reviews)

**Insight 9: Claude Code in 2026 is strong enough to replace 13 specialized Mastra agents.**
Ignis needed a custom Express backend with 13 agents orchestrated by Mastra because models in early 2025 weren't strong enough to handle the full pipeline in one context. Claude Opus 4.6 can read a SKILL.md and follow a multi-step research workflow (search APIs, generate code, run cloud commands, write LaTeX) without custom agent infrastructure.

**Why this matters:** The "no backend" architecture is not a compromise. It's a bet that models will keep getting stronger. Every month that passes makes the SKILL.md approach more capable without any code changes. The infrastructure-heavy approach (Ignis) gets harder to maintain over time. The lightweight approach (RStack) gets better for free.

**Insight 10: Credentials should stay in native CLI auth stores, not in your config.**
Codex review caught that duplicating API keys into JSON files is both a security risk and unnecessary. Cloud provider CLIs (Modal, gcloud) already manage their own auth. RStack stores only auth STATUS (is the provider configured?), not secrets.

**Why this matters:** Follow existing patterns. Don't reinvent credential management. The same principle applies to any dev tool: lean on what the user's machine already knows.

### Comparable Products (from web search, March 2026)

| Tool | GitHub Stars | Scope | Key Limitation |
|------|-------------|-------|----------------|
| AutoResearch (Karpathy) | 62.2k | Experiment loop only | No lit review, no cloud, no paper |
| Sakana AI Scientist | — | Full pipeline | 42% experiment failure rate |
| claude-scientific-skills | — | Generic research skills | No cloud compute, no journal-aware papers |
| MLAgentBench | — | Benchmark framework | Not a production tool |

None of these are composable Claude Code skills with cloud compute abstraction and venue-aware paper writing. RStack occupies an empty niche.
