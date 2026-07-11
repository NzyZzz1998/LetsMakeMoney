# v0.7 当前阶段摘要

**阶段**：V07-A0/A1/A2/A3 已完成；历史重写本地镜像演练通过，远端未执行
**仓库状态**：私有，不得公开
**发布状态**：v0.7 未验收、未打包、未发布

## 已完成

- A0：冻结 Git、v0.6 发布身份、公开候选与排除边界。
- A1：MIT 代码许可、受限素材许可、资产清单和所有者签核。
- A2：第三方人工/机器清单、许可证原文、notices、`LICENSES/` 结构、staging 与检查脚本。
- A3：当前树与 33 个可达提交的双专业秘密扫描、Git 对象/路径/资产审计和诊断隐私回归；P0 为 0。

## 当前阻塞

- 项目所有者已选择方案 3。本地独立镜像已经完成清洗、双扫描和回归；当前 v0.7 工作迁移及远端 heads/tags 替换尚未执行，仓库必须继续保持私有。
- B1 尚未实现固定 godot-cpp 获取、工具链锁定和从零构建。
- Inno Setup 版本未选择，安装器未形成；GitHub Actions 尚未选择。
- 当前 v0.6 Zip 没有 v0.7 `LICENSES/` 结构，只能作为历史发布基线，不能作为公开合规候选。

## 事实入口

- 项目入口：`doc/current.md`
- A2 依赖清单：`doc/releases/v0.7/third-party-dependencies.md`
- 机器清单：`third_party/dependencies.json`
- 验证：`doc/releases/v0.7/verification.md`
- 公开门禁：`doc/releases/v0.7/public-readiness.md`
