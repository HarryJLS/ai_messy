# Plan Log - 手动日志工作流

**指令**: `/plan-log`

**描述**: 记录进度到任务特定日志文件

## 📂 日志文件架构

**统一日志**（简化管理）：
- `dev-YYYY-MM-DD.log` - 所有日志条目按时间序写入此文件（项目根目录，YYYY-MM-DD 为初始化日期）

---

## ⚠️ 范围边界

此命令只记录进度。完成后：
- **停止**并等待用户下一个命令
- 不要自动运行其他命令

## 何时使用

⚠️ `/plan-next` **自动记录到 `dev-YYYY-MM-DD.log`**
⚠️ `/plan-init` **自动记录到 `dev-YYYY-MM-DD.log`**

**仅用于手动、非任务进度**（同样写入 `dev-YYYY-MM-DD.log`）：
- 架构/设计决策（非任务部分）
- 会议记录、技术评审
- 紧急 bug 修复（不在 features.json 中）
- 独立重构/优化（不在当前任务中）
- 配置/环境变更（不在当前任务中）

---

## 协议

### 步骤 1: DIFF

- 检查 `git status` 或回忆最近的写入/编辑操作
- 如果没有代码变更：
  - 询问："有非代码进度吗？（设计决策、讨论）"
  - ⛔ **等待用户响应** - 没有输入不得继续

### 步骤 2: SYNTHESIZE

生成包含三个元素的摘要：

| 元素 | 问题 |
|------|------|
| Context | 为什么这个变更？什么触发了它？ |
| Action | 修改了什么文件/函数？什么解决方案？ |
| Evaluation | 结果？目标达成？副作用？ |

### 步骤 3: APPEND

**确定日志文件**：
- 所有日志统一追加到 `dev-YYYY-MM-DD.log`

追加到 `dev-YYYY-MM-DD.log`，使用**增强结构化格式**：

```
[ISO 时间戳] [类型] Task [ID]: [一句话总结]
├─ Context: [为什么？背景？触发因素？]
├─ Files: [file1.js:func1,func2 | file2.js:ClassA | file3.css:line20-45]
├─ Changes: [做了什么？实现方法？]
│  └─ Code: [关键代码片段或伪代码（如相关）]
├─ Tech: [依赖: lib@ver | APIs: name | 模式: architecture]
├─ Decision: [为什么这种方法？备选: A,B,C → 选择: B → 原因: ...]
├─ Problems: [问题1 -> 方案1 | 问题2 -> 方案2]
└─ Result: [结果？目标达成？副作用？影响: 受影响的模块/文件]
---
```

---

## 日志类型

### 自动生成（不要手动使用）
- `[Init]` - 框架初始化（由 /plan-init 自动记录）
- `[Explore]` - 代码库探索（由 /plan-next 阶段 2 自动记录）
- `[Pending]` - 任务规划（由 /plan-next 阶段 3 自动记录）
- `[TDD-Red]` - 红灯确认（由 /plan-next 阶段 4 自动记录）
- `[TDD-Green]` - 绿灯验证（由 /plan-next 阶段 6 自动记录）
- `[Completed]` - 任务完成（由 /plan-next 阶段 7 自动记录）

### 手动日志类型（使用 /plan-log）
- `[Fix]` - 紧急 bug 修复（不在 features.json 中）
- `[Refactor]` - 独立重构
- `[Optimization]` - 性能改进
- `[Design]` - 架构/设计决策
- `[Test]` - 测试添加/修改
- `[Docs]` - 文档更新
- `[Config]` - 配置/环境变更

---

## 成功标准

全部必须为真：
1. ✅ `dev-YYYY-MM-DD.log` 已更新
2. ✅ 条目使用增强结构化格式，包含所有相关部分
3. ✅ 时间戳和类型标签正确
