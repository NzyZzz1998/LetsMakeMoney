# LetsMakeMoney v0.7 Beta 开发日志

> 本文记录 v0.7 开发过程、关键决策、异常处理和验证摘要。它不替代 `progress_v0.7.md`；progress 只保留状态看板和最小任务 checklist。

## 基本信息

- 版本：v0.7 Beta
- 对应 PRD：`doc/releases/v0.7/prd.md`
- 对应 dev plan：`doc/releases/v0.7/dev_plan_v0.7.md`
- 对应 progress：`doc/releases/v0.7/progress_v0.7.md`
- 对应追踪矩阵：`doc/releases/v0.7/traceability.md`
- 当前阶段：V07-A0/A1/A2/A3 与远端历史重写已完成；等待进入 B1
- 最后更新：2026-07-11

## 开发记录

### 2026-07-11 / V07-A3 完整 Git 历史、隐私与资产审计

- 审计范围：当前候选快照、所有本地/远端可达分支、全部 tag、33 个提交、844 个 Git 对象和 551 个 blob。
- 秘密扫描：使用经官方 checksums 校验的 Gitleaks 8.30.1 和 TruffleHog 3.95.9；当前树及完整历史均为 0 命中。TruffleHog 关闭联网验证，避免潜在值外传。
- 对象审计：历史有 97 个二进制 blob、7 个大于 1 MiB 的 blob、1 个 Zip；没有 EXE、DLL、私钥、用户配置、运行日志或私有验收目录。
- 隐私审计：历史包含本机绝对路径和作者身份元数据。作者邮箱已获所有者接受公开；用户名和路径只以类别与计数记录，不复制原值。
- 资产交叉检查：A1 证明运行时橘猫、占位猫和图标可按受限许可公开；历史 `temp/`、实验素材和 ComfyUI 内容虽无权属未知项，但与既定排除政策冲突。
- 隐私回归：新增诊断摘要样例测试，注入用户名、用户目录、私有路径、薪资、坐标和伪 token；摘要均未泄露。
- 决策边界：P0 为 0；所有者随后选择方案 3。历史重写与复验完成前不公开，不用 ignore 或白名单掩盖历史。
- 转交：B3 清理当前树的 `temp/`、实验内容和 ComfyUI 资料；B1/B3/E1 清理活跃绝对路径；历史处置仍由所有者决策。
- 边界：未修改业务代码、未删除/移动/取消跟踪文件、未重写历史、未执行远端操作。

### 2026-07-11 / V07-A3 所有者签核与历史重写准备

- 所有者决策：不接受历史披露，选择方案 3；要求清除所有临时内容、ComfyUI 文档/脚本、本机绝对路径和个人作者邮箱。
- A3 状态：12/12 完成。该签核仅授权制定并准备历史重写，不代表历史已清洁或仓库可公开。
- 方案产物：新增 `git-history-rewrite-plan.md`，定义精确路径删除、私有文本替换表、仓库外邮箱映射、独立 mirror、双备份、复扫、tag/Release 对齐和回滚门禁。
- 安全边界：当前工作区有大量未提交 v0.7 改动，禁止直接运行 filter-repo；实际重写必须在独立镜像中执行，远端在验收前保持不变。

### 2026-07-11 / Git 历史重写本地镜像演练

- 保护措施：创建并验证完整 Git bundle，保存 tracked binary patch、59 个 untracked 文件和 SHA256 清单；当前工作区未改写。
- 工具：隔离安装 git-filter-repo 2.47.0；重新下载并校验 Gitleaks 8.30.1 与 TruffleHog 3.95.9 官方归档。
- 演练修正：识别并修复规则文件 BOM、作者名 BOM、PowerShell 占位符非法路径和 v0.4 ComfyUI Spike 旧断言四类问题；每次从 pristine 重新生成。
- 最终结果：32 个提交；新 main `bec93b9...`；目标路径、绝对路径和旧个人邮箱残留均为 0；作者身份统一为 GitHub noreply。
- 差异审计：main 共有 95 个变化路径，其中 70 个计划内删除、25 个路径/测试调整、0 个新增、0 个非预期删除。
- 验证：Gitleaks/TruffleHog 0 命中，git fsck 通过；v0.4/v0.5/v0.6、配置、M4、M5 导出冒烟和托盘双模式回归通过。
- 后续迁移：最新 v0.7 工作已复制到清洗后的独立 main，清理当前树 5 条绝对路径警告并形成本地候选提交；公开检查和双扫描均为 0。
- 演练阶段边界：当时尚未修改正式本地仓库或远端 heads/tags/Release；后续执行结果见下一节。

