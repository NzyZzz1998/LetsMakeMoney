# 共享资源

Apple Targets 使用的节假日资源以 `shared/salary-schema/v1/holidays/` 为唯一事实源。未来 Xcode 工程通过受控复制或生成阶段将已校验数据放入 App/Extension Bundle，不在本目录手工维护第二份副本。

M1 提供纯 Swift `HolidayCalendar` 解码与注入接口；Bundle 资源装配属于后续 App Target 接入任务。

`Localizable.xcstrings` 是 Apple 产品线用户文案的 String Catalog。纯内核只暴露稳定本地化键，视图和错误反馈在 M3 起通过该目录解析，不在 Swift 产品源码中散落中文字符串。`scripts/apple/validate_apple_localization.py` 负责检查键完整性和硬编码文案。

本目录不得放入签名材料、本机截图或来源不明素材。
