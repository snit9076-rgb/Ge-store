## Adapted plugin recipes

- `recipes/<plugin-id>/candidate.yaml`：记录上游来源、接入结论与初步风险评估
- `recipes/<plugin-id>/mapping.yaml`：记录能力映射、裁剪项、权限映射与发布结论
- `recipes/<plugin-id>/generated/plugin.json`：当前 recipe 生成的 GeminiNotes manifest 样例
- `reports/<plugin-id>.md`：面向商店与审核流程的适配说明、限制说明与验证记录

当前仓库里已经有两份已落地的 adapted 示例：`app.quick-actions` 与 `app.linter-actions`。它们分别演示了“模板/选区命令”与“当前笔记清理命令”两类适配方向。

`recipes/` 目录也可以先放“候选评估卡”，即使它们还没有进入真正的重打包阶段。这样可以先积累候选池，再决定哪些插件值得进入 `mapping / generated / report` 阶段。