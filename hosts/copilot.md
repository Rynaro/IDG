# Wiring Scribe into GitHub Copilot

## 1. Install

```bash
bash install.sh --target ./.eidolons/idg --hosts copilot
```

The installer creates or appends to `.github/copilot-instructions.md`.

## 2. Config

The installed dispatch entry in `.github/copilot-instructions.md`:

```markdown
## Scribe Agent
See `.eidolons/idg/agent.md` for the SCRIBE methodology entry point.
```

Copilot Chat loads `.github/copilot-instructions.md` as custom instructions automatically in repositories where it is present.

### For Copilot in VS Code / JetBrains

If using a workspace-level instructions file, also verify the path in `.vscode/settings.json`:

```json
{
  "github.copilot.chat.codeGeneration.instructions": [
    { "file": ".github/copilot-instructions.md" }
  ]
}
```

## 3. Verify

In Copilot Chat:

```
"Follow the Scribe SCRIBE cycle to produce an ADR skeleton for: choosing Redis over Memcached for session caching."
```

Expected: Copilot applies the IDG methodology, requests missing context if needed, and produces an ADR with structural markers.

## 4. Troubleshooting

**Copilot not following Scribe methodology**
- Verify `.github/copilot-instructions.md` is committed and present in the repo root's `.github/` dir
- In VS Code, confirm the instructions file is enabled in settings

**Scribe producing hallucinated content**
- Copilot does not enforce the "write from provided context only" rule automatically — you must explicitly provide context in the chat
