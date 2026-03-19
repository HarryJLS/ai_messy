# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 提供项目指导。

## 交互语言

- 思考过程和回复一律使用中文

## 项目概览

这是一个 Claude Code Plugin，提供 AI Agent 工作流和开发指南的技能合集（主要为中文）。

通过 `/plugin install` 安装后，可直接使用以下技能。

## 核心技能

### 开发流程

| 命令 | 用途 |
|------|------|
| `/plan-preview` | 预研技术方案，输出 `.plan/task.md` 供 `/plan-init` 使用 |
| `/plan-init` | 需求分析和任务分解，生成计划文件供审批 |
| `/plan-write` | 读取审批后的计划文件，写入 `.plan/features.json` 和 `.plan/dev-YYYY-MM-DD.log` |
| `/plan-next` | 执行下一个待处理任务，使用 TDD 循环（RED → GREEN → COMMIT） |
| `/backend-team` | 全流程编排：预研 + 初始化 + 开发 + 简化 + 修复 |
| `/framework-team` | 新项目脚手架编排：架构设计 + 脚手架 + TDD + 验证 + CR |
| `/frontend-team` | 前端开发编排：设计系统 + UI 方案 + 开发 + UI/UX 打磨 + CR |
| `/fullstack-team` | 全栈开发编排：后端预研 + 前端设计 → 后端开发 → 前端对接 → 打磨 → CR |
| `/backend-single` | 精简版后端编排：plan-write → plan-next → simplifier → fixer（需先 /plan-init） |
| `/fullstack-single` | 精简版全栈编排：plan-write → 后端 plan-next → 前端 plan-next → simplifier → fixer（需先 /plan-init） |

### 代码质量

| 命令 | 用途 |
|------|------|
| `/code-review` | 审查代码变更，生成审查报告 |
| `/code-fixer` | 自动修复代码风格问题（保留变量名不变） |
| `/code-simplifier` | 简化和优化代码 |
| `/unit-test` | 生成单元测试 |
| `/e2e-test` | 前端 E2E 验证（启动服务 → Playwright 验证 → 截图 → 报告） |
| `/api-verify` | 后端 API 运行时验证（启动服务 → 逐接口验证 → 报告） |

### Git 工具

| 命令 | 用途 |
|------|------|
| `/git-quick` | 快捷 pull/commit/push/checkout 一键完成 |
| `/git-worktree` | Git worktree 管理 |

### 持续学习

| 命令 | 用途 |
|------|------|
| `/learn` | 手动提取当前会话中的可复用模式，质量评估后保存 |
| `/instinct` | 自动观察 + 原子级学习 + 演化（hooks 驱动，项目隔离） |

### 其他工具

| 命令 | 用途 |
|------|------|
| `/setup-permissions` | 配置 Claude Code 权限白名单 |
| `/claude-md-manager` | 管理和更新 CLAUDE.md 文件 |
| `/add_or_update_skill` | 管理 skill 的添加和更新 |
| `/find-skills` | 发现和安装 agent skills |
| `/skill-creator` | 创建新 skill 的向导 |
| `/frontend-design` | 前端界面设计 |
| `/markitdown` | 文件转 Markdown |
| `/notebooklm-skill` | 查询 Google NotebookLM |
| `/planning-with-files` | 基于文件的任务规划 |
| `/ui-ux-pro-max` | UI/UX 设计智能 |

## 开发团队（Agent 团队编排）

### backend-team（现有项目开发）

详见 `skills/backend-team/SKILL.md`。

多 Agent 团队，自动编排完整开发流水线：

**团队角色：**

| 角色 | Agent | 职责 |
|------|-------|------|
| lead | self | 方案预研、Research & Reuse、任务分解、计划写入、全量验证、编排协调、用户沟通、决策 |
| developer | general-purpose (bypassPermissions) | TDD 任务执行循环 |
| polisher | general-purpose (bypassPermissions) | 代码简化 + 风格修复 |
| build-fixer | build-error-resolver（项目 agent） | 验证失败时自动修复 build/lint/type 错误 |
| plan-reviewer | code-architect（项目 agent） | 零上下文方案审查，挑战完整性和合理性 |
| reviewer | code-reviewer（项目 agent） | 生产级 CR，拥有完整代码上下文 |
| blind-reviewer | code-reviewer（项目 agent） | 零上下文盲审，仅基于 PR 描述 + diff |
| security-reviewer | security-reviewer（项目 agent） | 安全审查，聚焦漏洞检测（条件触发） |

