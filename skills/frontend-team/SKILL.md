---
name: frontend-team
description: 前端开发团队编排，串联设计 → 编码 → 打磨 → 审查的完整流水线。当用户说 "/frontend-team" 时触发。支持 React、Vue3、Vue2 三种前端框架，集成 ui-ux-pro-max 设计系统和 frontend-design 美学指南。
---

# Frontend Team - 前端开发团队编排

Lead 亲自主导设计系统生成、UI 方案预研和计划写入，再通过 Agent Team 协调 `/plan-next` → `/code-simplifier` → `/code-fixer`，实现从设计到前端交付的全流程自动化。

**与 backend-team 的核心区别**：backend-team 围绕"通用代码"设计（plan-init 深度模式探索代码库），本 skill 面向"前端开发"场景——阶段 1 用设计系统生成 + UI 方案替代代码探索，polisher 增加 UI/UX 规范检查，全程按检测到的前端框架（React/Vue3/Vue2）分支处理。

## 团队架构

| 角色 | Agent 名称 | 类型 | spawn 模式 | 职责 |
|------|-----------|------|-----------|------|
| 团队负责人 | lead（自身） | - | - | 需求分析、设计系统生成、UI 方案构建、任务分解、计划写入、全量验证、编排调度 |
| 开发者 | developer | general-purpose | bypassPermissions | 前端组件/页面实现（TDD 循环） |
| 打磨者 | polisher | general-purpose | bypassPermissions | UI/UX 规范检查 + 代码简化 + 规范修复 |
| 构建修复者 | build-fixer | build-error-resolver（项目 agent） | - | 验证失败时自动修复 build/lint/type 错误 |
| 方案审查者 | plan-reviewer | code-architect（项目 agent） | - | 零上下文审查设计方案，挑战完整性和合理性 |
| 审查者 | reviewer | code-reviewer（项目 agent） | - | 前端 CR，有完整代码上下文，引用 `code-review/frontend.md` |
| 盲审者 | blind-reviewer | code-reviewer（项目 agent） | - | 零上下文盲审，仅依据 PR 描述 + diff |
| 安全审查者 | security-reviewer | security-reviewer（项目 agent） | - | 前端安全审查（XSS、敏感数据、CSP，条件触发） |

**设计说明**：
- lead 亲自执行设计系统生成 + `/plan-init` + `/plan-write`：设计方案是前端项目决策的核心环节，lead 直接与用户交互，避免决策转发导致的上下文丢失和延迟
- polisher 合并 simplifier + fixer + UI/UX 检查：都是后处理，顺序执行
- reviewer / blind-reviewer / plan-reviewer 使用项目级 agent 定义（`agents/` 目录），不依赖外部 plugin

## 多框架适配策略

| 维度 | React | Vue3 | Vue2 |
|------|-------|------|------|
| 构建工具 | Vite / Next.js | Vite | Webpack (vue-cli) |
| 状态管理 | useState/Context/Zustand | Pinia / ref+reactive | Vuex |
| 类型系统 | TypeScript + interface Props | TypeScript + defineProps | Options API + PropTypes |
| 测试 | React Testing Library | @vue/test-utils + Vitest | @vue/test-utils + Jest |
| 组件模式 | 函数组件 + Hooks | Composition API + SFC | Options API + SFC |
| 样式方案 | CSS Modules / Tailwind / styled-components | Scoped CSS / Tailwind | Scoped CSS / Less/Sass |
| 路由 | React Router / Next.js App Router | Vue Router 4 | Vue Router 3 |
| CR 标准 | `code-review/frontend.md`（已有） | 同左 + Vue 专项 | 同左 + Vue2 专项 |

**框架检测规则**（阶段 0 执行）：

| 检测条件 | 判定框架 |
|----------|----------|
| `package.json` 含 `react` 依赖 | React |
| `package.json` 含 `vue` 依赖且版本 `^3.x` 或 `>=3` | Vue3 |
| `package.json` 含 `vue` 依赖且版本 `^2.x` 或 `<3` | Vue2 |
| `next.config.*` 存在 | React (Next.js) |
| `vite.config.*` 含 `@vitejs/plugin-vue` | Vue3 |
| `vue.config.js` 存在 | Vue2 |
| 无法自动判定 | AskUserQuestion 询问用户 |

## 用户交互机制