### 2026-07-11 / Git 历史远端替换与 fresh clone 复验

- 经所有者明确授权，使用逐 ref lease 和原子强制推送替换 `main`、`test` 与 v0.2-v0.6 tags；不存在并发覆盖。
- fresh clone 首轮发现 Inno Setup 许可证 CRLF/LF 哈希不可复现；同步脚本改为先验证上游 CRLF 哈希，再保存 LF 规范化仓库副本，manifest 固定规范化哈希。
- 首轮修复后远端 main 为 `451311a...`；fresh clone 的第三方合规、公开候选、双扫描、v0.4-v0.6、M4/M5 和托盘双模式均通过。
- 最终作者身份复核发现顶部 3 个 v0.7 提交继承本机 Git 邮箱；使用完整 bundle 备份后，在文件树哈希不变的前提下将作者和提交者统一为 GitHub noreply 身份，并再次执行远端带 lease 强制替换与全量复验。
- 正式本地项目切换到新历史；旧 `.git`、bundle、工作区快照和排除内容均保存在仓库外，没有删除。
- 限制：自动化浏览器没有私有 GitHub 登录态，Release 页面附件关联需人工只读确认；仓库保持 private。

### 2026-07-11 / 路径发现与 fresh clone 可复现性收尾

- fresh clone 发现 Inno Setup 上游 CRLF 原文在 Git LF checkout 后与旧 manifest 哈希不一致；同步脚本现先验证上游字节，再保存 LF 规范化副本并固定其哈希。
- 未设置 `LMM_GODOT_EXE` / `LMM_GODOT_ROOT` / `LMM_MSYS2_BASH` 时，历史路径替换留下空候选；相关验证和构建入口现跳过空值并给出可读的工具发现错误。
- 受影响脚本在显式环境变量下通过 v0.2、M3、M5 和当前 v0.4-v0.7 回归；无环境变量路径确认不再触发 `Test-Path` 空字符串异常。
- `verify_v03.ps1` 仍因既有“首次向导模态准备路径”断言失败，属于历史 wrapper 与当前实现的兼容债；本轮不修改业务逻辑，转交 B2 统一历史 wrapper 治理。

### 2026-07-11 / V07-A2 第三方依赖与 Release 合规

- 本轮目标：建立源码、构建工具和最终分发物之间可交叉验证的第三方合规链路。
- 本机取证：Godot 4.7 stable commit `5b4e0cb0f`；godot-cpp `ba0edfed...` 且 checkout 干净；Python 3.12.8；SCons 4.10.1；Pillow 12.2.0；GCC 16.1.0-5；MinGW CRT/headers `14.0.0.r92.g818fa6510-1`。
- 二进制边界：`objdump` 显示 native DLL 只动态依赖 Windows/UCRT 系统 DLL；保守随包提供 MinGW runtime notices 与 GCC Runtime Library Exception。
- 合规产物：新增人工/机器依赖清单、THIRD_PARTY_NOTICES、13 份带哈希许可证原文、包内 `LICENSES/` 规范、许可同步/staging/check 脚本和测试。
- 计划依赖：Inno Setup 未安装且版本未定，安装器保持阻塞；GitHub Actions 未选择，后续必须固定 commit 并记录许可。
- 定向测试：正常包通过；缺依赖条目、缺许可证、未知 DLL、未知字体、notices 版本不一致均失败。
- v0.6 只读审计：历史包缺少 v0.7 `LICENSES/` 结构，因此不满足未来公开合规；未修改或重新打包。
- 转交：godot-cpp 固定获取与干净构建进入 B1；Actions 进入 B2/E3；Inno/签名进入 C1/C2；已跟踪 temp 和历史风险进入 A3/B3。
- 边界：未修改业务代码、Main/native、旧发布包或 Git 历史，未创建 CI/安装器/更新器，未执行远端操作。

### 2026-07-11 / V07-A1 MIT 与受限素材许可

