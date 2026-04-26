#!/usr/bin/env bash
set -euo pipefail

EIDOLON_NAME="idg"
EIDOLON_VERSION="1.1.4"
METHODOLOGY="IDG"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- defaults ---
TARGET="./.eidolons/${EIDOLON_NAME}"
HOSTS="auto"
FORCE=false
DRY_RUN=false
NON_INTERACTIVE=false
MANIFEST_ONLY=false
SHARED_DISPATCH=false

usage() {
  cat <<EOF
Usage: bash install.sh [OPTIONS]

Options:
  --target DIR            Target install dir (default: ${TARGET})
  --hosts LIST            claude-code,copilot,cursor,opencode,codex,all (default: auto)
  --shared-dispatch       Compose marker-bounded section in root AGENTS.md /
                          CLAUDE.md / .github/copilot-instructions.md (opt-in).
  --no-shared-dispatch    Skip root dispatch files (default). Per-vendor files
                          remain self-sufficient.
  --force                 Overwrite existing install
  --dry-run               Print actions, no writes
  --non-interactive       No prompts; fail on ambiguity (meta-installer mode)
  --manifest-only         Only emit install.manifest.json
  --version               Print Eidolon version
  -h, --help              Show help
EOF
}

# --- arg parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)               TARGET="$2"; shift 2 ;;
    --hosts)                HOSTS="$2"; shift 2 ;;
    --shared-dispatch)      SHARED_DISPATCH=true; shift ;;
    --no-shared-dispatch)   SHARED_DISPATCH=false; shift ;;
    --force)                FORCE=true; shift ;;
    --dry-run)              DRY_RUN=true; shift ;;
    --non-interactive)      NON_INTERACTIVE=true; shift ;;
    --manifest-only)        MANIFEST_ONLY=true; shift ;;
    --version)              echo "${EIDOLON_VERSION}"; exit 0 ;;
    -h|--help)              usage; exit 0 ;;
    *)                      echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# --- host detection ---
# EIIS v1.1 §4.5 — `.codex/` and root `AGENTS.md` are Codex signals; root
# `AGENTS.md` is co-owned with copilot and treated as a definitive Codex
# signal when no `.github/` is present.
detect_hosts() {
  local -a detected=()
  [[ -f "CLAUDE.md" || -d ".claude" ]]          && detected+=("claude-code")
  [[ -d ".github" ]]                             && detected+=("copilot")
  [[ -d ".cursor" || -f ".cursorrules" ]]        && detected+=("cursor")
  [[ -d ".opencode" ]]                           && detected+=("opencode")
  if [[ -d ".codex" ]]; then
    detected+=("codex")
  elif [[ -f "AGENTS.md" && ! -d ".github" ]]; then
    detected+=("codex")
  fi
  printf "%s\n" "${detected[@]+"${detected[@]}"}"
}

if [[ "$HOSTS" == "auto" ]]; then
  detected_list="$(detect_hosts | paste -sd, -)"
  HOSTS="${detected_list:-none}"
elif [[ "$HOSTS" == "all" ]]; then
  HOSTS="claude-code,copilot,cursor,opencode,codex"
fi

# Validate host list (EIIS v1.1 §2.1, §2.7).
IFS=',' read -ra _HOST_ARRAY <<< "$HOSTS"
for _h in "${_HOST_ARRAY[@]}"; do
  case "$_h" in
    claude-code|copilot|cursor|opencode|codex|raw|none|"") : ;;
    *) echo "Invalid --hosts value: $_h" >&2; exit 2 ;;
  esac
done
unset _HOST_ARRAY _h

hosts_contains() { [[ ",$HOSTS," == *",$1,"* ]]; }

# --- resolve target ---
if [[ "$DRY_RUN" != "true" ]]; then
  mkdir -p "$TARGET"
  TARGET="$(cd "$TARGET" && pwd)"
fi

# Relative form for @-pointers (strip absolute prefix or leading ./)
TARGET_REL="${TARGET#$(pwd)/}"
TARGET_REL="${TARGET_REL#./}"

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

