---
name: fullstack-single
description: 精简版全栈开发编排，先后端再前端顺序执行四个核心 skill（plan-write → plan-next → code-simplifier → code-fixer）。当用户说 "/fullstack-single"、"全栈精简" 时触发。需先运行 /plan-init 完成任务分解。
---

# Fullstack Single - 精简版全栈开发编排

顺序执行 4 个核心 skill，无 Agent Team，无方案预研，无 CR。开发阶段按 domain 分两轮：先后端再前端。

**前置条件**：需先运行 `/plan-init` 完成任务分解并审批。任务 JSON 中需包含 `domain` 字段区分 backend/frontend 任务。

**与 fullstack-team 的区别**：去掉方案预研（plan-init 深度模式 + 设计系统）、方案审查（plan-reviewer）、全量验证（build-fixer）、多维 CR（reviewer/blind-reviewer/security-reviewer）、pr-description.md 生成、De-Sloppify 检查。保留核心开发流水线。

## 流水线概览

```
阶段 0: 确认需求 + 跳入点判断 + 语言/框架检测
  ↓
阶段 1: Skill("plan-write")
  ↓
阶段 2: 后端开发（循环 plan-next，只执行 domain=backend 的任务）
  ↓
阶段 3: 前端开发（循环 plan-next，只执行 domain=frontend 的任务）
  ↓
阶段 4: Skill("code-simplifier") + Skill("code-fixer")
  ↓
阶段 5: 执行报告
```

## 核心协议

**通用验证原则：** 每次检查/验收时，逐项确认每个方法/功能是否真正完整实现，而非仅写了兜底/stub/placeholder。除非用户明确声明"先留口子，后续开发"，才允许只写兜底方案。

### 阶段 0: 确认需求 + 跳入点判断 + 语言/框架检测

1. 确认用户的需求描述（文字、MD 文件路径、飞书/语雀链接等），记录完整的原始输入
2. 如涉及参考其他项目代码，确认参考项目路径并记录
3. **后端语言检测**：检查项目根目录的构建文件

| 检测条件 | 判定语言 |
|----------|----------|
| `pom.xml` 或 `build.gradle` 存在 | Java |
| `go.mod` 存在 | Go |
| `package.json` 含后端框架（express/koa/nestjs/fastify） | Node.js |
| `requirements.txt` 或 `pyproject.toml` 或 `setup.py` 存在 | Python |
| 无法自动判定 | AskUserQuestion 询问用户 |

4. **前端框架检测**：检查项目的 `package.json`、配置文件

| 检测条件 | 判定框架 |
|----------|----------|
| `package.json` 含 `react` 依赖 | React |
| `package.json` 含 `vue` 依赖且版本 `^3.x` 或 `>=3` | Vue3 |
| `package.json` 含 `vue` 依赖且版本 `^2.x` 或 `<3` | Vue2 |
| `next.config.*` 存在 | React (Next.js) |
| `vite.config.*` 含 `@vitejs/plugin-vue` | Vue3 |
| `vue.config.js` 存在 | Vue2 |
| 无法自动判定 | AskUserQuestion 询问用户 |

5. 记录两个检测结果（后端语言 + 前端框架），后续阶段分别使用
6. 检查现有文件状态，确定跳入点：

| 文件状态 | 跳入阶段 |
|----------|----------|
| 无 `.plan/features.json` | 阶段 1（完整流程） |
| 有 `.plan/features.json`、有 backend 未完成任务（`passes: false` 且 `domain=backend`） | 阶段 2（继续后端开发） |
| 有 `.plan/features.json`、backend 全完成、有 frontend 未完成任务 | 阶段 3（继续前端开发） |
| 有 `.plan/features.json`、全部完成、dev log 中无 `[Polisher-Done]` 标记 | 阶段 4（代码优化） |
| 有 `.plan/features.json`、全部完成、dev log 中有 `[Polisher-Done]` 标记 | 直接输出报告 |

**目标范围**：
- 按 `domain` 字段区分后端/前端任务，阶段 2 只看 `domain=backend`，阶段 3 只看 `domain=frontend`
- 如果用户指定了 app 名（如 `/fullstack-single order-service`），进一步只看 `app` 匹配的任务
- 未指定 app 时，执行所有符合 domain 条件的任务

