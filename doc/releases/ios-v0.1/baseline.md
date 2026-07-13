# iOS v0.1 开发基线

## 记录时间

2026-07-13（Asia/Shanghai）

## Windows 主线身份

| 对象 | 身份 |
| --- | --- |
| 主工作区 | `E:\codex\LetsMakeMoney` |
| 分支 | `main` |
| HEAD | `5c302efcc2edb868231c4c4d9f002e8355e03001` |
| 远端 `origin/main` | `5c302efcc2edb868231c4c4d9f002e8355e03001` |
| 最新 Windows tag | `v0.7-beta` |
| tag commit | `e79149d91e8e0adb3cbf1e53cd8819f072f7154f` |

主工作区在建立 Apple 工作区时含有未跟踪的 iOS PRD、原型、开发承接文档和 `.superpowers/`。这些内容未被删除或覆盖；仅 iOS 相关文档被复制到独立工作区。

## Windows v0.7 发布身份

| 产物 | 状态 | 大小 | SHA256 |
| --- | --- | ---: | --- |
| `releases/v0.7/LetsMakeMoney-v0.7-beta-windows-x86_64.zip` | 本地存在，已发布便携包 | 44,157,654 字节 | `16F47A844EFD78D387E9D08FBCD3DE76C8C8BDD518731C1B0BA022E7F598121F` |
| `releases/v0.7/SHA256SUMS.txt` | 本地存在 | 109 字节 | `264C2D7C055C09859EC3490FEC7BE2B0BC77268E07480F8B1D43753903217C62` |
| v0.7 测试安装器 | 当前主工作区已不存在 | 不适用 | 不适用 |

Apple 开发不得修改或重新包装上述 Windows 产物。

## Apple 独立工作区

| 对象 | 身份 |
| --- | --- |
| 工作区 | `E:\codex\LetsMakeMoney-ios` |
| 分支 | `ios-main` |
| 基线 HEAD | `5c302efcc2edb868231c4c4d9f002e8355e03001` |
| 远端分支 | 尚未创建/推送 |
| 当前状态 | iOS 文档和 M0 文件未提交 |

## 基线验证

```text
scripts/verify_v07.ps1：通过
scripts/check_docs_status.ps1：通过
```

运行时显式使用 Godot 4.7 console 路径；该路径只用于本地验证，未写入仓库配置。

## 边界结论

- 当前 HEAD：Windows v0.8 工程治理后的源码基线，不等于 iOS 实现。
- Windows v0.7 便携 Zip：已发布产物，身份锁定，不作为 Apple 构建输入。
- `ios-main`：从当前 `main` HEAD 创建的 Apple 开发分支。
- 未来公开/发布候选：必须在 iOS Acceptance 中重新锁定 HEAD、签名、归档和哈希。
