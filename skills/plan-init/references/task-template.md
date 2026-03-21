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
    "dependsOn": [],
    "complexity": "small|medium|large|trivial",
    "category": "core|ui|feature|optimization|bugfix|refactor|middleware",
    "description": "任务描述（做什么 + 为什么 + 业务背景）",
    "steps": ["步骤1（精确到文件:方法）", "步骤2"],
    "implementationGuide": {
      "targetFiles": ["src/service/XxxService.java:processData()"],
      "approach": "实现思路描述，说明核心逻辑怎么写",
      "referenceCode": ["src/service/YyyService.java:similarMethod() — 可参考的实现模式"],
      "dataFlow": "数据从哪来 → 经过什么处理 → 到哪去",
      "keyInterfaces": ["需要实现/调用的关键接口说明"]
    },
    "apiContracts": [
      {
        "method": "GET",
        "path": "/api/users",
        "description": "获取用户列表",
        "request": { "query": { "page": "number", "size": "number" } },
        "response": { "code": 200, "body": { "list": "User[]", "total": "number" } }
      }
    ],
    "acceptance": ["验收标准1：具体验证步骤"],
    "boundary": "只改什么，不改什么",
    "test": "unit: 测试策略和关键用例",
    "references": [],
    "dataSamples": [],
    "passes": false
  }
]

## 风险与注意事项

- [风险1及应对]
- [风险2及应对]
```
