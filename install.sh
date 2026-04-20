#!/usr/bin/env bash
set -euo pipefail

EIDOLON_NAME="scribe"
EIDOLON_VERSION="1.1.0"
METHODOLOGY="SCRIBE"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- defaults ---
TARGET="./agents/${EIDOLON_NAME}"
HOSTS="auto"
FORCE=false
DRY_RUN=false
NON_INTERACTIVE=false
MANIFEST_ONLY=false

usage() {
  cat <<EOF
Usage: bash install.sh [OPTIONS]

Options:
  --target DIR          Target install dir (default: ./agents/${EIDOLON_NAME})
  --hosts LIST          claude-code,copilot,cursor,opencode,all (default: auto)
  --force               Overwrite existing install
  --dry-run             Print actions, no writes
  --non-interactive     No prompts; fail on ambiguity (meta-installer mode)
  --manifest-only       Only emit install.manifest.json
  --version             Print Eidolon version
  -h, --help            Show help
EOF
}

# --- arg parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)           TARGET="$2"; shift 2 ;;
    --hosts)            HOSTS="$2"; shift 2 ;;
    --force)            FORCE=true; shift ;;
    --dry-run)          DRY_RUN=true; shift ;;
    --non-interactive)  NON_INTERACTIVE=true; shift ;;
    --manifest-only)    MANIFEST_ONLY=true; shift ;;
    --version)          echo "${EIDOLON_VERSION}"; exit 0 ;;
    -h|--help)          usage; exit 0 ;;
    *)                  echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# --- host detection ---
detect_hosts() {
  local -a detected=()
  [[ -f "CLAUDE.md" || -d ".claude" ]]          && detected+=("claude-code")
  [[ -d ".github" ]]                             && detected+=("copilot")
  [[ -d ".cursor" || -f ".cursorrules" ]]        && detected+=("cursor")
  [[ -d ".opencode" ]]                           && detected+=("opencode")
  printf "%s\n" "${detected[@]+"${detected[@]}"}"
}

if [[ "$HOSTS" == "auto" ]]; then
  detected_list="$(detect_hosts | paste -sd, -)"
  HOSTS="${detected_list:-none}"
elif [[ "$HOSTS" == "all" ]]; then
  HOSTS="claude-code,copilot,cursor,opencode"
fi

hosts_contains() { [[ ",$HOSTS," == *",$1,"* ]]; }

# --- resolve target ---
if [[ "$DRY_RUN" != "true" ]]; then
  mkdir -p "$TARGET"
  TARGET="$(cd "$TARGET" && pwd)"
fi

# --- idempotency check ---
if [[ -f "${TARGET}/install.manifest.json" && "$FORCE" != "true" ]]; then
  EXISTING_VER="$(grep -o '"version":"[^"]*"' "${TARGET}/install.manifest.json" 2>/dev/null | cut -d'"' -f4 || echo "unknown")"
  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    echo "Existing install v${EXISTING_VER} at ${TARGET}. Pass --force to overwrite." >&2
    exit 3
  fi
  read -rp "Existing install v${EXISTING_VER} at ${TARGET}. Overwrite? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

# --- portable sha256 helper ---
sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d' ' -f1
  else
    openssl dgst -sha256 -hex "$1" | awk '{print $2}'
  fi
}

