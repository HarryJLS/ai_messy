---
name: frontend-single
description: 精简版前端开发编排，顺序执行四个核心 skill（plan-write → plan-next → code-simplifier → code-fixer）。当用户说 "/frontend-single"、"前端精简" 时触发。需先运行 /plan-init 完成任务分解。支持 React、Vue3、Vue2 框架自动检测。
---

# Frontend Single - 精简版前端开发编排

顺序执行 4 个核心 skill，无 Agent Team，无设计系统生成，无 CR，专注快速交付。支持 React、Vue3、Vue2 三种前端框架自动检测。

**前置条件**：需先运行 `/plan-init` 完成任务分解并审批。

**与 frontend-team 的区别**：去掉设计系统生成（ui-ux-pro-max + frontend-design）、方案审查（plan-reviewer）、全量验证（build-fixer）、多维 CR（reviewer/blind-reviewer/security-reviewer）、pr-description.md 生成、De-Sloppify 检查。保留框架检测、前端专项开发规则和精简 UI/UX 检查。

## 流水线概览

```
阶段 0: 确认需求 + 框架检测 + 跳入点判断
  ↓
阶段 1: Skill("plan-write")
  ↓
阶段 2: 循环 Skill("plan-next") 直到所有任务完成
  ↓
阶段 2.5: 快速验证（build + test）+ 精简 UI/UX 检查
  ↓
阶段 3: Skill("code-simplifier") + Skill("code-fixer")
  ↓
阶段 4: 执行报告
```

## 框架检测规则

| 检测条件 | 判定框架 |
|----------|----------|
| `package.json` 含 `react` 依赖 | React |
| `package.json` 含 `vue` 依赖且版本 `^3.x` 或 `>=3` | Vue3 |
| `package.json` 含 `vue` 依赖且版本 `^2.x` 或 `<3` | Vue2 |
| `next.config.*` 存在 | React (Next.js) |
| `vite.config.*` 含 `@vitejs/plugin-vue` | Vue3 |
| `vue.config.js` 存在 | Vue2 |
| 无法自动判定 | AskUserQuestion 询问用户 |

## 框架适配速查

| 维度 | React | Vue3 | Vue2 |
|------|-------|------|------|
| 组件模式 | 函数组件 + Hooks | Composition API + SFC | Options API + SFC |
| 状态管理 | useState/Context/Zustand | Pinia / ref+reactive | Vuex |
| 测试 | React Testing Library | @vue/test-utils + Vitest | @vue/test-utils + Jest |
| 样式方案 | CSS Modules / Tailwind | Scoped CSS / Tailwind | Scoped CSS / Less/Sass |

## 核心协议

**通用验证原则：** 每次检查/验收时，逐项确认每个方法/功能是否真正完整实现，而非仅写了兜底/stub/placeholder。除非用户明确声明"先留口子，后续开发"，才允许只写兜底方案。

### 阶段 0: 确认需求、框架检测与跳入点判断

1. 确认用户的需求描述（文字、MD 文件路径、设计稿链接等），记录完整的原始输入
2. **框架检测**：检查项目的 `package.json`、配置文件，按上方框架检测规则判定前端框架
   - 如无法自动判定，用 AskUserQuestion 询问用户选择 React / Vue3 / Vue2
   - 记录检测结果，后续阶段均以此为上下文
3. 如涉及参考其他项目代码，确认参考项目路径并记录
4. 检查现有文件状态，确定跳入点：

| 文件状态 | 跳入阶段 |
|----------|----------|
| 无 `.plan/features.json` | 阶段 1（完整流程） |
| 有 `.plan/features.json`、有目标范围内未完成任务、`.plan/dev-*.log` 中有开发日志 | 阶段 2（中断恢复） |
| 有 `.plan/features.json`、有目标范围内未完成任务、无开发日志 | 阶段 1（需先 plan-write） |
| 有 `.plan/features.json`、目标范围内全部完成、dev log 中无 `[Polisher-Done]` 标记 | 阶段 3（代码优化） |
| 有 `.plan/features.json`、目标范围内全部完成、dev log 中有 `[Polisher-Done]` 标记 | 直接输出报告 |

**目标范围**：
- 如果任务含 `domain` 字段，只看 `domain=frontend` 的任务；否则看所有任务
- 如果用户指定了 app 名（如 `/frontend-single admin-web`），进一步只看 `app=admin-web` 的任务
- 未指定 app 时，执行所有符合 domain 条件的任务

---

### 阶段 1: 计划写入

**前置检查**：确认 `~/.claude/plans/*.md` 存在（由 `/plan-init` 生成）。若不存在，提示用户先运行 `/plan-init`，然后停止。

1. 调用 `Skill("plan-write")` 将计划写入项目文件
2. 确认 `.plan/features.json` 和 `.plan/dev-*.log` 存在 → 进入阶段 2

---

### 阶段 2: 前端开发（plan-next 循环）

调用 `Skill("plan-next")` 并传入过滤参数，让 plan-next 只执行目标范围内的任务：

- 传入 `domain=frontend`
- 如果用户指定了 app（如 `/frontend-single admin-web`），同时传入 `app=admin-web`

plan-next 会自动按过滤条件循环执行所有匹配的任务，包括 appPath 路由和 apiContracts 感知。