- 本轮目标：建立代码与视觉素材的可审计双许可边界，不改变运行行为。
- 关键决策：原创代码和代码文档采用 MIT，版权口径为 `2026 NzyZzz1998`；橘猫、占位猫、Logo、应用/托盘图标和可提取品牌视觉采用独立受限许可。
- 资产取证：运行时三套宠物资源为橘猫 v2、橘猫 v1 回退和旧占位猫。所有者确认这些角色、Logo、图标和相关 AI 视觉由本人主导生成并拥有官方公开所需权利。
- 排除范围：`_review`、`experiments/ai_cat_assets`、`temp/` 不纳入公开素材授权。
- 实施结果：新增 MIT、受限素材许可、人工/机器清单、所有者确认、目录入口、中英文 README 许可入口和贡献边界。
- 自动门禁：许可检查器要求每个候选视觉有清单覆盖；未知状态、缺文件、缺入口或未登记视觉均失败。
- 验证：真实项目检查通过；正常夹具通过，未登记 PNG 夹具失败。
- 转交：第三方依赖许可与包内 notices 进入 A2；已跟踪排除素材及完整历史进入 A3。
- 边界：未删除或移动素材，未修改业务代码、发布包或 Git 历史，未执行 Git 远端操作。

### 2026-07-11 / V07-A0 事实冻结与公开候选边界

- 本轮目标：冻结 v0.6 发布身份、当前脏工作区和未来公开候选边界，不改业务代码。
- 关键事实：
  - 当前 `main` HEAD 与 `v0.6-beta` tag 均指向 `e6f25ae8cb4d9583aa3e629cb79416e278060117`。
  - v0.6 验收代码记录为 `77cef5cf3f8dc39e695f12d03e12598aa7260fee`；最终发布提交与验收代码身份分开记录。
  - 已验收 Zip SHA256 为 `CECD3C3ABACFCB5EF594584E2AEB0E25C1824BAE97AB84B224073E7444E72615`；EXE 为 `749F18E...943E3B`；native DLL 为 `AB57D372...FF696`。
- 实施结果：
  - `doc/current.md` 切换为 v0.7 私有开发事实入口。
  - 建立 v0.7 status、verification、public-readiness、公开候选清单和排除清单。
  - `.gitignore` 增加本地验收、发布展开、运行数据、签名材料和安装/更新中间产物规则。
  - 增加只读当前树检查器及正反夹具测试；脚本采用纯 ASCII 源码，兼容 Windows PowerShell 5 的默认脚本解码。
  - 文档状态检查升级为同时验证 v0.7 私有开发和 v0.6 已发布基线。
- 验证摘要：
  - 检查器测试通过；文档状态、严格 UTF-8、活跃 Markdown 链接、ignore 命中/误伤和补丁格式通过。
  - 当前树扫描 432 个候选文件，返回 44 个失败和 31 个警告。失败来自已跟踪 `temp/` 路径及其中一个 Zip；警告为 Windows 绝对路径。
  - `doc/releases/v0.6/` 无差异，历史验收结论未被改写。
- 转交：`temp/`、`experiments/`、素材权属和绝对路径进入 A1/A2/A3；完整 Git 历史只在 A3 扫描。
- 边界：未删除、移动或取消跟踪文件；未修改业务代码；未 commit、push、tag、Release 或修改可见性。

### 2026-07-11 / 开发承接

- 本轮目标：将已确认的完整 PRD 和高保真原型转换为可执行开发计划与最小任务看板。
- 改动模块：仅 v0.7 开发承接文档。
- 关键实现：
  - 按 V07-A 至 V07-E 建立公开治理、工程质量、Windows 分发、未来规划和社区治理里程碑。
  - 将 `FR-001` 至 `FR-014`、`IDEA-001` 至 `IDEA-017` 映射到开发模块。
  - 将 Main/native 行为测试和状态合同设为深度治理强制前置门禁。
  - 将安装器、签名、更新和回退拆成独立模块与独立发布门禁。
  - 将仓库公开放在开发完成后的独立 Acceptance 与项目所有者确认之后。
- 遇到的问题：无 PRD 阻塞项。
- 处理方式：保留证书供应商、更新请求细节、脚本最终命名和 Dependabot/CodeQL 作为对应阶段前的工程决策，不扩大产品范围。
- 已验证：承接文档结构与 v0.6 风格一致；业务代码未修改。
- 未验证/待补证：全部实现、自动验证、真实 Windows 验收和公开门禁均尚未开始。
- 关联 bugfix/spike：无。

