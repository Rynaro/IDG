# Scribe Agent — Design Rationale

How research findings and architectural patterns map to the Scribe's design decisions.

---

## Core Design Thesis

> **The Scribe is a synthesis agent, not a research agent. Its value is in transforming provided context into structured, grounded, actionable documents — not in gathering that context.**

This thesis determines every design boundary. The research literature (DocAgent, Chain-of-Agents, the full Scriber blueprint from the research phase) consistently conflates retrieval, analysis, and synthesis into a single agent. The Scribe deliberately separates these concerns — retrieval and analysis belong to other tools or agents in the workflow. The Scribe receives their output and transforms it.

---

## Decision Map

### 1. Single Agent with Skills, Not Internal Multi-Agent Pipeline

**Research input**: DocAgent (arXiv 2504.08725) uses 5 specialized roles (Reader, Searcher, Writer, Verifier, Orchestrator). The research blueprint proposed 7 internal sub-agents.

**Decision**: Single agent with on-demand skills. No internal sub-agents.

**Rationale**: DocAgent's topology solves a different problem — documenting an entire codebase where retrieval and dependency ordering are the bottleneck. The Scribe receives pre-gathered context. Adding internal retrieval roles would duplicate capabilities that belong elsewhere in the workflow.

**Precedent**: APIVR-Δ proves that a single agent with on-demand skill loading achieves high performance while keeping the working set under 4,350 tokens. The Scribe mirrors this architecture.

### 2. IDG Cycle (Intake → Draft → Gate), Not Full APIVR-Δ

**Research input**: APIVR-Δ uses a 5-phase cycle. Other frameworks use 7-phase cycles. The research blueprint proposed a 7-stage internal pipeline.

**Decision**: 3-phase cycle — IDG. Intentionally minimal.

**Rationale**: The Scribe doesn't implement code, doesn't need test anchors, doesn't need failure recovery taxonomies, and doesn't need a Delta phase. It receives context, composes a document, and verifies it. Three phases cover the full workflow without ceremony.

**Evidence**: Context engineering research (Anthropic, Sept 2025) emphasizes that phase-irrelevant instructions degrade performance. Loading a 7-phase pipeline when only 3 phases apply wastes tokens and introduces noise.

### 3. Structural Markers as Primary Value-Add

**Research input**: Harness AI incident scribe conventions. DocAgent's CHT verification. Community-observed producer-reviewer patterns.

**Decision**: Four structural markers (`[DECISION]`, `[ACTION]`, `[DISPUTED]`, `[GAP]`) are mandatory outputs.

**Rationale**: The difference between a transcription and actionable intelligence is structured annotation. A chronicle that just describes what happened is marginally useful. A chronicle that flags decisions made, actions needed, conflicts found, and gaps identified transforms documentation from passive record into active project management artifact.

