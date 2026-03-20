# 与 /plan-init 的兼容性说明

## category 兼容性

plan-preview 的 `category` 为 plan-init 的超集，兼容映射如下：

| plan-preview category | plan-init 是否支持 | 说明 |
|----------------------|-------------------|------|
| core | 支持 | 核心功能 |
| ui | 支持 | 界面相关 |
| feature | 支持 | 新功能 |
| optimization | 支持 | 性能/逻辑优化 |
| bugfix | 原样保留 | plan-init 会保留未识别的 category 值 |
| refactor | 原样保留 | plan-init 会保留未识别的 category 值 |
| middleware | 原样保留 | plan-init 会保留未识别的 category 值 |

## implementationGuide 字段说明

`implementationGuide` 是 plan-preview 的增强字段，为执行者提供精确的实现指引。
- plan-init 会原样保留此字段到 .plan/features.json（JSON 向前兼容）
- plan-next 执行时可参考此字段中的 targetFiles、approach 等信息加速理解
- 如果用户手动删除此字段，不影响 plan-init / plan-next 的核心流程