| 阶段 | 交互方式 |
|------|---------|
| 阶段 0-2（lead 自己执行） | lead 直接用 AskUserQuestion 与用户交互，无需转发 |
| 阶段 1.5（plan-reviewer 执行） | plan-reviewer SendMessage 给 lead → lead 用 AskUserQuestion 展示审查结果 → 采纳的修改更新到 .plan/task.md |
| 阶段 3-4（teammate 执行） | teammate SendMessage 给 lead → lead 用 AskUserQuestion 询问用户 → lead SendMessage 转发答案 |
| 阶段 5（CR reviewer 执行） | reviewer SendMessage 给 lead → lead 汇总后用 AskUserQuestion 展示报告 |

**teammate 交互区分标准**：
- 关键决策（设计方向、组件库选择、状态管理方案）：必须 SendMessage 给 lead 请求用户决策
- 非关键门控（代码探索确认、理解确认等）：teammate 自主判断，跳过门控继续执行

## 核心协议

**通用验证原则：** 每次检查/验收时，逐项确认每个方法/功能是否真正完整实现，而非仅写了兜底/stub/placeholder。除非用户明确声明"先留口子，后续开发"，才允许只写兜底方案。

### 阶段 0: 初始化与跳入点判断

**lead 操作：**

1. 确认用户的需求描述（文字、MD 文件路径、设计稿链接等），记录完整的原始输入
2. **框架检测**：检查项目的 `package.json`、配置文件，按上方框架检测规则判定前端框架
   - 如无法自动判定，用 AskUserQuestion 询问用户选择 React / Vue3 / Vue2
   - 记录检测结果，后续阶段均以此为分支条件
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

### 阶段 1: 设计系统生成 + UI 方案预研（替代 backend-team 的 plan-init 深度模式）

**这是与 backend-team 的核心区别。** 不走 plan-init 的通用深度模式，而是先生成设计系统、构建 UI 方案，再输出 .plan/task.md。

**lead 操作：**

**1a. 设计系统生成（集成 ui-ux-pro-max）**

1. 从用户需求中提取关键词（产品类型、行业、风格偏好）
2. 调用 ui-ux-pro-max 的 search.py 生成设计系统：

```bash
python3 skills/ui-ux-pro-max/scripts/search.py "<产品类型> <行业> <风格关键词>" --design-system -p "<项目名>"
```

3. 获取推荐的设计系统：样式、调色板、字体搭配、效果、反模式
4. 如用户有特定偏好，用 AskUserQuestion 确认或调整设计系统

**1b. UI 方案构建（参考 frontend-design）**

1. 运用 frontend-design 的设计思考框架：
   - **Purpose**：界面解决什么问题？谁在使用？
   - **Tone**：选择明确的美学方向（极简、极繁、复古未来、有机自然、奢华精致等）
   - **Constraints**：技术约束（检测到的框架、性能、无障碍）
   - **Differentiation**：什么让这个界面令人难忘？
2. 基于 1a 的设计系统 + 1b 的设计思考，规划页面/组件结构
3. 对于每个页面/组件，确定：
   - 布局方案（响应式断点策略）
   - 交互模式（动画、过渡、状态反馈）
   - 组件拆分粒度

**1c. 生成 .plan/task.md + .plan/pr-description.md**

1. 综合 1a 和 1b 的结果，生成 `.plan/task.md`：

```markdown
## 设计系统

### 调色板
{来自 ui-ux-pro-max 推荐}

### 字体
{来自 ui-ux-pro-max 推荐}

### 风格
{来自 ui-ux-pro-max 推荐 + frontend-design 美学方向}

## 技术方案

### 框架
{检测到的框架：React / Vue3 / Vue2}

### 整体思路
{UI 方案概述：页面结构、组件拆分、状态管理策略}

### 任务列表
| # | 任务 | category | dependsOn | complexity |
|---|------|----------|-----------|------------|
| 1 | 项目配置和设计系统基础设施 | config | - | S |
| 2 | 公共组件（Button/Input/Card等） | core | 1 | M |
| 3 | 页面 A 实现 | feature | 2 | L |
| ... | ... | ... | ... | ... |
```

2. 生成 `.plan/pr-description.md`：

```markdown
## PR 标题
{一句话概括变更}

## 变更动机
{为什么要做这个改动，业务背景}

## 方案概述
{技术方案的核心思路，不含实现细节}

## 设计方向
{设计系统的核心选择：风格、调色板、字体}

## 预期改动范围
{涉及的模块/文件类型，粗粒度}
```

