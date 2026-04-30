# 任务 JSON Schema 与字段规则

本文件是 `.plan/features.json` 任务数组的权威 schema 定义，SKILL.md 正文只保留字段总览表，完整定义、规则示例全部放在这里。

## 完整 Schema

```json
{
  "id": "1",
  "domain": "backend|frontend",
  "app": "order-service",
  "appPath": "../order-service",
  "dependsOn": [],
  "complexity": "trivial|small|medium|large",
  "category": "core|ui|feature|optimization|bugfix|refactor|middleware",
  "description": "清晰的任务描述（做什么 + 为什么）",
  "steps": ["具体步骤1", "具体步骤2"],
  "implementationGuide": {
    "targetFiles": ["src/service/XxxService.java:processData()"],
    "approach": "实现思路描述",
    "referenceCode": ["src/service/YyyService.java:similarMethod()"],
    "dataFlow": "数据从哪来 → 经过什么处理 → 到哪去",
    "keyInterfaces": ["需要实现/调用的关键接口说明"]
  },
  "apiContracts": [],
  "acceptance": ["验收标准1：可验证的结果"],
  "boundary": "可选：明确边界（只改什么，不改什么）",
  "test": "unit|integration|e2e|manual: 简述测试方法和关键用例",
  "references": ["可选：用户指定的参考方法/工具/API/文档"],
  "dataSamples": ["可选：用户提供的数据样例描述或路径"],
  "passes": false
}
```

## 字段规则

### `id`

字符串形式的序号，如 `"1"`、`"2"`。plan-next 按此字段识别任务。

### `domain`

| 项目类型 | 是否必填 |
|----------|----------|
| 纯后端 / 纯前端 | 可省略（按项目类型推断） |
| 全栈项目 | 必填，每个任务都要标 `backend` 或 `frontend` |

### `app` + `appPath`

| 项目类型 | 是否必填 |
|----------|----------|
| 单应用 | 可省略 |
| 多应用 / 微服务 | 必填：`app` 是应用名，`appPath` 是相对/绝对路径 |

plan-write 检测到不同 `appPath` 则启用多应用模式，backend-single/frontend-single 支持按 app 过滤并自动 cd 到 appPath。

### `dependsOn` — 只设编译级依赖

格式：
- 同应用内：纯 ID 数组 `["1", "2"]`
- 跨应用：`app:id` 格式 `["share-api:1"]`
- 混合：`["1", "share-api:3"]`

**核心判断标准**：任务 B 的代码**是否 import/引用了任务 A 新增的类、方法或接口定义**。是 → 设；否 → 不设。

| 场景 | 是否设 dependsOn | 理由 |
|------|-------------------|------|
| 前端任务 vs 后端任务（不同 domain） | ❌ 不设 | 通过 apiContracts 约定接口，可并行开发 |
| 同 app 内，任务 B 使用任务 A 新增的类/方法 | ✅ 设 | 编译级依赖 |
| 同 domain 不同 app，服务 B 调用服务 A 的 HTTP 接口 | ❌ 不设 | 运行时依赖，用 apiContracts 约定即可 |
| 业务 app 依赖 share/common 包的新增类 | ✅ 设 | share 包是编译级依赖 |
| 同 app 内，任务 B 修改的文件依赖任务 A 修改的文件 | ✅ 设 | 直接代码依赖 |
| 两个任务改不同文件、无调用关系 | ❌ 不设 | 无交集，可并行 |

**典型模式图**：

```
share 包任务（定义公共接口/DTO）
  ↓ dependsOn（编译依赖）
业务服务 A 任务    业务服务 B 任务
              ↑ 无 dependsOn（HTTP 调用，运行时依赖）
前端任务（通过 apiContracts 对接）
  ↑ 无 dependsOn（不同 domain，可并行）
```

**失误代价**：设错会导致不必要的串行等待；漏设会让后续任务编译失败。倾向于"只在确定编译依赖时设"。

### `complexity`

| 值 | 流水线影响 |
|----|------------|
| `trivial` | plan-next 跳过探索和 De-Sloppify 清理 |
| `small` | 标准流程 |
| `medium` | 标准流程 |
| `large` | plan-next 额外做影响分析 + 回滚检查 |

### `category`

原样保留，不影响流水线逻辑：`core | ui | feature | optimization | bugfix | refactor | middleware`。

### `implementationGuide`

深度模式必填（来自代码探索结果），标准模式可选。plan-next 执行时会读取 `targetFiles`、`approach`、`referenceCode`、`dataFlow`、`keyInterfaces` 加速理解。

### `apiContracts` — 涉及接口对接时必填

**必须生成的场景**：

| 项目类型 | 在哪个任务定义 apiContracts |
|----------|---------------------------|
| 全栈项目 + 后端新增/修改接口 | 后端任务里定义（前端任务的 `implementationGuide.keyInterfaces` 引用后端任务 ID） |
| 纯前端项目 + 调用后端 API | 前端任务里记录要对接的接口规格 |
| 纯后端且无前端消费方 | 可省略 |

Schema：

```json
"apiContracts": [
  {
    "method": "GET|POST|PUT|DELETE",
    "path": "/api/users",
    "description": "获取用户列表",
    "request": {
      "query": { "page": "number", "size": "number" },
      "body": {}
    },
    "response": {
      "code": 200,
      "body": { "list": "User[]", "total": "number" }
    }
  }
]
```

只定义会用到的接口，已有且不变的接口无需重复。

### `acceptance`

可验证的结果清单。plan-next 在 GREEN 阶段会逐项检查。

### `test`

格式：`"类型: 简述"`，类型可选 `unit | integration | e2e | manual`，plan-next 的 RED 阶段按此字段决定测试策略。

### `references` / `dataSamples` — 硬约束

用户在需求中指定的参考方法、工具、API、文档、数据样例。plan-next 的 PLAN 阶段必须查阅这两个字段，不得忽略或自行替代。

### `passes`

初始化时一律为 `false`，plan-next 完成任务后设为 `true`。失败时额外加 `"skipped": true` + `"skipReason": "..."`。
