---
name: dev-team
description: 智能开发团队编排，使用 Agent Team 协调五个 skill 的全流程自动化执行。当用户说 "/dev-team"、"启动开发团队"、"团队开发"、"全流程开发" 时触发。从方案预研到代码交付一站式完成。
---

# Dev Team - 智能开发团队编排

使用 Agent Team 协调 `/plan-preview` → `/plan-init` → `/plan-next` → `/code-simplifier` → `/code-fixer` 五个 skill，实现从方案预研到代码交付的全流程自动化。

## 团队架构

| 角色 | Agent 名称 | 类型 | spawn 模式 | 职责 |
|------|-----------|------|-----------|------|
| 团队负责人 | lead（自身） | - | - | 编排调度、用户沟通、转达决策 |
| 架构师 | architect | general-purpose | dontAsk | 方案预研 + 项目初始化 |
| 开发者 | developer | general-purpose | bypassPermissions | TDD 循环开发所有任务 |
| 打磨者 | polisher | general-purpose | bypassPermissions | 代码简化 + 规范修复 |

**设计说明**：
- architect 用 `dontAsk` 而非 `plan`：skill 自身管理 EnterPlanMode/ExitPlanMode 时机，`plan` 模式会导致 agent 无法在退出 plan mode 后写文件
- architect 合并 preview + init：两者顺序依赖，同一 agent 保持上下文连续
- polisher 合并 simplifier + fixer：都是后处理，顺序执行

## 用户交互代理机制

teammate 无法直接与用户交互（AskUserQuestion），所有用户交互通过 lead 代理：

| 交互类型 | 处理方式 |
|----------|---------|
| 关键决策（技术选型、架构方向、方案审批） | teammate SendMessage 给 lead → lead 用 AskUserQuestion 询问用户 → lead SendMessage 转发答案 |
| 非关键门控（代码探索确认、理解确认等） | teammate 自主判断，跳过门控继续执行 |
| ExitPlanMode 审批 | plan_approval_request 自动发给 lead → lead 审核后 plan_approval_response |

**区分标准**：涉及"用户偏好"或"多选一方案"的是关键决策；信息确认类的是非关键门控。

## 核心协议

**通用验证原则：** 每次检查/验收时，逐项确认每个方法/功能是否真正完整实现，而非仅写了兜底/stub/placeholder。除非用户明确声明"先留口子，后续开发"，才允许只写兜底方案。

### 阶段 0: 团队初始化

**lead 操作：**

1. 确认用户的需求描述（文字、MD 文件路径、飞书/语雀链接等），记录完整的原始输入
2. 如涉及参考其他项目代码，确认参考项目路径并记录
3. 检查现有文件状态，确定跳入点：

| 文件状态 | 跳入阶段 |
|----------|----------|
| 无 `task.md`、无 `features.json` | 阶段 1（完整流程） |
| 有 `task.md`、无 `features.json` | 阶段 2（跳过预研） |
| 有 `features.json`、有未完成任务 | 阶段 3（跳过初始化） |
| 有 `features.json`、所有 `passes: true` | 阶段 4（仅优化） |

4. 创建团队和任务（含依赖关系），根据跳入点进入对应阶段

---

### 阶段 1: 方案预研（architect）

**lead 操作：**
spawn architect（`subagent_type: general-purpose`, `mode: dontAsk`, `team_name: dev-team`），发送指令：

```
请执行 /plan-preview。用户需求如下：
{用户的完整原始输入，包括文件路径/链接}

（如有参考项目）参考项目路径：{路径}
- 先探索参考项目的相关代码流程，理解其实现模式
- 将参考项目的关键文件路径写入 task.md 任务的 references 字段
- 在任务描述中说明与参考项目的差异点（如参数来源不同）

注意事项：
- 调用 Skill("plan-preview") 执行方案预研
- skill 会自行管理 EnterPlanMode/ExitPlanMode，你无需额外处理
- 非关键门控（需求理解确认、代码探索确认）：你自主判断，跳过门控继续
- 关键决策（技术选型有多个方案需用户选择时）：SendMessage 给 lead 说明选项，等待 lead 回复后继续
- ExitPlanMode 的审批会自动发给 lead 处理
- 完成后 SendMessage 通知 lead，报告 task.md 已生成
```

**lead 在此阶段的职责：**
- 收到 architect 的关键决策请求 → AskUserQuestion 询问用户 → SendMessage 转发答案
- 收到 plan_approval_request → 审核计划内容 → plan_approval_response
- 收到完成通知 → 确认 `task.md` 存在 → 标记任务完成 → 进入阶段 2

