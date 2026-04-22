# Wiring Scribe into OpenCode

## 1. Install

```bash
bash install.sh --target ./.eidolons/idg --hosts opencode
```

The installer creates `.opencode/.eidolons/idg.md`.

## 2. Config

The installed agent descriptor at `.opencode/.eidolons/idg.md`:

```markdown
# SCRIBE — scribe

See `.eidolons/idg/agent.md` for the SCRIBE methodology entry point.
```

OpenCode picks up `.opencode/agents/*.md` files automatically and makes them available as named agents in the session.

## 3. Verify

In an OpenCode session:

```
"/agent scribe — produce an ADR for: choosing PostgreSQL over MySQL for JSONB support."
```

Expected: OpenCode loads the Scribe agent from `.opencode/.eidolons/idg.md`, which points to `.eidolons/idg/agent.md`. Scribe runs the IDG cycle and delivers an ADR with provenance metadata.

## 4. Troubleshooting

**Agent not visible in OpenCode**
- Verify `.opencode/.eidolons/idg.md` is present
- Restart the OpenCode session after adding the agent file

**Scribe not finding skill files**
- The `.eidolons/idg/` directory must be at the project root
- Paths in OpenCode are resolved relative to the working directory when the session started
