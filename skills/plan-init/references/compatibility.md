# category、domain、implementationGuide、apiContracts 兼容性说明

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

## domain 字段

标识任务属于 `backend` 还是 `frontend`。

- 纯后端/纯前端项目可省略
- 全栈项目必须标注
- plan-write 会原样保留此字段到 .plan/features.json
- plan-next 和 fullstack-team/fullstack-single 根据 domain 分轮执行（先 backend 再 frontend）

## implementationGuide 字段说明

`implementationGuide` 是深度模式的增强字段，为执行者提供精确的实现指引。
- plan-write 会原样保留此字段到 .plan/features.json
- plan-next 执行时可参考此字段中的 targetFiles、approach 等信息加速理解
- 如果用户手动删除此字段，不影响 plan-write / plan-next 的核心流程

## apiContracts 字段说明

`apiContracts` 用于全栈项目中后端任务定义前端需要的接口契约。

- 仅在全栈项目的后端任务中使用（同时存在 backend 和 frontend 任务时）
- plan-write 会原样保留此字段到 .plan/features.json
- plan-next 执行后端任务时按契约实现接口，前端任务开发时可直接引用
- 纯后端/纯前端项目无需此字段