---

### 阶段 2: 项目初始化（architect 继续）

**lead 操作：**
向 architect 发送消息：

```
task.md 已确认。请继续执行 /plan-init。

注意事项：
- 调用 Skill("plan-init") 执行项目初始化
- 非关键门控（文件冲突处理）：选择"覆盖"，跳过门控
- 关键决策（核心目标有歧义、技术选型需选择时）：SendMessage 给 lead
- ExitPlanMode 的审批会自动发给 lead 处理
- 完成后 SendMessage 通知 lead，报告 features.json 和 dev-YYYY-MM-DD.log 已创建
```

**lead 验证：**
- 确认 `features.json` 和 `dev-*.log` 存在 → 标记任务完成
- 向 architect 发送 shutdown_request → 进入阶段 3

---

### 阶段 3: 任务开发（developer）

**lead 操作：**
spawn developer（`subagent_type: general-purpose`, `mode: bypassPermissions`, `team_name: dev-team`），发送指令：

```
请循环执行 /plan-next，直到所有任务的 passes 都为 true。

执行步骤：
1. 读取 features.json，找到第一个 passes: false 的任务
2. 调用 Skill("plan-next") 执行该任务
3. 按 TDD 流程完成（READ → EXPLORE → PLAN → RED → IMPLEMENT → GREEN → COMMIT）
4. 每完成一个任务，SendMessage 通知 lead 进度（已完成/总数）
5. 继续下一个 passes: false 的任务
6. 全部完成后 SendMessage 通知 lead

注意事项：
- TDD 流程内的常规门控（EXPLORE→PLAN、PLAN→RED 确认）：自主跳过
- 关键技术决策（实现方式有多个方案、不确定用户意图时）：SendMessage 给 lead
- features.json 在此阶段只有你一个 agent 读写，无并发问题
```

**lead 验证：**
- 收到进度通知后确认 features.json 状态
- 收到关键决策请求 → AskUserQuestion 询问用户 → SendMessage 转发答案
- 全部 `passes: true` → 标记任务完成 → shutdown developer → 进入阶段 4

---

### 阶段 4: 代码优化（polisher）

**lead 操作：**
spawn polisher（`subagent_type: general-purpose`, `mode: bypassPermissions`, `team_name: dev-team`），发送指令：

```
请依次执行代码优化：

第一步：调用 Skill("code-simplifier")
- 先用 git diff 确定本次开发修改的文件范围，将文件列表作为优化目标
- 完成后 SendMessage 通知 lead

第二步：调用 Skill("code-fixer")
- 对代码进行规范修复（基于 git diff）
- 需确认的改动（CONFIRM 类）：SendMessage 给 lead 说明改动列表，等待回复
- 完成后 SendMessage 通知 lead，报告优化全部完成
```

**lead 验证：**
- 收到 CONFIRM 类改动请求 → AskUserQuestion 询问用户 → SendMessage 转发答案
- 确认优化完成 → 标记任务完成 → shutdown polisher → 进入阶段 5

---

### 阶段 5: 收尾

**lead 操作：**
1. 清理团队：`TeamDelete`
2. 向用户输出最终报告：

```markdown
## Dev Team 执行报告

### 执行概览
| 阶段 | 状态 | 执行者 |
|------|------|--------|
| 方案预研 | 完成 | architect |
| 项目初始化 | 完成 | architect |
| 任务开发 | 完成 | developer |
| 代码优化 | 完成 | polisher |

### 产出文件
- `task.md` - 技术方案文档
- `features.json` - 任务状态（所有 passes: true）
- `dev-YYYY-MM-DD.log` - 开发日志
- 代码实现 + 测试文件

### 后续建议
- 运行 `/plan-archive` 归档本次开发
- 运行 `/code-review` 进行代码审查
```

## 错误处理

| 错误类型 | 处理方式 |
|----------|----------|
| teammate 执行失败 | teammate SendMessage 通知 lead 错误详情 → lead 通知用户并请求决策 |
| agent 无响应/异常 | lead 重新 spawn 同名 agent，发送恢复指令 |
| 测试失败（plan-next） | developer 在 TDD 流程内自行处理，无需上报 |

中断恢复：重新执行 `/dev-team` 时，lead 根据文件状态自动判断跳入阶段（见阶段 0 的文件状态检查表）。
