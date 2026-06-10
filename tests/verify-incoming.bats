#!/usr/bin/env bats
# tests/verify-incoming.bats — blocking, symmetric verify-incoming gate (ECL §6.2.2)
#
# Asserts:
#   1. skills/verify-incoming.md exists in the repo and declares BLOCKING posture.
#   2. It does NOT declare warn-only / "payload is always processed" / "process anyway".
#   3. install.sh (non-interactive) installs skills/verify-incoming.md into the target.
#   4. install.manifest.json records skills/verify-incoming.md (source_path).
#   5. The vendor copy .claude/skills/idg-verify-incoming/SKILL.md is installed
#      when claude-code host is wired.

load helpers.bash

INSTALL_TARGET=""

setup() {
  INSTALL_TARGET="$(mktemp -d)"
}

teardown() {
  teardown_install
}

# ── Skill source file assertions ─────────────────────────────────────────────

@test "skills/verify-incoming.md exists in the repo" {
  [ -f "${REPO_ROOT}/skills/verify-incoming.md" ]
}

@test "skills/verify-incoming.md declares BLOCKING posture" {
  run grep -qiE 'REFUSE|SHALL NOT|blocking' "${REPO_ROOT}/skills/verify-incoming.md"
  [ "$status" -eq 0 ]
}

@test "skills/verify-incoming.md does NOT declare warn-only posture as the current behaviour" {
  # Negative assertion: the skill must NOT instruct the receiver to PROCESS
  # a tampered or unverified payload (i.e. adopt the old warn-only posture).
  # "warn-only" and "processed the payload anyway" legitimately appear in
  # historical-context notes; we check for imperative "process" language
  # that would instruct the receiver to proceed despite a failure.
  run grep -qiE 'always processes?|shall process|must process|proceed.*anyway|process.*despite' \
    "${REPO_ROOT}/skills/verify-incoming.md"
  # grep must NOT find a match (exit 1)
  [ "$status" -ne 0 ]
}

@test "skills/verify-incoming.md has canonical frontmatter (name: idg-verify-incoming)" {
  run grep -m1 '^name:' "${REPO_ROOT}/skills/verify-incoming.md"
  [ "$status" -eq 0 ]
  [[ "$output" == "name: idg-verify-incoming" ]]
}

@test "skills/verify-incoming.md frontmatter has a non-empty description:" {
  run grep -m1 '^description:' "${REPO_ROOT}/skills/verify-incoming.md"
  [ "$status" -eq 0 ]
  [[ -n "$output" ]]
}

# ── Install: exit code + file placement ──────────────────────────────────────

@test "install.sh exits 0 with --hosts none" {
  run_install "${INSTALL_TARGET}"
  [ "$INSTALL_STATUS" -eq 0 ]
}

@test "install.sh writes skills/verify-incoming.md into target" {
  run_install "${INSTALL_TARGET}"
  [ -f "${INSTALL_TARGET}/skills/verify-incoming.md" ]
}

@test "installed skills/verify-incoming.md content matches source" {
  run_install "${INSTALL_TARGET}"
  local src="${REPO_ROOT}/skills/verify-incoming.md"
  local dst="${INSTALL_TARGET}/skills/verify-incoming.md"
  [ -f "$dst" ]
  run diff "$src" "$dst"
  [ "$status" -eq 0 ]
}

# ── Manifest assertions ───────────────────────────────────────────────────────

@test "install.manifest.json is generated" {
  run_install "${INSTALL_TARGET}"
  [ -f "${INSTALL_TARGET}/install.manifest.json" ]
}

@test "install.manifest.json records skills/verify-incoming.md in files_written" {
  if ! command -v jq >/dev/null 2>&1; then
    skip "jq not available"
  fi
  run_install "${INSTALL_TARGET}"
  local manifest="${INSTALL_TARGET}/install.manifest.json"
  run jq -e '[.files_written[] | select(.path == "skills/verify-incoming.md")] | length > 0' \
    "$manifest"
  [ "$status" -eq 0 ]
  [[ "$output" == "true" ]]
}

@test "install.manifest.json records skills/verify-incoming.md in skills[]" {
  if ! command -v jq >/dev/null 2>&1; then
    skip "jq not available"
  fi
  run_install "${INSTALL_TARGET}"
  local manifest="${INSTALL_TARGET}/install.manifest.json"
  run jq -e '[.skills[] | select(.name == "verify-incoming")] | length > 0' \
    "$manifest"
  [ "$status" -eq 0 ]
  [[ "$output" == "true" ]]
}

@test "manifest skills[verify-incoming].source_path points at idg skills dir" {
  if ! command -v jq >/dev/null 2>&1; then
    skip "jq not available"
  fi
  run_install "${INSTALL_TARGET}"
  local manifest="${INSTALL_TARGET}/install.manifest.json"
  run jq -r '.skills[] | select(.name == "verify-incoming") | .source_path' "$manifest"
  [ "$status" -eq 0 ]
  [[ "$output" == *"idg/skills/verify-incoming.md"* ]]
}

@test "manifest files_written[verify-incoming].sha256 matches installed file" {
  if ! command -v jq >/dev/null 2>&1; then
    skip "jq not available"
  fi
  run_install "${INSTALL_TARGET}"
  local manifest="${INSTALL_TARGET}/install.manifest.json"
  local declared_sha
  declared_sha="$(jq -r '[.files_written[] | select(.path == "skills/verify-incoming.md")][0].sha256' "$manifest")"
  local actual_sha
  actual_sha="$(sha256_of "${INSTALL_TARGET}/skills/verify-incoming.md")"
  [[ "$declared_sha" == "$actual_sha" ]]
}

# ── Vendor copy (claude-code host) ───────────────────────────────────────────

@test "install.sh with --hosts claude-code writes vendor SKILL.md" {
  # Seed CLAUDE.md so detect_hosts would pick it up; but we pass --hosts explicitly.
  run bash "${REPO_ROOT}/install.sh" \
    --non-interactive \
    --force \
    --target "${INSTALL_TARGET}" \
    --hosts claude-code
  [ "$status" -eq 0 ]
  [ -f ".claude/skills/idg-verify-incoming/SKILL.md" ]
  # Cleanup vendor copy
  rm -rf ".claude/skills/idg-verify-incoming"
}

@test "vendor SKILL.md content matches source when claude-code wired" {
  run bash "${REPO_ROOT}/install.sh" \
    --non-interactive \
    --force \
    --target "${INSTALL_TARGET}" \
    --hosts claude-code
  [ "$status" -eq 0 ]
  local vendor=".claude/skills/idg-verify-incoming/SKILL.md"
  [ -f "$vendor" ]
  run diff "${REPO_ROOT}/skills/verify-incoming.md" "$vendor"
  [ "$status" -eq 0 ]
  # Cleanup vendor copy
  rm -rf ".claude/skills/idg-verify-incoming"
}