来源：从 .plan/task.md 的设计系统和技术方案提取，**不含具体文件路径和代码细节**。

3. 确认 `.plan/task.md` 和 `.plan/pr-description.md` 已生成 → 进入阶段 1.5

---

### 阶段 1.5: 方案对抗审查（plan-reviewer）

**触发条件**：.plan/task.md 中任务数 ≥ 3 时执行。任务数 < 3 的小改动直接跳过，进入阶段 2。

**lead 操作：**

1. 读取 .plan/task.md 内容，统计任务数量
2. spawn plan-reviewer（`subagent_type: code-architect`（项目 agent）, `team_name: frontend-team`），发送指令：

```
你是方案审查者，负责用独立视角挑战前端技术方案的完整性和合理性。

## 技术方案
{.plan/task.md 完整内容}

请从以下维度审查，只报告你认为**确实有问题**的点（没问题的不用列）：

1. **遗漏检查**：任务列表是否遗漏了必要的步骤？（如：缺少响应式适配、缺少加载状态/错误状态、缺少无障碍支持）
2. **设计系统一致性**：设计系统的选择（调色板、字体、风格）是否与目标产品匹配？
3. **组件粒度**：组件拆分是否合理？是否有组件过大需要拆分？或过细可以合并？
4. **依赖顺序**：dependsOn 是否正确？公共组件是否在页面组件之前？
5. **技术决策盲点**：前端框架/构建工具/状态管理的选型是否有更优替代？
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

**优势**：lead 在阶段 1 亲历了设计系统生成和 UI 方案全过程，此阶段大部分门控可基于已有上下文直接通过，无需重复询问用户。

---

### 阶段 3: 前端开发（developer）

**lead 操作：**
创建团队（如未创建），spawn developer（`subagent_type: general-purpose`, `mode: bypassPermissions`, `team_name: frontend-team`），发送指令（详见 `references/developer-prompt.md`）：

```
请循环执行 /plan-next，直到所有任务的 passes 都为 true。

框架：{检测到的框架}
设计系统摘要：{.plan/task.md 中设计系统部分的关键信息}

执行步骤：
1. 读取 .plan/features.json，找到第一个 passes: false 的任务
2. 调用 Skill("plan-next") 执行该任务
3. 按 TDD 流程完成（READ → EXPLORE → PLAN → RED → IMPLEMENT → GREEN → COMMIT）
4. 每完成一个任务，SendMessage 通知 lead 进度（已完成/总数）
5. 继续下一个 passes: false 的任务
6. 全部完成后 SendMessage 通知 lead

前端专项规则：
- 组件实现时遵循设计系统（调色板、字体、间距）
- 所有布局必须通过响应式验证：至少覆盖 375px（手机）、768px（平板）、1024px（桌面）三个断点
- 交互元素必须有 hover/focus/active 状态
- 按框架约定组织文件（React: 组件文件夹模式，Vue: SFC 单文件组件）

注意事项：
- TDD 流程内的常规门控（EXPLORE→PLAN、PLAN→RED 确认）：自主跳过
- 关键技术决策（组件库选择、状态管理方案、路由结构）：SendMessage 给 lead
- .plan/features.json 在此阶段只有你一个 agent 读写，无并发问题

卡住策略：
- 同一任务内测试连续失败 3 次：SendMessage 给 lead，附带错误日志和已尝试的方案
- 探索代码后发现任务 description 与实际代码结构不匹配：SendMessage 给 lead 说明差异
- 遇到需要外部依赖但环境未配置：SendMessage 给 lead
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

1. 执行前端全量验证：

| 验证项 | 命令 | 说明 |
|--------|------|------|
| Build | `npm run build` 或 `yarn build` 或 `pnpm build` | 编译无错误 |
| Lint | `npm run lint` 或项目配置的 lint 命令 | ESLint 无 error |
| Type Check | `npx tsc --noEmit`（TS 项目）或 `npx vue-tsc --noEmit`（Vue3 + TS） | 类型检查通过 |
| Test | `npm test` 或 `npx vitest run` 或 `npx jest` | 测试全部通过 |
| Coverage | `npm test -- --coverage` 或 `npx vitest run --coverage` | 目标 80% |
| Security | `npm audit --audit-level=high` | 无高危漏洞 |
| Diff | `git diff --stat` | 检查是否有意外修改的文件 |
| E2E | 调用 `Skill("frontend-test")` | 页面可访问、无控制台错误、响应式正常 |

