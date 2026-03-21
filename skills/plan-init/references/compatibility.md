# category 与 implementationGuide 兼容性说明

## category 字段

所有合法的 `category` 值：

| category | 说明 |
|----------|------|
| core | 核心功能 |
| ui | 界面相关 |
| feature | 新功能 |
| optimization | 性能/逻辑优化 |
| bugfix | Bug 修复 |
| refactor | 代码重构 |
| middleware | 中间件/工具 |

plan-write 和 plan-next 会原样保留所有 category 值。

## implementationGuide 字段说明

`implementationGuide` 是深度模式的增强字段，为执行者提供精确的实现指引。
- plan-write 会原样保留此字段到 .plan/features.json
- plan-next 执行时可参考此字段中的 targetFiles、approach 等信息加速理解
- 如果用户手动删除此字段，不影响 plan-write / plan-next 的核心流程
