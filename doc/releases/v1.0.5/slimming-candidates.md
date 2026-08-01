# LetsMakeMoney Windows v1.0.5 瘦身候选

> 状态：Review 候选，不执行删除、移动、归档或重构。
>
> 原则：降低公开仓库和本地工作区的理解成本，不以代码行数越少越好。每项均核对调用方、动态入口/资源/反射、配置、测试、日志和平台行为六类证据。

## 总体判断

- 当前仓库的主要复杂度来自历史可复验性和版本化发布脚本，不是大量无调用业务代码。
- v1.0.4 已建立前后端分层，`App.tsx`、`model.ts` 和 Rust `lib.rs` 仍长，但属于“局部切片候选”，不是删除候选。
- 本地可释放空间约 41.6 MiB，主要是忽略的验收证据和历史发布副本；清理前必须先确认哪些是唯一原始证据。
- `spikes/v1.0-ui/` 仍被 v1.0-v1.0.2 历史脚本引用，当前不能直接归档。

## 候选总表

| ID | 文件/符号 | 当前作用与摩擦 | 调用方 | 动态入口/资源/反射 | 配置 | 测试 | 日志 | 平台行为 | 最小调整 | 验证与回退 | 建议 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| V105-SLIM-001 | `.tmp_v104_desktop_smoke/` | 当前为空，仅是本地 smoke 临时目录 | smoke 脚本可按需重建 | 无跟踪资源入口 | 无 | 重跑 smoke 可重建 | 无唯一日志 | 无持久平台状态 | 删除空目录 | 重跑 smoke；回退为重新创建目录 | 可直接清理 |
| V105-SLIM-002 | `.tmp_acceptance/` | 47 个文件、约 10.4 MB；可能包含 GUI 原始证据 | 文档可能只引用摘要，不直接运行 | 截图/日志属于外部证据，不是运行资源 | 不应包含生产配置 | 不参与自动测试 | 可能包含唯一原始日志 | 可能记录 Windows/DPI 操作 | 先生成脱敏索引，确认非唯一证据后删除副本 | 对照 verification/manual verification；回退为从外部证据库恢复 | 需证据保全后清理 |
| V105-SLIM-003 | `releases/v1.0.1` 至 `v1.0.4` | 本地约 33.1 MB；同名 v1.0.4 已与远端身份漂移 | 手工验收/包验默认读取版本目录 | Zip/EXE 是验收对象，不是源码资源 | 无 | package verifier 读取 | BUILD-INFO 是身份日志 | Windows EXE 真实运行对象 | 将本地 candidate 与 published cache 分目录；只保留显式锁定对象 | 比对 GitHub digest、BUILD-INFO、source dirty；回退为重新下载远端附件 | 需身份确认后清理 |
| V105-SLIM-004 | `package_v10.ps1` 至 `package_v104.ps1` | 每版复制打包流程，修复容易只落在最新版 | 人工发布、历史复验 | 无反射；按版本选择脚本 | 版本、路径、README、日历合同写在脚本中 | 各版本包验 | 输出 BUILD-INFO/哈希 | 生成 Windows 便携包 | 提取共享原子打包内核，保留版本薄入口 | 对 v1.0-v1.0.4 夹具生成等价包；失败时保留旧脚本 | 需补测试后合并 |
| V105-SLIM-005 | `verify_v10*.ps1`、`verify_v101*.ps1` 至 `verify_v104*.ps1` | 聚合链逐版继承，入口数量高、事实断言分散 | CI、本地门禁、发布验收 | 无运行时动态入口 | 工具路径和版本参数分散 | 自身就是验证入口 | 产生门禁输出 | Windows/Python/Node/Rust 工具链 | 建立参数化共享 verifier，版本入口只声明差异 | 连续跑全部历史门禁；回退为旧入口 | 需补测试后合并 |
| V105-SLIM-006 | `spikes/v1.0-ui/` | 46 个跟踪文件；兼有技术选型证据和历史脚本依赖 | `package_v10/v101/v102`、`verify_v10_m1`、历史文档 | fixture/token/golden path 是历史资源 | 不持有生产配置 | 历史合同依赖 | 无生产日志 | 不参与当前 v1.0.4 运行 | 先迁移旧脚本依赖，再决定归档位置 | 在临时无-spike clone 复验 v1.0-v1.0.2；回退为恢复目录 | 必须保留，迁移后再评估 |
| V105-SLIM-007 | `App.tsx`（1,096 行） | 多窗口页面编排和局部交互集中，改动扩散 | React 入口直接渲染 | 页面组件是动态窗口入口 | 读写配置草稿 | Presentation/配置/日历测试 | 反馈由 Service 记录 | Workbench/Settings/Wizard 窗口 | 仅在需求触碰时抽出页面组件和纯 selector | 行为测试 + 窗口冒烟；回退为保留旧组件入口 | 需补测试后局部拆分 |
| V105-SLIM-008 | `model.ts`（1,012 行） | Dashboard、日历缓存、timer、fallback 与 Hook 集中 | 全部主要窗口 | Tauri/browser 双入口 | 间接消费权威配置 | 同步、生命周期、日历、高风险组合测试 | 权威同步日志 | WebView 可见/隐藏与系统时间 | 先分离 calendar session、dashboard session 和 browser fallback | characterization tests；按导出 API 独立回退 | 需补测试后局部拆分 |
| V105-SLIM-009 | Rust `lib.rs`（1,962 行） | 启动组装、窗口、托盘、WebView2、Mini edge 编排集中 | Tauri main/commands/events | Windows 原生回调与 tray 是动态入口 | 读取窗口/隐私配置 | Rust、M6、桌面冒烟 | 原生语义日志 | 高度依赖 Windows 生命周期 | 抽取 window runtime、tray runtime、mini edge runtime，但不改 command 合同 | Rust 测试 + 包后通知区/窗口找回；回退为模块 re-export | 需要测试与真实桌面门禁 |
| V105-SLIM-010 | v0.9 宠物/Figma/动画合同、iOS 原型 | 历史体积与目录较多，但保存产品演进和潜在桌宠恢复证据 | 历史文档、未来产品 Review | 图片/原型是文档资源，不是 v1 runtime | 不影响 v1 config | 不参与 v1 测试 | 无生产日志 | 不影响当前 Windows 窗口 | 建立所有权/事实源索引，不移动内容 | 链接检查、跨仓库接管证明；回退为保留原路径 | 必须保留，待独立决策 |
| V105-SLIM-011 | 根 README 与版本文档 | 重复描述版本，当前已发生 v1.0.3/v1.0.4 漂移 | 外部用户、贡献者、docs gate | README 图片和链接为公开入口 | 无 | verify_docs 覆盖不足 | 无 | 无 | 定义 `doc/current.md` 为内部事实源，README 只投影必要公开事实并加断言 | docs gate；回退为恢复上一版 README | 更新/治理，不删除 |

