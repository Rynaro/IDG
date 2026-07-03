#!/usr/bin/env bats
# tests/ecl-v2-adoption.bats — Wave-3 ECL v2.0 adoption sweep
#
# Covers: the vendored v2 envelope schema shape, v1 schema retention,
# install.sh wiring for the new schema file, retirement of the divergent
# warn-only intake variant in skills/composition.md (drift-kill greps),
# canonical verify-incoming convergence with Kupo's failure-code set, ISE
# (Intent, Source, Entitlement) consumption-only wiring across the intake
# skill and templates, and version-stamp agreement across the 5 canonical
# homes. IDG emits no envelopes (handoffs.emits = []) — there is no outbound
# ISE emission to test, only inbound consumption.

load helpers.bash

INSTALL_TARGET=""

setup() {
  INSTALL_TARGET="$(mktemp -d)"
}

teardown() {
  teardown_install
}

# ─────────────────────────────────────────────────────────────────────────────
# v2 envelope schema — shape
# ─────────────────────────────────────────────────────────────────────────────

@test "v2: schemas/ecl-envelope.v2.json exists and is valid JSON" {
  [ -f "${REPO_ROOT}/schemas/ecl-envelope.v2.json" ]
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq empty "${REPO_ROOT}/schemas/ecl-envelope.v2.json"
  [ "$status" -eq 0 ]
}

@test "v2: schemas/ecl-envelope.v1.json is RETAINED (not removed by the sweep)" {
  [ -f "${REPO_ROOT}/schemas/ecl-envelope.v1.json" ]
}

@test "v2: envelope_version pattern is strict to 2.0" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.properties.envelope_version.pattern' "${REPO_ROOT}/schemas/ecl-envelope.v2.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"2"* ]]
}

@test "v2: schema declares an ise \$defs block with assertion_grade required" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.["$defs"].ise.required[0]' "${REPO_ROOT}/schemas/ecl-envelope.v2.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "assertion_grade" ]]
}

@test "v2: ise.assertion_grade enum has the four ECL v2.0 §6.5.2 values" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.["$defs"].ise.properties.assertion_grade.enum[]' "${REPO_ROOT}/schemas/ecl-envelope.v2.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"unverified"* ]]
  [[ "$output" == *"self-attested"* ]]
  [[ "$output" == *"validated"* ]]
  [[ "$output" == *"human-reviewed"* ]]
}

@test "v2: top-level ise property refs the \$defs/ise block" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.properties.ise["$ref"]' "${REPO_ROOT}/schemas/ecl-envelope.v2.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "#/\$defs/ise" ]]
}

@test "v2: schema performative enum matches the closed ten-value set" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.properties.performative.enum | length' "${REPO_ROOT}/schemas/ecl-envelope.v2.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "10" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# install.sh wiring — v2 schema
# ─────────────────────────────────────────────────────────────────────────────

@test "v2: install.sh copies schemas/ecl-envelope.v2.json" {
  grep -q 'ecl-envelope.v2.json' "${REPO_ROOT}/install.sh"
}

@test "v2: install.sh records schemas/ecl-envelope.v2.json in files_written (files_append)" {
  grep -q '"schemas/ecl-envelope.v2.json"' "${REPO_ROOT}/install.sh"
}

@test "v2: install (--hosts none) produces both v1 and v2 schema files in target" {
  run_install "${INSTALL_TARGET}"
  [ "$INSTALL_STATUS" -eq 0 ]
  [ -f "${INSTALL_TARGET}/schemas/ecl-envelope.v1.json" ]
  [ -f "${INSTALL_TARGET}/schemas/ecl-envelope.v2.json" ]
}

@test "v2: installed schemas/ecl-envelope.v2.json content matches source" {
  run_install "${INSTALL_TARGET}"
  run diff "${REPO_ROOT}/schemas/ecl-envelope.v2.json" "${INSTALL_TARGET}/schemas/ecl-envelope.v2.json"
  [ "$status" -eq 0 ]
}