### 2026-07-11 / 仓库公开策略与多平台优先级调整

- 项目所有者确认 A0-A3 已足以关闭源码仓库公开的安全、许可、历史与隐私门禁，授权仓库先公开，B-E 继续作为 v0.7 工程、分发与发布门禁。
- 仓库公开不代表 v0.7 已发布；tag、安装器、便携 Zip、更新能力和 GitHub Release 仍须完成对应实现与独立验收。
- 多平台路线优先级调整为 iOS、macOS、Android；v0.7 只建立路线规划，不修改平台代码。
- 新增 `roadmaps/platform-roadmap.md`，记录 iOS 产品形态、沙盒、后台、签名和 App Store 研究边界。
- GitHub 公共 API 返回 `private=false`、`visibility=public`、默认分支 `main`，仓库公开动作已完成核验。

### 2026-07-11 / V07-B1 固定依赖与可复现构建

- 新增 `third_party/native-toolchain.lock.json`，固定 Godot 4.7 stable、godot-cpp、Python、SCons、MSYS2/GCC 与 MinGW-w64 身份。
- 新增 `bootstrap_native_dependencies.ps1`：使用镜像缓存，只检出固定 godot-cpp commit，支持离线恢复、显式替换和安全清缓存。
- 重写 native 构建入口：参数/环境变量/自动发现分层；构建前强制校验 lock、Godot SHA256 和 godot-cpp commit；输出完整工具链身份。
- 仓库外全新工作区完成在线 bootstrap、仅缓存离线恢复、`template_debug` 和 `template_release` 构建。Debug 首次构建约 15 分钟，Release 追加约 11 分钟；以后 CI 需要缓存和独立超时。
- 正反向测试覆盖缺离线缓存、错误 commit、错误 Godot SHA256 和缺失 MSYS2。重复补哈希冷构建被主动终止，相关子进程已清理，不作为失败门禁。
- native README 与中英文入口已补充固定依赖、离线缓存、失败处理和首次构建耗时。

### 2026-07-11 / V07-B2 CI 与验证/打包脚本治理

- 新增参数化 `package_common.ps1` 与 `verify_package_common.ps1`，v0.4-v0.6 仅保留版本 wrapper。
- 统一隔离 APPDATA、阻塞输出判定、manifest/checksum、未知二进制和许可 staging 门禁。
- Windows PowerShell 5.1 不支持 `Path.GetRelativePath()`，公共打包内核改用安全前缀校验后的兼容相对路径实现。
- 新增 docs/compliance 与 native/Godot 两条 Windows Actions；权限只读，缓存键包含 native lock，Fork PR 不读取发布秘密。
- 新增机器可读验证摘要，使本机与 CI 可比较步骤、状态和退出码。
- 真实托盘、任务栏、点击穿透、DPI、多显示器和签名明确留给候选产物 Acceptance。

### 2026-07-11 / V07-B3 低风险代码与仓库瘦身

- 调用、scene、signal、动态调用和测试引用交叉检查确认 Settings 旧 `_build_ui` 不在运行链路。
- 先建立 Settings 五页与 Wizard 四步运行态节点契约，再移除旧 UI 函数、三个无调用 helper 和 v0.2 测试适配 API。
- v0.2 验证改为检查当前真实字段，避免为历史测试永久保留生产 API。
- v0.4 的旧静态断言同步到当前低权重状态说明结构，不保留死函数来迎合测试。
- A3 历史重写后当前树已无被跟踪的临时目录、实验素材和 ComfyUI 脚本；历史产品决策文档保留为事实，不再作为运行时入口。
- 当前源码重新导出并完成含许可证的受控 Zip 启动烟测；Pet/Salary、降级托盘、导入元数据和状态缓存未修改。

### 2026-07-11 / V07-B4 Main/native 行为测试与状态合同

- 新增窗口与原生状态合同，明确 DragResizeSystem、Main、Platform、WindowsPlatform 和 native controller 的唯一所有权。
- 新增机器可读 native 协议，冻结托盘 callback message、0-5 命令 ID、布尔返回值与 last_error 语义。
- 将普通/纯桌宠、Popup/Modal、native available/degraded/unavailable、退出和多显示器/DPI 组合纳入回归矩阵。
- 当前导出 EXE 的普通模式和纯桌宠模式托盘各完成 2 轮 PostMessage 行为回归。
- 合同评审未发现必须先改业务语义的冲突，允许进入 B5 分阶段治理；每个切面仍须独立回退。