**执行步骤：**
1. 调用 `Skill("plan-next", args: "domain=frontend")`（如有 app 参数则追加，如 `"domain=frontend app=admin-web"`）
2. plan-next 内部按 TDD 流程循环完成所有匹配任务
3. plan-next 循环结束后 → 进入阶段 2.5

**前端专项规则（在 plan-next 执行时遵循）：**
- 组件实现时按框架约定组织文件（React: 组件文件夹模式，Vue: SFC 单文件组件）
- 所有布局必须考虑响应式：至少覆盖 375px（手机）、768px（平板）、1024px（桌面）三个断点
- 交互元素必须有 hover/focus/active 状态
- 样式方案遵循框架适配速查表中的推荐方案

**卡住策略：**
- 同一任务内测试连续失败 3 次：用 AskUserQuestion 向用户展示错误日志和已尝试的方案，请求决策
- 发现任务 description 与实际代码结构不匹配：用 AskUserQuestion 向用户说明差异
- 不要在失败后无限重试同一方案，尝试 2 种不同思路后仍失败即向用户求助

---

### 阶段 2.5: 快速验证 + UI/UX 检查

在代码优化前确认基本可用性和 UI 质量。

**步骤 1: Build + Test 验证**

1. 读取 features.json，统计目标范围内任务状态：
   - 如有跳过的任务，输出警告："⚠️ X 个任务被跳过，建议检查后再继续"
2. **Build 验证**：检测项目构建工具并运行构建
   | 检测条件 | 构建命令 |
   |----------|---------|
   | `package.json` 有 build script | `npm run build` |
   | `vite.config.*` 存在 | `npx vite build` |
   | `next.config.*` 存在 | `npx next build` |
3. **Test 验证**：运行项目测试（如有测试脚本）
4. 输出结果："快速验证: Build [PASS/FAIL] | Test [PASS/FAIL]"
5. Build 失败 → AskUserQuestion（展示错误日志，询问是否修复后继续或跳过验证）
6. Test 失败（仅新失败的用例） → AskUserQuestion

**步骤 2: 精简 UI/UX 检查（5 项核心）**

先用 `git diff` 确定本次修改的前端文件范围，逐项检查：

- [ ] **交互反馈**：所有可点击元素有 `cursor-pointer`，hover 状态提供清晰视觉反馈
- [ ] **响应式布局**：375px / 768px / 1024px 下无布局破损、无横向滚动
- [ ] **主题色一致**：使用 CSS 变量 / Tailwind token 而非硬编码颜色值（如 `#3B82F6`）
- [ ] **基础无障碍**：所有 `<img>` 有 `alt` 文本，表单 `<input>` 有关联 `<label>`
- [ ] **过渡动画**：transition 时长 150-300ms，hover 不引起布局偏移

发现的问题直接修复。检查完成后输出简要检查报告（通过项 / 修复项）。

全部通过 → 进入阶段 3

---

### 阶段 3: 代码优化

**3a. 代码简化（code-simplifier）**

1. 多应用模式：cd 到当前 app 的 appPath 目录
2. 调用 `Skill("code-simplifier")`
3. 先用 `git diff` 确定本次开发修改的文件范围，将文件列表作为优化目标

**3b. 代码规范修复（code-fixer）**

1. 调用 `Skill("code-fixer")`
2. 对代码进行规范修复（基于 git diff）
3. 完成后在 dev log 中写入 `[Polisher-Done]` 标记（多应用模式写入 `{appPath}/.plan/dev-YYYY-MM-DD.log`）
4. 多应用模式：cd 回编排目录
5. 进入阶段 4

---

### 阶段 4: 执行报告

向用户输出最终报告：

```markdown
## Frontend Single 执行报告

### 执行概览
| 阶段 | 状态 |
|------|------|
| 计划写入（plan-write） | 完成 |
| 前端开发（plan-next） | 完成 |
| UI/UX 检查（5 项） | X 通过 / Y 修复 |
| 代码简化（code-simplifier） | 完成 |
| 规范修复（code-fixer） | 完成 |

### 量化指标
| 指标 | 数值 |
|------|------|
| 前端框架 | {React / Vue3 / Vue2} |
| 任务总数 | X |
| 变更文件数 | X |
| 新增/删除行数 | +X / -X |

### 产出文件
- `.plan/features.json` - 任务状态（所有 passes: true）
- `.plan/dev-YYYY-MM-DD.log` - 开发日志
- 前端组件 + 页面 + 测试文件

### 后续建议
- 运行 `/code-review` 进行代码审查
- 运行 `/plan-archive` 归档本次开发
```

## 错误处理

| 错误类型 | 处理方式 |
|----------|----------|
| plan-write 失败 | 检查计划文件是否存在（需先运行 /plan-init），重新执行 |
| plan-next 测试失败 | TDD 流程内自行处理；连续失败 3 次则 AskUserQuestion |
| UI/UX 检查修复失败 | AskUserQuestion 展示问题，询问是否跳过 |
| code-simplifier/code-fixer 失败 | AskUserQuestion 展示错误，询问是否跳过 |

中断恢复：重新执行 `/frontend-single` 时，根据文件状态自动判断跳入阶段（见阶段 0 的文件状态检查表）。
