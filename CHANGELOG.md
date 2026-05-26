# Changelog

All notable changes to Scribe are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [Semantic Versioning](https://semver.org/).

---

## [1.4.1] — 2026-05-26

### Fixed
- `SPEC.md`: corrected three stale prose references from the v1.3 subdir layout
  (`skills/<skill>/SKILL.md`) to the v1.3-flattened flat layout (`skills/<skill>.md`).
  Affected lines: skill-loading table (×2) and ECL Gate — Truthfulness prose reference.

---

## [1.4.0] — 2026-05-26

### Changed
- Declares EIIS v1.4 conformance (`EIIS_VERSION = 1.4`).
- BREAKING (install-target): `DESIGN-RATIONALE.md` is no longer copied to
  `<target>/`. The source-repo file at the IDG root is unchanged (EIIS §1.1
  source-repo MUSTs retain it).
- `.claude/agents/idg.md` HEREDOC rewritten per EIIS v1.4 §4.2.6: references
  both `./.eidolons/idg/agent.md` (always-loaded P0 rules) and
  `./.eidolons/idg/SPEC.md` (deep on-demand spec); adds `model: haiku`
  frontmatter. Legacy `IDG.md` reference removed.
- `agent.md` role in `files_written[]` changed from `entry-point` to
  `agent-profile` (EIIS v1.4 §1.8.6 new role value).
- `LEGACY_SPEC_FILES` extended with `DESIGN-RATIONALE.md` so upgrade-from-v1.3.1
  sweeps the stale install-target copy.
- Vendored `schemas/install.manifest.v1.json` synced to EIIS v1.4 (adds
  `agent-profile` and `ecl-version` to the `role` enum; adds optional
  `canonical_inventory_strict` field; retains IDG-local `comm` property).
- Fixture `evals/fixtures/install.manifest.json` updated to v1.4 format
  (role `agent-profile`, `ECL_VERSION` entry, v1.4.0 version).

### Added
- `<target>/ECL_VERSION` is now written by `install.sh` with `role:
  "ecl-version"` (EIIS v1.4 §3.7.1; closes canonical-inventory G3).
- Manifest-driven `canonical_inventory_sweep` helper at install-end (EIIS v1.4
  §6.X). Removes any file under `<target>/` not in the current run's
  `files_written[]` allow-set; runs after all writes, before manifest
  finalisation. Belt-and-braces alongside the existing `cleanup_legacy_v1_2`
  early sweep.
- `canonical_inventory_strict: true` emitted in `install.manifest.json` (EIIS
  v1.4 §3.7).
- Fixture `.claude/agents/idg.md` added at `evals/fixtures/.claude/agents/`
  for conformance checker I4 validation.

### Compliance
- `EIIS_VERSION` bumped to `1.4`.

---

## [1.3.1] — 2026-05-26

### Fixed
- `install.sh` now sweeps legacy v1.2-era artefacts on upgrade: removes stale
  `<TARGET>/IDG.md`, `<TARGET>/SCRIBE.md` (defensive), and any
  `<TARGET>/skills/{composition,verification}/` subdir trees.
  Fresh installs are unaffected (guards short-circuit when files are absent).

---

## [1.3.0] — 2026-05-25 — EIIS v1.3 layout normalization (SPEC.md + flat skills)

### Changed
- BREAKING: source file `SCRIBE.md` renamed to `SPEC.md`; install destination
  renamed `IDG.md` → `SPEC.md` (EIIS v1.3 §1.8). The rename-on-copy fallback
  block (`install.sh:132-137`) is retired.
- BREAKING: skills layout flattened from `skills/<skill>/SKILL.md` (subdir) to
  `skills/<skill>.md` (flat). Vendor copies at `.claude/skills/idg-<skill>/SKILL.md`
  are unchanged. Per EIIS v1.3 §4.2.4.3.
- `EIDOLON_VERSION` bumped from `1.2.2` to `1.3.0`.

### Fixed
- `agent.md` frontmatter `methodology: SCRIBE` corrected to `methodology: IDG`
  (OQ-2 stale SCRIBE residue, GAP-3 from install-normalization scout report).
- `agent.md` line 60 `SCRIBE.md` reference now points to `SPEC.md`.
- `AGENTS.md`, `CLAUDE.md`, `hosts/*.md`, `INSTALL.md`, `.github/copilot-instructions.md`,
  `DESIGN-RATIONALE.md`, and `evals/canary-missions.md` updated to remove remaining
  SCRIBE residue (filename references and stale methodology labels).
- Manifest `files_written[]` now records correct paths for skills
  (`skills/composition.md`, `skills/verification.md`) and includes vendor-copy
  entries for `.claude/skills/idg-*/SKILL.md` when `claude-code` is wired.

### Added
- Manifest `spec_file` field (EIIS v1.3 §1.8): `.eidolons/idg/SPEC.md`.
- Manifest `skills[]` array (EIIS v1.3 §4.2.4): dual-write records for
  `composition` and `verification` skills with `source_path`, `source_sha256`,
  `vendor_path`, and `vendor_sha256`.
- Vendored `schemas/install.manifest.v1.json` updated to include `spec_file`
  and `skills` fields (additive; backward-compatible with v1.2 manifests).

### Compliance
- `EIIS_VERSION` bumped to `1.3`.

---

## [1.2.2] — 2026-05-13 — declare ECL v2.0 conformance

### Changed
- Declaration-only patch bump. No behaviour change, no schema change, no
  envelope-shape change.
- IDG emits envelopes byte-compatible with ECL v2.0 (backward-compatible
  per ECL §7.3, compatibility window through 2027-05-13).
- Files modified:
  - `ECL_VERSION`: `1.2` → `2.0`
  - `agent.md` frontmatter `comm.envelope_version`: `"1.2"` → `"2.0"`
  - `AGENTS.md` frontmatter `comm.envelope_version`: `"1.2"` → `"2.0"`
  - `install.sh` `EIDOLON_VERSION`: `1.2.1` → `1.2.2`

### Notes
- Spec reference: `Rynaro/eidolons-ecl@v2.0.0` (`spec/ecl-2.0.md`,
  introducing ISE trust hierarchy).
- Companion patches: ATLAS v1.5.2 ✓ merged, SPECTRA v4.3.2 ✓ released,
  APIVR-Δ v3.1.2 ✓ released; FORGE, VIGIL follow.

---

## [1.2.1] — 2026-05-12 — Declare ECL v1.2 conformance

### Changed
- `ECL_VERSION` file: `1.0` → `1.2`. Targets the latest ECL spec
  (`Rynaro/eidolons-ecl@v1.2.0`); IDG's inbound verifier remains
  byte-compatible (v1.2 is backward-compatible with v1.0 per ECL §1.1.1).
- `agent.md` + `AGENTS.md` frontmatter: `comm.envelope_version`
  `"1.0"` → `"1.2"`.
- `install.sh`: `EIDOLON_VERSION` `1.2.0` → `1.2.1` (PATCH bump —
  declaration-only change; no behaviour change).

### Notes
- No envelope-format changes. IDG continues to accept v1.0/v1.1/v1.2
  envelopes from upstream Eidolons (APIVR-Δ completion-report,
  VIGIL root-cause-report). Warn-only verify semantics preserved —
  verification misses surface as `[DISPUTED]` markers in the chronicle.
- IDG remains terminal in the canonical hand-off graph; no emit
  envelopes shipped.

## [1.2.0] — 2026-05-11 — ECL v1.0 inbound conformance

### Added
- `ECL_VERSION` file at root containing `1.0` (declares this Eidolon targets ECL v1.0 for verification of inbound envelopes).
- Vendored `schemas/ecl-envelope.v1.json` (with the ten-value `performative` enum inlined at both `$ref` call sites) plus `schemas/ecl-base-profile.v1.json` and the inbound profile schemas `schemas/apivr-completion-report-profile.v1.json` and `schemas/root-cause-report-profile.v1.json` from `eidolons-ecl@v1.0.0`.
- `comm` block in `install.manifest.json` declaring `envelope_version: "1.0"`, `emits: []`, `verifies: [apivr-completion-report, root-cause-report]`.
- Intake skill (`skills/composition/SKILL.md`) recognises `*.envelope.json` sidecars next to source payloads; validates schema + sha256 + performative; **warns on mismatch (never refuses)** — a verification failure surfaces as a `[DISPUTED]` marker in the chronicle.
- `templates/session-chronicle.md` carries an optional **Communication Lineage** section surfacing `message_id` / `thread_id` / `verify_pass`/`verify_fail` for envelope-attested sources.
- ADR / runbook / change-narrative templates accept `ecl://thread/<thread_id>/message/<message_id>` as a source citation form in their Provenance sections.

### Changed
- Bumped `EIDOLON_VERSION` in `install.sh` from `1.1.5` to `1.2.0`.
- `agent.md` / `AGENTS.md` frontmatter adds `comm.envelope_version: "1.0"`.
- `schemas/install.manifest.v1.json` hand-extended with an OPTIONAL `comm` property (`envelope_version` + `emits` + `verifies` arrays).
- `SCRIBE.md` records the ECL inbound-verification contract; `DESIGN-RATIONALE.md` carries the warn-only rationale entry.

### Notes
- Adoption is **opt-in and warn-only** at ECL v1.0. IDG never refuses to chronicle on a verification miss; failures become `[DISPUTED]` markers.
- IDG is terminal in the canonical hand-off graph and does not emit envelopes in v1.0. An optional `ACKNOWLEDGE` emission path is left unspecified; flag for ECL v1.1 contract enumeration if exercised.
- No `tests/` directory exists in this repo — gate runs use `jq`, `shellcheck`, project-local idempotency, and EIIS conformance per project conventions.

## [1.1.5] - 2026-04-26 — Re-vendor EIIS v1.1 schema (codex enum)

### Fixed
- `schemas/install.manifest.v1.json` re-vendored from EIIS v1.1 — the previously bundled copy lacked `codex` in the `hosts_wired` enum, causing the EIIS conformance checker's M14 (JSON Schema validation) to fail when a validator (`ajv` / `python -m jsonschema`) was on PATH. Pure schema fix; no install.sh behaviour change.

## [Unreleased]

### Added
- `.github/workflows/release.yml` — caller workflow that invokes the eidolons-nexus `eidolon-release-template.yml` (PR #24, 2026-04-29). Tagging a SemVer release now produces a GitHub Release with `release-manifest.json` (commit, tree, archive_sha256, manifest_sha256, provenance.github_attestation) and `SHA256SUMS`, ready for nexus-side `Roster Intake` to populate `versions.releases.<v>` in `roster/index.yaml`.

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
