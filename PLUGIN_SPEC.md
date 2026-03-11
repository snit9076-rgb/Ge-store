# PLUGIN_SPEC.md — GeminiNotes Plugin Development Guide

> This document describes how to create, package, and contribute **Syntax Cards** and **Deck Presets** for GeminiNotes.

---

## Overview

GeminiNotes uses a **Card Slot** system where rendering capabilities are provided by modular *Syntax Cards*. Each card:

- Claims a set of syntax patterns (e.g. `math_inline`, `spoiler`)
- May provide a lightweight `render.js` bootstrap and/or a `post.js` DOM post-processor
- Optionally provides CSS styles

Community-contributed cards are distributed as `.cardslot` files (ZIP archives) and indexed in the [`gemininotes-plugins`](https://github.com/gemininotes/plugins) repository.

---

## File Format: `.cardslot`

A `.cardslot` file is a **ZIP archive** with a flat structure:

```text
my-plugin.cardslot (ZIP)
├── manifest.json   REQUIRED — plugin metadata and capabilities
├── render.js       recommended — optional bootstrap / transform entry
├── post.js         optional — DOM post-processing after Markdown render
├── style.css       optional — additional CSS injected into the preview
├── preview.png     optional — screenshot shown in the Store (800×400px)
└── README.md       optional — documentation shown in the Store detail view
```

---

## `manifest.json` Specification

```json
{
  "id":          "ext.your-plugin-id",
  "name":        "Your Plugin Name",
  "version":     "1.0.0",
  "author":      "Your Name",
  "description": "One-line description shown in the Store",
  "iconName":    "Extension",
  "claimedPatterns": ["spoiler", "custom_block"],
  "incompatibleWith": []
}
```

### Field Reference

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `id` | string | ✅ | Must start with `ext.`, e.g. `ext.spoiler`. Globally unique. |
| `name` | string | ✅ | Display name, max 40 chars |
| `version` | string | ✅ | Semantic version: `MAJOR.MINOR.PATCH` |
| `author` | string | ✅ | Your name or GitHub username |
| `description` | string | ✅ | Max 120 chars |
| `iconName` | string | — | Material Icons name. Default: `Extension`. See supported [icon list](#icons). |
| `claimedPatterns` | array | — | Pattern IDs your card handles. See [Pattern Naming](#pattern-naming-convention). |
| `incompatibleWith` | array | — | Card IDs that conflict with yours (e.g. two math renderers). |

### Pattern Naming Convention

Use lowercase snake_case. Built-in reserved patterns (do not claim):

| Pattern ID | Handled by |
| ---------- | ---------- |
| `markdown_base` | `builtin.markdown` |
| `code_highlight` | `builtin.highlight` |
| `math_inline`, `math_block` | `builtin.katex` |
| `mermaid` | `builtin.mermaid` |
| `task_list` | `builtin.tasklist` |

Your custom patterns should be namespaced: `spoiler`, `timeline`, `callout_obsidian`, etc.

### Icons

Supported values for `iconName` (Material Icons):
`Code`, `Terminal`, `Functions`, `AccountTree`, `AutoAwesome`, `Info`, `CheckBox`, `UnfoldMore`, `Link`, `Extension` (default)

---

## `render.js` Interface

Your script is executed in a sandboxed WebView. It must expose a global function:

```js
/**
 * Called with the raw HTML produced by the base Markdown renderer.
 * Return the modified HTML string.
 * @param {string} html - Input HTML
 * @param {Object} options - Reserved for future use
 * @returns {string} - Transformed HTML
 */
function transform(html, options) {
    // Your transformation here
    return html;
}
```

**Rules:**

- The function must be synchronous
- Must not make network requests
- Return value must be a valid HTML string
- Limit execution time (< 200ms for typical notes)

### Example: Spoiler Tag

```js
function transform(html, options) {
    // Convert >! spoiler !< syntax to <details> element
    return html.replace(
        /&gt;!([\s\S]*?)!&lt;/g,
        '<details class="spoiler"><summary>Spoiler</summary><div>$1</div></details>'
    );
}
```

---

## `style.css`

CSS is injected into the preview `<head>` after the built-in styles. Use specific class names to avoid conflicts:

```css
/* Prefix with your plugin id */
.ext-spoiler details.spoiler {
    background: #f5f5f5;
    border-left: 3px solid #aaa;
    padding: 8px 12px;
    border-radius: 6px;
}

.ext-spoiler details.spoiler summary {
    cursor: pointer;
    font-style: italic;
    color: #666;
}
```

---

## File Format: `.deckslot`

A `.deckslot` file packages a **Deck configuration** (which cards, in what order, enabled/disabled). It lets users share complete rendering setups.

```text
my-deck.deckslot (ZIP)
└── deck.json   REQUIRED — deck metadata + card list
```

### `deck.json` Format

```json
{
  "name": "Academic Notes",
  "description": "Optimised for math-heavy writing",
  "colorHex": "#85C1E9",
  "formatVersion": 1,
  "cards": [
    { "id": "builtin.katex",    "isEnabled": true,  "priority": 0 },
    { "id": "builtin.mermaid",  "isEnabled": true,  "priority": 1 },
    { "id": "ext.spoiler",      "isEnabled": true,  "priority": 2,
      "source": "https://raw.githubusercontent.com/gemininotes/plugins/main/plugins/releases/spoiler.cardslot" }
  ]
}
```

When a `.deckslot` is imported:

1. **Built-in cards** are activated directly
2. **External cards already installed** are used as-is
3. **External cards with a `source` URL** are downloaded and installed automatically
4. **External cards with no `source`** are skipped (warned to the user)

> `cards[].source` 应指向 `.cardslot` 文件本体（如 GitHub Raw / GitHub Releases），不要指向说明网页。说明页、截图页可以单独放在 GitHub README 或 GitHub Pages。

---

## Submitting to the Community Store

1. **Fork** the [`gemininotes-plugins`](https://github.com/gemininotes/plugins) repository
2. Add your `.cardslot` file to `plugins/releases/your-plugin.cardslot`
3. Add an entry to `plugins/plugins.json`:

```json
{
  "id": "ext.spoiler",
  "name": "Spoiler Blocks",
  "version": "1.0.0",
  "author": "YourName",
  "description": "Add >! spoiler !< syntax to hide content",
  "downloadUrl": "https://raw.githubusercontent.com/gemininotes/plugins/main/plugins/releases/spoiler.cardslot",
  "homepageUrl": "https://github.com/gemininotes/plugins/blob/main/plugins/sources/spoiler/README.md",
  "sourceRepoUrl": "https://github.com/gemininotes/plugins/tree/main/plugins/sources/spoiler",
  "iconName": "UnfoldMore",
  "category": "UX",
  "downloads": 0,
  "rating": 0,
  "supportedPatterns": ["spoiler"],
  "useCases": ["Study Notes", "Knowledge Base"],
  "qualitySignals": ["Verified", "Beginner-friendly"],
  "minAppVersion": 12,
  "installHint": "Works best in decks used for private answers or progressive disclosure.",
  "featured": false
}
```

> 推荐把 `downloadUrl` 固定为**包文件直链**，把 `homepageUrl` 用作说明页/演示页，把 `sourceRepoUrl` 用作源码仓库入口。短期不必专门做网页；若后续需要更强展示，可再补 GitHub Pages。

1. Run the store validator before publishing:

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\validate-store.ps1
```

> `category` is an open string field. The Store UI renders available categories dynamically from `plugins.json`, so new categories can be introduced without changing the app code.

> `supportedPatterns` 应与插件包 `manifest.json` 里的 `claimedPatterns` 保持一致；`useCases`、`qualitySignals` 与 `installHint` 则用于帮助用户判断“这张卡适合谁、是否可靠、装到哪里最合适”。

1. Open a **Pull Request** — after review, your plugin appears in all users' Stores automatically.

---

## Version Bumping

Increment `version` in `manifest.json` and `plugins.json` using semantic versioning:

- `PATCH` (1.0.x) — bug fixes only
- `MINOR` (1.x.0) — new features, backward compatible
- `MAJOR` (x.0.0) — breaking changes to claimed patterns or render interface

The app compares installed vs. remote versions and shows an **Update** button automatically.