## 六类证据结论

### 1. 调用方

- 当前未发现可在无验证前直接删除的业务函数或 Rust command。
- 历史 package/verify 脚本仍有人工作为入口；不能以“版本旧”为由删除。
- `spikes/v1.0-ui/` 至少被四个历史脚本直接引用。

### 2. 动态入口、资源与反射

- Tauri 窗口、托盘、事件监听和 WebView2 生命周期是动态入口，普通文本调用图不足以证明可删。
- v0.9/Figma/iOS 资源属于文档和产品历史，不是 v1 运行时冗余。
- Mini 状态机由 pointer/focus/Tauri event 组合触发，任何删减都需要真实桌面验证。

### 3. 配置

- config v8 仍保存窗口位置、主题、`mini_edge_auto_hide` 和 `mini_edge_dock`；对应逻辑必须保留兼容。
- v5-v7 迁移和非法值回退是用户数据安全能力，不属于旧兼容垃圾。

### 4. 测试

- 现有聚合测试覆盖主业务和多数失败路径，是局部拆分的安全网。
- Mini 仍缺拖拽结束无 pointerleave、sibling 窗口关闭焦点转移两条组合测试。
- 历史脚本参数化前必须证明 v1.0-v1.0.4 门禁语义不丢失。

### 5. 日志

- 本地 `.tmp_acceptance/` 可能保留唯一 GUI/系统日志，不应先删后补摘要。
- BUILD-INFO 是发布身份的一部分；本地 dirty candidate 应保留到完成身份处置决策。

### 6. 平台行为

- 托盘、窗口找回、透明 WebView、DPI、Mini edge 和 WebView2 suspend/resume 都需要 Windows 实机门禁。
- 纯 TypeScript 测试不能单独证明原生窗口像素位置和焦点行为。

## 分类清单

### 可直接清理

- `.tmp_v104_desktop_smoke/` 空目录。

### 需要补证据或测试

- `.tmp_acceptance/`。
- `releases/v1.0.1` 至 `v1.0.4` 本地副本。
- 版本化 package/verify 脚本。
- `App.tsx`、`model.ts`、Rust `lib.rs` 的局部拆分。

### 必须保留

- `spikes/v1.0-ui/`，直到历史脚本解除依赖。
- config v5-v7 迁移、窗口与 Mini 兼容字段。
- v0.9 桌宠、Figma、动画合同和历史 release/验收文档。
- 当前正式发布的 license、third-party、calendar 和 BUILD-INFO 合同。

### 暂不处理

- 全局状态管理重写。
- Rust/Tauri 主链路整体重构。
- 批量迁移所有历史文档和原型。
- 桌宠资产接回 v1 runtime。

## 删除验证方案

任何后续清理批次都按以下顺序：

1. 锁定 Git HEAD、候选路径、调用者和外部证据位置。
2. 在独立分支或 worktree 执行单一批次。
3. 跑 `verify_v104.ps1`、对应历史门禁和 `git diff --check`。
4. 涉及包时重新核对 BUILD-INFO、Zip/EXE/DLL 哈希与远端附件。
5. 涉及原生窗口时补 Computer Use 与日志。
6. 每批有独立 commit，失败时只回退该批，不连带其他治理。

