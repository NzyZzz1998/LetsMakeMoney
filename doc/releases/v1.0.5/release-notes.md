# LetsMakeMoney Windows v1.0.5 发布说明草案

> 状态：**独立验收候选，不可发布。** 本文不是 GitHub Release 说明；最终内容必须由独立验收和项目所有者发布授权锁定。

## 本版重点

### Mini 隐私贴边

- 修复首次拖到屏幕边缘后必须再次交互才收起的问题。
- 收起后保留可读的非金额隐私竖条，展示“距离上班 / 休息 / 恢复工作 / 下班”等阶段信息。
- 竖条禁止显示月薪、今日已赚、日薪、时薪、日期或精确工作制度。
- 普通窗口焦点不再误触发显式找回；托盘、键盘和点击找回仍保留。

### 日历与窗口质感

- official 正常态不再常驻展示来源块；estimated、stale、loading 与 error 保留明确风险提示。
- “今天”使用角标、字重和复合 ARIA 语义，不覆盖日期原有的工作/休息/手动调整状态。
- Workbench、Settings 和 Wizard 统一为单一表面职责，减少双层边框与阴影观感。

### 发布可信度

- 开发候选只写入隔离目录，不覆盖正式发布缓存。
- candidate 与 published 包验证采用不同身份合同。
- 版本、源码 HEAD、dirty 状态、Zip、EXE、DLL 和离线 README 建立交叉验证。

## 兼容性

- Windows 10/11 x86_64；Windows 10 真实视觉证据仍待补充。
- 收入、日历数据、日期调整、主题和配置 schema 保持 v1.0.4 兼容。
- 不恢复宠物，不新增账号、云同步、安装器或静默更新。

## M6 受控候选

- 候选 ID：`V105-20260801T002456Z-277b121b-clean`
- 源码状态：`clean`，`source_tree_dirty=false`
- Zip SHA256：`BE2E1004427859AD30A4A4B23B12C00CF8A5EBD69F7A2442F345813F28CA521C`
- EXE SHA256：`0B650A0DF85A315104BDDA0B5E0E0B1E0D97DA21A5B96D72C26217FC3206A25A`
- WebView2Loader SHA256：`8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`
- 发布状态：**不可发布**。

## 发布前仍需完成

1. 对唯一 clean 候选执行独立验收并恢复用户环境。
2. 关闭验收发现的发布阻塞，或明确记录待补证边界。
3. 获得项目所有者单独的 push、tag 与 Release 授权。