---

### 阶段 1: 计划写入

**前置检查**：确认 `~/.claude/plans/*.md` 存在（由 `/plan-init` 生成）。若不存在，提示用户先运行 `/plan-init`，然后停止。

跳过条件：已存在 `.plan/features.json` 时跳过，直接进入阶段 2。

1. 调用 `Skill("plan-write")` 将计划写入项目文件
2. 确认 `.plan/features.json` 和 `.plan/dev-*.log` 存在 → 进入阶段 2

---

### 阶段 2: 后端开发（plan-next 循环，domain=backend）

调用 `Skill("plan-next")` 并传入过滤参数，让 plan-next 只执行后端任务：

- 传入 `domain=backend`
- 如果用户指定了 app（如 `/fullstack-single order-service`），同时传入 `app=order-service`

plan-next 会自动按过滤条件循环执行所有匹配的后端任务，包括 appPath 路由。

**执行步骤：**
1. 调用 `Skill("plan-next", args: "domain=backend")`（如有 app 参数则追加，如 `"domain=backend app=order-service"`）
2. plan-next 内部按 TDD 流程循环完成所有匹配任务
3. plan-next 循环结束后 → 进入阶段 3

**卡住策略：**
- 同一任务内测试连续失败 3 次：用 AskUserQuestion 向用户展示错误日志和已尝试的方案，请求决策
- 发现任务 description 与实际代码结构不匹配：用 AskUserQuestion 向用户说明差异
- 不要在失败后无限重试同一方案，尝试 2 种不同思路后仍失败即向用户求助

---

### 阶段 3: 前端开发（plan-next 循环，domain=frontend）

调用 `Skill("plan-next")` 并传入过滤参数，让 plan-next 只执行前端任务：

- 传入 `domain=frontend`
- 如果用户指定了 app（如 `/fullstack-single order-service`），同时传入 `app=order-service`

plan-next 会自动按过滤条件循环执行所有匹配的前端任务，包括 appPath 路由和 apiContracts 感知。

**执行步骤：**
1. 调用 `Skill("plan-next", args: "domain=frontend")`（如有 app 参数则追加），附加说明：前端调用后端 API 使用已实现的真实接口，不用 mock
2. plan-next 内部按 TDD 流程循环完成所有匹配任务
3. plan-next 循环结束后 → 进入阶段 4

**卡住策略**：同阶段 2。

---

### 阶段 4: 代码优化

**4a. 代码简化（code-simplifier）**

1. 调用 `Skill("code-simplifier")`
2. 先用 `git diff` 确定本次开发修改的文件范围（后端 + 前端），将文件列表作为优化目标

**4b. 代码规范修复（code-fixer）**

1. 调用 `Skill("code-fixer")`
2. 对代码进行规范修复（基于 git diff）
3. 完成后在 dev log 中写入 `[Polisher-Done]` 标记
4. 进入阶段 5

---

### 阶段 5: 执行报告

向用户输出最终报告：

```markdown
## Fullstack Single 执行报告

### 执行概览
| 阶段 | 状态 |
|------|------|
| 计划写入（plan-write） | 完成 |
| 后端开发（plan-next × N） | 完成 |
| 前端开发（plan-next × N） | 完成 |
| 代码简化（code-simplifier） | 完成 |
| 规范修复（code-fixer） | 完成 |

### 量化指标
| 指标 | 数值 |
|------|------|
| 后端语言 | {Java / Go / Node.js / Python} |
| 前端框架 | {React / Vue3 / Vue2} |
| 任务总数 | X（后端 Y + 前端 Z） |
| 变更文件数 | X |
| 新增/删除行数 | +X / -X |

### 产出文件
- `.plan/features.json` - 任务状态（所有 passes: true）
- `.plan/dev-YYYY-MM-DD.log` - 开发日志
- 后端代码 + 前端组件/页面 + 测试文件

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

中断恢复：重新执行 `/fullstack-single` 时，根据文件状态自动判断跳入阶段（见阶段 0 的文件状态检查表）。
