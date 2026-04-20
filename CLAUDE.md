# Claude Code — Scribe

Load order for this repository:

1. `agent.md` — entry point, always loaded (≤ 1,000 tokens)
2. `SCRIBE.md` — full methodology specification
3. `skills/<phase>/SKILL.md` — on-demand per phase
4. `templates/<artifact>.md` — on-demand per output type

## Consumer Project Usage

After installing this Eidolon into a consumer project (`bash install.sh`), Claude Code will find the installed agent at `agents/scribe/agent.md`.

Add to the consumer project's `CLAUDE.md`:

```
@agents/scribe/agent.md
```
