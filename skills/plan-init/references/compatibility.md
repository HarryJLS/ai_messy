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

## app 字段

标识任务所属的应用/服务名（如 `order-service`、`user-service`、`admin-web`）。

- 单应用项目可省略
- 多应用/微服务项目必须标注
- 配合 `appPath` 字段指定项目路径（相对路径或绝对路径）
- plan-write 会原样保留此字段到 .plan/features.json
- backend-single/frontend-single 支持按 app 过滤执行，自动 cd 到 appPath 目录

## dependsOn 字段说明

`dependsOn` 用于声明任务间的执行依赖关系，plan-next 会在执行前检查依赖任务是否已完成。

**格式**：
- 同应用内依赖：纯 ID，如 `["1", "2"]`
- 跨应用依赖：`app:id` 格式，如 `["share-api:1"]`
- 混合使用：`["1", "share-api:3"]`

**智能设置原则——只设编译级依赖**：

dependsOn 是硬阻塞，设错会导致不必要的串行等待。核心判断标准是：**任务 B 的代码是否 import/引用了任务 A 新增的类、方法或接口定义**。

| 依赖类型 | 是否设 dependsOn | 说明 |
|---------|-----------------|------|
| 编译依赖（import 对方新增的类/接口） | ✅ 设 | 不完成则无法编译 |
| 运行时依赖（HTTP/RPC/MQ 调用） | ❌ 不设 | 用 apiContracts 约定契约，可并行开发 |
| 跨 domain 依赖（前端 vs 后端） | ❌ 不设 | 不同技术栈，通过 apiContracts 对接 |
| share/common 包提供新类 → 业务服务引用 | ✅ 设 | 典型编译依赖 |
| 同 app 内无调用关系的两个任务 | ❌ 不设 | 无交集，可并行 |

**典型模式**：
```
share 包（公共接口/DTO）  →  编译依赖  →  业务服务 A、B
业务服务 A  ←  HTTP 调用（运行时）  ←  业务服务 B  ← 无 dependsOn
后端任务  ←  apiContracts 约定  ←  前端任务  ← 无 dependsOn
```

## implementationGuide 字段说明

`implementationGuide` 是深度模式的增强字段，为执行者提供精确的实现指引。
- plan-write 会原样保留此字段到 .plan/features.json
- plan-next 执行时可参考此字段中的 targetFiles、approach 等信息加速理解
- 如果用户手动删除此字段，不影响 plan-write / plan-next 的核心流程

## apiContracts 字段说明

`apiContracts` 用于记录任务涉及的接口契约，是接口对接的硬依赖——缺失会导致开发时接口格式不明确。

**生成条件**（满足任一即需要）：
1. **全栈项目**：后端任务新增/修改接口且前端任务会调用 → 后端任务必须包含 apiContracts
2. **纯前端项目**：前端任务涉及接口对接（调用后端 API）→ 该前端任务必须包含 apiContracts，记录要对接的接口规格
3. **纯后端项目**且无前端消费方时，无需此字段

- plan-write 会原样保留此字段到 .plan/features.json
- plan-next 执行时按契约实现/调用接口
