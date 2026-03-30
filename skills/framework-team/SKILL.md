---
name: framework-team
description: 新项目脚手架团队编排，从零开始搭建项目：需求收集 → 架构设计 → 脚手架搭建 → TDD 开发 → 验证 → CR。当用户说 "/framework-team" 时触发。适用于没有现有代码库的全新项目。
---

# Framework Team - 新项目脚手架团队编排

Lead 亲自主导需求收集、架构设计和计划写入，再通过 Agent Team 协调 `/plan-next` → `/code-simplifier` → `/code-fixer`，实现从零到交付的全流程自动化。

**与 backend-team 的核心区别**：backend-team 围绕"现有代码"设计（plan-init 深度模式探索代码库），本 skill 面向"从零开始"场景——无代码可探索，从需求出发设计架构、生成脚手架，再进入标准开发流程。

## 团队架构

| 角色 | Agent 名称 | 类型 | spawn 模式 | 职责 |
|------|-----------|------|-----------|------|
| 团队负责人 | lead（自身） | - | - | 需求收集、架构设计、任务分解、计划写入、全量验证、编排调度、用户沟通、决策 |
| 开发者 | developer | general-purpose | bypassPermissions | 脚手架搭建 + TDD 循环开发 |
| 打磨者 | polisher | general-purpose | bypassPermissions | 代码简化 + 规范修复 |
| 方案审查者 | plan-reviewer | code-architect（项目 agent） | - | 零上下文审查架构方案，挑战完整性和合理性 |
| 审查者 | reviewer | code-reviewer（项目 agent） | - | 上线前正式 CR，有完整代码上下文 |
| 盲审者 | blind-reviewer | code-reviewer（项目 agent） | - | 零上下文盲审，仅依据 PR 描述 + diff |

**设计说明**：
- lead 亲自执行架构设计 + `/plan-init` + `/plan-write`：架构设计是项目决策的核心环节，lead 直接与用户交互，避免决策转发导致的上下文丢失和延迟
- polisher 合并 simplifier + fixer：都是后处理，顺序执行
- reviewer / blind-reviewer / plan-reviewer 使用项目级 agent 定义（`agents/` 目录），不依赖外部 plugin

## 用户交互机制

| 阶段 | 交互方式 |
|------|---------|
| 阶段 0-2（lead 自己执行） | lead 直接用 AskUserQuestion 与用户交互，无需转发 |
| 阶段 1.5（plan-reviewer 执行） | plan-reviewer SendMessage 给 lead → lead 用 AskUserQuestion 展示审查结果 → 采纳的修改更新到 .plan/task.md |
| 阶段 3-4（teammate 执行） | teammate SendMessage 给 lead → lead 用 AskUserQuestion 询问用户 → lead SendMessage 转发答案 |
| 阶段 5（CR reviewer 执行） | reviewer SendMessage 给 lead → lead 汇总后用 AskUserQuestion 展示报告 |

**teammate 交互区分标准**：
- 关键决策（技术选型、架构方向）：必须 SendMessage 给 lead 请求用户决策
- 非关键门控（代码探索确认、理解确认等）：teammate 自主判断，跳过门控继续执行

## 核心协议

**通用验证原则：** 每次检查/验收时，逐项确认每个方法/功能是否真正完整实现，而非仅写了兜底/stub/placeholder。除非用户明确声明"先留口子，后续开发"，才允许只写兜底方案。

### 阶段 0: 需求收集与跳入点判断

**lead 操作：**

1. 确认用户的需求描述（文字、MD 文件路径、飞书/语雀链接等），记录完整的原始输入
2. 收集关键信息（通过 AskUserQuestion 或从用户输入提取）：
   - **项目名称**：用于目录命名和包名
   - **项目类型**：CLI / Web API / Web App / Library / Monorepo 等
   - **技术栈偏好**：语言、框架、构建工具（用户可能已指定或需要建议）
3. 如涉及参考其他项目代码，确认参考项目路径并记录
4. 检查现有文件状态，确定跳入点：

