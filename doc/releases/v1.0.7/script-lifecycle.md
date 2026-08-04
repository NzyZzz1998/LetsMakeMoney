# LetsMakeMoney Windows v1.0.7 脚本生命周期

## v1.0.7 发布工程入口

- current 聚合：`scripts/verify_windows_current.ps1`
- current 发布复核：`scripts/verify_v107.ps1`
- current M7 门禁：`scripts/verify_v107_m7.ps1`
- reusable 包体身份：`scripts/verify_v107_package.ps1`
- manual 事务式打包：`scripts/package_v107.ps1`

打包入口会复用冻结的通用事务实现，但不会改写 v1.0.5/v1.0.6 历史包装脚本。脏工作树候选始终记录 `publication_allowed=false`；published 模式只接受干净 source HEAD、tag、Release URL、回下载缓存和校验文件一致的对象。

## 唯一当前入口

当前开发和 CI 只允许使用：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_windows_current.ps1
```

该入口读取 `scripts/current-manifest.json`，只调用 lifecycle 为 `current` 或 `reusable` 的门禁。任何版本化历史脚本都不能替代当前门禁。

## 生命周期

| 状态 | 含义 | 调用规则 |
| --- | --- | --- |
| `current` | v1.0.7 当前必需门禁 | 由唯一 current 入口调用 |
| `reusable` | 跨版本稳定工具 | current 入口可调用，但不得承载某个历史版本身份 |
| `manual` | 需要明确环境、人工批准或外部证据的工具 | 不进入默认 CI；必须显式传入保护参数 |
| `historical` | 仅用于复核对应旧版本 | current manifest 引用时必须失败 |

机器索引位于 `scripts/script-lifecycle.json`。验证器要求仓库中每个 `scripts/*.ps1` 恰好出现一次；缺失、重复或陈旧路径都会失败。

## v1.0.7 条件工具

- `scripts/collect_v107_performance.ps1`：manual。只采集脱敏性能指标；需要显式允许用户配置目录证据，并在结束后恢复配置与日志。
- `scripts/spike_v107_csp.ps1`：manual。只在隔离构建中覆盖 CSP；正式 `tauri.conf.json` 不得被写回。

## 历史误用保护

`apps/windows-v1/tests/verify_v107_m1.py` 和 `scripts/verify_current_manifest.py` 覆盖以下负向场景：

- current manifest 版本错误；
- current manifest 引用 historical 脚本；
- current gate 文件不存在；
- lifecycle 索引缺少、重复或包含陈旧脚本；
- CI 直接调用版本化 verify/package 脚本。

历史脚本保持不可变证据。v1.0.7 不批量重写旧脚本，只阻止它们被误当作当前绿色门禁。