if [[ "$MANIFEST_ONLY" != "true" ]]; then
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] Target: ${TARGET}"
    echo "[dry-run] Hosts:  ${HOSTS}"
    echo "[dry-run] Would write:"
    echo "  ${TARGET}/agent.md"
    echo "  ${TARGET}/SCRIBE.md"
    echo "  ${TARGET}/DESIGN-RATIONALE.md"
    echo "  ${TARGET}/skills/composition/SKILL.md"
    echo "  ${TARGET}/skills/verification/SKILL.md"
    echo "  ${TARGET}/templates/session-chronicle.md"
    echo "  ${TARGET}/templates/adr.md"
    echo "  ${TARGET}/templates/runbook.md"
    echo "  ${TARGET}/templates/change-narrative.md"
    hosts_contains "claude-code" && echo "  CLAUDE.md (append @agents/${EIDOLON_NAME}/agent.md)"
    hosts_contains "copilot"     && echo "  .github/copilot-instructions.md"
    hosts_contains "cursor"      && echo "  .cursor/rules/${EIDOLON_NAME}.mdc"
    hosts_contains "opencode"    && echo "  .opencode/agents/${EIDOLON_NAME}.md"
  else
    # Create directory structure
    mkdir -p \
      "${TARGET}/skills/composition" \
      "${TARGET}/skills/verification" \
      "${TARGET}/templates"

    # Copy agent files (preserve existing copy-files logic)
    cp "${SCRIPT_DIR}/agent.md"                                   "${TARGET}/agent.md"
    cp "${SCRIPT_DIR}/SCRIBE.md"                                  "${TARGET}/SCRIBE.md"
    cp "${SCRIPT_DIR}/DESIGN-RATIONALE.md"                        "${TARGET}/DESIGN-RATIONALE.md"
    cp "${SCRIPT_DIR}/skills/composition/SKILL.md"                "${TARGET}/skills/composition/SKILL.md"
    cp "${SCRIPT_DIR}/skills/verification/SKILL.md"               "${TARGET}/skills/verification/SKILL.md"
    cp "${SCRIPT_DIR}/templates/session-chronicle.md"             "${TARGET}/templates/session-chronicle.md"
    cp "${SCRIPT_DIR}/templates/adr.md"                           "${TARGET}/templates/adr.md"
    cp "${SCRIPT_DIR}/templates/runbook.md"                       "${TARGET}/templates/runbook.md"
    cp "${SCRIPT_DIR}/templates/change-narrative.md"              "${TARGET}/templates/change-narrative.md"

    # --- host dispatch wiring ---
    if hosts_contains "claude-code"; then
      if [[ -f "CLAUDE.md" ]]; then
        if ! grep -q "agents/${EIDOLON_NAME}/agent.md" "CLAUDE.md" 2>/dev/null; then
          printf "\n@agents/%s/agent.md\n" "${EIDOLON_NAME}" >> "CLAUDE.md"
        fi
      else
        printf "@agents/%s/agent.md\n" "${EIDOLON_NAME}" > "CLAUDE.md"
      fi
    fi

    if hosts_contains "copilot"; then
      mkdir -p ".github"
      if [[ -f ".github/copilot-instructions.md" ]]; then
        if ! grep -q "${EIDOLON_NAME}" ".github/copilot-instructions.md" 2>/dev/null; then
          printf "\n## %s Agent\nSee \`agents/%s/agent.md\` for the %s methodology.\n" \
            "${EIDOLON_NAME^}" "${EIDOLON_NAME}" "${METHODOLOGY}" >> ".github/copilot-instructions.md"
        fi
      else
        printf "# %s Agent — %s\n\nSee \`agents/%s/agent.md\` for the %s methodology entry point.\n" \
          "${METHODOLOGY}" "${EIDOLON_NAME}" "${EIDOLON_NAME}" "${METHODOLOGY}" > ".github/copilot-instructions.md"
      fi
    fi

    if hosts_contains "cursor"; then
      mkdir -p ".cursor/rules"
      cat > ".cursor/rules/${EIDOLON_NAME}.mdc" <<CURSOR_EOF
---
alwaysApply: false
---
# ${METHODOLOGY} — ${EIDOLON_NAME}