| 文件状态 | 跳入阶段 |
|----------|----------|
| 无 `.plan/task.md`、无 `.plan/features.json` | 阶段 1（完整流程） |
| 有 `.plan/task.md`、无计划文件（`~/.claude/plans/*.md`）、无 `.plan/features.json` | 阶段 2（plan-init 标准模式 + plan-write） |
| 有 `.plan/task.md`、有计划文件、无 `.plan/features.json` | 阶段 2b（仅 plan-write） |
| 有 `.plan/features.json`、有未完成任务 | 阶段 3（跳过初始化） |
| 有 `.plan/features.json`、所有 `passes: true`、dev log 中无 `[Verification-Done]` 标记 | 阶段 3.5（全量验证） |
| 有 `.plan/features.json`、所有 `passes: true`、dev log 中有 `[Verification-Done]` 标记、无 `[Polisher-Done]` 标记 | 阶段 4（仅优化） |
| 有 `.plan/features.json`、所有 `passes: true`、dev log 中有 `[Polisher-Done]` 标记 | 阶段 5（CR） |

5. 根据跳入点：
   - 若进入阶段 1 或 2：lead 直接执行，无需创建团队（团队在阶段 3 才需要）
   - 若进入阶段 3、4 或 5：创建团队，spawn 对应 agent

---

### 阶段 1: 架构设计（替代 backend-team 的 plan-init 深度模式）

**这是与 backend-team 唯一的本质区别。** 无代码可探索，从需求出发设计架构并生成 .plan/task.md。

**lead 操作（在 EnterPlanMode 中完成）：**

1. **确定技术栈**：根据项目类型和用户偏好，确定：
   - 语言 + 框架版本
   - 构建工具（Maven/Gradle/npm/pnpm/go mod 等）
   - 测试框架（JUnit/pytest/Jest/go test 等）
   - 日志框架、配置方式、代码规范工具
   - 与用户确认技术决策点

2. **设计项目架构**：
   - 模块划分和职责定义
   - 目录结构设计（输出目录树）
   - 核心接口/数据模型设计
   - 依赖关系和分层架构

3. **生成 .plan/task.md**：任务分两批：
   - **脚手架批**（category: config，前 2-4 个任务）：
     - 项目初始化（package.json / go.mod / pom.xml 等）
     - 目录结构创建
     - 构建配置（编译/打包/运行脚本）
     - 测试基础设施（测试框架配置、示例测试）
   - **核心批**（category: core/feature，后续任务）：
     - 核心模块实现（按依赖顺序排列）
     - 每个任务包含 dependsOn + complexity

   .plan/task.md 格式兼容 `/plan-write`，示例：
   ```markdown
   ## 技术方案

   ### 整体思路
   {架构设计概述}

   ### 任务列表
   | # | 任务 | category | dependsOn | complexity |
   |---|------|----------|-----------|------------|
   | 1 | 项目初始化和构建配置 | config | - | S |
   | 2 | 目录结构和基础模块 | config | 1 | S |
   | 3 | 测试基础设施 | config | 1 | S |
   | 4 | 核心模块 A | core | 2,3 | M |
   | 5 | 功能模块 B | feature | 4 | L |
   ```

4. **生成 .plan/pr-description.md**：

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

5. ExitPlanMode → 用户审批 → 写入 .plan/task.md 和 .plan/pr-description.md
6. 确认两个文件已生成 → 进入阶段 1.5

---

### 阶段 1.5: 方案对抗审查（plan-reviewer）

**触发条件**：.plan/task.md 中任务数 ≥ 3 时执行。任务数 < 3 的小改动直接跳过，进入阶段 2。

**lead 操作：**

1. 读取 .plan/task.md 内容，统计任务数量
2. spawn plan-reviewer（`subagent_type: code-architect`（项目 agent）, `team_name: framework-team`），发送指令：

