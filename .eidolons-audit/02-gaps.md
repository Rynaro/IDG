# Phase 2 — GAP ANALYSIS

| Gap ID | File | Class | Severity | Reason | Proposed Action |
|--------|------|-------|----------|--------|-----------------|
| G-01 | agent.md | CREATE | blocker | Always-loaded compact entry point (≤1000 tokens) required by §1; SCRIBE.md is the full spec (>1000 tokens), not a substitute | Create agent.md as a compact entry pointing to SCRIBE.md |
| G-02 | AGENTS.md | CREATE | blocker | Open-standard auto-discovery file required by §1; missing entirely | Create AGENTS.md with §5 frontmatter |
| G-03 | CLAUDE.md | CREATE | blocker | Claude Code pointer required by §1; missing entirely | Create CLAUDE.md with load-order + consumer usage section |
| G-04 | .github/copilot-instructions.md | CREATE | blocker | Copilot primary entry required by §1; .github/ dir absent | Create .github/ dir and copilot-instructions.md |
| G-05 | INSTALL.md | CREATE | major | Human cross-host install guide required by §1; missing | Create INSTALL.md covering all four hosts |
| G-06 | CHANGELOG.md | CREATE | major | Keep-a-Changelog format required by §1; missing | Create CHANGELOG.md with initial entry for v1.0.0 and v1.1.0 |
| G-07 | hosts/claude-code.md | CREATE | major | Per-host wiring doc required by §1; hosts/ dir absent | Create hosts/claude-code.md |
| G-08 | hosts/copilot.md | CREATE | major | Per-host wiring doc required by §1 | Create hosts/copilot.md |
| G-09 | hosts/cursor.md | CREATE | major | Per-host wiring doc required by §1 | Create hosts/cursor.md |
| G-10 | hosts/opencode.md | CREATE | major | Per-host wiring doc required by §1 | Create hosts/opencode.md |
| G-11 | evals/canary-missions.md | CREATE | major | At least one smoke mission required by §1; evals/ dir absent | Create evals/canary-missions.md with one smoke mission |
| G-12 | schemas/install.manifest.v1.json | CREATE | blocker | JSON Schema for manifest required by §1; schemas/ dir absent | Create schemas/install.manifest.v1.json with §4 schema |
| G-13 | install.sh | PATCH | blocker | Missing all §3 flags (--target, --hosts, --force, --dry-run, --non-interactive, --manifest-only, --version, -h/--help); no host detection; no manifest emission; no token measurement; no smoke test banner | Patch install.sh to add arg-parsing loop, host detection, manifest emission, token measurement, smoke test; preserve existing copy-files logic |

**Totals**: 4 blockers (G-01, G-02, G-03, G-04, G-12, G-13 — actually 6 blockers including G-12, G-13), 7 majors, 0 minors, 0 flagged.

Corrected count:
- Blockers: G-01, G-02, G-03, G-04, G-12, G-13 → **6 blockers**
- Majors: G-05, G-06, G-07, G-08, G-09, G-10, G-11 → **7 majors**
- Minors: 0
- Flagged: 0
