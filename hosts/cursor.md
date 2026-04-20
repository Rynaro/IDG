# Wiring Scribe into Cursor

## 1. Install

```bash
bash install.sh --target ./agents/scribe --hosts cursor
```

The installer creates `.cursor/rules/scribe.mdc`.

## 2. Config

The installed rule file at `.cursor/rules/scribe.mdc`:

```markdown
---
alwaysApply: false
---
# SCRIBE — scribe

See `agents/scribe/agent.md` for the SCRIBE methodology entry point.
```

`alwaysApply: false` means the rule loads on-demand when you reference it. To always load it, change to `alwaysApply: true` (adds ~800 tokens to every session).

### Alternative: `.cursorrules`

For older Cursor versions, add to `.cursorrules`:

```
agents/scribe/agent.md
```

## 3. Verify

In Cursor Composer:

```
"@scribe — produce a runbook for deploying this service using the SCRIBE methodology."
```

Or reference the rule file directly:

```
"Using the scribe rule, write a change-narrative for this PR."
```

## 4. Troubleshooting

**Rule not appearing in Cursor's rule list**
- Verify `.cursor/rules/scribe.mdc` exists and has valid frontmatter
- Restart Cursor after adding new rule files

**Skills/templates not loading**
- Confirm `agents/scribe/skills/` and `agents/scribe/templates/` are present
- Cursor does not auto-load skill files — the Scribe requests them; provide the content when asked