```
你是方案审查者，负责用独立视角挑战技术方案的完整性和合理性。

## 技术方案
{.plan/task.md 完整内容}

请从以下维度审查，只报告你认为**确实有问题**的点（没问题的不用列）：

1. **遗漏检查**：任务列表是否遗漏了必要的步骤？（如：缺少配置文件、缺少错误处理基础设施、缺少日志配置）
2. **脚手架完整性**：config 类任务是否覆盖了项目启动所需的所有基础设施？
3. **任务粒度**：是否有任务过大需要拆分？或过小可以合并？
4. **依赖顺序**：dependsOn 是否正确？是否有循环依赖或缺失依赖？
5. **技术决策盲点**：已确定的技术选型是否有明显更优的替代方案未被考虑？
6. **验收标准可执行性**：每个任务的验收标准是否具体到可直接验证？

输出格式：
- 每个问题：[维度] 问题描述 → 建议改进
- 如果方案没有明显问题，直接说"方案审查通过，无需调整"

完成后 SendMessage 给 lead。
```

3. **lead 处理审查结果：**

| 审查结果 | lead 处理 |
|----------|----------|
| "审查通过" | 直接进入阶段 2 |
| 有具体问题 | AskUserQuestion 展示问题清单，询问是否采纳 → 采纳的修改更新到 task.md → 进入阶段 2 |

4. shutdown plan-reviewer → 进入阶段 2

---

### 阶段 2: 任务分解 + 计划写入（lead 自己执行）

**lead 操作：**

**2a. 任务分解（plan-init 标准模式）**

跳过条件：已存在计划文件（`~/.claude/plans/*.md`）时跳过，直接进入 2b。

1. 调用 `Skill("plan-init")` 执行任务分解和审批（plan-init 检测到 .plan/task.md 已存在，自动进入标准模式）
2. skill 内的门控处理：
   - 核心目标确认：基于阶段 1 已确认的方案，直接确认
   - 技术决策：基于阶段 1 已确认的决策，直接确认
3. 确认计划文件已生成（`~/.claude/plans/*.md`）

**2b. 计划写入（plan-write）**

1. 调用 `Skill("plan-write")` 将计划写入项目文件
2. skill 内的门控处理：
   - 文件冲突（.plan/features.json 已存在）：选择"覆盖"
3. 确认 `.plan/features.json` 和 `.plan/dev-*.log` 存在 → 进入阶段 3

---

### 阶段 3: 任务开发（developer）

**lead 操作：**
创建团队（如未创建），spawn developer（`subagent_type: general-purpose`, `mode: bypassPermissions`, `team_name: framework-team`），发送指令（详见 `references/developer-prompt.md`）：

```
请循环执行 /plan-next，直到所有任务的 passes 都为 true。

执行步骤：
1. 读取 .plan/features.json，找到第一个 passes: false 的任务
2. 调用 Skill("plan-next") 执行该任务
3. 按 TDD 流程完成（READ → EXPLORE → PLAN → RED → IMPLEMENT → GREEN → COMMIT）
4. 每完成一个任务，SendMessage 通知 lead 进度（已完成/总数）
5. 继续下一个 passes: false 的任务
6. 全部完成后 SendMessage 通知 lead

脚手架任务特殊处理：
- .plan/features.json 中 category 为 "config" 的任务，属于脚手架搭建
- 脚手架任务使用 TDD 简化模式：跳过 RED 阶段（无需先写失败测试），直接 IMPLEMENT → GREEN → COMMIT
- 核心/功能任务正常走完整 TDD 流程

注意事项：
- TDD 流程内的常规门控（EXPLORE→PLAN、PLAN→RED 确认）：自主跳过
- 关键技术决策（实现方式有多个方案、不确定用户意图时）：SendMessage 给 lead
- .plan/features.json 在此阶段只有你一个 agent 读写，无并发问题

卡住策略：
- 同一任务内测试连续失败 3 次：SendMessage 给 lead，附带错误日志和已尝试的方案
- 探索代码后发现任务 description 与实际代码结构不匹配：SendMessage 给 lead 说明差异
- 遇到需要外部依赖（数据库、第三方 API）但环境未配置：SendMessage 给 lead
- 不要在失败后无限重试同一方案，尝试 2 种不同思路后仍失败即上报
```

