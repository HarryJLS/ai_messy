# .plan/task.md 格式模板

```markdown
# [项目/功能名称] 技术方案

## 背景

[需求背景描述]

## 目标

[核心目标，1-3 句话]

## 现状分析

[基于代码探索的现状描述]
- 技术栈：[语言/框架]
- 相关模块：[关键文件清单]
- 现有模式：[项目约定]

### 关键代码路径

[列出核心调用链和数据流，帮助开发者快速理解代码运行逻辑]

### 现有抽象层

[项目中可复用的工具类/基类/接口，避免重复造轮子]

## 技术方案

### 整体思路

[方案核心描述]

### 数据流图

[描述数据从输入到输出的完整路径，用文字或伪图表达]

### 接口设计

[新增/修改的接口签名和参数说明]

### 技术决策

| 决策点 | 选择 | 理由 |
|--------|------|------|
| [决策1] | [选择] | [理由] |

### 改动范围

- 涉及：[模块/文件列表]
- 不涉及：[明确排除项]

## 任务列表

以下任务列表可直接用于 `/plan-write`：

[
  {
    "id": "1",
    "domain": "backend",
    "app": "share-api",
    "appPath": "../share-api",
    "dependsOn": [],
    "complexity": "small",
    "category": "core",
    "description": "在 share 包中定义公共 DTO 和接口（编译级基础依赖，其他服务 import 这些类）",
    "steps": ["步骤1（精确到文件:方法）", "步骤2"],
    "implementationGuide": {
      "targetFiles": ["src/api/UserDTO.java"],
      "approach": "定义公共数据传输对象",
      "referenceCode": [],
      "dataFlow": "",
      "keyInterfaces": []
    },
    "acceptance": ["验收标准1：DTO 类可被其他模块引用"],
    "boundary": "只定义接口和 DTO，不写业务逻辑",
    "test": "unit: 编译通过即可",
    "references": [],
    "dataSamples": [],
    "passes": false
  },
  {
    "id": "2",
    "domain": "backend",
    "app": "order-service",
    "appPath": "../order-service",
    "dependsOn": ["share-api:1"],
    "complexity": "medium",
    "category": "feature",
    "description": "实现订单服务业务逻辑（依赖 share 包的 DTO，编译级依赖需设 dependsOn）",
    "steps": ["步骤1", "步骤2"],
    "implementationGuide": {
      "targetFiles": ["src/service/OrderService.java"],
      "approach": "实现订单创建逻辑",
      "referenceCode": [],
      "dataFlow": "请求 → OrderService → OrderRepository",
      "keyInterfaces": ["引用 share-api 的 OrderDTO"]
    },
    "apiContracts": [
      {
        "method": "POST",
        "path": "/api/orders",
        "description": "创建订单",
        "request": { "body": { "userId": "string", "items": "OrderItem[]" } },
        "response": { "code": 200, "body": { "orderId": "string" } }
      }
    ],
    "acceptance": ["验收标准1"],
    "test": "unit: 测试订单创建逻辑",
    "references": [],
    "dataSamples": [],
    "passes": false
  },
  {
    "id": "3",
    "domain": "backend",
    "app": "user-service",
    "appPath": "../user-service",
    "dependsOn": ["share-api:1"],
    "complexity": "medium",
    "category": "feature",
    "description": "实现用户服务（依赖 share 包的 DTO，但与 order-service 无编译依赖，可并行开发）",
    "steps": ["步骤1", "步骤2"],
    "implementationGuide": {
      "targetFiles": ["src/service/UserService.java"],
      "approach": "实现用户查询逻辑",
      "referenceCode": [],
      "dataFlow": "请求 → UserService → UserRepository",
      "keyInterfaces": ["引用 share-api 的 UserDTO"]
    },
    "acceptance": ["验收标准1"],
    "test": "unit: 测试用户查询逻辑",
    "references": [],
    "dataSamples": [],
    "passes": false
  },
  {
    "id": "4",
    "domain": "frontend",
    "app": "admin-web",
    "appPath": "../admin-web",
    "dependsOn": [],
    "complexity": "medium",
    "category": "ui",
    "description": "实现前端订单页面（通过 apiContracts 对接后端，不同 domain 无需 dependsOn，可与后端并行开发）",
    "steps": ["步骤1", "步骤2"],
    "implementationGuide": {
      "targetFiles": ["src/pages/OrderList.tsx"],
      "approach": "基于 apiContracts 定义的接口规格开发",
      "referenceCode": [],
      "dataFlow": "页面 → API 调用（参考任务 2 的 apiContracts） → 渲染",
      "keyInterfaces": ["调用任务 2 定义的 POST /api/orders"]
    },
    "acceptance": ["验收标准1"],
    "test": "unit: 测试组件渲染",
    "references": [],
    "dataSamples": [],
    "passes": false
  }
]

> **dependsOn 设置说明**：
> - 任务 2、3 依赖任务 1（share 包）：编译级依赖，import 了 share 包新增的类
> - 任务 2 和 3 之间无依赖：虽然都是后端，但不同 app 间通过 HTTP 调用，运行时依赖不设 dependsOn
> - 任务 4（前端）无依赖：不同 domain，通过 apiContracts 约定接口，可与后端并行开发

## 风险与注意事项

- [风险1及应对]
- [风险2及应对]
```