# --- resolve spec source (support both legacy SCRIBE.md and canonical IDG.md) ---
if [[ -f "${SCRIPT_DIR}/IDG.md" ]]; then
  SRC_SPEC="${SCRIPT_DIR}/IDG.md"
else
  SRC_SPEC="${SCRIPT_DIR}/SCRIBE.md"
fi

# upsert_eidolon_block <file> <content>
#
# Owns a marker-bounded region in a composable dispatch file. Rewrites the
# body in place when markers already exist; appends a new block otherwise.
# Cleans up any pre-existing symlink at the target.
upsert_eidolon_block() {
  local dst="$1" content="$2"
  local start="<!-- eidolon:${EIDOLON_NAME} start -->"
  local end="<!-- eidolon:${EIDOLON_NAME} end -->"

  if [[ "$DRY_RUN" == "true" ]]; then
    local action="append"
    [[ -f "$dst" ]] && grep -qF "$start" "$dst" 2>/dev/null && action="rewrite"
    echo "[dry-run] ${action} eidolon:${EIDOLON_NAME} block in ${dst}"
    return
  fi

  mkdir -p "$(dirname "$dst")" 2>/dev/null || true
  [[ -L "$dst" ]] && rm -f "$dst"

  local content_file tmp
  content_file="$(mktemp)"
  printf '%s\n' "$content" > "$content_file"

  if [[ -f "$dst" ]] && grep -qF "$start" "$dst" 2>/dev/null; then
    tmp="$(mktemp)"
    awk -v start="$start" -v end="$end" -v cf="$content_file" '
      BEGIN { in_block = 0 }
      $0 == start {
        print start
        while ((getline line < cf) > 0) print line
        close(cf)
        in_block = 1
        next
      }
      $0 == end {
        print end
        in_block = 0
        next
      }
      !in_block { print }
    ' "$dst" > "$tmp"
    mv "$tmp" "$dst"
    echo "  rewrote eidolon:${EIDOLON_NAME} block in ${dst}"
  elif [[ -f "$dst" ]]; then
    { printf '\n%s\n' "$start"; cat "$content_file"; printf '%s\n' "$end"; } >> "$dst"
    echo "  appended eidolon:${EIDOLON_NAME} block to ${dst}"
  else
    { printf '%s\n' "$start"; cat "$content_file"; printf '%s\n' "$end"; } > "$dst"
    echo "  created ${dst} with eidolon:${EIDOLON_NAME} block"
  fi

  rm -f "$content_file"
}

if [[ "$MANIFEST_ONLY" != "true" ]]; then
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] Target: ${TARGET}"
    echo "[dry-run] Hosts:  ${HOSTS}"
    echo "[dry-run] Would write:"
    echo "  ${TARGET}/agent.md"
    echo "  ${TARGET}/IDG.md"
    echo "  ${TARGET}/DESIGN-RATIONALE.md"
    echo "  ${TARGET}/skills/composition/SKILL.md"
    echo "  ${TARGET}/skills/verification/SKILL.md"
    echo "  ${TARGET}/templates/session-chronicle.md"
    echo "  ${TARGET}/templates/adr.md"
    echo "  ${TARGET}/templates/runbook.md"
    echo "  ${TARGET}/templates/change-narrative.md"
    hosts_contains "claude-code" && echo "  CLAUDE.md (append @${TARGET_REL}/agent.md)"
    hosts_contains "claude-code" && echo "  .claude/agents/${EIDOLON_NAME}.md"
    hosts_contains "copilot"     && echo "  .github/copilot-instructions.md"
    hosts_contains "cursor"      && echo "  .cursor/rules/${EIDOLON_NAME}.mdc"
    hosts_contains "opencode"    && echo "  .opencode/agents/${EIDOLON_NAME}.md"
    hosts_contains "codex"       && echo "  AGENTS.md (eidolon:${EIDOLON_NAME} marker block)"
    hosts_contains "codex"       && echo "  .codex/agents/${EIDOLON_NAME}.md"
  else
    # Create directory structure
    mkdir -p \
      "${TARGET}/skills/composition" \
      "${TARGET}/skills/verification" \
      "${TARGET}/templates"

    # Copy agent files
    cp "${SCRIPT_DIR}/agent.md"                                   "${TARGET}/agent.md"
    cp "${SRC_SPEC}"                                              "${TARGET}/IDG.md"
    cp "${SCRIPT_DIR}/DESIGN-RATIONALE.md"                        "${TARGET}/DESIGN-RATIONALE.md"
    cp "${SCRIPT_DIR}/skills/composition/SKILL.md"                "${TARGET}/skills/composition/SKILL.md"
    cp "${SCRIPT_DIR}/skills/verification/SKILL.md"               "${TARGET}/skills/verification/SKILL.md"
    cp "${SCRIPT_DIR}/templates/session-chronicle.md"             "${TARGET}/templates/session-chronicle.md"
    cp "${SCRIPT_DIR}/templates/adr.md"                           "${TARGET}/templates/adr.md"
    cp "${SCRIPT_DIR}/templates/runbook.md"                       "${TARGET}/templates/runbook.md"
    cp "${SCRIPT_DIR}/templates/change-narrative.md"              "${TARGET}/templates/change-narrative.md"

    # --- shared composable block (opt-in via --shared-dispatch) ---
    SHARED_BLOCK="## ${METHODOLOGY} — Documentation synthesis (v${EIDOLON_VERSION})

