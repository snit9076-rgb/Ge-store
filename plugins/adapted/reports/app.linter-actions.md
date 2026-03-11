## app.linter-actions adaptation report

### Upstream

- Origin store: `obsidian-community`
- Upstream plugin: `Linter`
- Upstream author: `Victor Tao`
- Locked upstream version: `1.27.1`

### What is preserved in GeminiNotes

- Normalize markdown heading spacing in the active note
- Normalize unordered / ordered list marker spacing
- Trim trailing spaces and tabs line by line
- Collapse repeated blank lines in the active note

### What is intentionally removed

- Vault-wide batch linting across multiple files
- File rename, metadata, and file-system driven cleanup workflows
- Any lint rule that depends on desktop-only Obsidian APIs

### Current release posture

- Compatibility level: `adapted`
- Review status: `experimental`
- Risk level: `low`
- Host runtime: GeminiNotes declarative command host only

### Validation notes

- The adapted package must pass `validate-store.ps1`
- Host actions must stay deterministic and current-note scoped
- Any future note-action API expansion should update both this report and `mapping.yaml`