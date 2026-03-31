#!/usr/bin/env bash
set -euo pipefail

# Scribe install script
# Copies the Scribe agent into a target directory in your project.
#
# Usage:
#   bash install.sh [target-directory]
#
# Default target: ./agents/scribe

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_REL="${1:-./agents/scribe}"

# Resolve target to absolute path (create it first so realpath/cd works)
mkdir -p "$TARGET_REL"
TARGET="$(cd "$TARGET_REL" && pwd)"

# Check for existing installation
if [[ -f "$TARGET/SCRIBE.md" ]]; then
  EXISTING_VERSION="$(grep -m1 'version:' "$TARGET/SCRIBE.md" | awk '{print $2}' || echo "unknown")"
  echo "Existing Scribe installation found at: $TARGET"
  echo "Installed version: $EXISTING_VERSION"
  read -rp "Overwrite? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

# Create directory structure
mkdir -p \
  "$TARGET/skills/composition" \
  "$TARGET/skills/verification" \
  "$TARGET/templates"

# Copy agent files (exclude source repo artifacts)
cp "$SCRIPT_DIR/SCRIBE.md"                                "$TARGET/SCRIBE.md"
cp "$SCRIPT_DIR/DESIGN-RATIONALE.md"                      "$TARGET/DESIGN-RATIONALE.md"
cp "$SCRIPT_DIR/skills/composition/SKILL.md"              "$TARGET/skills/composition/SKILL.md"
cp "$SCRIPT_DIR/skills/verification/SKILL.md"             "$TARGET/skills/verification/SKILL.md"
cp "$SCRIPT_DIR/templates/session-chronicle.md"           "$TARGET/templates/session-chronicle.md"
cp "$SCRIPT_DIR/templates/adr.md"                         "$TARGET/templates/adr.md"
cp "$SCRIPT_DIR/templates/runbook.md"                     "$TARGET/templates/runbook.md"
cp "$SCRIPT_DIR/templates/change-narrative.md"            "$TARGET/templates/change-narrative.md"

echo ""
echo "Scribe installed to: $TARGET"
echo ""
echo "Next steps depend on your AI tooling:"
echo ""
echo "  Claude Code"
echo "    Add to CLAUDE.md or reference directly:"
echo "    @$TARGET/SCRIBE.md"
echo ""
echo "  Cursor"
echo "    Add to .cursorrules or custom instructions:"
echo "    $TARGET/SCRIBE.md"
echo ""
echo "  Windsurf"
echo "    Add to .windsurfrules:"
echo "    $TARGET/SCRIBE.md"
echo ""
echo "  Raw API / any LLM"
echo "    Load as system prompt:"
echo "    $TARGET/SCRIBE.md"
echo ""
echo "Skills and templates load on-demand from the same directory."
echo "Do not pre-load them — SCRIBE.md handles this."
echo ""
