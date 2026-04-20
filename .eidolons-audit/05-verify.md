# Phase 6 — VERIFY

| Check | Status | Notes |
|-------|--------|-------|
| AGENTS.md exists | ✓ PASS | §5 frontmatter: name, version, methodology, methodology_version, role, handoffs |
| CLAUDE.md exists | ✓ PASS | load-order + consumer usage |
| .github/copilot-instructions.md exists | ✓ PASS | points at SCRIBE.md |
| README.md exists | ✓ PASS | (pre-existing) |
| INSTALL.md exists | ✓ PASS | covers all 4 hosts + raw + submodule |
| CHANGELOG.md exists | ✓ PASS | [Unreleased] EIIS section + v1.1.0 + v1.0.0 |
| DESIGN-RATIONALE.md exists | ✓ PASS | (pre-existing) |
| agent.md exists | ✓ PASS | 310 tokens BPE ≤ 1000 ✓ |
| SCRIBE.md exists | ✓ PASS | (pre-existing full methodology) |
| install.sh exists | ✓ PASS | §3 interface complete |
| hosts/claude-code.md | ✓ PASS | |
| hosts/copilot.md | ✓ PASS | |
| hosts/cursor.md | ✓ PASS | |
| hosts/opencode.md | ✓ PASS | |
| evals/canary-missions.md | ✓ PASS | 2 smoke missions |
| skills/composition/SKILL.md | ✓ PASS | (pre-existing) |
| skills/verification/SKILL.md | ✓ PASS | (pre-existing) |
| templates/session-chronicle.md | ✓ PASS | (pre-existing) |
| templates/adr.md | ✓ PASS | (pre-existing) |
| templates/runbook.md | ✓ PASS | (pre-existing) |
| templates/change-narrative.md | ✓ PASS | (pre-existing) |
| schemas/install.manifest.v1.json | ✓ PASS | JSON Schema draft 2020-12 |
| install.sh --help | ✓ PASS | all §3 flags present |
| install.sh --version | ✓ PASS | outputs 1.1.0 |
| install.sh --dry-run | ✓ PASS | prints all 13 paths, no writes |
| install.sh real install | ✓ PASS | install.manifest.json written with sha256, tokens=310 |
| install.manifest.json structure | ✓ PASS | all required fields present |
| AGENTS.md §5 frontmatter | ✓ PASS | all 6 required fields present |
| agent.md token budget | ✓ PASS | 310 tokens (limit ≤ 1000) |
| Methodology files untouched | ✓ PASS | SCRIBE.md, skills/, templates/, DESIGN-RATIONALE.md unmodified |

**Result: PASS — 0 items blocked**
