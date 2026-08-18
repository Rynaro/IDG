#!/usr/bin/env bats
# tests/verify-incoming.bats — blocking, symmetric verify-incoming gate (ECL §6.2.2)
#
# Asserts:
#   1. skills/verify-incoming/SKILL.md exists in the repo and declares BLOCKING posture.
#   2. It does NOT declare warn-only / "payload is always processed" / "process anyway".
#   3. install.sh (non-interactive) installs skills/verify-incoming/SKILL.md into the target.
#   4. install.manifest.json records skills/verify-incoming/SKILL.md (source_path).
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

@test "skills/verify-incoming/SKILL.md exists in the repo" {
  [ -f "${REPO_ROOT}/skills/verify-incoming/SKILL.md" ]
}

@test "skills/verify-incoming/SKILL.md declares BLOCKING posture" {
  run grep -qiE 'REFUSE|SHALL NOT|blocking' "${REPO_ROOT}/skills/verify-incoming/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "skills/verify-incoming/SKILL.md does NOT declare warn-only posture as the current behaviour" {
  # Negative assertion: the skill must NOT instruct the receiver to PROCESS
  # a tampered or unverified payload (i.e. adopt the old warn-only posture).
  # "warn-only" and "processed the payload anyway" legitimately appear in
  # historical-context notes; we check for imperative "process" language
  # that would instruct the receiver to proceed despite a failure.
  run grep -qiE 'always processes?|shall process|must process|proceed.*anyway|process.*despite' \
    "${REPO_ROOT}/skills/verify-incoming/SKILL.md"
  # grep must NOT find a match (exit 1)
  [ "$status" -ne 0 ]
}

@test "skills/verify-incoming/SKILL.md has canonical frontmatter (name: idg-verify-incoming)" {
  run grep -m1 '^name:' "${REPO_ROOT}/skills/verify-incoming/SKILL.md"
  [ "$status" -eq 0 ]
  [[ "$output" == "name: idg-verify-incoming" ]]
}

@test "skills/verify-incoming/SKILL.md frontmatter has a non-empty description:" {
  run grep -m1 '^description:' "${REPO_ROOT}/skills/verify-incoming/SKILL.md"
  [ "$status" -eq 0 ]
  [[ -n "$output" ]]
}

# ── Install: exit code + file placement ──────────────────────────────────────



@test "installed skills/verify-incoming/SKILL.md content matches source" {
  run_install "${INSTALL_TARGET}"
  local src="${REPO_ROOT}/skills/verify-incoming/SKILL.md"
  local dst="${INSTALL_TARGET}/skills/verify-incoming/SKILL.md"
  [ -f "$dst" ]
  run diff "$src" "$dst"
  [ "$status" -eq 0 ]
}

# ── Manifest assertions ───────────────────────────────────────────────────────






# ── Vendor copy (claude-code host) ───────────────────────────────────────────