**流水线：** Research & Reuse（lead）→ 方案预研（lead）→ 方案审查（plan-reviewer）→ 任务分解（lead）→ 计划写入（lead）→ TDD 开发循环（developer）→ 全量验证 + 自动修复（lead + build-fixer）→ 代码打磨（polisher）→ 多维代码审查（reviewer + blind-reviewer + security-reviewer）→ 报告

### framework-team（新项目脚手架）

详见 `skills/framework-team/SKILL.md`。

面向"从零开始"的新项目场景，替换 backend-team 的方案预研为架构设计，其余阶段完全复用。

**与 backend-team 的核心差异：** 阶段 1 用架构设计（技术栈选择 → 目录结构 → 模块划分）替代代码探索，脚手架任务（config 类）使用 TDD 简化模式。

**流水线：** 需求收集（lead）→ 架构设计（lead）→ 方案审查（plan-reviewer）→ 任务分解（lead）→ 计划写入（lead）→ 脚手架+TDD 开发（developer）→ 全量验证（lead）→ 代码打磨（polisher）→ 双重代码审查（reviewer + blind-reviewer）→ 报告

### frontend-team（前端开发）

详见 `skills/frontend-team/SKILL.md`。

面向前端开发场景，串联设计 → 编码 → 打磨 → 审查的完整流水线。支持 React、Vue3、Vue2 三种前端框架。

**与 backend-team 的核心差异：** 阶段 1 用设计系统生成 + UI 方案（集成 ui-ux-pro-max + frontend-design）替代代码探索，阶段 4 polisher 增加 UI/UX Pre-Delivery Checklist，全程按检测到的框架分支处理。

**团队角色：**

| 角色 | Agent | 职责 |
|------|-------|------|
| lead | self | 需求分析、设计系统生成、UI 方案、任务分解、计划写入、全量验证、编排协调 |
| developer | general-purpose (bypassPermissions) | 前端组件/页面实现 |
| polisher | general-purpose (bypassPermissions) | UI/UX 规范检查 + 代码简化 + 风格修复 |
| build-fixer | build-error-resolver（项目 agent） | 验证失败时自动修复 build/lint/type 错误 |
| plan-reviewer | code-architect（项目 agent） | 零上下文方案审查，挑战完整性和合理性 |
| reviewer | code-reviewer（项目 agent） | 前端 CR（引用 code-review/frontend.md） |
| blind-reviewer | code-reviewer（项目 agent） | 零上下文盲审，仅基于 PR 描述 + diff |
| security-reviewer | security-reviewer（项目 agent） | 前端安全审查（XSS、敏感数据暴露、CSP，条件触发） |

**流水线：** 设计系统生成（lead）→ UI 方案预研（lead）→ 方案审查（plan-reviewer）→ 任务分解（lead）→ 计划写入（lead）→ 前端开发（developer）→ 全量验证 + 自动修复（lead + build-fixer）→ UI/UX 打磨（polisher）→ 多维代码审查（reviewer + blind-reviewer + security-reviewer）→ 报告

### fullstack-team（全栈开发）

详见 `skills/fullstack-team/SKILL.md`。

面向全栈开发场景，合并后端方案预研 + 前端设计系统，共享一个 .plan/features.json，按"先后端 API → 再前端对接"的顺序开发。

**与 backend-team / frontend-team 的核心差异：** .plan/task.md 中通过 `domain` 列区分 backend/frontend 任务，阶段 1 合并后端预研和前端设计，阶段 3 分两轮（先后端开发→验证→再前端开发→验证），阶段 4 合并后端打磨和前端 UI/UX 检查，阶段 5 审查维度覆盖后端+前端+联调。

**团队角色：**

