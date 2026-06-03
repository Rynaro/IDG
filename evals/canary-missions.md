# Canary Missions — IDG (Scribe)

> v1.13.0 DSL-format missions for `eidolons canary idg`. Legacy free-form
> missions preserved under "Legacy mission catalog (pre-DSL)" below.

---

## Mission: smoke-default

### Prompt

Using the IDG (Scribe) methodology, synthesize an Architecture Decision Record from the following context:

> **Decision:** The team chose PostgreSQL over MySQL.
> **Reason:** PostgreSQL's JSONB type was required for flexible schema storage without a separate document store.
> **Rejected alternative:** MySQL — no native JSONB; the JSON column type stores plain text only.
> **Audience:** Backend engineers on the team.

Walk the I → D → G cycle: Intake (classify type, validate context, load template), Draft (produce the ADR with structural markers), Gate (CHT scoring + revision pass if any dimension scores below 4). Emit the final ADR with a provenance block listing the document type, source artefacts, CHT scores per dimension, and an explicit gap assessment.

### Expected output shape

A response that walks the three phases as headings, then delivers the ADR. The ADR contains a `[DECISION]` marker recording what / why / rejected alternative. The Gate section scores Completeness, Helpfulness, and Truthfulness on a 1-5 scale. The provenance block at the end of the document records the document type (`adr`), source artefacts, CHT scores per dimension, and whether a revision pass was needed. No facts are invented (no team names, no dates, no rationale not present in the prompt).

### Validation criteria

- MUST contain heading: `## Intake`
- MUST contain heading: `## Draft`
- MUST contain heading: `## Gate`
- MUST contain phrase: `\[DECISION\]`
- MUST contain phrase: `provenance`
- MUST contain phrase: `Completeness`
- MUST contain phrase: `Helpfulness`
- MUST contain phrase: `Truthfulness`
- SHOULD contain phrase: `PostgreSQL`
- SHOULD contain phrase: `JSONB`
- SHOULD have token count between 700 and 2500

---

## Mission: memory-round-trip

### Prompt

Using the IDG (Scribe) methodology with CRYSTALIUM memory tools available, synthesize
a session chronicle from the following context:

> **Session summary:** APIVR-Δ implemented a Redis-backed session cache to replace
> the in-memory store. Key decisions: Redis chosen for its sorted-set support;
> Memcached rejected (no sorted sets); TTL set to 3600s. One `[ACTION]` remains:
> update Terraform modules to provision the Redis cluster.
> **Source artefacts:** `apivr-completion-report.md` (no envelope present).
> **Audience:** Backend engineers on the team.

Walk the I → D → G cycle. At the start of Phase I, recall prior context via
`mcp__crystalium__recall(scope={project, agent_class_visibility:"idg"}, query="session chronicle Redis cache decision", k=5, layers=[semantic,episodic,procedural])`. After the Gate DELIVER decision, persist the document via `mcp__crystalium__commit(layer=episodic, provenance={author_agent:"idg", document_type:"session-chronicle"})` and call `mcp__crystalium__session_end()`. If CRYSTALIUM tools are unavailable, proceed without memory and note the skip.

### Expected output shape

A response that walks the three phases as headings. Phase I includes a memory recall
call (or a graceful-skip note if CRYSTALIUM is absent). Phase G ends with a DELIVER
decision followed by a memory commit + session_end call (or skip note). The delivered
chronicle contains a `[DECISION]` marker and at least one `[ACTION]` item. The
provenance block records `author_agent: idg`.

### Validation criteria

- MUST contain heading: `## Intake`
- MUST contain heading: `## Draft`
- MUST contain heading: `## Gate`
- MUST contain phrase: `mcp__crystalium__recall` OR phrase: `CRYSTALIUM`
- MUST contain phrase: `mcp__crystalium__session_end` OR phrase: `graceful` OR phrase: `skip`
- MUST contain phrase: `author_agent`
- MUST contain phrase: `\[DECISION\]`
- MUST contain phrase: `\[ACTION\]`
- MUST contain phrase: `provenance`
- SHOULD contain phrase: `Redis`
- SHOULD have token count between 800 and 3000

---

## Mission: parallel-section-synthesis

### Prompt

Using the IDG (Scribe) methodology at the TRANCE tier, synthesize a session chronicle
from the following context. The document has six independent sections, so apply the G5
gated parallel section-synthesis mode (`skills/section-parallel.md`).

