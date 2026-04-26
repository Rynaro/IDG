# Fixtures

Sample artefacts used by EIIS conformance and regression checks.

## `install.manifest.json`

A sample manifest produced by running:

```
bash install.sh --target ./.eidolons/idg --hosts codex --non-interactive --force
```

against an empty consumer cwd. The file is captured here (with `target`
sanitised to a relative path and `installed_at` pinned) so the
EIIS conformance checker (`Rynaro/eidolons-eiis/conformance/check.sh`)
can validate manifest contents without re-running the installer. The
`installed_at` value is illustrative; live installs always rewrite it.