**lead 验证：**
- 收到进度通知后确认 .plan/features.json 状态
- 收到关键决策请求 → AskUserQuestion 询问用户 → SendMessage 转发答案
- 收到卡住上报 → AskUserQuestion 展示错误详情，询问用户决策（修复方向 / 跳过任务 / 调整方案）
- 全部 `passes: true` → 标记任务完成 → shutdown developer → 进入阶段 3.5

---

### 阶段 3.5: 全量验证（lead 自己执行）

**触发条件**：developer 完成所有任务后、进入 polisher 前。

**lead 操作：**

1. 执行全量验证（根据项目语言选择对应命令）：

| 验证项 | Java | Go | JS/TS | Python |
|--------|------|----|-------|--------|
| Build | `mvn compile` | `go build ./...` | `npm run build` | - |
| Lint | checkstyle/spotbugs | `go vet ./...` | `npm run lint` | `ruff check .` |
| Test | `mvn test` | `go test ./...` | `npm test` | `pytest` |
| Security | 硬编码扫描 | 硬编码扫描 | `npm audit` | 硬编码扫描 |
| Diff | `git diff --stat` | `git diff --stat` | `git diff --stat` | `git diff --stat` |

2. 输出验证报告：

```
验证报告
========
Build:    [PASS/FAIL]
Lint:     [PASS/FAIL] (X warnings)
Test:     [PASS/FAIL] (X/Y passed)
Security: [PASS/FAIL] (X issues)
Diff:     [X files changed, +Y/-Z lines]（检查是否有意外修改的文件）

结论: [通过/不通过]
```

3. 将验证报告追加到 dev log，并写入 `[Verification-Done]` 标记

4. 处理结果：

| 结论 | lead 处理 |
|------|----------|
| 通过 | 进入阶段 4 |
| 不通过 | AskUserQuestion 展示失败项，询问：修复后继续 / 跳过验证继续 |

---

### 阶段 4: 代码优化（polisher）

**lead 操作：**
spawn polisher（`subagent_type: general-purpose`, `mode: bypassPermissions`, `team_name: framework-team`），发送指令（详见 `references/polisher-prompt.md`）：

```
请依次执行代码优化：

第零步：De-Sloppify 检查
- 检测 AI 过度工程化的模式：
  - 测试中是否测试了语言特性而非业务逻辑（如测试 null 参数构造函数而非业务规则）
  - 是否有过度防守的类型检查（内部方法间传递已校验的参数又重复校验）
  - 是否有不必要的 try-catch（catch 后只是重新抛出）
  - 是否有过度抽象（只用了一次的 interface/abstract class）
- 发现后直接清理，SendMessage 给 lead 报告清理项

第一步：优先调用 Skill("simplify")，若 simplify skill 不可用则回退调用 Skill("code-simplifier")
- 先用 git diff 确定本次开发修改的文件范围，将文件列表作为优化目标
- 完成后 SendMessage 通知 lead

第二步：调用 Skill("code-fixer")
- 对代码进行规范修复（基于 git diff）
- 需确认的改动（CONFIRM 类）：SendMessage 给 lead 说明改动列表，等待回复
- 完成后在 dev log 中写入 `[Polisher-Done]` 标记
- SendMessage 通知 lead，报告优化全部完成
```

**lead 验证：**
- 收到 CONFIRM 类改动请求 → AskUserQuestion 询问用户 → SendMessage 转发答案
- 确认优化完成 → 标记任务完成 → shutdown polisher → 进入阶段 5

---

### 阶段 5: Code Review（reviewer + blind-reviewer）

**lead 操作：**

1. 准备 CR 材料：
   - 执行 `git diff main...HEAD`（或合适的 base branch），保存 diff 内容
   - 读取 `.plan/pr-description.md`

2. 并行 spawn 两个 reviewer（审查标准详见 `references/reviewer-prompt.md`）：

**reviewer（Production CR）：**
spawn（`subagent_type: code-reviewer`（项目 agent）, `team_name: framework-team`），发送指令：

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

置信度过滤：
- 只报告置信度 >80% 的问题
- 跳过代码风格偏好（除非违反项目规范）
- 相似问题合并

