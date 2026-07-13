# salary-schema v1 契约目录

## 当前阶段

M0 只冻结目录与责任边界；机器可读 schema、测试向量和 Swift Codable 实现由 M1 完成。

## 计划内容

```text
shared/salary-schema/v1/
  schema.json
  examples/
  vectors/
  README.md
```

## 契约边界

- 用途：未来配置口令的一次性迁移基础，以及 Windows/Swift 算法测试向量对齐。
- v1 不实现口令编码、加密、签名、二维码、导入或导出 UI。
- v1 不预埋加班字段；后续通过 schema 版本升级扩展。
- 金额统一使用最小货币单位整数。
- 时间为不带日期的本地时间；测试向量必须显式提供日期、时区和当前时刻。
- 未知字段处理、必填字段、错误码和版本升级在 M1 固定。
