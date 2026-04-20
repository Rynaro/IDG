# Phase 1 — SCOUT

**Eidolon**: scribe  
**Version**: 1.1.0  
**Cycle**: I → D → G (Intake → Draft → Gate)  
**Role**: Documentation synthesis specialist  
**Audit mode**: Fresh (no prior .eidolons-audit/, no EIIS_VERSION file)

---

## §1 Required File Inventory

| File | Status | Notes |
|------|--------|-------|
| AGENTS.md | ❌ MISSING | — |
| CLAUDE.md | ❌ MISSING | — |
| .github/copilot-instructions.md | ❌ MISSING | .github/ dir absent |
| README.md | ✅ EXISTS | root, scribe v1.1.0 |
| INSTALL.md | ❌ MISSING | — |
| CHANGELOG.md | ❌ MISSING | — |
| DESIGN-RATIONALE.md | ✅ EXISTS | root |
| agent.md | ❌ MISSING | SCRIBE.md exists but is the full spec; agent.md (compact entry ≤1000 tokens) is absent |
| SCRIBE.md | ✅ EXISTS | full methodology (~1,066 tokens BPE) — this is the `<EIDOLON>.md` |
| install.sh | ✅ EXISTS | contract violations (see below) |
| hosts/claude-code.md | ❌ MISSING | hosts/ dir absent |
| hosts/copilot.md | ❌ MISSING | — |
| hosts/cursor.md | ❌ MISSING | — |
| hosts/opencode.md | ❌ MISSING | — |
| evals/canary-missions.md | ❌ MISSING | evals/ dir absent |
| skills/composition/SKILL.md | ✅ EXISTS | ~913 tokens |
| skills/verification/SKILL.md | ✅ EXISTS | ~834 tokens |
| templates/session-chronicle.md | ✅ EXISTS | — |
| templates/adr.md | ✅ EXISTS | — |
| templates/runbook.md | ✅ EXISTS | — |
| templates/change-narrative.md | ✅ EXISTS | — |
| schemas/install.manifest.v1.json | ❌ MISSING | schemas/ dir absent |

**Summary**: 8 files present, 13 files missing.

---

## install.sh Contract Audit (vs §3)

[FINDING-001] install.sh accepts only positional $1 for target — no named flags at all.  
Evidence: install.sh:13 `TARGET_REL="${1:-./agents/scribe}"`

[FINDING-002] Missing required flags: `--target`, `--hosts`, `--force`, `--dry-run`, `--non-interactive`, `--manifest-only`, `--version`, `-h/--help`.  
Evidence: install.sh:1-68, no `while [[ $# -gt 0 ]]` arg parsing loop.

[FINDING-003] No host detection logic. Script always outputs Claude Code, Cursor, Windsurf prompts regardless of consumer project structure.  
Evidence: install.sh:47-66.

[FINDING-004] No manifest emission — does not write install.manifest.json.  
Evidence: install.sh:1-68, no JSON output.

[FINDING-005] No token budget measurement (`wc -w | awk`).  
Evidence: install.sh:1-68.

[FINDING-006] No smoke test banner at end.  
Evidence: install.sh:1-68.

[FINDING-007] Idempotency check is only interactive (`read -rp`); will hang under `--non-interactive` (flag doesn't exist yet).  
Evidence: install.sh:20-26.

[FINDING-008] install.sh copies SCRIBE.md but there is no agent.md to copy — installer references methodology file, not a compact entry point.  
Evidence: install.sh:35 `cp "$SCRIPT_DIR/SCRIBE.md" "$TARGET/SCRIBE.md"`.

---

## AGENTS.md Frontmatter Audit

[FINDING-009] AGENTS.md does not exist. §5 frontmatter cannot be checked.

---

## .github/copilot-instructions.md Audit

[FINDING-010] .github/ directory does not exist. File cannot be checked.

---

## hosts/ Audit

[FINDING-011] hosts/ directory does not exist. None of the four required per-host docs are present.

---

## install.manifest.json Audit

[FINDING-012] No install.manifest.json found at repo root or elsewhere. Not in delta mode.

---

## EIIS_VERSION

[FINDING-013] No EIIS_VERSION file found. Proceeding as fresh v1.0 audit.

---

## Token Budget

SCRIBE.md (full methodology): 800 words → ~1,066 tokens BPE estimate.  
This exceeds the ≤1,000 token budget for agent.md. A new, compact agent.md must be created; SCRIBE.md remains the full spec file.