2. 输出验证报告：

```
验证报告
========
Build:      [PASS/FAIL]
Lint:       [PASS/FAIL] (X warnings)
Type Check: [PASS/FAIL] (X errors)
Test:       [PASS/FAIL] (X/Y passed)
Coverage:   [X%] (目标 80%, 达标/不达标)
Security:   [PASS/FAIL] (X issues)
Diff:       [X files changed, +Y/-Z lines]（检查是否有意外修改的文件）

结论: [通过/不通过]
```

注：Coverage 不达标不阻断流程，但在报告中标注并提醒。

3. 将验证报告追加到 dev log，并写入 `[Verification-Done]` 标记

4. 处理结果：

| 结论 | lead 处理 |
|------|----------|
| 通过 | 进入阶段 4 |
| 不通过（Build/Lint/Type Check 失败） | spawn build-error-resolver（`subagent_type: build-error-resolver`（项目 agent））自动修复 → 重新验证 → 仍失败则 AskUserQuestion |
| 不通过（Test 失败） | AskUserQuestion 展示失败项（测试失败需人工判断） |
| 不通过（Security 失败） | AskUserQuestion 展示失败项（安全问题需人工确认） |

---

### 阶段 4: UI/UX 打磨（polisher）

**这是与 backend-team 的另一个核心区别。** polisher 在标准代码打磨基础上，增加 UI/UX 规范检查。

**lead 操作：**
spawn polisher（`subagent_type: general-purpose`, `mode: bypassPermissions`, `team_name: frontend-team`），发送指令（详见 `references/polisher-prompt.md`）：

```
请依次执行 UI/UX 检查和代码优化：

框架：{检测到的框架}

第零步：De-Sloppify 检查
- 检测 AI 过度工程化的模式：
  - 测试中是否测试了语言特性而非业务逻辑
  - 是否有过度防守的类型检查
  - 是否有不必要的 try-catch
  - 是否有过度抽象（只用了一次的 interface/abstract class）
- 发现后直接清理，SendMessage 给 lead 报告清理项

第一步：UI/UX Pre-Delivery Checklist（来自 ui-ux-pro-max）
- 先用 git diff 确定本次修改的前端文件范围
- 逐项检查 Pre-Delivery Checklist：

  **视觉质量**
  - [ ] 无 emoji 用作图标（使用 SVG 替代）
  - [ ] 所有图标来自统一图标集（Heroicons/Lucide）
  - [ ] hover 状态不引起布局偏移
  - [ ] 使用主题色变量而非硬编码颜色值

  **交互**
  - [ ] 所有可点击元素有 cursor-pointer
  - [ ] hover 状态提供清晰的视觉反馈
  - [ ] 过渡动画平滑（150-300ms）
  - [ ] 键盘导航有可见的 focus 状态

  **明暗模式**（如适用）
  - [ ] 浅色模式文字有足够对比度（4.5:1 以上）
  - [ ] 透明元素在浅色模式下可见
  - [ ] 边框在两种模式下都可见

  **布局**
  - [ ] 响应式：375px、768px、1024px、1440px 下布局正常
  - [ ] 无移动端横向滚动
  - [ ] 固定元素不遮挡内容

  **无障碍**
  - [ ] 所有图片有 alt 文本
  - [ ] 表单输入有 label
  - [ ] 颜色不是唯一指示器
  - [ ] 尊重 prefers-reduced-motion

- 发现的问题直接修复
- SendMessage 给 lead 报告检查结果和修复项

第二步：调用 Skill("code-simplifier")
- 将第零步确定的文件范围作为优化目标
- 完成后 SendMessage 通知 lead

第三步：调用 Skill("code-fixer")
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
   - **安全审查触发判断**：检查 diff 中是否包含安全相关关键词（`auth`、`login`、`password`、`token`、`secret`、`key`、`middleware`、`interceptor`、`filter`、`sql`、`query`、`exec`、`.env`、`config`、`cors`、`csp`、`cookie`、`localStorage`、`innerHTML`、`dangerouslySetInnerHTML`）

2. 并行 spawn reviewer（审查标准详见 `references/reviewer-prompt.md`）：
   - 默认 spawn 2 个：reviewer + blind-reviewer
   - 若触发安全审查条件：额外 spawn security-reviewer，共 3 个并行

**reviewer（Production CR）：**
spawn（`subagent_type: code-reviewer`（项目 agent）, `team_name: frontend-team`），发送指令：

```
你是 Production Code Reviewer，负责上线前的正式前端代码审查。
前端框架：{检测到的框架}

