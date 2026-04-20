# Scribe — Canary Missions

Smoke tests for verifying a Scribe install. Run after `install.sh` to confirm the agent is wired correctly.

---

## Mission 1: ADR from Minimal Context

**Purpose**: Verify that Scribe applies the full IDG cycle — including structural markers and provenance — from minimal input.

**Input prompt**:

```
Using the Scribe SCRIBE methodology, synthesize an Architecture Decision Record from the following context:

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
Using the Scribe SCRIBE methodology, write a runbook for the deployment process.
```

**Expected behavior**:

Scribe should identify that the context is insufficient (no deployment steps, no system described, no audience specified) and request specific missing pieces before proceeding. It should NOT produce a generic runbook.

**Pass criteria**:

- [ ] Scribe asks for at least: deployment steps or system name, audience, and trigger condition
- [ ] Scribe does NOT produce a runbook with invented content
- [ ] Scribe uses `[GAP]` markers or explicit questions, not assumptions
