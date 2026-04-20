# Changelog

All notable changes to Scribe are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Added — EIIS-1.0 conformance

- `agent.md` — compact always-loaded entry point (≤ 1,000 tokens)
- `AGENTS.md` — open-standard auto-discovery file with EIIS §5 frontmatter
- `CLAUDE.md` — Claude Code load-order pointer
- `.github/copilot-instructions.md` — Copilot primary entry
- `INSTALL.md` — human cross-host install guide
- `hosts/claude-code.md`, `hosts/copilot.md`, `hosts/cursor.md`, `hosts/opencode.md` — per-host wiring docs
- `evals/canary-missions.md` — smoke mission for install verification
- `schemas/install.manifest.v1.json` — JSON Schema for install manifest (EIIS §4)
- `install.sh` patched with full §3 interface: `--target`, `--hosts`, `--force`, `--dry-run`, `--non-interactive`, `--manifest-only`, `--version`, `-h/--help`; host auto-detection; manifest emission; token budget measurement; smoke test banner

---

## [1.1.0] — 2025-04-20

### Changed

- Restructured skills into `skills/<name>/SKILL.md` layout
- Added `install.sh` for direct project installation

---

## [1.0.0] — 2025-04-20

### Added

- Initial release: Scribe documentation synthesis agent
- `SCRIBE.md` — full IDG methodology
- `DESIGN-RATIONALE.md` — research → design decision mapping
- `skills/composition/SKILL.md` — writing methodology and style standards
- `skills/verification/SKILL.md` — CHT verification gates and provenance
- `templates/` — session-chronicle, adr, runbook, change-narrative
