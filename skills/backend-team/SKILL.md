---
name: backend-team
description: 智能开发团队编排，使用 Agent Team 协调六个 skill 的全流程自动化执行。当用户说 "/backend-team" 时触发。从方案预研到代码交付一站式完成。
---

# Backend Team - 智能开发团队编排

Lead 亲自主导方案预研、项目初始化和计划写入，再通过 Agent Team 协调 `/plan-next` → `/code-simplifier` → `/code-fixer`，实现从方案预研到代码交付的全流程自动化。

## 团队架构

| 角色 | Agent 名称 | 类型 | spawn 模式 | 职责 |
|------|-----------|------|-----------|------|
| 团队负责人 | lead（自身） | - | - | Research & Reuse、方案预研、任务分解、计划写入、全量验证、编排调度、用户沟通、决策 |
| 开发者 | developer | general-purpose | bypassPermissions | TDD 循环开发所有任务 |
| 打磨者 | polisher | general-purpose | bypassPermissions | 代码简化 + 规范修复 |
| 构建修复者 | build-fixer | build-error-resolver（项目 agent） | - | 验证失败时自动修复 build/lint/type 错误 |
| 方案审查者 | plan-reviewer | code-architect（项目 agent） | - | 零上下文审查 .plan/task.md，挑战方案完整性和合理性 |
| 审查者 | reviewer | code-reviewer（项目 agent） | - | 上线前正式 CR，有完整代码上下文 |
| 盲审者 | blind-reviewer | code-reviewer（项目 agent） | - | 零上下文盲审，仅依据 PR 描述 + diff |
| 安全审查者 | security-reviewer | security-reviewer（项目 agent） | - | 安全审查，聚焦漏洞检测（条件触发） |

**设计说明**：
- lead 亲自执行 `/plan-init` + `/plan-write`：方案预研、任务分解和计划写入是项目决策的核心环节，lead 直接与用户交互，避免决策转发导致的上下文丢失和延迟
- polisher 合并 simplifier + fixer：都是后处理，顺序执行
- reviewer / blind-reviewer / plan-reviewer 使用项目级 agent 定义（`agents/` 目录），不依赖外部 plugin
- 代码探索量特别大时，lead 可用 Task 工具 spawn 临时 Explore agent 做深度探索，结果拿回来自己决策

## 用户交互机制

| 阶段 | 交互方式 |
|------|---------|
| 阶段 1-2（lead 自己执行） | lead 直接用 AskUserQuestion 与用户交互，无需转发 |
| 阶段 1.5（plan-reviewer 执行） | plan-reviewer SendMessage 给 lead → lead 用 AskUserQuestion 展示审查结果 → 采纳的修改更新到 .plan/task.md |
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
| 无 `.plan/task.md`、无 `.plan/features.json` | 阶段 1（完整流程） |
| 有 `.plan/task.md`、无计划文件（`~/.claude/plans/*.md`）、无 `.plan/features.json` | 阶段 2（plan-init 标准模式 + plan-write） |
| 有 `.plan/task.md`、有计划文件、无 `.plan/features.json` | 阶段 2b（仅 plan-write） |
| 有 `.plan/features.json`、有未完成任务 | 阶段 3（跳过初始化） |
| 有 `.plan/features.json`、所有 `passes: true`、dev log 中无 `[Verification-Done]` 标记 | 阶段 3.5（全量验证） |
| 有 `.plan/features.json`、所有 `passes: true`、dev log 中有 `[Verification-Done]` 标记、无 `[Polisher-Done]` 标记 | 阶段 4（仅优化） |
| 有 `.plan/features.json`、所有 `passes: true`、dev log 中有 `[Polisher-Done]` 标记 | 阶段 5（CR） |

4. 根据跳入点：
   - 若进入阶段 1 或 2：lead 直接执行，无需创建团队（团队在阶段 3 才需要）
   - 若进入阶段 3、4 或 5：创建团队，spawn 对应 agent

---

### 阶段 1: 方案预研（lead 自己执行）

**lead 操作：**

**0. Research & Reuse（5 分钟速查）**

在进入方案预研前，先搜索现有实现，避免重复造轮子：

- 如有参考项目：探索参考项目相关代码，提取可复用的模式和工具函数
- WebSearch 搜索是否有成熟的库/工具可以直接使用
- 检查项目现有代码库中是否已有类似实现可复用
- 将发现记录到 .plan/task.md 的 references 字段

**1. 方案预研 + 任务分解**

1. 调用 `Skill("plan-init")` 执行方案预研和任务分解（plan-init 会根据输入清晰度自动选择深度模式或标准模式）
2. 将用户的完整原始输入（包括文件路径/链接）和 Research 阶段的发现作为上下文传入
3. 如有参考项目：
   - 先探索参考项目的相关代码流程，理解其实现模式
   - 将参考项目的关键文件路径写入 .plan/task.md 任务的 references 字段
   - 在任务描述中说明与参考项目的差异点
