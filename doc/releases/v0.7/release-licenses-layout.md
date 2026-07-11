# v0.7 发布包许可结构

## 便携 Zip 与安装器应用目录

```text
LetsMakeMoney-v0.7-beta-windows-x86_64/
  LetsMakeMoney.exe
  letsmakemoney_native.dll
  app_icon.ico
  README.md
  release-notes.md
  manifest.json
  checksums.txt
  LICENSES/
    PROJECT_LICENSE.txt
    ASSETS_LICENSE.md
    ASSETS_MANIFEST.md
    THIRD_PARTY_NOTICES.md
    dependencies.json
    third-party/
      Godot/LICENSE.txt
      Godot/COPYRIGHT.txt
      godot-cpp/LICENSE.md
      MinGW-w64/COPYING
      MinGW-w64/COPYING.RUNTIME
      GCC/COPYING3
      GCC/COPYING.RUNTIME
```

开发工具许可证可以保留在源码树 `licenses/third-party/`，不要求全部复制到最终用户包；运行时/静态链接相关原文必须进入 `LICENSES/third-party/`。

## 安装器额外要求

- 安装器显示代码 MIT、视觉素材受限许可和第三方 notices 的入口。
- 安装后应用目录保留上述完整 `LICENSES/`。
- Inno Setup 版本与许可进入依赖 manifest；安装器未固定/未签名时不得发布。
- 卸载许可不删除用户配置的默认策略与许可文件本身无冲突。

## 门禁

`scripts/stage_release_licenses.ps1` 负责复制许可；`scripts/check_third_party_compliance.ps1 -PackageRoot <目录>` 负责检查必需文件、manifest、版本、未知 DLL/字体及排除目录。任一失败必须非零退出。