> **Document:** post-incident session chronicle with six independent sections —
> 1. Incident summary, 2. Timeline, 3. Root cause, 4. Remediation, 5. Customer impact,
> 6. Follow-up actions. Sections 1–5 are mutually independent; section 6 depends on 3 and 4.
> **Source artefacts:** `vigil-root-cause-report.md`, `apivr-completion-report.md`,
> `incident-timeline.md` (no envelopes present).
> **Audience:** Engineering leadership.

Walk the cycle. In Phase D, because the gate fires (≥6 independent sections at TRANCE),
do not draft sequentially: (1) dependency-layer the sections; (2) fan out at most five
clean-context per-section subagents per layer, read-only, no worktree; (3) run a
per-section CHT mini-gate (one revision max per section); (4) assemble in topological
order by selection, not averaging — conflicting claims become `[DISPUTED]`; (5) run one
document-level coherence pass and merge every per-section provenance note into a single
provenance block.

### Expected output shape

A response that walks the three phases as headings. Phase D shows the dependency-layering
(layer 0 = independent sections, a later layer containing section 6), states the bounded
fan-out (≤5 per layer), and notes the read-only / no-worktree posture. Each section is
drafted once and carries its own per-section CHT note. The Gate section shows the single
document-level coherence pass. The final chronicle has a `[DECISION]` marker and a single
merged provenance block unioning all per-section source citations. No facts are invented.

### Validation criteria

- MUST contain heading: `## Intake`
- MUST contain heading: `## Draft`
- MUST contain heading: `## Gate`
- MUST contain phrase: `topological` OR phrase: `layer`
- MUST contain phrase: `selection` OR phrase: `not averaging`
- MUST contain phrase: `coherence`
- MUST contain phrase: `provenance`
- MUST contain phrase: `\[DECISION\]`
- MUST contain phrase: `Completeness`
- SHOULD contain phrase: `read-only` OR phrase: `no worktree`
- SHOULD have token count between 900 and 3500

---

## Legacy mission catalog (pre-DSL)

> The original two free-form missions ("ADR from Minimal Context",
> "Insufficient Context Handling") are preserved below as historical
> reference. The v1.13.0 validator parses only the `## Mission: <id>`
> blocks above.

---

## Mission 1: ADR from Minimal Context

**Purpose**: Verify that Scribe applies the full IDG cycle — including structural markers and provenance — from minimal input.

**Input prompt**:

```
Using the IDG methodology, synthesize an Architecture Decision Record from the following context:

Decision: The team chose PostgreSQL over MySQL.
Reason: PostgreSQL's JSONB type was required for flexible schema storage without a separate document store.
Rejected alternative: MySQL (no native JSONB; JSON column is text only).
Audience: Backend engineers on the team.
```

**Expected outputs**:

1. Scribe runs Intake: classifies document type as `adr`, validates context sufficiency, loads `templates/adr.md`
2. Scribe runs Draft: produces ADR with all template sections addressed, includes at minimum:
   - `[DECISION]` marker with what, why, and rejected alternative
   - At least one `[GAP]` or `[ACTION]` if applicable
3. Scribe runs Gate: CHT scores each ≥ 3; if any < 4, performs one revision pass
4. Scribe delivers the ADR with a provenance block containing:
   - Document type: `adr`
   - Source artifacts listed
   - CHT scores (e.g., C:5/5 H:4/5 T:5/5)
   - Coverage assessment

**Pass criteria**:

- [ ] `[DECISION]` marker present with what/why/rejected structure
- [ ] Provenance block present at end of document
- [ ] No fabricated claims (e.g., no invented team names, dates, or rationale not in input)
- [ ] CHT gate reached and reported (pass or flagged revision)

**Fail signals**:

- Scribe produces output without provenance metadata
- Scribe invents a rejected alternative not mentioned in input
- Scribe skips the Gate phase
- Output is unbounded (> 2 revision passes indicated)

---

## Mission 2: Insufficient Context Handling

**Purpose**: Verify that Scribe requests missing context rather than fabricating it.

**Input prompt**:

```
Using the IDG methodology, write a runbook for the deployment process.
```

**Expected behavior**:

Scribe should identify that the context is insufficient (no deployment steps, no system described, no audience specified) and request specific missing pieces before proceeding. It should NOT produce a generic runbook.

**Pass criteria**:

- [ ] Scribe asks for at least: deployment steps or system name, audience, and trigger condition
- [ ] Scribe does NOT produce a runbook with invented content
- [ ] Scribe uses `[GAP]` markers or explicit questions, not assumptions