See \`agents/${EIDOLON_NAME}/agent.md\` for the ${METHODOLOGY} methodology entry point.
CURSOR_EOF
    fi

    if hosts_contains "opencode"; then
      mkdir -p ".opencode/agents"
      printf "# %s — %s\n\nSee \`agents/%s/agent.md\` for the %s methodology entry point.\n" \
        "${METHODOLOGY}" "${EIDOLON_NAME}" "${EIDOLON_NAME}" "${METHODOLOGY}" \
        > ".opencode/agents/${EIDOLON_NAME}.md"
    fi
  fi
fi

# --- emit manifest ---
if [[ "$DRY_RUN" != "true" ]]; then
  INSTALLED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  # Build hosts_wired JSON array
  hosts_json="["
  first=true
  IFS=',' read -ra host_list <<< "$HOSTS"
  for h in "${host_list[@]}"; do
    [[ "$h" == "none" ]] && continue
    [[ "$first" == "true" ]] && first=false || hosts_json+=", "
    hosts_json+="\"$h\""
  done
  hosts_json+="]"

  # Build files_written JSON array
  files_json="[]"
  if [[ "$MANIFEST_ONLY" != "true" && -f "${TARGET}/agent.md" ]]; then
    sha_agent=$(sha256_file "${TARGET}/agent.md")
    sha_scribe=$(sha256_file "${TARGET}/SCRIBE.md")
    sha_dr=$(sha256_file "${TARGET}/DESIGN-RATIONALE.md")
    sha_comp=$(sha256_file "${TARGET}/skills/composition/SKILL.md")
    sha_verif=$(sha256_file "${TARGET}/skills/verification/SKILL.md")
    sha_chron=$(sha256_file "${TARGET}/templates/session-chronicle.md")
    sha_adr=$(sha256_file "${TARGET}/templates/adr.md")
    sha_run=$(sha256_file "${TARGET}/templates/runbook.md")
    sha_cn=$(sha256_file "${TARGET}/templates/change-narrative.md")
    files_json=$(cat <<FILES_EOF
[
    {"path": "agent.md",                       "sha256": "${sha_agent}",  "role": "entry-point", "mode": "created"},
    {"path": "SCRIBE.md",                      "sha256": "${sha_scribe}", "role": "spec",        "mode": "created"},
    {"path": "DESIGN-RATIONALE.md",            "sha256": "${sha_dr}",    "role": "other",       "mode": "created"},
    {"path": "skills/composition/SKILL.md",    "sha256": "${sha_comp}",  "role": "skill",       "mode": "created"},
    {"path": "skills/verification/SKILL.md",   "sha256": "${sha_verif}", "role": "skill",       "mode": "created"},
    {"path": "templates/session-chronicle.md", "sha256": "${sha_chron}", "role": "template",    "mode": "created"},
    {"path": "templates/adr.md",               "sha256": "${sha_adr}",   "role": "template",    "mode": "created"},
    {"path": "templates/runbook.md",           "sha256": "${sha_run}",   "role": "template",    "mode": "created"},
    {"path": "templates/change-narrative.md",  "sha256": "${sha_cn}",    "role": "template",    "mode": "created"}
  ]
FILES_EOF
)
  fi

  AGENT_TOKENS=$(wc -w < "${TARGET}/agent.md" | awk '{printf "%d", $1/0.75}')

  cat > "${TARGET}/install.manifest.json" <<MANIFEST_EOF
{
  "eidolon": "${EIDOLON_NAME}",
  "version": "${EIDOLON_VERSION}",
  "methodology": "${METHODOLOGY}",
  "installed_at": "${INSTALLED_AT}",
  "target": "${TARGET}",
  "hosts_wired": ${hosts_json},
  "files_written": ${files_json},
  "handoffs_declared": {
    "upstream": [],
    "downstream": []
  },
  "token_budget": {
    "entry": ${AGENT_TOKENS},
    "working_set_target": 1000
  },
  "security": {
    "reads_repo": false,
    "reads_network": false,
    "writes_repo": false,
    "persists": []
  }
}
MANIFEST_EOF

  echo ""
  echo "Scribe installed to: ${TARGET}"
  echo "Hosts wired: ${HOSTS}"
  echo ""
  echo "✓ agent.md: ${AGENT_TOKENS} tokens (budget: ≤1000)"

  if [[ "${AGENT_TOKENS}" -gt 1000 && "$NON_INTERACTIVE" == "true" ]]; then
    echo "ERROR: agent.md exceeds 1000-token budget." >&2
    exit 4
  fi
fi

# --- smoke test banner ---
echo ""
echo "Smoke test:"
echo "  \"Using the Scribe SCRIBE methodology, synthesize an ADR from: we chose PostgreSQL over MySQL for its JSONB support. Include provenance metadata.\""
