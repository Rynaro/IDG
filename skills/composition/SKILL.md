# Composition Methodology

Loaded during the Draft phase. Governs how the Scribe transforms context into structured prose.

---

## Section-Level Composition

Write one section at a time, in topological order. For each section:

1. **Scope the section** — what question does this section answer for the reader?
2. **Select context** — pull only the source material relevant to this section. Discard the rest for now.
3. **Draft** — write the section. Ground every claim.
4. **Cite** — tag each factual statement with its source artifact (inline or footnote, per template convention).
5. **Mark** — apply structural markers where appropriate.
6. **Transition** — write the bridge to the next section if the document type requires narrative flow.

### Context Budget Rule

When composing a section, keep injected context to the minimum necessary. If the full source material for a section exceeds ~2,000 tokens, summarize the supporting evidence and keep the original references as citations. This preserves working space for the model to reason about composition rather than drowning in raw material.

### Topological Section Order

Write sections that establish context before sections that depend on it:

- Background/Context → Decisions → Consequences
- Problem Statement → Steps Taken → Outcomes → Lessons
- Summary → Details → Follow-ups

If sections have no dependency relationship, write them in the template's default order.

---

## Structural Markers Reference

Markers are the Scribe's primary value-add. They transform passive documentation into actionable intelligence.

### `[DECISION]`
A choice was made. Always include:
- **What** was decided
- **Why** (rationale, even if brief)
- **Alternatives rejected** (if available in source material; `[GAP]` if not)

```markdown
[DECISION] Adopted Redis for session caching over Memcached.
Rationale: Redis supports data structures needed for rate-limiting (sorted sets).
Rejected: Memcached (no sorted sets), DynamoDB (latency budget exceeded).
```

### `[ACTION]`
Something needs to happen. Include:
- **What** needs doing
- **Owner** (if known; `TBD` if not)
- **Deadline or trigger** (if known)

```markdown
[ACTION] Update Terraform modules to provision Redis cluster. Owner: Platform team. Trigger: Before Sprint 14 deployment.
```

### `[DISPUTED]`
Source material conflicts. Present both sides neutrally:

```markdown
[DISPUTED] Load test results disagree on p99 latency.
- Agent A's benchmark: 12ms p99 under 10k RPS
- Manual test by engineer: 45ms p99 under 8k RPS
Resolution: Not yet determined. Recommend re-running with standardized methodology.
```

### `[GAP]`
Expected information is missing from provided context:

```markdown
[GAP] Rollback procedure not documented in session artifacts. Requested from Ops team.
```

---

## Writing Standards

### Grounding Rules

| Rule | Detail |
|------|--------|
| **No unsourced claims** | Every factual assertion must trace to a specific source artifact |
| **Distinguish inference from fact** | If the Scribe infers something (e.g., likely rationale for a decision), prefix with "Likely:" or "Inferred:" |
| **Preserve source fidelity** | Do not editorialize or interpret beyond what sources support |
| **Quote sparingly** | Paraphrase unless exact wording is load-bearing (error messages, commit messages, CLI output) |

### Audience Adaptation

| Audience | Depth | Jargon | Examples |
|----------|-------|--------|----------|
| Engineers on the team | Full technical depth | Domain terms OK without definition | Code snippets, file paths, CLI commands |
| Engineering leadership | Architectural level | Define non-obvious acronyms | Diagrams, trade-off summaries, impact statements |
| Cross-functional | Business outcomes | Minimal jargon, explain technical terms | User-facing impact, timelines, risk levels |

Determine audience from the document type default or explicit instruction. When uncertain, default to "Engineers on the team."

### Tone

- **Active voice** preferred ("The team decided..." not "It was decided...")
- **Concrete over abstract** ("Added 3 retry attempts with exponential backoff" not "Improved error handling")
- **Terse over verbose** — every sentence should earn its place
- **No hedging without cause** — "The migration completed successfully" not "The migration appears to have completed successfully" (unless completion is genuinely uncertain)

---

## Section Composition Checklist

Before moving to the next section, verify:

- [ ] Section answers the question it was scoped to answer
- [ ] Every factual claim has a source citation
- [ ] Structural markers applied where appropriate
- [ ] Tone matches audience level
- [ ] No information fabricated or assumed without marking
- [ ] Transition to next section is clear (if applicable)

---

*Scribe v1.1.0 — Composition Skill*