| 角色 | Agent | 职责 |
|------|-------|------|
| lead | self | Research & Reuse、后端方案预研、前端设计系统、任务分解、计划写入、全量验证、编排协调 |
| developer | general-purpose (bypassPermissions) | TDD 循环（先后端任务，再前端任务） |
| polisher | general-purpose (bypassPermissions) | 后端代码打磨 + 前端 UI/UX 打磨 |
| build-fixer | build-error-resolver（项目 agent） | 验证失败时自动修复 build/lint/type 错误 |
| plan-reviewer | code-architect（项目 agent） | 零上下文方案审查，挑战完整性和合理性 |
| reviewer | code-reviewer（项目 agent） | 全栈 CR（后端+前端+联调维度） |
| blind-reviewer | code-reviewer（项目 agent） | 零上下文盲审，仅基于 PR 描述 + diff |
| security-reviewer | security-reviewer（项目 agent） | 全栈安全审查（后端+前端，条件触发） |

**流水线：** Research & Reuse（lead）→ 后端方案预研（lead）→ 前端设计系统（lead）→ 方案审查（plan-reviewer）→ 任务分解（lead）→ 计划写入（lead）→ 后端开发（developer）→ 后端验证（lead）→ 前端开发（developer）→ 前端验证（lead）→ 全量验证 + 自动修复（lead + build-fixer）→ 代码打磨（polisher）→ 多维代码审查（reviewer + blind-reviewer + security-reviewer）→ 报告

## 精简版编排（Single 模式）

### backend-single

`/backend-single` 是 `/backend-team` 的精简版，去掉 Agent Team、方案预研、方案审查、全量验证、多维 CR，只保留 4 个核心 skill 的顺序执行。

**前置条件：** 需先运行 `/plan-init` 完成任务分解并审批。

**流水线：** plan-write → plan-next 循环 → code-simplifier → code-fixer

**跳入点判断：**

| 文件状态 | 跳入阶段 |
|----------|----------|
| 无 `.plan/features.json` | 阶段 1（完整流程） |
| 有 `.plan/features.json`、有未完成任务 | 阶段 2（继续开发） |
| 有 `.plan/features.json`、全部完成、无 `[Polisher-Done]` | 阶段 3（代码优化） |
| 有 `.plan/features.json`、全部完成、有 `[Polisher-Done]` | 直接输出报告 |

### fullstack-single

`/fullstack-single` 是 `/fullstack-team` 的精简版，去掉 Agent Team、方案预研、设计系统、方案审查、全量验证、多维 CR，按 domain 分两轮执行。

**前置条件：** 需先运行 `/plan-init` 完成任务分解并审批。.plan/task.md 中需包含 `domain` 列。

**流水线：** plan-write → 后端 plan-next 循环 → 前端 plan-next 循环 → code-simplifier → code-fixer

**跳入点判断：**

| 文件状态 | 跳入阶段 |
|----------|----------|
| 无 `.plan/features.json` | 阶段 1（完整流程） |
| 有 `.plan/features.json`、有 backend 未完成任务 | 阶段 2（继续后端开发） |
| 有 `.plan/features.json`、backend 全完成、有 frontend 未完成 | 阶段 3（继续前端开发） |
| 有 `.plan/features.json`、全部完成、无 `[Polisher-Done]` | 阶段 4（代码优化） |
| 有 `.plan/features.json`、全部完成、有 `[Polisher-Done]` | 直接输出报告 |

## 支持的代码规范

- Java：阿里巴巴 Java 开发规范
- Go：字节跳动 Go 开发规范
- 前端：React/TypeScript 最佳实践
- 后端：Python/FastAPI 最佳实践

## 工作流产物目录

所有 plan 相关的工作流产物统一存放在项目根目录的 `.plan/` 文件夹下：

| 文件 | 用途 | 创建者 |
|------|------|--------|
| `.plan/task.md` | 技术方案文档 | `/plan-preview` |
| `.plan/features.json` | 任务的单一事实来源 | `/plan-write` |
| `.plan/dev-YYYY-MM-DD.log` | 统一开发日志 | `/plan-write` |
| `.plan/pr-description.md` | PR 描述 | team 编排 |
| `.plan/features.backup.*.json` | 任务备份 | `/plan-init` |

`.plan/` 目录已在 `.gitignore` 中忽略。

## 设计原则

- 防遗忘：通过日志条目恢复上下文
- 防范围蔓延：JSON 定义范围，日志提供细节
- 精准修改：只改需要改的，绝不碰无关代码
- 高级开发者视角：考虑可复用性、可扩展性、健壮性
