# v1.0.5 三窗单一表面真实壳 Spike

## 结论

- 结论：`通过（Windows 10 环境待补证）`。
- 决策：保留单一表面候选，进入 V105-M6 聚合门禁。
- 范围：仅 Workbench、Settings、Wizard；Mini 保持原有独立表面和阴影。
- 发布边界：本次对象来自 dirty 工作树，只能作为 M5 开发验证候选，禁止发布。

## 问题与最小改动

v1.0.4 的三个标准窗口同时由 Web `.window-frame` 和 Tauri 原生窗口绘制阴影，形成双重表面职责。M5 没有改窗口尺寸、内容结构、主题、拖动方式或业务功能，只执行以下调整：

1. `.window-frame` 继续负责背景、边框与圆角。
2. Tauri 原生窗口继续负责透明窗口与系统阴影。
3. 移除 `.window-frame` 的 CSS 阴影。
4. 为窗口根写入可测试的表面与阴影所有权标记。
5. `.mini-window` 继续使用原有 CSS 阴影，不纳入本次调整。

## 锁定对象

| 对象 | 身份 |
| --- | --- |
| v1.0.4 正式 Zip | `C4F28892831891A4266C4D9B12D432CD5C970BB3C9B36A6B8DB21FA2566DE50E` |
| v1.0.4 正式 EXE | `E0C9C603703FC2632619AFBC84F63B1B1D403273CD01D29AA0A308A95243E107` |
| M5 候选 ID | `V105-M5-20260801-032724` |
| M5 候选 EXE | `DF18CC5A3A99975CE1A8CEE965D0A83F2DB0FB5B4628F079FDA96D4262546A3B` |
| Native DLL | `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C` |

## 尺寸基线

| 窗口 | v1.0.4 | M5 候选 | 结论 |
| --- | ---: | ---: | --- |
| Workbench | 922×642 | 922×642 | 未改变 |
| Settings | 762×562 | 762×562 | 未改变 |
| Wizard | 782×582 | 782×582 | 未改变 |

## 真实 Windows 验证

| 检查 | 结果 | 说明 |
| --- | --- | --- |
| Windows 11 | 通过 | Windows 11 Pro，build 26200 |
| Windows 10 | 待补证 | 当前没有 Windows 10 设备或 VM，不以 Windows 11 推断通过 |
| 透明根、圆角、边框、阴影 | 通过 | Web 单表面与原生阴影职责分离，未见双框 |
| Workbench | 通过 | 浅/深主题、拖动、关闭、焦点恢复通过 |
| Settings | 通过 | 浅/深主题、拖动、保存、未保存关闭模态通过 |
| Wizard | 通过 | 浅色真实壳、拖动与退出模态通过；深色由主题合同覆盖，独立 ACC 再补实机 |
| Mini | 通过 | 隐私竖条、展开及独立阴影未受影响 |
| 100% DPI | 通过 | 三窗无裁切、重叠或异常尺寸 |
| 125% DPI | 通过 | 使用真实 Windows 系统缩放验证 |
| 150% DPI | 通过 | 使用真实 Windows 系统缩放验证 |

## 自动门禁

- 窗口表面合同：`16/16`。
- Rust：`54/54`。
- TypeScript strict、Vite production build、Rust fmt、clippy 与 release build：通过。
- 三个 `WindowFrame` 消费点固定为 Workbench、Settings、Wizard。
- Mini 被自动门禁排除在 `WindowFrame` 表面调整之外。

## 环境恢复

- Windows 缩放已恢复为 100%，`AppliedDPI=96`。
- 两项 per-monitor DPI 值均恢复为 `0`。
- `config.json`、`config.json.previous` 与 `debug.log` 按备份哈希恢复。
- 测试后 LetsMakeMoney 进程数为 `0`。

## 回退与失效条件

候选按门禁保留。出现以下任一情况时，必须回退本次两处表面改动并恢复 v1.0.4 双表面实现，再重新执行 M5 与 ACC：

- `.window-frame` 再次拥有 CSS 阴影。
- Tauri 原生窗口关闭透明或阴影能力。
- 三个窗口任一尺寸变化、圆角裁切、拖动失效或模态异常。
- Mini 阴影、隐私竖条或展开行为发生变化。
- 100%/125%/150% DPI 任一档出现裁切、模糊或双边框。
- 候选 EXE、Native DLL、窗口表面代码或本证据摘要发生变化。

Windows 10 证据保留为独立 ACC 的环境待补项，不将其伪装为通过。
