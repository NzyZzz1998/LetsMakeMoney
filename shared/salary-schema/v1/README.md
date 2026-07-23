# salary-schema v1

## 目的

`salary-schema v1` 是 LetsMakeMoney Windows 与 Apple 产品线共享的工资配置与计算测试契约。它只描述可迁移的基础配置，不实现口令编码、加密、签名、二维码或导入导出界面，也不预埋加班字段。

## 兼容策略

- `schemaVersion` 必须等于 `1`。低版本先显式迁移，高于 `1` 的文档必须拒绝覆盖。
- 当前运行配置采用严格写入：未知字段会被拒绝，避免旧客户端静默覆盖新字段。
- 未来导入预览可以保留原始 JSON 中的未知字段，但 v1 不提供导入功能。
- 金额统一使用最小货币单位整数；CNY 的 `1200000` 表示 `12000.00` 元。
- 日期使用 `YYYY-MM-DD`，本地时间使用 24 小时制 `HH:mm`。测试向量额外显式提供 IANA 时区和当前时刻。
- Apple 与 Windows/reference 实现必须读取同一组 `vectors/salary-vectors.json`。

## 配置字段

| 字段 | 类型 | 约束 |
| --- | --- | --- |
| `schemaVersion` | 整数 | 固定为 `1` |
| `monthlySalaryMinor` | 整数 | 大于等于 0 |
| `currencyCode` | 字符串 | 三位大写 ISO 4217 代码 |
| `restMode` | 枚举 | `doubleWeekend`、`singleWeekend`、`alternatingWeekend` |
| `alternatingAnchor` | 日期或 `null` | 大小周时必须提供已知双休周的周六 |
| `workStart` / `workEnd` | 本地时间 | 开始必须早于结束 |
| `lunchStart` / `lunchEnd` | 本地时间 | 必须完整位于工作区间内且开始早于结束 |
| `standardWorkSeconds` | 整数 | 1 至 86400 |
| `dateOverrides` | 数组 | 同一日期不可重复，优先级高于官方数据和周规则 |
| `holidayDatasetVersion` | 字符串 | 对应 `holidays/manifest.json` 数据身份 |
| `notificationPreference` | 枚举 | `notRequested`、`allowed`、`denied` |
| `watchMetric` | 枚举 | `remainingTime`、`todayIncome`、`progress` |

日期覆盖包含 `date`、`isWorkday`、`isPaid`，可选 `effectiveWorkSeconds`。特殊计薪工作日按 `effectiveWorkSeconds / standardWorkSeconds` 调整当日满额收入；它不是加班记录。

## 规则优先级与计算

```text
手动日期覆盖 > 官方节假日/调休 > 周休规则
```

- 双休：周一至周五工作。
- 单休：周一至周六工作。
- 大小周：周一至周五工作；周日休息；锚点所在周六为休息，之后按自然周交替。
- 月工作日为当月所有“应工作且计薪”的日期数量。
- 日薪以整数最小货币单位按“除数一半向上”舍入。
- 今日收入按有效工作秒数线性计算；午休期间不增长，下班后封顶。
- 本月累计按当前月配置重算：已过去计薪工作日计满额，今日计实时收入，未来日期不计。
- 官方数据覆盖范围之外回退到周休规则，并输出 `holidayDatasetOutOfRange` 警告。

## 状态与错误

状态：`beforeWork`、`working`、`lunchBreak`、`finished`、`restDay`。

错误码：

- `unsupportedSchemaVersion`
- `invalidConfiguration`
- `missingAlternatingAnchor`
- `invalidTimeRange`
- `duplicateDateOverride`
- `noPaidWorkdays`
- `holidayDatasetMismatch`

错误必须结构化返回，不能输出看似有效的金额。

## 目录

```text
shared/salary-schema/v1/
  schema.json
  examples/
  holidays/
  vectors/
  README.md
```
