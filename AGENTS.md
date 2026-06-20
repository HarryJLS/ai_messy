# AGENTS.md

AI Messy 技能包为 Codex 提供 AI Agent 工作流和开发指南。

## 可用技能

Codex 加载本插件后，可在对话中使用以下技能：

| 命令 | 用途 |
|------|------|
| `plan-init` | 需求分析和任务分解 |
| `plan-write` | 写入任务计划文件 |
| `plan-next` | TDD 循环执行下一个任务 |
| `backend-single` | 精简版后端开发编排 |
| `frontend-single` | 精简版前端开发编排 |
| `fullstack-single` | 精简版全栈开发编排 |
| `backend-team` | 后端 Agent 团队全流程编排 |
| `frontend-team` | 前端 Agent 团队全流程编排 |
| `fullstack-team` | 全栈 Agent 团队全流程编排 |
| `framework-team` | 新项目脚手架团队编排 |
| `code-review` | 代码审查 |
| `code-fixer` | 自动代码风格修复 |
| `code-simplifier` | 代码简化与优化 |
| `git-quick` | 快捷 Git 操作 |
| `backend-test` | 后端测试验证 |
| `frontend-test` | 前端测试验证 |

## 工作流

推荐使用"跨会话两步走"策略：

1. **会话 A**: `plan-init` → 专注需求讨论、架构梳理与任务拆解
2. **会话 B**: `backend-single` → 提供纯净上下文，高效完成代码编写

## 交互语言

- 思考过程和回复一律使用中文

## Commit 规范

- 版本号格式：`YYYYMMDD-N`（从 `-0` 开始）
- 每次 commit 自动 bump 版本号