@test "v2: install.manifest.json records schemas/ecl-envelope.v2.json in files_written" {
  if ! command -v jq >/dev/null 2>&1; then
    skip "jq not available"
  fi
  run_install "${INSTALL_TARGET}"
  run jq -e '[.files_written[] | select(.path == "schemas/ecl-envelope.v2.json")] | length > 0' \
    "${INSTALL_TARGET}/install.manifest.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "true" ]]
}

@test "v2: canonical_inventory_sweep does not remove the v2 schema on a second install run" {
  run_install "${INSTALL_TARGET}"
  [ "$INSTALL_STATUS" -eq 0 ]
  run_install "${INSTALL_TARGET}"
  [ "$INSTALL_STATUS" -eq 0 ]
  [ -f "${INSTALL_TARGET}/schemas/ecl-envelope.v2.json" ]
  [ -f "${INSTALL_TARGET}/schemas/ecl-envelope.v1.json" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Retirement of the divergent warn-only intake in skills/composition.md
# ─────────────────────────────────────────────────────────────────────────────

@test "drift: skills/composition.md no longer validates inline against ecl-envelope.v1.json" {
  # The retirement note ("...v1.json retained for the ECL §7.3 compatibility
  # window") legitimately mentions the v1 filename; what must be gone is the
  # old *inline validation instruction* against it.
  run grep -c 'Validate the sidecar JSON against the vendored schema at' "${REPO_ROOT}/skills/composition.md"
  [[ "$output" == "0" ]]
}

@test "drift: skills/composition.md no longer carries the ^1\.0 intake compatibility regex" {
  run grep -c '\^1\\\.0' "${REPO_ROOT}/skills/composition.md"
  [[ "$output" == "0" ]]
}

@test "drift: skills/composition.md header is ECL v2.0, not v1.0" {
  grep -q 'Envelope-Aware Intake (ECL v2.0)' "${REPO_ROOT}/skills/composition.md"
  run grep -c 'ECL v1\.0' "${REPO_ROOT}/skills/composition.md"
  [[ "$output" == "0" ]]
}

@test "drift: skills/composition.md preserves the four-step intake numbering" {
  grep -q '### Step 1 — Detect' "${REPO_ROOT}/skills/composition.md"
  grep -q '### Step 2 — Validate' "${REPO_ROOT}/skills/composition.md"
  grep -q '### Step 3 — Recompute and compare sha256' "${REPO_ROOT}/skills/composition.md"
  grep -q '### Step 4 — Check performative' "${REPO_ROOT}/skills/composition.md"
}

@test "drift: skills/composition.md steps defer to verify-incoming (one gate, not two)" {
  grep -q 'one gate, not two' "${REPO_ROOT}/skills/composition.md"
  grep -qi 'owned by `skills/verify-incoming.md`' "${REPO_ROOT}/skills/composition.md"
}

@test "drift: skills/composition.md no longer produces a [DISPUTED] marker on sha256 mismatch (blocking, not warn-only)" {
  run grep -c 'ECL envelope sha256 mismatch' "${REPO_ROOT}/skills/composition.md"
  [[ "$output" == "0" ]]
}

@test "sanity: skills/composition.md markers/grounding/audience content preserved verbatim" {
  grep -q '\[DECISION\]' "${REPO_ROOT}/skills/composition.md"
  grep -q '\[ACTION\]' "${REPO_ROOT}/skills/composition.md"
  grep -q '\[DISPUTED\]' "${REPO_ROOT}/skills/composition.md"
  grep -q '\[GAP\]' "${REPO_ROOT}/skills/composition.md"
  grep -q 'Grounding Rules' "${REPO_ROOT}/skills/composition.md"
  grep -q 'Audience Adaptation' "${REPO_ROOT}/skills/composition.md"
  grep -q 'Topological Section Order' "${REPO_ROOT}/skills/composition.md"
}

# ─────────────────────────────────────────────────────────────────────────────
# Drift-kill: no stray "ECL v1.0" prose left in the rest of the methodology
# ─────────────────────────────────────────────────────────────────────────────

@test "drift: SPEC.md ECL Composition section targets v2.0, not v1.0" {
  grep -q 'ECL Composition (v2.0)' "${REPO_ROOT}/SPEC.md"
  run grep -c 'ECL v1\.0' "${REPO_ROOT}/SPEC.md"
  [[ "$output" == "0" ]]
}

@test "drift: SPEC.md declares comm.envelope_version 2.0 in prose (matches agent.md/AGENTS.md frontmatter)" {
  grep -q 'comm.envelope_version: "2.0"' "${REPO_ROOT}/SPEC.md"
}

@test "drift: templates/session-chronicle.md Communication Lineage note targets ECL v2.0" {
  grep -q 'ECL v2.0 envelopes' "${REPO_ROOT}/templates/session-chronicle.md"
  run grep -c 'ECL v1\.0' "${REPO_ROOT}/templates/session-chronicle.md"
  [[ "$output" == "0" ]]
}

@test "drift: CLAUDE.md load-order pointer names the v2 schema" {
  grep -q 'ecl-envelope.v2.json' "${REPO_ROOT}/CLAUDE.md"
}

@test "drift: agent.md and AGENTS.md frontmatter agree on envelope_version 2.0" {
  grep -q 'envelope_version: "2.0"' "${REPO_ROOT}/agent.md"
  grep -q 'envelope_version: "2.0"' "${REPO_ROOT}/AGENTS.md"
}

@test "drift: no file outside CHANGELOG.md / DESIGN-RATIONALE.md / .eidolons-audit / the v1 schema declares 'ECL v1.0'" {
  # Scoped to tracked methodology source only (not "." recursively) so a
  # gitignored vendor-copy leftover from another test's incomplete cleanup
  # (e.g. tests/verify-incoming.bats' .claude/skills/*/SKILL.md) can never
  # produce a false positive here.
  # tests/*.bats is deliberately excluded: bats files legitimately contain the
  # literal search string as part of their own grep-based assertions.
  cd "${REPO_ROOT}"
  run grep -l 'ECL v1\.0' \
    agent.md AGENTS.md CLAUDE.md SPEC.md README.md INSTALL.md install.sh \
    hosts/*.md evals/canary-missions.md evals/fixtures/install.manifest.json \
    skills/*.md templates/*.md
  # grep exits 1 with empty $output when nothing matches — that's the pass case.
  if [ "$status" -eq 0 ]; then
    echo "Stale 'ECL v1.0' prose found in: $output" >&3
    false
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Canonical verify-incoming convergence with ../Kupo
# ─────────────────────────────────────────────────────────────────────────────

@test "convergence: verify-incoming.md failure codes include CONTEXT_OVER_BUDGET (matches Kupo)" {
  grep -q 'CONTEXT_OVER_BUDGET' "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "convergence: verify-incoming.md failure codes include MISSING_REQUIRED_SECTION (matches Kupo)" {
  grep -q 'MISSING_REQUIRED_SECTION' "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "convergence: verify-incoming.md drops the stale 'six Eidolons' count" {
  run grep -c 'six Eidolons' "${REPO_ROOT}/skills/verify-incoming.md"
  [[ "$output" == "0" ]]
  grep -q 'All Eidolons in the roster ship this gate' "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "convergence: verify-incoming.md accepted-artifact table is preserved (IDG-specific inbound edges)" {
  grep -q '| `atlas` | PROPOSE, INFORM | `scout-report` |' "${REPO_ROOT}/skills/verify-incoming.md"
  grep -q '| `spectra` | PROPOSE, INFORM | `spec` |' "${REPO_ROOT}/skills/verify-incoming.md"
  grep -q '| `apivr` | INFORM, PROPOSE | `change-summary` |' "${REPO_ROOT}/skills/verify-incoming.md"
  grep -q '| `vigil` | PROPOSE, INFORM | `root-cause-report` |' "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "convergence: verify-incoming.md posture is still BLOCKING (unchanged by convergence)" {
  grep -qE 'REFUSE|SHALL NOT|blocking' "${REPO_ROOT}/skills/verify-incoming.md"
  run grep -ciE 'always processes?|shall process|must process|proceed.*anyway|process.*despite' \
    "${REPO_ROOT}/skills/verify-incoming.md"
  [[ "$output" == "0" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# ISE consumption (IDG emits nothing — consumption-only)
# ─────────────────────────────────────────────────────────────────────────────

@test "ise: skills/verify-incoming.md documents consumption-only ISE handling" {
  grep -qi 'ISE Consumption' "${REPO_ROOT}/skills/verify-incoming.md"
  grep -q 'ise.assertion_grade' "${REPO_ROOT}/skills/verify-incoming.md"
  grep -qi 'consumption-only' "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "ise: skills/composition.md intake carries ise.assertion_grade into the provenance block" {
  grep -q 'ise.assertion_grade' "${REPO_ROOT}/skills/composition.md"
}

@test "ise: SPEC.md documents ISE consumption (ECL v2.0 §6.5)" {
  grep -qi 'ISE consumption' "${REPO_ROOT}/SPEC.md"
}

@test "ise: all four templates' Provenance section notes the ise.assertion_grade citation form" {
  for f in session-chronicle adr runbook change-narrative; do
    grep -q 'ise.assertion_grade' "${REPO_ROOT}/templates/${f}.md"
  done
}

@test "ise: session-chronicle.md Communication Lineage table gains an ise_grade column" {
  grep -q 'ise_grade' "${REPO_ROOT}/templates/session-chronicle.md"
}

@test "ise: change-narrative.md Guidance calls out validated vs self-attested upstream work" {
  grep -qi 'validated' "${REPO_ROOT}/templates/change-narrative.md"
  grep -qi 'self-attested' "${REPO_ROOT}/templates/change-narrative.md"
}

@test "ise: IDG never claims to emit ise itself (consumption-only, handoffs.emits empty)" {
  grep -q 'emits: \[\]' "${REPO_ROOT}/agent.md"
  grep -q 'emits: \[\]' "${REPO_ROOT}/AGENTS.md"
}

# ─────────────────────────────────────────────────────────────────────────────
# Version stamp — 5 canonical homes at 1.10.0
# ─────────────────────────────────────────────────────────────────────────────

@test "stamp: install.sh, agent.md, AGENTS.md, SPEC.md, hosts/claude-code.md, fixture manifest agree on 1.10.0" {
  grep -q 'EIDOLON_VERSION="1.10.0"' "${REPO_ROOT}/install.sh"
  grep -q 'version: 1.10.0' "${REPO_ROOT}/agent.md"
  grep -q 'methodology_version: 1.10.0' "${REPO_ROOT}/agent.md"
  grep -q 'version: 1.10.0' "${REPO_ROOT}/AGENTS.md"
  grep -q 'methodology_version: 1.10.0' "${REPO_ROOT}/AGENTS.md"
  grep -q 'version: 1.10.0' "${REPO_ROOT}/SPEC.md"
  grep -q 'version: 1.10.0' "${REPO_ROOT}/hosts/claude-code.md"
  if command -v jq &>/dev/null; then
    run jq -r '.version' "${REPO_ROOT}/evals/fixtures/install.manifest.json"
    [[ "$output" == "1.10.0" ]]
  fi
}

@test "stamp: no template footer hardcodes a version (D1 convention preserved)" {
  for f in session-chronicle adr runbook change-narrative; do
    run grep -c 'Scribe version: [0-9]' "${REPO_ROOT}/templates/${f}.md"
    [[ "$output" == "0" ]]
  done
}
