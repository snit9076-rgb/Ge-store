## First adapted candidate pipeline

### Current batch

- `app.quick-actions` → already implemented as the first adapted sample package
- `app.linter-actions` → implemented as the second adapted sample package
- `app.templater-lite` → `accept_partial`
- `app.natural-language-dates-lite` → `accept_partial`
- `app.kanban-lite` → `reject`

### Why this batch matters

- It covers text cleanup, templates, date insertion, and a deliberately rejected complex-view plugin.
- It creates a reusable pattern for deciding whether a candidate should become a declarative command plugin, a future note-action plugin, or be rejected for now.

### Suggested implementation order

1. `app.templater-lite`
2. `app.natural-language-dates-lite`
3. Revisit `app.kanban-lite` only after host view APIs exist