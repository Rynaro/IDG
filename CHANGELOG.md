# Changelog

All notable changes to Scribe are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

## [1.1.4] — 2026-04-24

### Added — EIIS v1.1 + OpenAI Codex host

- `EIIS_VERSION` file at root containing `1.1` (resolves drift D-6 from
  the v1.0 conformance baseline; declares this Eidolon targets EIIS v1.1).
- `install.sh` now accepts `codex` in `--hosts` and includes `codex` in
  the `--hosts all` expansion (`claude-code,copilot,cursor,opencode,codex`).
- Per EIIS v1.1 §4.5, when `codex` is wired the installer:
  - Writes a marker-bounded `<!-- eidolon:idg start --> … end -->` block
    into root `AGENTS.md` (co-owned by `copilot` and `codex` per §4.1.0,
    written regardless of `--shared-dispatch`).
  - Emits `.codex/agents/idg.md` with valid YAML frontmatter (`name: idg`,
    a non-empty `description`) and a body that mirrors the existing
    `.claude/agents/idg.md` prompt and points at
    `./.eidolons/idg/agent.md` and `./.eidolons/idg/IDG.md`.
- `detect_hosts` now recognises `.codex/` and a bare root `AGENTS.md`
  (without `.github/`) as Codex signals.
- `--hosts` value validation: unknown values now exit `2` with a
  diagnostic on stderr (EIIS §2.7).
- `install.manifest.json` lists `.codex/agents/idg.md` and `AGENTS.md`
  under `files_written` when Codex is wired (EIIS §4.5.5).
- `evals/fixtures/install.manifest.json` — sample manifest fixture used
  by the EIIS conformance checker (`Rynaro/eidolons-eiis`).

### Changed

- Bumped `EIDOLON_VERSION` in `install.sh` from `1.1.0` to `1.1.4`.
- Help text and dry-run preview list the Codex artefacts.

### Notes

- No bats test directory exists in this repo; verification is by
  end-to-end smoke (`bash install.sh --hosts codex --non-interactive
  --force`) plus the EIIS conformance checker. Both run clean: shellcheck
  reports zero errors, the conformance check exits `0` against EIIS v1.1,
  a second invocation produces byte-identical `AGENTS.md` and
  `.codex/agents/idg.md`.

---

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
