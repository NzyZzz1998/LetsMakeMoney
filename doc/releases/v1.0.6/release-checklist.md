# LetsMakeMoney Windows v1.0.6 发布检查

## 当前判断

全部发布门禁已通过。正式附件来自 PR 合并后的干净 `main`，历史候选哈希未被复用；tag、Release 和回下载附件身份一致。

## 代码与合并

- [x] v1.0.6 定向范围完成且未扩展产品功能。
- [x] 历史候选自动门禁与真实 Windows 最小 GUI 冒烟通过。
- [x] 项目所有者授权发布。
- [x] 发布 PR #25 通过 `Windows v1 verification` 必需检查。
- [x] PR 以仓库允许的 squash 方式合入 `main`。
- [x] 合并后工作树干净，源码 HEAD 锁定为 `51e4c08da5260af9b9f4808c4f6d29591319e655`。

## 最终候选

- [x] 从合并后的干净 `main` 执行 `scripts/package_v106.ps1`。
- [x] `source_tree_dirty=false`，README、BUILD-INFO、版本与源码 HEAD 一致。
- [x] `scripts/verify_v106.ps1 -Milestone M6 -CandidatePath <Zip>` 通过。
- [x] Zip、EXE 与 WebView2Loader SHA256 已重新计算并记录。
- [x] 最小真实桌面冒烟覆盖浅色首帧、深色跨窗口预览和原生关闭确认；放弃事务由真实确认界面与行为测试共同证明。
- [x] 用户配置和日志精确恢复，结束后无 LetsMakeMoney 残留进程。

## GitHub 发布

- [x] annotated tag `v1.0.6` 指向最终合并提交。
- [x] Stable GitHub Release 仅上传便携 Zip 与 `SHA256SUMS.txt`。
- [x] GitHub 回下载 Zip SHA256 与本地锁定值一致。
- [x] published 模式验证通过。
- [x] 远端 `main`、tag、Release 标题、附件名和版本一致。

## 锁定身份

- 发布源提交：`51e4c08da5260af9b9f4808c4f6d29591319e655`。
- Zip SHA256：`AEE4BC4A41D3839E421138D0B152EA5A8B0FBDC60C5B189EA11790DE4ED8B66A`。
- EXE SHA256：`21EAC751534F4D0787DEC07545F315326E9C5D773F39D65D9F46AA1879518659`。
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`。
- Release：`https://github.com/NzyZzz1998/LetsMakeMoney/releases/tag/v1.0.6`。

## 停止条件

出现以下任一情况立即停止：

- 合并后源码或工作树不是预期干净身份。
- 必需 CI、M6、包体验证或桌面冒烟失败。
- Release 附件包含历史候选、日志、截图或其他临时文件。
- 回下载哈希与本地锁定值不一致。
