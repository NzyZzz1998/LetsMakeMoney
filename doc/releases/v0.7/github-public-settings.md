# GitHub 公开仓库设置清单

## 建议设置

- 描述：`Windows desktop pet and earnings progress widget built with Godot 4.7.`
- Topics：`godot`、`windows`、`desktop-pet`、`productivity`、`gdextension`、`cpp`
- 默认分支：`main`
- `main` 保护：要求 Pull Request、Windows docs/compliance 与 native/Godot 检查通过；禁止强制推送和删除。
- Actions：默认只读；Fork PR 不读取签名或 Release secrets。
- 开启 Private Vulnerability Reporting。

## 供应链决定

- 所有第三方 Action 固定到不可变 commit，并在行尾标注对应主版本。
- Dependabot：v0.7 先不启用。仓库没有常规 package manager 运行时依赖，固定 native lock 由现有检查负责，自动 PR 当前收益较低。
- CodeQL：v0.7 先不作为合并门禁。GDScript 覆盖有限，C++ 规模较小且 Windows/godot-cpp 构建耗时高；公开后观察贡献量再评估。
- Release workflow：仅维护者手动触发 dry run；正式发布必须另有 Acceptance 证据、签名门禁与项目所有者确认。

仓库网页设置和 Private Vulnerability Reporting 需由所有者在 GitHub 界面确认，本文件不冒充已经启用。
