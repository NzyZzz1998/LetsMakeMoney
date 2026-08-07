# LetsMakeMoney Windows v1.0.F 开发日志

## 2026-08-04 开发承接

### 状态

- 项目所有者确认 v1.0.F PRD，公开版本固定为 v1.0.8。
- 开发事实基线锁定为 `main@1801626a153a9644f448729dabc51ee9f88a0d9e`。
- 建立 `dev_plan_v1.0.F.md` 与 `progress_v1.0.F.md`，进入 M0。

### 当前发现

- 工作区不是干净基线，包含 L2 品牌、TimeField、Combobox、窗口表面、隐私竖条和原型候选。
- 这些文件来自先前项目所有者审阅与候选实现，必须保留并逐项审计；本轮不回退、不覆盖。
- 加班正式实现仍以 v1.0.7 schema v1 为基线，v1.0.F 需要新增 schema v2、动态边界和联动事务。

### 下一步

1. 逐文件映射候选到 FR，并记录纳入、重做、舍弃或转交。
2. 运行前端、Rust、current gate 和文档基线。
3. 先实现版本/候选身份与加班 v2 的 P0 合同。

## 2026-08-04 M0 基线收口

### 对象身份

- 分支：`main`。
- HEAD：`1801626a153a9644f448729dabc51ee9f88a0d9e`。
- 远端：`origin=https://github.com/NzyZzz1998/LetsMakeMoney.git`。
- 最新公开 tag：`v1.0.7`；本轮未修改远端、tag 或 Release。

### 候选所有权判定

- `brand/`、`AppMark.tsx`、图标生成脚本及图标文件：纳入 FR-003/FR-015，仍需确定性生成、尺寸和哈希门禁。
- `TimeField.tsx` 及其 App/CSS 接入：纳入 FR-004，仍需键盘、焦点、错误、主题和三档 DPI 验收。
- `AccessibleCombobox.tsx` 候选：纳入 FR-005，仍需弹层翻转、ARIA、焦点和 DPI 验收。
- `WindowFrame`、surface contract、native platform 候选：纳入 FR-006，静态合同通过，真实 Windows 表面仍待验收。
- 隐私竖条 presentation、样式、fixture 与测试：纳入 FR-007，真实贴边、悬停和找回仍待验收。
- Logo 探索 HTML/PNG：保留为 FR-015 设计证据，不属于运行时实现或发布附件。
- v1.0.F PRD、追踪、原型与开发承接文档：纳入当前事实层；原型通过不替代真实桌面验收。
- 加班 v1 实现：冻结为迁移基线，需要由 FR-017 扩展为 schema v2、动态边界与联动事务。

### 自动基线

- TypeScript strict：通过。
- Rust `cargo test`：68/68 通过。
- 候选行为测试：Combobox 14/14、窗口表面 5/5、TimeField 静态合同、隐私竖条和品牌资产检查通过。
- `git diff --check`：通过。
- v1.0.7 聚合门禁 M1-M5 通过；M6 仅因 `doc/current.md` 已进入 v1.0.F 开发而拒绝陈旧的“v1.0.7 已发布并复核”断言。

### 结论

M0 通过，可以进入 M1。旧 v1.0.7 门禁保留为 historical 复验入口，不能继续充当 v1.0.8 current gate。

## 2026-08-04 M1-M6 实施收口

### 实现

- M1：版本统一为 `1.0.8`，建立 current manifest、L2“燕麦石墨”确定性品牌资产和工具发现合同。
- M2：完成加班 schema v2、下一次真实工作解析、动态上限、周末联动、journal 补偿、v1 迁移和兼容导出。
- M3：完成加班与日期调整 UI、默认 8 小时联动、删除确认、失败回滚和月度统计。
- M4：完成 TimeField、Combobox、单一窗口表面和隐私竖条；真实三档 DPI 转入最终候选验收。
- M5：移除陈旧 M6 IPC，建立浏览器预览、支持矩阵、证据、品牌分层和 v2 债务合同。
- M6：完成 10 次冷启动与 10 次暖启动基线和复测。

### 冷启动结论

- 基线冷启动 Mini 为 `6217ms`，Workbench 为 `6589ms`。
- 根因是 Tauri 已创建 WebView 后仍同步执行多次 `reg.exe query` 探测 WebView2。
- 移除重复探测后，冷启动 Mini 为 `861ms`，Workbench 为 `1211ms`。
- Mini 冷启动收益 `86.151%`，超过 15% 保留阈值；定向优化保留。
- 该结论不宣称 CPU 或内存问题已经解决。

## 2026-08-04 M7 验收准备

- 新增 `package_v10f.ps1` 与 `verify_v10f_package.ps1`，公开包身份只接受 `1.0.8`。
- 修正 current manifest 的包内构建信息文件名为真实的 `BUILD-INFO.json`。
- 新增 candidate/published 正负 fixture 与 M7 current gate。
- 建立 verification、manual verification、release checklist 和 release notes 草案。
- 当前工作区为 dirty，不生成或锁定正式候选；干净提交、三档 DPI 和独立验收继续作为发布门禁。

### 聚合门禁结果

- `scripts/verify_windows_current.ps1` 通过。
- v1.0.F M1、M5、M6、M7 和 architecture current gates 全部通过。
- TypeScript strict 与 Vite production build 通过。
- Rust `cargo test` 为 77/77，通过 `cargo fmt --check` 与 `cargo clippy -D warnings`。
- candidate/published fixture、私密 `debug.log` 拒绝、文档状态和 `git diff --check` 通过。
- 脱敏摘要写入 `doc/releases/v1.0.F/evidence/m7-automation-summary.json`。
- 本结果只证明当前 dirty 开发树通过自动化门禁；未生成正式候选，也未替代三档 DPI 与独立验收。
