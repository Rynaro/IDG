# Installing Scribe

Scribe installs into any project as a self-contained agent directory.

## Prerequisites

- `bash` 4.0+ (macOS ships with bash 3; use `brew install bash` or prefix with `env bash`)
- `git` (for clone/submodule methods)

## Quick Install

```bash
git clone https://github.com/Rynaro/scribe
cd your-project
bash ../scribe/install.sh
```

Default target: `./.eidolons/idg`. Then wire your AI tooling (see host sections below).

## Options

```
bash install.sh [OPTIONS]

  --target DIR          Target install dir (default: ./.eidolons/idg)
  --hosts LIST          claude-code,copilot,cursor,opencode,all (default: auto)
  --force               Overwrite existing install
  --dry-run             Print actions, no writes
  --non-interactive     No prompts; fail on ambiguity (meta-installer mode)
  --manifest-only       Only emit install.manifest.json
  --version             Print Scribe version
  -h, --help            Show help
```

---

## Claude Code

**Install:**
```bash
bash install.sh --target ./.eidolons/idg --hosts claude-code
```

**Wire:**
Add to your project's `CLAUDE.md`:
```
@.eidolons/idg/agent.md
```

Or reference inline:
```
@.eidolons/idg/agent.md
```

**Verify:**
Open a session and run: `"Using Scribe, write a one-sentence ADR for choosing PostgreSQL over MySQL."`

---

## GitHub Copilot

**Install:**
```bash
bash install.sh --target ./.eidolons/idg --hosts copilot
```

**Wire:**
The installer appends to or creates `.github/copilot-instructions.md`. Verify it contains:
```markdown
See `.eidolons/idg/agent.md` for the SCRIBE methodology entry point.
```

**Verify:**
Open a Copilot Chat and ask: `"Follow the Scribe SCRIBE cycle to produce an ADR skeleton."`

---

## Cursor

**Install:**
```bash
bash install.sh --target ./.eidolons/idg --hosts cursor
```

**Wire:**
The installer creates `.cursor/rules/idg.mdc`. Activate it in Cursor's rules panel or reference it from `.cursorrules`.

**Verify:**
Open Cursor composer: `"Using the scribe agent, draft a runbook for deploying this service."`

---

## OpenCode

**Install:**
```bash
bash install.sh --target ./.eidolons/idg --hosts opencode
```

**Wire:**
The installer creates `.opencode/.eidolons/idg.md`. OpenCode picks this up automatically.

**Verify:**
In an OpenCode session: `"Load the scribe agent and produce a change-narrative for this PR."`

---

## All Hosts at Once

```bash
bash install.sh --hosts all
```

---

## Raw API / Any LLM

Copy `.eidolons/idg/agent.md` (compact, ≤ 1,000 tokens) as the system prompt. Load `.eidolons/idg/SCRIBE.md` for the full methodology. Load skills and templates on-demand.

---

## Git Submodule (alternative)

```bash
git submodule add https://github.com/Rynaro/scribe .eidolons/idg
```

All internal paths are relative. Works from any location.

---

## Uninstall

```bash
rm -rf .eidolons/idg
```

Then remove the dispatch lines added to `CLAUDE.md`, `.github/copilot-instructions.md`, etc.