严重等级：CRITICAL / HIGH / MEDIUM / LOW
输出格式：[严重等级] 问题标题 → 文件:行号 → 问题描述 → 修复建议
审查结束附加摘要表和结论（APPROVE/WARNING/BLOCK）

完成后 SendMessage 给 lead。
```

**blind-reviewer（Blind CR）：**
spawn（`subagent_type: code-reviewer`（项目 agent）, `team_name: framework-team`），发送指令：

```
你是 Blind Code Reviewer，执行零上下文盲审。
你只有以下信息，禁止读取任何项目文件或探索代码库：

## PR 描述
{.plan/pr-description.md 内容}

## Code Diff
{git diff 输出}

请仅基于以上信息审查：
1. diff 中是否存在明显 bug、逻辑错误
2. 是否有安全风险
3. 代码变更是否与 PR 描述一致（做了描述之外的事？遗漏了描述中的需求？）
4. diff 中是否有可疑的模式（硬编码、TODO/FIXME、空实现）
5. 变更的合理性（改动量是否与目标匹配）

置信度过滤：
- 只报告置信度 >80% 的问题
- 相似问题合并

严重等级：CRITICAL / HIGH / MEDIUM / LOW
输出格式：[严重等级] 问题标题 → 文件:行号 → 问题描述 → 修复建议
审查结束附加摘要表和结论（APPROVE/WARNING/BLOCK）

完成后 SendMessage 给 lead。
```

3. **lead 汇总：**
   - 收集两个 reviewer 的报告
   - 合并去重，按严重等级排序（CRITICAL 优先）
   - 标注来源（Production / Blind / 双方一致）
   - 双方一致的发现升级置信度标记（**高置信度**）
   - 汇总 verdict：取两者中更严格的结论（BLOCK > WARNING > APPROVE）
   - 用 AskUserQuestion 展示汇总报告，询问用户处理决策
   - shutdown 两个 reviewer

---

### 阶段 6: 收尾

**lead 操作：**
1. 清理团队：`TeamDelete`
2. 向用户输出最终报告：

```markdown
## Framework Team 执行报告

### 执行概览
| 阶段 | 状态 | 执行者 |
|------|------|--------|
| 需求收集 | 完成 | lead |
| 架构设计 | 完成 | lead |
| 方案审查 | 完成/跳过 | plan-reviewer |
| 任务分解 | 完成 | lead |
| 计划写入 | 完成 | lead |
| 任务开发 | 完成 | developer |
| 全量验证 | 完成 | lead |
| 代码优化 | 完成 | polisher |
| Code Review | 完成 | reviewer + blind-reviewer |

### 量化指标
| 指标 | 数值 |
|------|------|
| 任务总数 | X |
| 脚手架任务 | X（config） |
| 核心任务 | X（core/feature） |
| 变更文件数 | X |
| 新增/删除行数 | +X / -X |
| 验证结果 | PASS/FAIL |
| CR 结论 | APPROVE/WARNING/BLOCK |
| CR 发现 | CRITICAL:X HIGH:X MEDIUM:X LOW:X |

### 产出文件
- `.plan/task.md` - 架构设计文档
- `.plan/pr-description.md` - PR 描述（阶段 1 生成）
- `.plan/features.json` - 任务状态（所有 passes: true）
- `.plan/dev-YYYY-MM-DD.log` - 开发日志
- 项目脚手架 + 核心代码 + 测试文件

### 后续建议
- 运行 `/plan-archive` 归档本次开发
```

## 错误处理

| 错误类型 | 处理方式 |
|----------|----------|
| teammate 执行失败 | teammate SendMessage 通知 lead 错误详情 → lead 通知用户并请求决策 |
| agent 无响应/异常 | lead 重新 spawn 同名 agent，发送恢复指令 |
| 测试失败（plan-next） | developer 在 TDD 流程内自行处理；连续失败 3 次则上报 lead |
| 全量验证失败 | lead 用 AskUserQuestion 展示失败项，询问用户决策 |

中断恢复：重新执行 `/framework-team` 时，lead 根据文件状态自动判断跳入阶段（见阶段 0 的文件状态检查表）。
