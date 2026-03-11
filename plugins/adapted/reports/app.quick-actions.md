## app.quick-actions adaptation report

### Upstream

- Origin store: `obsidian-community`
- Upstream plugin: `QuickAdd`
- Upstream author: `Christian B. B. Houmann`
- Locked upstream version: `1.11.5`

### What is preserved in GeminiNotes

- Insert a lightweight meeting template into the current note
- Wrap the current selection into an action-items block
- Append a follow-up checklist to the end of the current note

### What is intentionally removed

- Vault-wide file creation and desktop automation macros
- Custom modal flows and interactive capture pipelines
- Any workflow that depends on Obsidian-specific desktop APIs

### Current release posture

- Compatibility level: `partial`
- Review status: `experimental`
- Risk level: `medium`
- Host runtime: GeminiNotes declarative command host only

### Validation notes

- The adapted package must pass `validate-store.ps1`
- The generated `.gnplugin` must keep its command list aligned with this recipe
- Any future host API expansion should update both this report and `mapping.yaml`