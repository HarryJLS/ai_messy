---
name: dev-team
description: 智能开发团队编排，使用 Agent Team 协调五个 skill 的全流程自动化执行。当用户说 "/dev-team" 时触发。从方案预研到代码交付一站式完成。
---

# Dev Team - 智能开发团队编排

Lead 亲自主导方案预研和项目初始化，再通过 Agent Team 协调 `/plan-next` → `/code-simplifier` → `/code-fixer`，实现从方案预研到代码交付的全流程自动化。

## 团队架构

| 角色 | Agent 名称 | 类型 | spawn 模式 | 职责 |
|------|-----------|------|-----------|------|
| 团队负责人 | lead（自身） | - | - | 方案预研、项目初始化、编排调度、用户沟通、决策 |
| 开发者 | developer | general-purpose | bypassPermissions | TDD 循环开发所有任务 |
| 打磨者 | polisher | general-purpose | bypassPermissions | 代码简化 + 规范修复 |
| 审查者 | reviewer | feature-dev:code-reviewer | - | 上线前正式 CR，有完整代码上下文 |
| 盲审者 | blind-reviewer | feature-dev:code-reviewer | - | 零上下文盲审，仅依据 PR 描述 + diff |

**设计说明**：
- lead 亲自执行 `/plan-preview` + `/plan-init`：方案预研和初始化是项目决策的核心环节，lead 直接与用户交互，避免决策转发导致的上下文丢失和延迟
- polisher 合并 simplifier + fixer：都是后处理，顺序执行
- 代码探索量特别大时，lead 可用 Task 工具 spawn 临时 Explore agent 做深度探索，结果拿回来自己决策

## 用户交互机制

| 阶段 | 交互方式 |
|------|---------|
| 阶段 1-2（lead 自己执行） | lead 直接用 AskUserQuestion 与用户交互，无需转发 |
| 阶段 3-4（teammate 执行） | teammate SendMessage 给 lead → lead 用 AskUserQuestion 询问用户 → lead SendMessage 转发答案 |
| 阶段 5（CR reviewer 执行） | reviewer SendMessage 给 lead → lead 汇总后用 AskUserQuestion 展示报告 |

**teammate 交互区分标准**：
- 关键决策（技术选型、架构方向）：必须 SendMessage 给 lead 请求用户决策
- 非关键门控（代码探索确认、理解确认等）：teammate 自主判断，跳过门控继续执行

## 核心协议

**通用验证原则：** 每次检查/验收时，逐项确认每个方法/功能是否真正完整实现，而非仅写了兜底/stub/placeholder。除非用户明确声明"先留口子，后续开发"，才允许只写兜底方案。

### 阶段 0: 初始化与跳入点判断

**lead 操作：**

1. 确认用户的需求描述（文字、MD 文件路径、飞书/语雀链接等），记录完整的原始输入
2. 如涉及参考其他项目代码，确认参考项目路径并记录
3. 检查现有文件状态，确定跳入点：

| 文件状态 | 跳入阶段 |
|----------|----------|
| 无 `task.md`、无 `features.json` | 阶段 1（完整流程） |
| 有 `task.md`、无 `features.json` | 阶段 2（跳过预研） |
| 有 `features.json`、有未完成任务 | 阶段 3（跳过初始化） |
| 有 `features.json`、所有 `passes: true`、无 polisher 完成标记 | 阶段 4（仅优化） |
| 有 `features.json`、所有 `passes: true`、polisher 已完成（dev log 中有 `[polisher] 完成` 记录） | 阶段 5（CR） |

4. 根据跳入点：
   - 若进入阶段 1 或 2：lead 直接执行，无需创建团队（团队在阶段 3 才需要）
   - 若进入阶段 3、4 或 5：创建团队，spawn 对应 agent

---

### 阶段 1: 方案预研（lead 自己执行）

**lead 操作：**

1. 调用 `Skill("plan-preview")` 执行方案预研
2. 将用户的完整原始输入（包括文件路径/链接）作为上下文传入
3. 如有参考项目：
   - 先探索参考项目的相关代码流程，理解其实现模式
   - 将参考项目的关键文件路径写入 task.md 任务的 references 字段
   - 在任务描述中说明与参考项目的差异点
4. skill 内的所有门控（需求确认、代码探索确认、技术决策）由 lead 直接与用户交互完成
5. 确认 `task.md` 已生成
6. 从 task.md 提取关键信息，生成 `pr-description.md`：

```markdown
## PR 标题
{一句话概括变更}

## 变更动机
{为什么要做这个改动，业务背景}

## 方案概述
{技术方案的核心思路，不含实现细节}

## 预期改动范围
{涉及的模块/文件类型，粗粒度}
```

