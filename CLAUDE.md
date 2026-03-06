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
| `/plan-preview` | 预研技术方案，输出 `task.md` 供 `/plan-init` 使用 |
| `/plan-init` | 需求分析和任务分解，生成计划文件供审批 |
| `/plan-write` | 读取审批后的计划文件，写入 `features.json` 和 `dev-YYYY-MM-DD.log` |
| `/plan-next` | 执行下一个待处理任务，使用 TDD 循环（RED → GREEN → COMMIT） |
| `/plan-log` | 手动记录非任务进度（架构决策、紧急修复等） |
| `/plan-archive` | 将已完成的工作归档到 `archives/YYYY-MM-DD-HHMMSS/` |
| `/dev-team` | 全流程编排：预研 + 初始化 + 开发 + 简化 + 修复 |

### 代码质量

| 命令 | 用途 |
|------|------|
| `/code-review` | 审查代码变更，生成审查报告 |
| `/code-fixer` | 自动修复代码风格问题（保留变量名不变） |
| `/code-simplifier` | 简化和优化代码 |
| `/unit-test` | 生成单元测试 |

### Git 工具

| 命令 | 用途 |
|------|------|
| `/git-quick` | 快捷 pull/commit/push/checkout 一键完成 |
| `/git-worktree` | Git worktree 管理 |

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

详见 `skills/dev-team/SKILL.md`。

多 Agent 团队，自动编排完整开发流水线：

**团队角色：**

| 角色 | Agent | 职责 |
|------|-------|------|
| lead | self | 方案预研、任务分解、计划写入、全量验证、编排协调、用户沟通、决策 |
| developer | general-purpose (bypassPermissions) | TDD 任务执行循环 |
| polisher | general-purpose (bypassPermissions) | 代码简化 + 风格修复 |
| plan-reviewer | code-architect（项目 agent） | 零上下文方案审查，挑战完整性和合理性 |
| reviewer | code-reviewer（项目 agent） | 生产级 CR，拥有完整代码上下文 |
| blind-reviewer | code-reviewer（项目 agent） | 零上下文盲审，仅基于 PR 描述 + diff |

**流水线：** 方案预研（lead）→ 方案审查（plan-reviewer）→ 任务分解（lead）→ 计划写入（lead）→ TDD 开发循环（developer）→ 全量验证（lead）→ 代码打磨（polisher）→ 双重代码审查（reviewer + blind-reviewer）→ 报告

## 支持的代码规范

- Java：阿里巴巴 Java 开发规范
- Go：字节跳动 Go 开发规范
- 前端：React/TypeScript 最佳实践
- 后端：Python/FastAPI 最佳实践

## 设计原则

- 防遗忘：通过日志条目恢复上下文
- 防范围蔓延：JSON 定义范围，日志提供细节
- 精准修改：只改需要改的，绝不碰无关代码
- 高级开发者视角：考虑可复用性、可扩展性、健壮性