Entry:     \`${TARGET_REL}/agent.md\`
Full spec: \`${TARGET_REL}/${METHODOLOGY}.md\`
Cycle:     I (Intake) → D (Draft) → G (Gate)

**P0 (non-negotiable):** synthesis from provided context only (no retrieval or code analysis); structural markers ([DECISION], [ACTION], [DISPUTED], [GAP]) required; CHT verification gate (Completeness / Helpfulness / Truthfulness) with one revision max; provenance-first (every claim traces to source session)."

    # --- per-skill vendor wiring helpers ---
    strip_frontmatter() {
      local f="$1"
      if [[ "$(head -1 "$f")" == "---" ]]; then
        awk 'NR==1 && /^---$/ {in_fm=1; next}
             in_fm && /^---$/ {in_fm=0; next}
             !in_fm {print}' "$f"
      else
        cat "$f"
      fi
    }
    extract_fm_field() {
      awk -v field="$2" '
        NR==1 && /^---$/ { in_fm=1; next }
        in_fm && /^---$/ { exit }
        in_fm { p=index($0, field ":"); if (p==1) { sub("^" field ":[[:space:]]*", ""); print; exit } }
      ' "$1"
    }
    wire_skill() {
      local src_dir="$1" skill_name="$2"
      local src_skill="${src_dir}/SKILL.md"
      [[ -f "$src_skill" ]] || return
      local description
      description="$(extract_fm_field "$src_skill" "description")"
      [[ -z "$description" ]] && description="${skill_name}"

      if hosts_contains "claude-code"; then
        local dst_dir=".claude/skills/${skill_name}"
        rm -rf "$dst_dir"
        mkdir -p "$dst_dir"
        cp -R "${src_dir}/." "${dst_dir}/"
      fi
      if hosts_contains "copilot"; then
        mkdir -p ".github/instructions"
        {
          echo "---"
          echo "applyTo: \"**\""
          echo "description: \"${description}\""
          echo "---"
          strip_frontmatter "$src_skill"
        } > ".github/instructions/${skill_name}.instructions.md"
      fi
      if hosts_contains "cursor"; then
        mkdir -p ".cursor/rules"
        {
          echo "---"
          echo "description: \"${description}\""
          echo "alwaysApply: false"
          echo "---"
          strip_frontmatter "$src_skill"
        } > ".cursor/rules/${skill_name}.mdc"
      fi
    }

    # Emit per-skill vendor files for every skill.
    for skill in composition verification; do
      wire_skill "${SCRIPT_DIR}/skills/${skill}" "${EIDOLON_NAME}-${skill}"
    done

    # --- host dispatch wiring ---
    if hosts_contains "claude-code"; then
      [[ "$SHARED_DISPATCH" == "true" ]] && upsert_eidolon_block "CLAUDE.md" "$SHARED_BLOCK"

      # Subagent dispatch — always written when claude-code wired.
      mkdir -p ".claude/agents"
      if [[ ! -f ".claude/agents/${EIDOLON_NAME}.md" || "$FORCE" == "true" ]]; then
        cat > ".claude/agents/${EIDOLON_NAME}.md" <<AGENT
---
name: ${EIDOLON_NAME}
description: "Documentation synthesis — structured markers, CHT verification, provenance-first."
when_to_use: "After APIVR-Δ (or an equivalent implementation session) produces a session log, delta history, or completion report and you need it chronicled as an ADR, runbook, or change-narrative."
tools: Read, Grep, Glob, Write
methodology: ${METHODOLOGY}
methodology_version: "${EIDOLON_VERSION%.*}"
role: Scriber — documentation synthesis with provenance
handoffs: []
---

${METHODOLOGY} runs the I→D→G cycle. Given session artifacts, it produces
structured documentation (chronicle, ADR, runbook, change-narrative) with
markers that verify provenance back to the source session.

See \`${TARGET_REL}/agent.md\` for P0 rules and
\`${TARGET_REL}/${METHODOLOGY}.md\` for the full specification. Skills load on
demand — see \`${TARGET_REL}/skills/\`.
AGENT
      fi
    fi

    if hosts_contains "copilot"; then
      [[ "$SHARED_DISPATCH" == "true" ]] && upsert_eidolon_block ".github/copilot-instructions.md" "$SHARED_BLOCK"
    fi

    if hosts_contains "cursor"; then
      # Drop the legacy methodology-level rule — per-skill rules are canonical now.
      [[ -f ".cursor/rules/${EIDOLON_NAME}.mdc" && "$FORCE" == "true" ]] && rm -f ".cursor/rules/${EIDOLON_NAME}.mdc"
    fi

    if hosts_contains "opencode"; then
      mkdir -p ".opencode/agents"
      if [[ ! -f ".opencode/agents/${EIDOLON_NAME}.md" || "$FORCE" == "true" ]]; then
        printf "# %s — %s\n\nSee \`%s/agent.md\` for the %s methodology entry point.\n" \
          "${METHODOLOGY}" "${EIDOLON_NAME}" "${TARGET_REL}" "${METHODOLOGY}" \
          > ".opencode/agents/${EIDOLON_NAME}.md"
      fi
    fi

    # Codex (EIIS v1.1 §4.5). Required: `.codex/agents/<name>.md` with YAML
    # frontmatter (`name`, `description`); SHOULD point at the methodology
    # entry. Body mirrors the Claude subagent prompt for parity (§4.5.3.3
    # allows divergence; we choose to mirror).
    if hosts_contains "codex"; then
      mkdir -p ".codex/agents"
      if [[ ! -f ".codex/agents/${EIDOLON_NAME}.md" || "$FORCE" == "true" ]]; then
        cat > ".codex/agents/${EIDOLON_NAME}.md" <<CODEX_AGENT
---
name: ${EIDOLON_NAME}
description: Documentation synthesis subagent — structured markers, CHT verification, provenance-first chronicle/ADR/runbook output from session artifacts.
---

# ${METHODOLOGY} — Codex subagent

${METHODOLOGY} runs the I→D→G cycle. Given session artifacts, it produces
structured documentation (chronicle, ADR, runbook, change-narrative) with
markers that verify provenance back to the source session.

When Codex delegates to this subagent, treat the methodology in
\`${TARGET_REL}/agent.md\` as authoritative. The full ruleset lives in
\`${TARGET_REL}/${METHODOLOGY}.md\`. Skills load on demand — see
\`${TARGET_REL}/skills/\`.

## P0 (non-negotiable)

- Synthesize from provided context only — no retrieval, no code analysis.
- Apply structural markers: \`[DECISION]\`, \`[ACTION]\`, \`[DISPUTED]\`, \`[GAP]\`.
- One CHT verification gate (Completeness / Helpfulness / Truthfulness),
  one revision max, then deliver with flags.
- Provenance-first: every claim traces to its source session.
- Do not produce code.

## When to use

After APIVR-Δ (or an equivalent implementation session) produces a session
log, delta history, or completion report and you need it chronicled as an
ADR, runbook, or change-narrative.
CODEX_AGENT
      fi
    fi

    # Root AGENTS.md is co-owned by `copilot` and `codex` per EIIS v1.1
    # §4.1.0. Write the marker block when --shared-dispatch is set OR when
    # codex is wired (Codex's primary instruction surface).
    if [[ "$SHARED_DISPATCH" == "true" ]] || hosts_contains "codex"; then
      upsert_eidolon_block "AGENTS.md" "$SHARED_BLOCK"
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
    sha_spec=$(sha256_file "${TARGET}/IDG.md")
    sha_dr=$(sha256_file "${TARGET}/DESIGN-RATIONALE.md")
    sha_comp=$(sha256_file "${TARGET}/skills/composition/SKILL.md")
    sha_verif=$(sha256_file "${TARGET}/skills/verification/SKILL.md")
    sha_chron=$(sha256_file "${TARGET}/templates/session-chronicle.md")
    sha_adr=$(sha256_file "${TARGET}/templates/adr.md")
    sha_run=$(sha256_file "${TARGET}/templates/runbook.md")
    sha_cn=$(sha256_file "${TARGET}/templates/change-narrative.md")

    files_entries=""
    files_append() {
      if [[ -z "$files_entries" ]]; then
        files_entries="    $1"
      else
        files_entries="${files_entries},
    $1"
      fi
    }
    files_append "{\"path\": \"agent.md\",                       \"sha256\": \"${sha_agent}\", \"role\": \"entry-point\", \"mode\": \"created\"}"
    files_append "{\"path\": \"IDG.md\",                         \"sha256\": \"${sha_spec}\",  \"role\": \"spec\",        \"mode\": \"created\"}"
    files_append "{\"path\": \"DESIGN-RATIONALE.md\",            \"sha256\": \"${sha_dr}\",    \"role\": \"other\",       \"mode\": \"created\"}"
    files_append "{\"path\": \"skills/composition/SKILL.md\",    \"sha256\": \"${sha_comp}\",  \"role\": \"skill\",       \"mode\": \"created\"}"
    files_append "{\"path\": \"skills/verification/SKILL.md\",   \"sha256\": \"${sha_verif}\", \"role\": \"skill\",       \"mode\": \"created\"}"
    files_append "{\"path\": \"templates/session-chronicle.md\", \"sha256\": \"${sha_chron}\", \"role\": \"template\",    \"mode\": \"created\"}"
    files_append "{\"path\": \"templates/adr.md\",               \"sha256\": \"${sha_adr}\",   \"role\": \"template\",    \"mode\": \"created\"}"
    files_append "{\"path\": \"templates/runbook.md\",           \"sha256\": \"${sha_run}\",   \"role\": \"template\",    \"mode\": \"created\"}"
    files_append "{\"path\": \"templates/change-narrative.md\",  \"sha256\": \"${sha_cn}\",    \"role\": \"template\",    \"mode\": \"created\"}"

    # Codex artefacts (EIIS v1.1 §4.5.5).
    if hosts_contains "codex"; then
      if [[ -f ".codex/agents/${EIDOLON_NAME}.md" ]]; then
        sha_codex=$(sha256_file ".codex/agents/${EIDOLON_NAME}.md")
        files_append "{\"path\": \".codex/agents/${EIDOLON_NAME}.md\", \"sha256\": \"${sha_codex}\", \"role\": \"dispatch\", \"mode\": \"created\"}"
      fi
      if [[ -f "AGENTS.md" ]]; then
        sha_agents=$(sha256_file "AGENTS.md")
        files_append "{\"path\": \"AGENTS.md\", \"sha256\": \"${sha_agents}\", \"role\": \"dispatch\"}"
      fi
    fi

    files_json="[
${files_entries}
  ]"
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
  echo "${METHODOLOGY} installed to: ${TARGET}"
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
echo "  \"Using the ${METHODOLOGY} methodology, synthesize an ADR from: we chose PostgreSQL over MySQL for its JSONB support. Include provenance metadata.\""
