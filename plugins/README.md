## Store backend scaffold

- `plugins.json`：商店索引
- `releases/*.cardslot` / `releases/*.gnplugin`：示例插件包
- `sources/*`：用于重新生成示例插件的源目录
- `adapted/recipes/*`：外部插件适配配方样例（候选评估、能力映射、生成 manifest）
- `adapted/reports/*`：适配说明、限制说明与审核报告样例
- `build-sample-store.ps1`：生成 Syntax Card 与 App Plugin 两类示例商店产物
- `validate-store.ps1`：对索引、版本、发布包、源码清单，以及 `pluginType / downloadUrl / homepageUrl / sourceRepoUrl / supportedPatterns / capabilities / useCases / qualitySignals / minAppVersion` 做发布前校验；对于 `sourceType = adapted` 的条目，还会额外校验 `originStore / upstream / adapterVersion / adapterMaintainer / preservedFeatures / knownLimitations / reviewStatus / riskLevel`
- `.github/workflows/plugin-store-validation.yml`：在 PR / push 时自动生成并校验商店产物

### 本地生成与校验

1. 运行 `powershell -ExecutionPolicy Bypass -File .\plugins\build-sample-store.ps1`
2. 如需单独校验，运行 `powershell -ExecutionPolicy Bypass -File .\plugins\validate-store.ps1`

### 发布步骤

1. 确认 `plugins/plugins.json` 与 `plugins/releases/*.{cardslot,gnplugin}` 已生成并通过校验
2. 将 `plugins/` 目录推送到公开 GitHub 仓库
3. 确认 Raw 地址可访问，例如：
   - `https://raw.githubusercontent.com/<owner>/<repo>/<branch>/plugins/plugins.json`
   - `https://raw.githubusercontent.com/<owner>/<repo>/<branch>/plugins/releases/<slug>.cardslot`
   - `https://raw.githubusercontent.com/<owner>/<repo>/<branch>/plugins/releases/<slug>.gnplugin`
4. 在 `plugins.json` 中把 `downloadUrl` 保持为**可直接下载的包文件地址**；如果要展示说明页或源码页，则分别填写 `homepageUrl` / `sourceRepoUrl`，不要把 `downloadUrl` 指向 HTML 页面
5. 如需更正式的对外分发，可把包文件迁到 GitHub Releases；如需更好展示，可后续再补 GitHub Pages，但它只负责展示，不作为下载中转
6. 再让应用中的 `PluginRepository.DEFAULT_INDEX_URL` 指向实际可访问的索引地址

### CI 自动校验

- 当 `plugins/**`、`PLUGIN_SPEC.md` 或对应 workflow 发生变更时，GitHub Actions 会自动执行：
  1. `build-sample-store.ps1`
  2. `validate-store.ps1`
  3. `git diff --exit-code -- plugins/plugins.json plugins/releases plugins/sources plugins/adapted`
- 如果生成结果与仓库内提交内容不一致，CI 会直接失败，避免过期索引或漏提交产物进入主分支。

### 上线前建议检查项

- `plugins.json` 中所有 `id` 唯一
- 每个条目的 `downloadUrl` 都能对应到本地 `releases/*.cardslot` 或 `releases/*.gnplugin`
- 若配置 `homepageUrl / sourceRepoUrl`，请确保使用公开 `http(s)` 地址，并分别承担“说明页 / 源码仓库”职责，而不是把它们混进 `downloadUrl`
- `sources/*/manifest.json` 或 `sources/*/plugin.json` 中的 `id / name / version / minAppVersion` 与 `plugins.json` 一致
- `syntax_card` 条目应声明非空的 `supportedPatterns / useCases / qualitySignals`
- `app_plugin` 条目应声明非空的 `capabilities / useCases / qualitySignals`
- `adapted` 条目应声明非空的 `originStore / upstream / preservedFeatures / knownLimitations / reviewStatus / riskLevel`
- 若配置 `previewUrl`，请确保使用公开 `http(s)` 地址