**Production observation**: The strongest documentation agents in practice (Claude Code's session logs, Harness AI incident scribes) share this pattern — they don't just describe, they annotate with structural metadata.

### 4. Bounded Reflection: One Gate, One Revision Max

**Research input**: Reflexion (Shinn et al., NeurIPS 2023) achieves 91% Pass@1 with verbal self-reflection. CorrectBench (2025) shows diminishing returns and stylistic degradation in open-ended text. Practitioner critique (vadim.blog) documents that reflection often produces "bland, corporate-speak."

**Decision**: Single CHT gate after drafting. If it fails, one targeted revision pass. Then deliver with flags.

**Rationale**: The research is clear — unbounded reflection loops degrade prose quality while increasing cost. For documentation (an inherently open-ended task), the risk of over-correction is higher than for code. One pass catches structural deficiencies (missing sections, unsourced claims). Beyond that, the requester should provide additional context rather than the Scribe hallucinating its way to a passing score.

**Precedent**: APIVR-Δ caps retries at 3 for the same reason — diminishing returns after attempt 2. The Scribe is even more conservative because prose degradation is harder to detect than code failures.

### 5. Single Invocation Mode with Shared Methodology

**Research input**: CrewAI Crews vs Flows. Claude Code sub-agents vs standalone Skills. Azure Architecture Center orchestration patterns (Feb 2026).

**Decision**: The Scribe follows the same IDG cycle regardless of how it is invoked — whether by a user directly, by another agent, or by an orchestration framework. The methodology is the same.

**Rationale**: The methodology must be identical regardless of invocation path. If different callers get different quality standards, documents produced by the same agent would be inconsistent. The only thing that changes is how context arrives — interactively from a user, or pre-packaged from an upstream process.

### 6. Topological Section Ordering

**Research input**: DocAgent ablation study (arXiv 2504.08725) confirms topological processing order is "load-bearing" — removing it significantly degrades output quality.

**Decision**: Write sections in dependency order (context before decisions, decisions before consequences).

**Rationale**: Sections that establish context produce better downstream sections because the model has its own output as additional context. This is a lightweight application of DocAgent's core insight — you don't need a full dependency graph, just awareness that section ordering matters for quality.

### 7. Context Budget Discipline

**Research input**: AI Agent Engineering Handbook (r/LocalLLaMA, March 2026) reports context quality degrades at ~25% window utilization. Anthropic (Sept 2025) describes context engineering as infrastructure-grade design. JetBrains finding that context quality outweighs quantity.

**Decision**: Section-level context injection with a ~2,000 token cap per section. Reserve working space for composition, don't fill the window with raw material.

**Rationale**: The Scribe's input can be large (full session logs, multiple outputs, code diffs). Dumping all of it into context and asking for a document produces worse output than selecting relevant context per section. This mirrors APIVR-Δ's progressive disclosure — inject what's needed, when it's needed.

### 8. Provenance as Hard Requirement

**Research input**: Delegation research emphasizes structural transparency and proofs of work. DocAgent's CHT framework includes explicit source grounding.

**Decision**: Every delivered document includes a provenance block with CHT scores, source artifact list, coverage assessment, and unresolved flags.

**Rationale**: Knowing which sources produced which content is essential for debugging quality issues. If a document contains an incorrect claim, the provenance block lets readers trace it back to the source artifact and determine whether the Scribe misinterpreted the source or the source itself was wrong.

---

## What Was Explicitly Excluded (and Why)

| Excluded | Reason |
|----------|--------|
| Code retrieval / AST analysis | Not synthesis. Retrieval belongs to dedicated retrieval tools or agents. |
| Intent absorption from sparse input | Over-scoped. The caller provides intent — the Scribe doesn't guess it. |
| Self-evolving prompt optimization (OPRO/MemAPO) | Experimental. No production validation for document agents. |
| Style embedding store | Over-engineered. Style rules fit in a skill file. |
| Chain-of-Symbol structural planning | Good for planning from scratch. The Scribe works from templates. |
| Internal sub-agent orchestration | Violates single-responsibility. Adds latency and token overhead. |
| Unbounded Reflexion loops | Proven to degrade prose quality (CorrectBench, vadim.blog). |

---

## Token Budget Analysis

| Component | Estimated Tokens | When Loaded |
|-----------|-----------------|-------------|
| SCRIBE.md (entry point) | ~900 | Always when Scribe active |
| composition.md | ~913 | Draft phase |
| verification.md | ~834 | Gate phase |
| Template (largest: runbook) | ~499 | Per document type |

**Typical working set**: SCRIBE.md + one skill + one template ≈ **2,200 tokens**

This is well under the ~4,350 token working set of comparable agents and significantly under the 5,000–15,000 token range of commercial monolithic system prompts. The remaining context budget is available for the actual source material the Scribe needs to synthesize.

---

## Research Sources

| Source | Contribution to Scribe Design |
|--------|-------------------------------|
| DocAgent (arXiv 2504.08725, Apr 2025) | CHT framework, topological ordering, ablation evidence |
| ReflAct (EMNLP 2025) | State-grounding loop concept (simplified to single gate pass) |
| CorrectBench (arXiv 2510.16062, 2025) | Evidence for bounding self-correction loops |
| Anthropic Context Engineering (Sept 2025) | Context budget discipline, progressive disclosure |
| AI Agent Engineering Handbook (Mar 2026) | 25% context quality threshold, skills-as-markdown |
| CrewAI Crews vs Flows | Invocation pattern |
| Azure Architecture Center (Feb 2026) | Orchestration pattern taxonomy |
| APIVR-Δ v3.0 | Layered loading architecture, on-demand skills, token budget methodology |
| Practitioner critique of reflection (vadim.blog) | Evidence against unbounded self-correction for open-ended text |
| Harness AI conventions | Structural marker pattern for incident/session documentation |

---

*Scribe v1.0.0 — Design Rationale*
