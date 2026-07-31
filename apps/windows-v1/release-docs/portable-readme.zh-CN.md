# LetsMakeMoney v{{VERSION}} 便携版

- 平台：{{PLATFORM}}
- 渠道：{{CHANNEL}}
- 形态：免安装便携 Zip

LetsMakeMoney 是本地优先的 Windows 收入进度工具。工资、作息、日期调整和日志均保存在本机。

## 启动

1. 将 Zip 完整解压到一个可写目录，不要直接在压缩包预览器中运行。
2. 双击 `LetsMakeMoney.exe`。
3. 首次启动时按向导填写月薪、休息模式和工作时间。
4. 应用隐藏后，可从 Windows 通知区的 LetsMakeMoney 图标找回或退出。

Windows 10/11 需要 Microsoft Edge WebView2 Runtime。启动失败时，请先确认系统已安装可用的 WebView2 Runtime，再重新打开应用。

## 数据与日志

配置、日志和本地状态位于：

```text
%APPDATA%\io.letsmakemoney.windows\
```

升级或回退前，请先从托盘退出应用，并备份该目录。解压新版本时建议使用新的程序目录；不要在程序运行期间覆盖 EXE 或 DLL。便携程序目录与用户数据目录相互独立。

## 更新与回退

- 应用内“检查更新”只查询公开 GitHub Release；下载和替换程序始终由用户确认。
- 本包不包含安装器、静默更新、自动替换程序或宠物功能。
- 需要回退时，退出当前版本并重新运行已保留的旧版便携目录；如需恢复旧配置，请先使用自己的配置备份。
- 发布文件和校验值见 [GitHub Releases](https://github.com/NzyZzz1998/LetsMakeMoney/releases)。

## 本包文档与许可

- [MIT 代码许可](LICENSE)
- [视觉素材许可](ASSETS_LICENSE.md)
- [素材清单](ASSETS_MANIFEST.md)
- [第三方声明](THIRD_PARTY_NOTICES.md)
- [版本变更](CHANGELOG.md)
- [English](README.en.md)

以上相对链接均指向本 Zip 内文件，断网时仍可阅读。

## 在线支持

- [项目仓库](https://github.com/NzyZzz1998/LetsMakeMoney)
- [问题反馈](https://github.com/NzyZzz1998/LetsMakeMoney/issues)
- [安全报告说明](https://github.com/NzyZzz1998/LetsMakeMoney/blob/main/SECURITY.md)

请勿在公开 Issue 中粘贴工资、完整配置、日志原文、用户名或本机绝对路径。