4. skill 内的所有门控（需求确认、代码探索确认、技术决策）由 lead 直接与用户交互完成
5. 确认 `.plan/task.md` 已生成，确认计划文件已生成（`~/.claude/plans/*.md`）
6. 从 .plan/task.md 提取关键信息，生成 `.plan/pr-description.md`：

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

来源：从 .plan/task.md 的「背景」「目标」「技术方案.整体思路」提取，**不含具体文件路径和代码细节**。

7. 确认 `.plan/pr-description.md` 已生成 → 进入阶段 1.5

---

### 阶段 1.5: 方案对抗审查（plan-reviewer）

**触发条件**：.plan/task.md 中任务数 ≥ 3 时执行。任务数 < 3 的小改动直接跳过，进入阶段 2。

**lead 操作：**

1. 读取 .plan/task.md 内容，统计任务数量
2. spawn plan-reviewer（`subagent_type: code-architect`（项目 agent）, `team_name: backend-team`），发送指令：

```
你是方案审查者，负责用独立视角挑战技术方案的完整性和合理性。

## 技术方案
{.plan/task.md 完整内容}

请从以下维度审查，只报告你认为**确实有问题**的点（没问题的不用列）：

1. **遗漏检查**：任务列表是否遗漏了必要的步骤？（如：改了接口没改调用方、加了功能没加测试、改了数据结构没改序列化）
2. **影响面低估**：改动范围是否低估？可探索代码库验证 .plan/task.md 中提到的文件路径和调用链
3. **任务粒度**：是否有任务过大需要拆分？或过小可以合并？
4. **技术决策盲点**：已确定的技术选型是否有明显更优的替代方案未被考虑？
5. **验收标准可执行性**：每个任务的验收标准是否具体到可直接验证？
6. **风险遗漏**：是否有未识别的风险（兼容性、性能、安全）？

输出格式：
- 每个问题：[维度] 问题描述 → 建议改进
- 如果方案没有明显问题，直接说"方案审查通过，无需调整"

完成后 SendMessage 给 lead。
```

3. **lead 处理审查结果：**

| 审查结果 | lead 处理 |
|----------|----------|
| "审查通过" | 直接进入阶段 2 |
| 有具体问题 | AskUserQuestion 展示问题清单，询问是否采纳 → 采纳的修改更新到 .plan/task.md → 进入阶段 2 |

4. shutdown plan-reviewer → 进入阶段 2

---

### 阶段 2: 计划写入（lead 自己执行）

**lead 操作：**

跳过条件：已存在 `.plan/features.json` 时跳过，直接进入阶段 3。

1. 调用 `Skill("plan-write")` 将计划写入项目文件
2. skill 内的门控处理：
   - 文件冲突（.plan/features.json 已存在）：选择"覆盖"
3. 确认 `.plan/features.json` 和 `.plan/dev-*.log` 存在 → 进入阶段 3

**优势**：lead 在阶段 1 亲历了方案预研和任务分解全过程，plan-write 阶段无需重复询问用户。

---

### 阶段 3: 任务开发（developer）

**lead 操作：**
创建团队（如未创建），spawn developer（`subagent_type: general-purpose`, `mode: bypassPermissions`, `team_name: backend-team`），发送指令（详见 `references/developer-prompt.md`）：

```
请循环执行 /plan-next，直到所有任务的 passes 都为 true。

执行步骤：
1. 读取 .plan/features.json，找到第一个 passes: false 的任务
2. 调用 Skill("plan-next") 执行该任务
3. 按 TDD 流程完成（READ → EXPLORE → PLAN → RED → IMPLEMENT → GREEN → COMMIT）
4. 每完成一个任务，SendMessage 通知 lead 进度（已完成/总数）
5. 继续下一个 passes: false 的任务
6. 全部完成后 SendMessage 通知 lead

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
| Coverage | `mvn test -Pcoverage` | `go test -cover ./...` | `npm test -- --coverage` | `pytest --cov` |
| Security | 硬编码扫描 | 硬编码扫描 | `npm audit` | 硬编码扫描 |
| Diff | `git diff --stat` | `git diff --stat` | `git diff --stat` | `git diff --stat` |
| API 验证 | 调用 `Skill("backend-test")`（仅当项目含 HTTP 服务时） | 服务可启动、接口无 5xx、响应结构正确 |

2. 输出验证报告：

```
验证报告
========
Build:    [PASS/FAIL]
Lint:     [PASS/FAIL] (X warnings)
Test:     [PASS/FAIL] (X/Y passed)
Coverage: [X%] (目标 80%, 达标/不达标)
Security: [PASS/FAIL] (X issues)
Diff:     [X files changed, +Y/-Z lines]（检查是否有意外修改的文件）

