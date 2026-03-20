---
name: plan-write
description: 读取 /plan-init 生成的计划文件，将任务列表写入 .plan/features.json 并创建开发日志。当用户说 "/plan-write"、"写入任务"、"完成初始化" 时触发。必须在 /plan-init 审批后运行。
---

# Plan Write

读取计划文件，写入 .plan/features.json 和 .plan/dev log，完成初始化。

## 协议

### 步骤 1: 找到计划文件

使用 Glob 工具查找最近的计划文件：`~/.claude/plans/*.md`

按修改时间取最新的一个。读取其内容，从中提取完整的 JSON 任务列表。

如果找不到计划文件或无法提取任务列表，告知用户先运行 `/plan-init`。

### 步骤 2: 检查现有文件

检查是否已存在 `.plan/features.json`。

- 如果存在且非空，询问用户：覆盖（备份后）/ 追加 / 取消
- 如果不存在或为空，直接创建

### 步骤 3: 写入文件（按顺序执行全部操作）

**操作 0：确保 `.plan/` 目录存在**

使用 Bash 工具执行 `mkdir -p .plan`，确保目录存在。

**操作 1：Write 工具 → 创建 `.plan/dev-YYYY-MM-DD.log`**（YYYY-MM-DD 为当天日期）

```
=== Agent 初始化日志 ===
初始化时间: [ISO 时间戳]
格式: 增强结构化格式

日志类型参考:
- [Init] - 框架初始化
- [Explore] - 代码库探索
- [Pending] - 任务规划
- [TDD-Red] - 红灯确认
- [TDD-Green] - 绿灯验证
- [Completed] - 任务完成
- [Fix/Refactor/Optimization/Design/Test/Docs/Config] - 手动日志

所有条目按时间序写入本文件，通过 [Phase] Task N: 标签区分来源
---
[ISO 时间戳] [Init] Agent 框架设置
├─ Context: 用户初始化 Agent 进行结构化开发工作流
├─ Files: .plan/features.json（待创建）| .plan/dev-YYYY-MM-DD.log（本文件）
├─ Changes: 设置统一日志架构
├─ Tech: JSON 用于任务存储 | 统一日志文件简化管理
├─ Decision: 统一日志架构 → 简化管理，结构化标签保证可检索
└─ Result: 框架准备就绪，可定义项目目标和任务分解
---
```

**操作 2：Write 工具 → 创建 `.plan/features.json`（写入完整任务列表）**

将从计划文件中提取的任务列表 JSON 写入。格式示例：
```json
[
  {
    "id": "1",
    "category": "core",
    "description": "任务描述",
    "steps": ["步骤1", "步骤2"],
    "acceptance": ["验收标准1"],
    "test": "unit: 测试方法",
    "passes": false
  }
]
```

**操作 3：Edit 工具 → 追加任务分解日志到 `.plan/dev-YYYY-MM-DD.log`**
```
[ISO 时间戳] [Init] 任务分解完成
├─ Context: 用户确认任务列表
├─ Tasks: [列出所有任务 ID 和简述]
├─ Files: .plan/features.json（已写入 N 个任务）
└─ Result: 任务已持久化，等待执行
---
```

**操作 4：Edit 工具 → 追加初始化总结到 `.plan/dev-YYYY-MM-DD.log`**
```
[ISO 时间戳] [Init] 初始化完成 - 准备执行
├─ Context: 框架设置完成，所有状态文件已创建
├─ Files: .plan/features.json（N 个任务）| .plan/dev-YYYY-MM-DD.log（3 条日志）
├─ Changes: 完成初始化 - 任务已定义，日志框架已设置
├─ Tech: 统一日志架构 | 基于 JSON 的任务管理
├─ Decision: 所有任务初始 passes:false → 需验证后才能标记完成
└─ Result: 系统准备好执行 /plan-next | 所有 N 个任务待处理
---
```

### 步骤 4: 输出确认

```
✅ 初始化完成！

已创建:
• .plan/features.json - [N] 个任务已写入（全部 passes: false）
• .plan/dev-YYYY-MM-DD.log - 初始化日志已记录

日志架构:
→ 所有日志统一写入 .plan/dev-YYYY-MM-DD.log
→ 通过 [Phase] Task N: 标签区分来源，精准检索

下一步:
• 运行 /plan-next 开始第一个任务
```

⛔ **输出后立即停止，不得自动执行任务或调用 /plan-next。**