### 2026-07-11 / V07-B5 Main/native 分阶段治理

- 第一切面新增纯逻辑 `WindowPolicyCoordinator`，统一普通/纯桌宠任务栏意图与 Popup/Modal 穿透启用判定；Main 保留布局和执行职责。
- 第二切面为 Platform fallback 与 WindowsPlatform 增加 available/degraded/unavailable capability 状态及逐能力 last_error，同时保留 v0.6 布尔兼容字段。
- 第三切面将托盘 callback、命令 ID 和返回值常量提取到共享 native protocol header，并与机器可读 JSON 合同交叉验证。
- native 编译发现非 MSYS 构建分支把 `-j$Jobs` 当字面量，已改为展开后的独立参数；Release 冷构建通过。
- 当前源码重新导出，普通和纯桌宠模式各完成 10 轮托盘显隐与任务栏策略回归。
- 未进行一次性 Main/native 重写；多显示器、DPI、真实通知区和任务栏继续留给候选产物验收。

## 关键决策

| 决策 | 背景 | 取舍 | 影响范围 | 后续观察 |
|---|---|---|---|---|
| A-E 全部完成后再公开 | 项目所有者明确要求 | 周期更长，但不将法律和工程债转嫁给公开用户 | 全版本 | Acceptance 前保持私有 |
| 代码 MIT、素材受限 | 代码与 AI 视觉素材权利不同 | 降低素材被误用风险，但需显著双许可说明 | 仓库、README、Release | 检查每个资产目录入口 |
| 保留完整 Git 历史 | 所有者接受作者邮箱公开 | 保留演进脉络，但历史审计成为 P0 | Git 历史 | 发现凭据先轮换，未经授权不改历史 |
| 固定 godot-cpp bootstrap | 当前依赖未固定且依赖本机缓存 | 增加脚本工作量，换取外部可复现 | native、CI | 干净和离线构建均验证 |
| Inno Setup + 签名门禁 | 需要传统安装器和可信分发 | 无签名时不发布安装器，Zip 可独立存在 | Windows Release | 证书供应商待 C2 前确认 |
| 用户确认更新 | 不接受静默替换 | 更新步骤更多，但用户知情且可回退 | Settings、退出、安装器 | 网络和签名失败必须非阻塞 |
| Main/native 分阶段治理 | 当前多层状态缓存风险高 | 拒绝一次性重写，先测试和状态合同 | Main/Platform/native | 每阶段独立回退 |
| 外部素材贡献暂不接受 | 受限素材许可与授权复杂 | 降低社区范围，但保留代码/UI/native 贡献 | CONTRIBUTING | 后续版本可重新评估 |
| 未来方向只做规划 | 多平台、主题、宠物均未成熟 | 不过度设计 v0.7 | 文档 | 不得标记产品能力已实现 |

## Bugfix 摘要

当前无 v0.7 bugfix。发现具体缺陷后创建 `doc/logs/v0.7-bugfix-log.md`，本节只保留摘要链接。

## Spike / 技术探索摘要

| 主题 | 当前结论 | 是否进入本版本 | 后续动作 |
|---|---|---|---|
| Main/native 状态合同 | 强制前置，尚未执行 | 是 | V07-B4 完成后才进入 B5 |
| Authenticode 证书托管 | 必须签名，供应商未定 | 是 | V07-C2 前形成安全方案 |
| Dependabot/CodeQL | 不机械启用 | 条件性 | V07-E3 评估信噪比 |

## 验证摘要

- 自动化验证：尚未进入实现；仅完成文档格式、UTF-8 和差异检查。
- 手动验证：高保真原型已在 PRD 阶段完成浏览器检查。
- 打包验证：尚未开始 v0.7 打包。
- 未覆盖项：所有业务实现、Main/native 状态矩阵、安装器、签名、更新、干净环境构建和公开 Acceptance。

## 收尾事项

- 文档同步：dev plan、progress、dev log 已建立。
- 发布说明：尚未创建 v0.7 发布结论。
- 回滚方式：当前仅文档变更，可独立回退；业务实现尚未发生。
- 下一阶段建议：项目所有者确认开发承接后，从 V07-A0 开始实现。
