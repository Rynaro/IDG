# Scribe — Documentation Synthesis Agent

A standalone specialist agent that transforms context into structured, grounded, actionable documents.

Give it session logs, code diffs, decision notes, or any raw material — it produces documentation you'd actually want to read.

## Architecture

```
scribe/
├── SCRIBE.md                   # Agent entry point (always loaded)
├── DESIGN-RATIONALE.md         # Research → design decision mapping
├── skills/                     # Loaded on-demand per phase
│   ├── composition.md          # Writing methodology + style standards
│   └── verification.md         # CHT verification gates + provenance
└── templates/                  # Document skeletons per type
    ├── session-chronicle.md    # Long coding session documentation
    ├── adr.md                  # Architecture Decision Record
    ├── runbook.md              # Operational procedure
    └── change-narrative.md     # Release notes / changelog
```

## Quick Start

### Embedding in a project

Copy or submodule this repository into your project:

```bash
# Git submodule
git submodule add https://github.com/Rynaro/scribe agents/scribe

# Or direct copy
cp -r scribe/ your-project/agents/scribe/
```

All internal references use relative paths. Works from any location.

### Using the Scribe

Point your AI tool at `SCRIBE.md` as the system prompt or agent instructions. Skills and templates load on-demand — do not load everything upfront.

The Scribe produces four document types out of the box:

| Type | Use When |
|------|----------|
| **session-chronicle** | Documenting what happened during a coding session |
| **adr** | Recording an architecture or design decision |
| **runbook** | Capturing an operational procedure |
| **change-narrative** | Writing release notes or changelogs |

Custom document types are supported — the Scribe builds a skeleton from context when no template matches.

## Design Principles

**Minimal entry point**: `SCRIBE.md` is the only file loaded at start. Skills and templates load on-demand per phase.

**Token-efficient**: Typical working set is ~2,200 tokens (entry point + one skill + one template). Leaves maximum context budget for source material.

**Synthesis, not research**: The Scribe writes from provided context. It does not retrieve, analyze code, or gather information. If it needs something, it asks.

**Bounded verification**: One CHT gate + one revision max. No unbounded reflection loops. Research shows these degrade prose quality.

**Structural markers**: Four markers (`[DECISION]`, `[ACTION]`, `[DISPUTED]`, `[GAP]`) transform passive documentation into actionable intelligence.

## IDG Cycle

```
I ──▶ D ──▶ G ──┬──▶ DELIVER
                └──▶ REVISE (one pass) ──▶ DELIVER
```

- **Intake**: Classify document type, validate context, build skeleton from template
- **Draft**: Compose section by section with grounding and structural markers
- **Gate**: CHT verification (Completeness, Helpfulness, Truthfulness)

## Research Foundation

See [DESIGN-RATIONALE.md](DESIGN-RATIONALE.md) for the full mapping of research findings to design decisions. Key influences:

- **DocAgent** (Meta/FAIR, arXiv 2504.08725): CHT verification framework, topological ordering evidence
- **CorrectBench** (2025): Evidence for bounding self-correction in open-ended tasks
- **Anthropic Context Engineering** (Sept 2025): Context budget discipline
- **APIVR-Δ v3.0**: Layered loading architecture, on-demand skills, token budget methodology
- **CrewAI/Azure patterns**: Invocation architecture

---

*Scribe v1.0.0*