请执行完整的代码审查：
1. 运行 git diff main...HEAD 获取本次所有变更
2. 对每个变更文件，读取完整文件理解上下文
3. 按以下维度审查（通用 + 前端专项）：

   通用维度：
   - 安全漏洞（XSS、未校验输入、敏感数据暴露）
   - 逻辑错误（边界条件、空值处理、竞态条件）
   - 性能问题（不必要的重渲染、大列表未虚拟化、未优化的计算）
   - 代码质量（嵌套过深、职责不清、缺少错误处理）
   - 测试覆盖（关键路径是否有测试）

   前端专项维度（参考 code-review/frontend.md）：
   - React 架构：组件大小、key 使用、props drilling
   - 状态管理：直接 mutation、派生状态存储、useEffect 依赖缺失
   - TypeScript 质量：any 类型、类型断言、未类型化的 API 响应
   - 样式：Tailwind 魔法值、缺失响应式变体、缺失 focus 状态
   - 并发与竞态：useEffect 竞态、闭包陈旧状态、并发 mutation

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
spawn（`subagent_type: code-reviewer`（项目 agent）, `team_name: frontend-team`），发送指令：

```
你是 Blind Code Reviewer，执行零上下文盲审。
你只有以下信息，禁止读取任何项目文件或探索代码库：

## PR 描述
{.plan/pr-description.md 内容}

## Code Diff
{git diff 输出}

请仅基于以上信息审查：
1. diff 中是否存在明显 bug、逻辑错误
2. 是否有安全风险（XSS、敏感数据暴露、未校验的用户输入）
3. 代码变更是否与 PR 描述一致（做了描述之外的事？遗漏了描述中的需求？）
4. diff 中是否有可疑的模式（硬编码、TODO/FIXME、空实现、内联样式混用）
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
spawn（`subagent_type: security-reviewer`（项目 agent）, `team_name: frontend-team`），发送指令：

```
你是 Security Reviewer，负责从安全角度审查本次前端代码变更。

请执行安全审查，重点关注前端安全：
1. 运行 git diff main...HEAD 获取本次所有变更
2. 聚焦前端安全相关文件
3. 重点维度：
   - XSS 防护（innerHTML、dangerouslySetInnerHTML、v-html 的使用）
   - 敏感数据暴露（localStorage 中存储 Token、前端代码暴露 API 密钥）
   - CSP（Content Security Policy）配置
   - CORS 配置是否过于宽松
   - 第三方依赖安全（npm audit）
   - Cookie 安全属性（HttpOnly、Secure、SameSite）
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
## Frontend Team 执行报告

### 执行概览
| 阶段 | 状态 | 执行者 |
|------|------|--------|
| 设计系统生成 | 完成 | lead |
| UI 方案预研 | 完成 | lead |
| 方案审查 | 完成/跳过 | plan-reviewer |
| 任务分解 | 完成 | lead |
| 计划写入 | 完成 | lead |
| 前端开发 | 完成 | developer |
| 全量验证 | 完成 | lead |
| UI/UX 打磨 | 完成 | polisher |
| Code Review | 完成 | reviewer + blind-reviewer |

### 量化指标
| 指标 | 数值 |
|------|------|
| 前端框架 | {React / Vue3 / Vue2} |
| 任务总数 | X |
| 变更文件数 | X |
| 新增/删除行数 | +X / -X |
| 验证结果 | PASS/FAIL |
| CR 结论 | APPROVE/WARNING/BLOCK |
| CR 发现 | CRITICAL:X HIGH:X MEDIUM:X LOW:X |

### 设计系统
- 风格：{选用的设计风格}
- 调色板：{主色/辅色}
- 字体：{标题字体 / 正文字体}

### 产出文件
- `.plan/task.md` - 设计方案 + 技术方案文档
- `.plan/pr-description.md` - PR 描述（阶段 1 生成）
- `.plan/features.json` - 任务状态（所有 passes: true）
- `.plan/dev-YYYY-MM-DD.log` - 开发日志
- 前端组件 + 页面 + 测试文件

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

中断恢复：重新执行 `/frontend-team` 时，lead 根据文件状态自动判断跳入阶段（见阶段 0 的文件状态检查表）。