来源：从 task.md 的「背景」「目标」「技术方案.整体思路」提取，**不含具体文件路径和代码细节**。

7. 确认 `pr-description.md` 已生成 → 进入阶段 2

---

### 阶段 2: 项目初始化（lead 自己执行）

**lead 操作：**

1. 调用 `Skill("plan-init")` 执行项目初始化
2. 将 `task.md` 作为需求文档输入
3. skill 内的门控处理：
   - 文件冲突（features.json 已存在）：选择"覆盖"
   - 核心目标确认：基于阶段 1 已确认的方案，直接确认
   - 技术决策：基于阶段 1 已确认的决策，直接确认
4. 确认 `features.json` 和 `dev-*.log` 存在 → 进入阶段 3

**优势**：lead 在阶段 1 亲历了方案预研全过程，此阶段大部分门控可基于已有上下文直接通过，无需重复询问用户。

---

### 阶段 3: 任务开发（developer）

**lead 操作：**
创建团队（如未创建），spawn developer（`subagent_type: general-purpose`, `mode: bypassPermissions`, `team_name: dev-team`），发送指令：

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

### 阶段 5: Code Review（reviewer + blind-reviewer）

**lead 操作：**

1. 准备 CR 材料：
   - 执行 `git diff main...HEAD`（或合适的 base branch），保存 diff 内容
   - 读取 `pr-description.md`

2. 并行 spawn 两个 reviewer：

**reviewer（Production CR）：**
spawn（`subagent_type: feature-dev:code-reviewer`, `team_name: dev-team`），发送指令：

```
你是 Production Code Reviewer，负责上线前的正式代码审查。

请执行完整的代码审查：
1. 运行 git diff main...HEAD 获取本次所有变更
2. 对每个变更文件，读取完整文件理解上下文
3. 按以下维度审查：
   - 安全漏洞（硬编码密钥、注入、未校验输入）
   - 逻辑错误（边界条件、空指针、并发问题）
   - 性能问题（N+1 查询、内存泄漏、不必要的循环）
   - 代码质量（嵌套过深、职责不清、缺少错误处理）
   - 测试覆盖（关键路径是否有测试）
4. 只审查 diff 中变更的代码，不审查未修改的代码
5. 完成后 SendMessage 给 lead，报告所有发现
```

**blind-reviewer（Blind CR）：**
spawn（`subagent_type: feature-dev:code-reviewer`, `team_name: dev-team`），发送指令：

```
你是 Blind Code Reviewer，执行零上下文盲审。
你只有以下信息，禁止读取任何项目文件或探索代码库：

## PR 描述
{pr-description.md 内容}

## Code Diff
{git diff 输出}

请仅基于以上信息审查：
1. diff 中是否存在明显 bug、逻辑错误
2. 是否有安全风险
3. 代码变更是否与 PR 描述一致（做了描述之外的事？遗漏了描述中的需求？）
4. diff 中是否有可疑的模式（硬编码、TODO/FIXME、空实现）
5. 变更的合理性（改动量是否与目标匹配）

完成后 SendMessage 给 lead。
```

3. **lead 汇总：**
   - 收集两个 reviewer 的报告
   - 合并去重，标注来源（Production / Blind / 双方一致）
   - 双方一致的发现标记为**高置信度**
   - 用 AskUserQuestion 展示汇总报告，询问用户处理决策
   - shutdown 两个 reviewer

---

### 阶段 6: 收尾

**lead 操作：**
1. 清理团队：`TeamDelete`
2. 向用户输出最终报告：

```markdown
## Dev Team 执行报告

### 执行概览
| 阶段 | 状态 | 执行者 |
|------|------|--------|
| 方案预研 | 完成 | lead |
| 项目初始化 | 完成 | lead |
| 任务开发 | 完成 | developer |
| 代码优化 | 完成 | polisher |
| Code Review | 完成 | reviewer + blind-reviewer |

### 产出文件
- `task.md` - 技术方案文档
- `pr-description.md` - PR 描述（阶段 1 生成）
- `features.json` - 任务状态（所有 passes: true）
- `dev-YYYY-MM-DD.log` - 开发日志
- 代码实现 + 测试文件

### 后续建议
- 运行 `/plan-archive` 归档本次开发
```

## 错误处理

| 错误类型 | 处理方式 |
|----------|----------|
| teammate 执行失败 | teammate SendMessage 通知 lead 错误详情 → lead 通知用户并请求决策 |
| agent 无响应/异常 | lead 重新 spawn 同名 agent，发送恢复指令 |
| 测试失败（plan-next） | developer 在 TDD 流程内自行处理，无需上报 |

中断恢复：重新执行 `/dev-team` 时，lead 根据文件状态自动判断跳入阶段（见阶段 0 的文件状态检查表）。
