# GitHub 优先的商店分发策略（Syntax Card / App Plugin / Deck）

## 1. 当前决策

- **下载层**：优先使用 GitHub Raw 或 GitHub Releases 提供可直接下载的包文件
- **说明层**：优先使用 GitHub README / docs
- **展示增强层**：后续如有需要，再补 GitHub Pages

这意味着当前**不需要为了下载专门做一个网页**。

## 2. 链接分工

### 2.1 插件商店条目

- `downloadUrl`：必须直接指向 `.cardslot` 或 `.gnplugin` 文件
- `homepageUrl`：可选，指向 README、说明页、演示页
- `sourceRepoUrl`：可选，指向源码仓库或源码目录
- `previewUrl`：可选，指向公开图片

约束：

1. 不要把 `downloadUrl` 指向 HTML 页面
2. `homepageUrl` 与 `sourceRepoUrl` 可以是 GitHub 仓库页、README、docs 页面
3. 如果后续切到 GitHub Releases，优先只替换 `downloadUrl`，不要改变字段语义

## 3. Deck 分发建议

当前项目已经具备 `.deckslot` 导入导出与缺卡自动补装链路，但**还没有独立的远程 Deck 商店实现**。

在真正做 Deck 商店前，建议先约定统一的 GitHub 分发模型：

- Deck 文件：`releases/*.deckslot`
- Deck 索引：后续可新增 `decks.json`
- Deck 内外部语法卡来源：继续使用 `cards[].source`

推荐字段：

- `id`
- `name`
- `version`
- `author`
- `description`
- `downloadUrl`（直链到 `.deckslot`）
- `homepageUrl`（说明页 / 示例页）
- `sourceRepoUrl`（源码或配置目录）
- `previewUrl`
- `useCases`
- `minAppVersion`

## 4. 推荐发布顺序

### 阶段 A：现在就能做

1. 把 `plugins/` 推到公开 GitHub 仓库
2. 用 Raw 地址驱动 `plugins.json`
3. 在插件详情里展示 `homepageUrl / sourceRepoUrl`
4. Deck 先继续走 `.deckslot` 文件分享 + 文档说明

### 阶段 B：更正式时再做

1. 把包文件迁到 GitHub Releases
2. 保留 README / docs 作为说明页
3. 如需更强展示，再补 GitHub Pages

## 5. 为什么不先做专门网页

- 当前核心问题是“能稳定分发并让用户拿到正确的包”
- GitHub 已经覆盖版本管理、公开访问、PR 审核、CI 校验
- 专门网页更适合承担“展示与介绍”，不适合取代包文件直链

因此当前最稳妥的方案是：

**GitHub 承担下载与说明，网页只作为后续增强，而不是下载前置条件。**