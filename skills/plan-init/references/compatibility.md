# 字段与 plan-write / plan-next 的兼容性说明

本文件只负责说明 **plan-init 产出的字段，下游 skill（plan-write / plan-next）如何处理**。字段的 schema 定义和填写规则见 [task-schema.md](task-schema.md)。

## 处理规则总览

| 字段 | plan-write 处理 | plan-next 处理 |
|------|----------------|----------------|
| `id` | 原样写入 features.json | 按此字段定位任务 |
| `domain` | 原样保留 | 用于按 domain 过滤（fullstack-team/single） |
| `app` / `appPath` | 检测到不同 appPath 则启用多应用模式，按 app 分组写入多份 features.json，生成 app-registry.json | 路由：任务含 appPath 时 cd 到该目录，读写 `{appPath}/.plan/` |
| `dependsOn` | 原样保留；跨应用依赖（`app:id`）用于生成 app-registry.json 的 buildOrder | 执行前检查依赖任务是否 `passes: true`，未完成则阻塞 |
| `complexity` | 原样保留 | trivial 跳过探索与清理；large 加影响分析与回滚检查 |
| `category` | 原样保留 | 不影响流程 |
| `description` / `steps` / `acceptance` / `boundary` / `test` | 原样保留 | 作为执行指南参考 |
| `implementationGuide` | 原样保留 | PLAN 阶段读取 targetFiles/approach/referenceCode/dataFlow |
| `apiContracts` | 原样保留 | 按契约实现/调用接口 |
| `references` / `dataSamples` | 原样保留 | PLAN 阶段必须查阅，用户提供的是**硬约束** |
| `passes` | 初始写入 `false` | 完成后设为 `true`；失败加 `skipped: true` + `skipReason` |

## 多应用模式额外产物

| 文件 | 创建者 | 用途 |
|------|--------|------|
| `{appPath}/.plan/features.json` | plan-write | 每个 app 一份，只含该 app 的任务 |
| `{appPath}/.plan/dev-YYYY-MM-DD.log` | plan-write | 每个 app 一份开发日志 |
| `.plan/app-registry.json` | plan-write | 应用索引 + buildOrder（按 dependsOn 推断的编译顺序） |

## 手动删除字段的影响

- `implementationGuide` 被删除 → plan-next 仍可运行，但失去实现指引，可能走弯路
- `apiContracts` 被删除 → 涉及前后端对接时接口格式不明确，可能出现契约不一致
- `references` / `dataSamples` 被删除 → 丢失用户硬约束，可能做出偏离意图的实现
- 其他字段被删除 → plan-write 仍可写入，plan-next 按默认流程执行

## 测试用例字段（test-cases.json）

plan-init 可选产出 `## Test Cases` 章节（JSON），plan-write 将其提取写入 `.plan/test-cases.json`。

- `serviceConfig.framework: "auto"` → backend-test 执行时自动检测框架并填充 startCommand/port/healthCheck
- `testSuites[].sequential: true` → 按顺序执行，支持上下文传递
- `tests[].saveAs` → JSONPath 语法提取响应值（如 `$.orderId`）保存为变量
- `tests[].dependsOn` → 引用同套件内测试 ID，前置失败则跳过
- `{{变量名}}` → 在 path/headers/body 中引用 variables 或 saveAs 的值
