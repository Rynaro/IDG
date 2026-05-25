# Claude Code — Scribe

Load order for this repository:

1. `agent.md` — entry point, always loaded (≤ 1,000 tokens)
2. `SPEC.md` — full methodology specification
3. `skills/<phase>.md` — on-demand per phase (flat layout)
4. `templates/<artifact>.md` — on-demand per output type
5. `schemas/ecl-envelope.v1.json` — load on demand during Intake when an `*.envelope.json` sidecar is detected.

## Consumer Project Usage

After installing this Eidolon into a consumer project (`bash install.sh`), Claude Code will find the installed agent at `.eidolons/idg/agent.md`.

Add to the consumer project's `CLAUDE.md`:

```
@.eidolons/idg/agent.md
```
