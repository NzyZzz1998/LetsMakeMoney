# LetsMakeMoney Windows v1.0.6 发布检查

## 当前判断

技术门禁、候选验收和项目所有者授权已通过。正式发布必须从 PR 合并后的干净 `main` 重建；最终身份生成前不得复用任何历史候选哈希。

## 代码与合并

- [x] v1.0.6 定向范围完成且未扩展产品功能。
- [x] 历史候选自动门禁与真实 Windows 最小 GUI 冒烟通过。
- [x] 项目所有者授权发布。
- [ ] 发布 PR 通过 `Windows v1 verification` 必需检查。
- [ ] PR 以仓库允许的 squash 方式合入 `main`。
- [ ] 合并后工作树干净，源码 HEAD 唯一锁定。

## 最终候选

- [ ] 从合并后的干净 `main` 执行 `scripts/package_v106.ps1`。
- [ ] `source_tree_dirty=false`，README、BUILD-INFO、版本与源码 HEAD 一致。
- [ ] `scripts/verify_v106.ps1 -Milestone M6 -CandidatePath <Zip>` 通过。
- [ ] Zip、EXE 与 WebView2Loader SHA256 已重新计算并记录。
- [ ] 最小真实桌面冒烟覆盖浅色首帧、深色跨窗口预览、原生关闭确认与放弃回滚。
- [ ] 用户配置和日志精确恢复，结束后无 LetsMakeMoney 残留进程。

## GitHub 发布

- [ ] annotated tag `v1.0.6` 指向最终合并提交。
- [ ] Stable GitHub Release 仅上传便携 Zip 与 `SHA256SUMS.txt`。
- [ ] GitHub 回下载 Zip SHA256 与本地锁定值一致。
- [ ] published 模式验证通过。
- [ ] 远端 `main`、tag、Release 标题、附件名和版本一致。

## 停止条件

出现以下任一情况立即停止：

- 合并后源码或工作树不是预期干净身份。
- 必需 CI、M6、包体验证或桌面冒烟失败。
- Release 附件包含历史候选、日志、截图或其他临时文件。
- 回下载哈希与本地锁定值不一致。
