# Wiring Scribe into Claude Code

## 1. Install

```bash
bash install.sh --target ./.eidolons/idg --hosts claude-code
```

Or install all hosts at once:

```bash
bash install.sh --hosts all
```

## 2. Config

Add to your consumer project's `CLAUDE.md`:

```markdown
@.eidolons/idg/agent.md
```

Claude Code loads `agent.md` into every session. Skills and templates load on-demand when the Scribe requests them.

### Frontmatter (agent.md)

```yaml
---
name: scribe
version: 1.9.0
methodology: IDG
role: documentation-synthesis — transforms context into structured, grounded, actionable documents
---
```

## 3. Verify

Open a Claude Code session in your project and run:

```
"Using Scribe, write an ADR for choosing PostgreSQL over MySQL for its JSONB support. Include provenance metadata."
```

Expected: Scribe loads `skills/composition.md`, produces an ADR with `[DECISION]` marker, and delivers a provenance block with CHT scores.

## 4. Troubleshooting

**Scribe not responding to @.eidolons/idg/agent.md**
- Verify `.eidolons/idg/agent.md` exists: `ls .eidolons/idg/agent.md`
- Verify the `@` path in `CLAUDE.md` is correct relative to project root

**Scribe loading full SPEC.md on every invocation**
- This is intentional only if explicitly referenced. If agent.md is the pointer, only ~800 tokens load at start.

**Skills not found**
- Verify `.eidolons/idg/skills/composition.md` and `.eidolons/idg/skills/verification.md` exist
- Check that paths are relative (not absolute) in the installed directory
