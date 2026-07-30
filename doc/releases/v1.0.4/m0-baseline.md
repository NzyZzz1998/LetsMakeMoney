# LetsMakeMoney Windows v1.0.4 M0 基线与 Go/No-Go

## 1. 结论

| 项目 | 结论 |
| --- | --- |
| M0 状态 | 通过 |
| 用户可见行为 | 未修改 |
| Mini 几何方案 | Go：使用 Tauri `Monitor::work_area()` 与纯物理像素几何函数 |
| 配置方案 | Go：保持 `config_version=8`，增加带 serde 默认值的可选字段 |
| 独立 `window-state.json` | 不需要 |
| Rust 工具链 | M3 固定 `1.97.1-x86_64-pc-windows-msvc` |
| FR-007 / FR-009 | 继承通过，不重复开发 |
| 下一批 | 可以进入 M1-M6；每个里程碑仍需独立门禁 |

M0 只增加纯函数、测试夹具、验证脚本和证据文档，没有把贴边行为接入真实窗口，也没有改动 React 可见界面。

## 2. Git 与 v1.0.3 发布身份

| 项目 | 身份 |
| --- | --- |
| 开发分支 | `main` |
| M0 开发基线 | `09f838d05c67efb5219437ec2208920e441f3f52` |
| 远端 | `origin` |
| v1.0.3 annotated tag object | `51741ba4dfc5a68ab83744d6320d95f63a6bbcb8` |
| v1.0.3 release commit | `87f6766a33fd6ff284f0fb3a42dc18c5a7292bf4` |
| GitHub Release | `LetsMakeMoney v1.0.3`，正式发布，非草稿、非预发布 |
| Zip | 3,204,791 bytes；`259CAE23D785FC7712CAC0EFD42991C8EE210C0BCEA1EB5C07FC171DFB993B28` |
| EXE | 9,997,312 bytes；`41BB11FCBC95C3789AD283D0F85E67DB0E17D4BC769B133B317FDB1804607237` |
| WebView2Loader.dll | 160,320 bytes；`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |

GitHub Release 资产摘要与本地 Zip 哈希一致。完整机器证据见 `evidence/m0-baseline.json`。

## 3. FR-004 现有证据与真实缺口

### 3.1 窗口生命周期

| 合同 | 当前直接证据 | 状态 | M4 是否补测 |
| --- | --- | --- | --- |
| hidden 停止本地 tick 与权威同步 | `dashboard-lifecycle.behavior.ts`：hidden -> `stop_timers` | 已覆盖 | 否 |
| shown 立即同步并只恢复一组 timer | 同文件：`reset_time_sample,start_timers,sync_window_shown` | 已覆盖 | 否 |
| 重复 hidden/shown 不重复注册 | 同文件：重复事件 effects 为空 | 已覆盖 | 否 |
| 隐藏期间保留最后有效快照 | 生命周期只证明状态；权威同步只证明 stale disposition | 部分覆盖 | 是，补组合行为 |
| 隐藏/卸载后的晚到结果不得覆盖 | sequence guard 与 deferred disposer 分别已有证据 | 部分覆盖 | 是，补晚到结果组合 |

### 3.2 配置事务

| 合同 | 当前直接证据 | 状态 | M4 是否补测 |
| --- | --- | --- | --- |
| 保存成功更新权威配置 | Rust `unchanged_and_success_are_distinct`；Desktop Service 保存结果 | 已覆盖 | 否 |
| 无变化返回 unchanged | Rust 直接测试 | 已覆盖 | 否 |
| 保存失败保留草稿与旧配置 | Rust `failed_writes_preserve_old_config_and_draft` | 已覆盖 | 否 |
| 可读分类与重试后收敛 | 失败分类和成功分别存在，缺少同一流程组合 | 部分覆盖 | 是 |

### 3.3 Dashboard 同步

| 合同 | 当前直接证据 | 状态 | M4 是否补测 |
| --- | --- | --- | --- |
| 同步失败保留最后有效快照 | `authoritative-sync.behavior.ts` stale/blocked 规则 | 已覆盖 | 否 |
| 初次无快照失败显示错误 | 只有 bounded retry 纯函数证据 | 部分覆盖 | 是 |
| 重试成功清错并更新快照 | 无直接 App 组合证据 | 未覆盖 | 是 |
| browser fallback 与 Tauri 同输入一致 | Service 接缝存在，缺领域结果对照 | 未覆盖 | 是 |

### 3.4 Tauri command 与 event

| 合同 | 当前直接证据 | 状态 | M4 是否补测 |
| --- | --- | --- | --- |
| command 成功/业务失败/invoke 异常稳定映射 | 成功委托与 desktop unavailable 已覆盖 | 部分覆盖 | 是 |
| listener 正确解除 | `architecture-runtime.behavior.ts` | 已覆盖 | 否 |
| 重复挂载不产生重复 listener | deferred disposer 已覆盖释放，缺挂载组合 | 部分覆盖 | 是 |

M4 只补表中标记的真实组合缺口，不复制已有断言。

## 4. FR-007 与 FR-009 继承证据

### FR-007 Runtime / Service

- Runtime：15/15。
- Desktop Service：21/21。
- 失效条件：Runtime adapter 语义变化、Service command/event 契约变化、桌面失败 fallback 变化。
- M0 结论：继承有效；FR-011 以后新增 Window Service API 时，只重测受影响的 Window Service 和 Runtime 边界。

### FR-009 首轮切片

- 架构结构：22/22。
- Presentation Utils：18/18。
- 失效条件：第二轮模块拆分、公开窗口/配置契约重命名、新全局状态架构。
- M0 结论：继承有效；v1.0.4 不借 FR-011 扩大 App/model/lib 的拆分。

## 5. 实际工具链

| 工具 | 实际版本 | 来源 |
| --- | --- | --- |
| Node | 24.14.0 | Codex bundled runtime |
| Python | 3.12.13 | Codex bundled runtime |
| rustc | 1.97.1 (`8bab26f4f`) | managed LMM toolchain |
| Cargo | 1.97.1 (`c980f4866`) | managed LMM toolchain |
| Visual Studio Build Tools | 2022 / 17.14.35 | managed build tools |
| MSVC | 14.44.35207 | managed build tools |
| Windows SDK | 10.0.22621.0 | system |
| WebView2 | 150.0.4078.105 | system evergreen runtime |

直接调用未注入 `RUSTUP_HOME` / `CARGO_HOME` 的 Cargo 会重新解析和下载缓存，证明 M3 的统一工具解析不是文档美化，而是可复现性缺口。

## 6. Rust stable / fixed 对照

| 路线 | rustc | Rust tests | release build |
| --- | --- | --- | --- |
| 当前 stable | 1.97.1 (`8bab26f4f`) | 46/46 | 通过 |
| 固定 1.97.1 | 1.97.1 (`8bab26f4f`) | 46/46 | 通过 |

两条路线编译器身份相同、行为相同。M3 将增加精确 pin，以降低未来 stable 漂移风险；这不是为了修复当前行为。

## 7. Work Area、DPI 与位置合同

夹具：`apps/windows-v1/tests/fixtures/v104-mini-edge-geometry.json`。

已覆盖：

- 任务栏从可用区域排除后的右侧停靠。
- 负坐标副屏的左侧停靠。
- 100%、125%、150% DPI。
- 16 逻辑像素停靠阈值。
- 10 逻辑像素隐私露出条。
- 24 逻辑像素拖离阈值。
- 显示器丢失后回到主屏 work area。

冻结合同：

1. 展开位置用于持久化和重启恢复。
2. 收起物理位置只用于运行态，永不写入 `mini_window_position`。
3. 工作区或显示器失效时清除停靠，完整显示于主屏安全区域。
4. Tauri 2.11.5 已提供 `Monitor::work_area()`，不新增 Win32 几何依赖。

## 8. v1.0.3 配置兼容与存储决策

夹具：`apps/windows-v1/tests/fixtures/v104-config-compatibility.json`。

已证明：

1. v1.0.3 serde reader 接受包含 `mini_edge_auto_hide` 与 `mini_edge_dock` 的 v8 配置。
2. v1.0.3 保存时只丢弃未知的新字段。
3. 月薪、主题、作息和正常 Mini 位置等旧字段保持不变。
4. v1.0.4 再启动时可按默认值恢复新增字段。

因此采用：

```json
{
  "config_version": 8,
  "mini_edge_auto_hide": true,
  "mini_edge_dock": "none"
}
```

M6 必须为缺失字段和非法 `mini_edge_dock` 提供 Rust serde 默认与校验回退。无需创建第二份 `window-state.json`。

## 9. 验证入口

聚合入口：`scripts/verify_v104.ps1`。

M0 入口必须执行：

- M0 证据和夹具静态校验。
- M0 verifier 负向规则测试。
- Rust 几何与配置兼容测试。
- v1.0.3 回归基线与架构继承门禁。
- `git diff --check`。

任一步失败均返回非零退出码。后续 M1-M6 只扩展同一聚合入口，不建立第二套互相漂移的验证脚本。