结论: [通过/不通过]
```

注：Coverage 不达标不阻断流程，但在报告中标注并提醒。

3. 将验证报告追加到 dev log，并写入 `[Verification-Done]` 标记

4. 处理结果：

| 结论 | lead 处理 |
|------|----------|
| 通过 | 进入阶段 4 |
| 不通过（Build/Lint/Type 失败） | spawn build-error-resolver（`subagent_type: build-error-resolver`（项目 agent））自动修复 → 重新验证 → 仍失败则 AskUserQuestion |
| 不通过（Test 失败） | AskUserQuestion 展示失败项（测试失败需人工判断） |
| 不通过（Security 失败） | AskUserQuestion 展示失败项（安全问题需人工确认） |

---

### 阶段 4: 代码优化（polisher）

**lead 操作：**
spawn polisher（`subagent_type: general-purpose`, `mode: bypassPermissions`, `team_name: backend-team`），发送指令（详见 `references/polisher-prompt.md`）：

```
请依次执行代码优化：

第零步：De-Sloppify 检查
- 检测 AI 过度工程化的模式：
  - 测试中是否测试了语言特性而非业务逻辑（如测试 null 参数构造函数而非业务规则）
  - 是否有过度防守的类型检查（内部方法间传递已校验的参数又重复校验）
  - 是否有不必要的 try-catch（catch 后只是重新抛出）
  - 是否有过度抽象（只用了一次的 interface/abstract class）
- 发现后直接清理，SendMessage 给 lead 报告清理项

第一步：调用 Skill("code-simplifier")
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

### 阶段 5: Code Review（reviewer + blind-reviewer + security-reviewer）

**lead 操作：**

1. 准备 CR 材料：
   - 执行 `git diff main...HEAD`（或合适的 base branch），保存 diff 内容
   - 读取 `.plan/pr-description.md`
   - **安全审查触发判断**：检查 diff 中是否包含安全相关关键词（`auth`、`login`、`password`、`token`、`secret`、`key`、`middleware`、`interceptor`、`filter`、`sql`、`query`、`exec`、`.env`、`config`）

2. 并行 spawn reviewer（审查标准详见 `references/reviewer-prompt.md`）：
   - 默认 spawn 2 个：reviewer + blind-reviewer
   - 若触发安全审查条件：额外 spawn security-reviewer，共 3 个并行

**reviewer（Production CR）：**
spawn（`subagent_type: code-reviewer`（项目 agent）, `team_name: backend-team`），发送指令：

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
spawn（`subagent_type: code-reviewer`（项目 agent）, `team_name: backend-team`），发送指令：

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

**security-reviewer（Security CR，仅在触发条件满足时 spawn）：**
spawn（`subagent_type: security-reviewer`（项目 agent）, `team_name: backend-team`），发送指令：

```
你是 Security Reviewer，负责从安全角度审查本次代码变更。

请执行安全审查：
1. 运行 git diff main...HEAD 获取本次所有变更
2. 聚焦安全相关文件（认证、授权、输入处理、数据存储、配置）
3. 按 6 个维度审查：凭证管理、输入校验、注入防护、认证授权、敏感数据、依赖安全
4. 只审查 diff 中变更的代码

置信度过滤：
- 只报告置信度 >80% 的安全问题
- 已有框架级防护覆盖的问题可跳过
- 同类问题合并

严重等级：CRITICAL / HIGH / MEDIUM / LOW
输出格式：[严重等级] 问题标题 → 维度 → 文件:行号 → 问题描述 → 风险 → 修复建议
审查结束附加安全摘要表和结论（SECURE/WARNING/BLOCK）

完成后 SendMessage 给 lead。
```

3. **lead 汇总：**
   - 收集所有 reviewer 的报告（2 个或 3 个）
   - 合并去重，按严重等级排序（CRITICAL 优先）
   - 标注来源（Production / Blind / Security / 多方一致）
   - 多方一致的发现升级置信度标记（**高置信度**）
   - 汇总 verdict：取所有 reviewer 中最严格的结论（BLOCK > WARNING > APPROVE/SECURE）
   - 用 AskUserQuestion 展示汇总报告，询问用户处理决策
   - shutdown 所有 reviewer

---

### 阶段 6: 收尾

**lead 操作：**
1. 清理团队：`TeamDelete`
2. 向用户输出最终报告：

```markdown
## Backend Team 执行报告

### 执行概览
| 阶段 | 状态 | 执行者 |
|------|------|--------|
| 方案预研 | 完成 | lead |
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
| 变更文件数 | X |
| 新增/删除行数 | +X / -X |
| 验证结果 | PASS/FAIL |
| CR 结论 | APPROVE/WARNING/BLOCK |
| CR 发现 | CRITICAL:X HIGH:X MEDIUM:X LOW:X |

### 产出文件
- `.plan/task.md` - 技术方案文档
- `.plan/pr-description.md` - PR 描述（阶段 1 生成）
- `.plan/features.json` - 任务状态（所有 passes: true）
- `.plan/dev-YYYY-MM-DD.log` - 开发日志
- 代码实现 + 测试文件

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

中断恢复：重新执行 `/backend-team` 时，lead 根据文件状态自动判断跳入阶段（见阶段 0 的文件状态检查表）。
