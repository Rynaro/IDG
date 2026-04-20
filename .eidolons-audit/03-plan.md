# Phase 3 — PLAN

## Summary

The Scribe repo (v1.1.0) has a complete and well-designed methodology — SCRIBE.md, both skills, and all four templates are present and authoritative. What is entirely absent is the EIIS install surface: no agent.md entry point, no AGENTS.md auto-discovery file, no CLAUDE.md, no Copilot instructions, no per-host wiring docs, no evals, no manifest schema, and an install.sh that predates the §3 interface contract. After this audit, the Scribe will expose the full EIIS-1.0 install surface while leaving its methodology content (SCRIBE.md, skills/, templates/, DESIGN-RATIONALE.md) completely untouched. Explicitly out of scope: any changes to Scribe's IDG cycle, CHT verification framework, structural markers, or document output format.

---

## File Change List

### G-01 — CREATE agent.md

Create a compact always-loaded entry point ≤ 1,000 tokens. This file is not SCRIBE.md — it is a shorter "executive summary + delegation pointer" that loads quickly in every context. It must include:
- Frontmatter: name, version, methodology, methodology_version, role, handoffs
- One-paragraph identity description (lifted from SCRIBE.md)
- IDG cycle summary (3 lines, no elaboration)
- Non-negotiable rules (P0 guardrails: never fabricate, one gate/one revision, structural markers required)
- Skill and template loading table (on-demand, same as SCRIBE.md)
- Pointer to SCRIBE.md for full spec

Target: < 600 words → ~800 tokens BPE to leave headroom.

### G-02 — CREATE AGENTS.md

Create root AGENTS.md with §5-compliant frontmatter:
- name: scribe
- version: 1.1.0
- methodology: SCRIBE
- methodology_version: 1.1.0
- role: documentation-synthesis — transforms context into structured, grounded, actionable documents
- handoffs: upstream: [] (accepts context from any upstream agent), downstream: []

Body: one-paragraph description (from README.md), IDG cycle, non-negotiable rules, skill loading pointer, install pointer.

### G-03 — CREATE CLAUDE.md

Create CLAUDE.md with load order for this repository:
1. agent.md — always loaded
2. SCRIBE.md — full methodology
3. skills/<phase>/SKILL.md — on-demand per phase
4. templates/<artifact>.md — on-demand per output type

Plus consumer project usage section explaining installed path.

### G-04 — CREATE .github/copilot-instructions.md

Create .github/ directory and copilot-instructions.md. Content:
- What Scribe is (one paragraph from README.md)
- Non-negotiable rules
- Phase pipeline table (I, D, G with skill files)
- Full spec pointer to SCRIBE.md

### G-05 — CREATE INSTALL.md

Create human cross-host install guide covering:
- Prerequisites (bash, git)
- Quick install command
- Per-host table: Claude Code, Copilot, Cursor, OpenCode, Raw API
- Detailed per-host instructions with config file paths
- Verification smoke test per host
- Uninstall instructions

### G-06 — CREATE CHANGELOG.md

Create CHANGELOG.md in Keep-a-Changelog format:
- [Unreleased] section (empty for now — EIIS changes will be added in Phase 5)
- [1.1.0] — restructured skills into skills/<name>/SKILL.md, added install.sh (from git log)
- [1.0.0] — initial release

### G-07–G-10 — CREATE hosts/{claude-code,copilot,cursor,opencode}.md

Four per-host wiring docs using the minimal skeleton template. Each covers:
1. Install (command sequence using install.sh)
2. Config (where the dispatch file lives, snippet)
3. Verify (smoke test prompt)
4. Troubleshooting (common issues)

### G-11 — CREATE evals/canary-missions.md

Create evals/ directory and canary-missions.md with one smoke mission:
- Mission: "Given a three-sentence session summary, produce an ADR with all required structural markers"
- Expected outputs: complete ADR with [DECISION], [GAP] or [ACTION], provenance block with CHT scores
- Pass criteria: no fabricated claims, Gate passes or revision produces flagged output

### G-12 — CREATE schemas/install.manifest.v1.json

Create schemas/ directory and install.manifest.v1.json with the exact JSON Schema from §4 of the EIIS spec (draft 2020-12). This file is committed to the Eidolon repo for consumer validation.

### G-13 — PATCH install.sh

Preserve all existing copy-files logic (lines 28–42). Add:
1. Named variables: EIDOLON_NAME="scribe", EIDOLON_VERSION="1.1.0", METHODOLOGY="SCRIBE"
2. Argument parsing loop with all §3 flags: --target, --hosts, --force, --dry-run, --non-interactive, --manifest-only, --version, -h/--help
3. Host detection function (checks .claude/, CLAUDE.md, .github/, .cursor/, .cursorrules, .opencode/)
4. Idempotency: check install.manifest.json (not SCRIBE.md), compare versions, respect --force and --non-interactive
5. Per-host dispatch file creation (guarded by $HOSTS membership)
6. Manifest emission: write install.manifest.json with required fields
7. Token measurement: `wc -w < "$TARGET/agent.md" | awk '{printf "%d", $1/0.75}'`
8. Smoke test banner at end
9. --dry-run guard around all writes

---

## Risk Register

| Risk | Mitigation |
|------|-----------|
| install.sh patch may break existing positional-arg behavior | Retain $1 as --target alias? No — the new --target flag is the contract. The old positional form is not part of EIIS §3. Document the breaking change in CHANGELOG.md. |
| agent.md may exceed 1,000 tokens if too verbose | Write conservatively; measure during Phase 5 and trim if needed |
| SCRIBE.md frontmatter has `description` field not in §5 schema | §5 specifies minimum fields; extra fields are fine. No change needed. |
| Canary mission may not have a clear pass/fail criterion | Keep the pass criteria simple and binary (structural markers present, no fabricated claims). Flag as best-effort smoke test. |

---

## Token Budget Estimate

| Component | Before | After |
|-----------|--------|-------|
| agent.md | absent | ~750–900 tokens (target) |
| SCRIBE.md | ~1,066 tokens | unchanged |
| Consumer always-loaded (agent.md) | — | ≤ 1,000 tokens ✓ |

---

## Rejected Alternatives

**Alternative: Rename SCRIBE.md to agent.md and trim it to ≤1,000 tokens.**  
Rejected because SCRIBE.md is the authoritative full methodology file. Trimming it would lose detail needed for high-quality document synthesis. The EIIS spec intentionally separates agent.md (compact entry) from `<EIDOLON>.md` (full spec) for this reason.

**Alternative: Generate a monolithic INSTALL.md + AGENTS.md combined file.**  
Rejected because AGENTS.md must have §5 frontmatter for machine parsing; combining it with INSTALL.md would break auto-discovery by Cursor, OpenCode, and eidolons-init.
