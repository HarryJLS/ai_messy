---
name: backend-single
description: 精简版后端开发编排，顺序执行四个核心 skill（plan-write → plan-next → code-simplifier → code-fixer）。当用户说 "/backend-single"、"精简开发" 时触发。需先运行 /plan-init 完成任务分解。适用于现有后端项目的功能开发。
---

# Backend Single - 精简版后端开发编排

顺序执行 4 个核心 skill，无 Agent Team，无方案预研，无 CR，专注快速交付。

**前置条件**：需先运行 `/plan-init` 完成任务分解并审批。

**与 backend-team 的区别**：去掉方案预研（plan-init 深度模式）、方案审查（plan-reviewer）、全量验证（build-fixer）、多维 CR（reviewer/blind-reviewer/security-reviewer）、pr-description.md 生成、De-Sloppify 检查。保留核心开发流水线。

## 流水线概览

```
阶段 0: 确认需求 + 跳入点判断
  ↓
阶段 1: Skill("plan-write")
  ↓
阶段 2: 循环 Skill("plan-next") 直到所有任务完成
  ↓
阶段 3: Skill("code-simplifier") + Skill("code-fixer")
  ↓
阶段 4: 执行报告
```

## 核心协议

**通用验证原则：** 每次检查/验收时，逐项确认每个方法/功能是否真正完整实现，而非仅写了兜底/stub/placeholder。除非用户明确声明"先留口子，后续开发"，才允许只写兜底方案。

### 阶段 0: 确认需求与跳入点判断

1. 确认用户的需求描述（文字、MD 文件路径、飞书/语雀链接等），记录完整的原始输入
2. 如涉及参考其他项目代码，确认参考项目路径并记录
3. 检查现有文件状态，确定跳入点：

| 文件状态 | 跳入阶段 |
|----------|----------|
| 无 `.plan/features.json` | 阶段 1（完整流程） |
| 有 `.plan/features.json`、有未完成任务（`passes: false`） | 阶段 2（继续开发） |
| 有 `.plan/features.json`、全部完成、dev log 中无 `[Polisher-Done]` 标记 | 阶段 3（代码优化） |
| 有 `.plan/features.json`、全部完成、dev log 中有 `[Polisher-Done]` 标记 | 直接输出报告 |

---

### 阶段 1: 计划写入

**前置检查**：确认 `~/.claude/plans/*.md` 存在（由 `/plan-init` 生成）。若不存在，提示用户先运行 `/plan-init`，然后停止。

跳过条件：已存在 `.plan/features.json` 时跳过，直接进入阶段 2。

1. 调用 `Skill("plan-write")` 将计划写入项目文件
2. 确认 `.plan/features.json` 和 `.plan/dev-*.log` 存在 → 进入阶段 2

---

### 阶段 2: 任务开发（plan-next 循环）

循环执行 `Skill("plan-next")`，直到所有任务的 `passes` 都为 `true`。

**执行步骤：**
1. 读取 `.plan/features.json`，确认还有 `passes: false` 的任务
2. 调用 `Skill("plan-next")` 执行下一个任务
3. plan-next 内部按 TDD 流程完成（RED → GREEN → COMMIT）
4. 检查 `.plan/features.json`，如仍有未完成任务则继续循环
5. 全部 `passes: true` → 进入阶段 3

**卡住策略：**
- 同一任务内测试连续失败 3 次：用 AskUserQuestion 向用户展示错误日志和已尝试的方案，请求决策
- 发现任务 description 与实际代码结构不匹配：用 AskUserQuestion 向用户说明差异
- 不要在失败后无限重试同一方案，尝试 2 种不同思路后仍失败即向用户求助

---

### 阶段 3: 代码优化

**3a. 代码简化（code-simplifier）**

1. 调用 `Skill("code-simplifier")`
2. 先用 `git diff` 确定本次开发修改的文件范围，将文件列表作为优化目标

**3b. 代码规范修复（code-fixer）**

1. 调用 `Skill("code-fixer")`
2. 对代码进行规范修复（基于 git diff）
3. 完成后在 dev log 中写入 `[Polisher-Done]` 标记
4. 进入阶段 4

---

### 阶段 4: 执行报告

向用户输出最终报告：

```markdown
## Backend Single 执行报告

### 执行概览
| 阶段 | 状态 |
|------|------|
| 计划写入（plan-write） | 完成 |
| 任务开发（plan-next） | 完成 |
| 代码简化（code-simplifier） | 完成 |
| 规范修复（code-fixer） | 完成 |

### 量化指标
| 指标 | 数值 |
|------|------|
| 任务总数 | X |
| 变更文件数 | X |
| 新增/删除行数 | +X / -X |

### 产出文件
- `.plan/features.json` - 任务状态（所有 passes: true）
- `.plan/dev-YYYY-MM-DD.log` - 开发日志
- 代码实现 + 测试文件

### 后续建议
- 运行 `/code-review` 进行代码审查
- 运行 `/plan-archive` 归档本次开发
```

## 错误处理

| 错误类型 | 处理方式 |
|----------|----------|
| plan-write 失败 | 检查计划文件是否存在（需先运行 /plan-init），重新执行 |
| plan-next 测试失败 | TDD 流程内自行处理；连续失败 3 次则 AskUserQuestion |
| code-simplifier/code-fixer 失败 | AskUserQuestion 展示错误，询问是否跳过 |

中断恢复：重新执行 `/backend-single` 时，根据文件状态自动判断跳入阶段（见阶段 0 的文件状态检查表）。
