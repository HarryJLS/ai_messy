# AI Messy

Claude Code Plugin — AI Agent 工作流和开发指南技能合集（中文）。

## 安装

```bash
# 1. 添加 marketplace
/plugin marketplace add HarryJLS/ai_messy

# 2. 安装插件
/plugin install ai_messy@ai_messy
```

安装后即可通过 `/skill-name` 命令调用所有技能。

---

## Skills 总览

### 开发流程

基于 TDD 的结构化开发工作流，支持任务管理、统一日志、上下文恢复。

| 命令 | 用途 |
|------|------|
| `/plan-init` | 需求分析和任务分解（三档自适应：模糊需求→深度模式，明确文档→标准模式，已有JSON→极速模式） |
| `/plan-write` | 读取审批后的计划文件，写入 `features.json` 和 `dev-YYYY-MM-DD.log` |
| `/plan-next` | 执行下一个任务（TDD: RED → GREEN → COMMIT） |

**手动执行流程：**

```
/plan-init → /plan-write → /plan-next (循环)
```

**单个任务执行：**

```
READ → EXPLORE → PLAN → RED 🔴 → IMPLEMENT → GREEN 🟢 → COMMIT
```

### Agent 团队编排

三种团队编排模式，自动编排完整开发流水线，无需手动逐个调用。

| 命令 | 用途 | 适用场景 |
|------|------|----------|
| `/backend-team` | 全流程编排：预研 + 初始化 + 开发 + 简化 + 多维 CR | 现有项目开发 |
| `/framework-team` | 脚手架编排：架构设计 + 脚手架 + TDD + 验证 + CR | 从零搭建新项目 |
| `/frontend-team` | 前端编排：设计系统 + UI 方案 + 开发 + UI/UX 打磨 + CR | 前端开发（React/Vue3/Vue2） |

> 详见下方 [团队编排详情](#团队编排详情) 章节。

### 代码质量

| 命令 | 用途 |
|------|------|
| `/code-review` | 审查代码变更，自动检测语言并应用对应规范 |
| `/code-fixer` | 自动修复代码规范问题（小修自动，大改需确认，禁改命名） |
| `/code-simplifier` | 简化优化代码，提升可维护性 |

**支持的规范：**

| 文件模式 | 规范 |
|----------|------|
| `*.java` | 阿里巴巴 Java 开发规范 |
| `*.go` | 字节跳动 Go 开发规范 |
| `*.tsx`, `*.jsx` | React/TypeScript 最佳实践 |
| `*.py` | Python/FastAPI 最佳实践 |

### 测试与验证

| 命令 | 用途 |
|------|------|
| `/unit-test` | 自动检测语言，生成符合最佳实践的单元测试 |
| `/backend-test` | 后端测试验证（单元测试 + API 契约验证 + 验收标准检查），基于 features.json 驱动 |
| `/frontend-test` | 前端测试验证（已有测试 + E2E 验证 + 验收标准检查），基于 features.json 驱动 |

### Git 工具

| 命令 | 用途 |
|------|------|
| `/git-quick` | 快捷 pull/commit/push/checkout 一键完成 |
| `/git-worktree` | Git worktree 创建/删除/列出 |

### 持续学习

| 命令 | 用途 |
|------|------|
| `/learn` | 手动提取当前会话中的可复用模式，质量评估后保存 |
| `/instinct` | 自动观察 + 原子级学习 + 演化（hooks 驱动，项目隔离） |

### Skill 与项目管理

| 命令 | 用途 |
|------|------|
| `/add_or_update_skill` | 同步 skill 到 Claude/Gemini 多平台 |
| `/setup-permissions` | 配置 Claude Code 权限白名单 |
| `/claude-md-manager` | 管理项目 CLAUDE.md，结构化沉淀开发经验 |
| `/skill-creator` | 创建和打包新 skill |
| `/find-skills` | 发现和安装 agent skills |

### 其他工具

| 命令 | 用途 |
|------|------|
| `/frontend-design` | 创建高质量前端界面 |
| `/ui-ux-pro-max` | UI/UX 设计智能（50+ 风格、97+ 配色、57+ 字体搭配） |
| `/markitdown` | 文件格式转 Markdown（PDF、DOCX、PPTX、图片等） |
| `/notebooklm-skill` | 查询 Google NotebookLM |
| `/planning-with-files` | Manus 风格文件化规划，适合复杂研究任务 |

---

## 团队编排详情

### backend-team（现有项目开发）

多 Agent 团队，自动编排完整开发流水线。详见 `skills/backend-team/SKILL.md`。

**团队角色：**

| 角色 | Agent | 职责 |
|------|-------|------|
| lead | self | 方案预研、Research & Reuse、任务分解、计划写入、全量验证、编排协调 |
| developer | general-purpose (bypassPermissions) | TDD 任务执行循环 |
| polisher | general-purpose (bypassPermissions) | 代码简化 + 风格修复 |
| build-fixer | build-error-resolver（项目 agent） | 验证失败时自动修复 build/lint/type 错误 |
| plan-reviewer | code-architect（项目 agent） | 零上下文方案审查，挑战完整性和合理性 |
| reviewer | code-reviewer（项目 agent） | 生产级 CR，拥有完整代码上下文 |
| blind-reviewer | code-reviewer（项目 agent） | 零上下文盲审，仅基于 PR 描述 + diff |
| security-reviewer | security-reviewer（项目 agent） | 安全审查，聚焦漏洞检测（条件触发） |

**流水线：**

```
Research & Reuse（lead）
  → 方案预研（lead）
  → 方案审查（plan-reviewer）
  → 任务分解 + 计划写入（lead）
  → TDD 开发循环（developer）
  → 全量验证 + 自动修复（lead + build-fixer）
  → 代码打磨（polisher）
  → 多维代码审查（reviewer + blind-reviewer + security-reviewer）
  → 报告
```

### framework-team（新项目脚手架）

面向"从零开始"的新项目场景。详见 `skills/framework-team/SKILL.md`。

**与 backend-team 的核心差异：** 阶段 1 用架构设计（技术栈选择 → 目录结构 → 模块划分）替代代码探索，脚手架任务使用 TDD 简化模式。

**流水线：**

```
需求收集（lead）
  → 架构设计（lead）
  → 方案审查（plan-reviewer）
  → 任务分解 + 计划写入（lead）
  → 脚手架 + TDD 开发（developer）
  → 全量验证（lead）
  → 代码打磨（polisher）
  → 双重代码审查（reviewer + blind-reviewer）
  → 报告
```

### frontend-team（前端开发）

面向前端开发场景，支持 React、Vue3、Vue2。详见 `skills/frontend-team/SKILL.md`。

**与 backend-team 的核心差异：** 阶段 1 集成 ui-ux-pro-max + frontend-design 生成设计系统和 UI 方案，阶段 4 polisher 增加 UI/UX Pre-Delivery Checklist。

**团队角色：**

| 角色 | Agent | 职责 |
|------|-------|------|
| lead | self | 需求分析、设计系统生成、UI 方案、任务分解、编排协调 |
| developer | general-purpose (bypassPermissions) | 前端组件/页面实现 |
| polisher | general-purpose (bypassPermissions) | UI/UX 规范检查 + 代码简化 + 风格修复 |
| build-fixer | build-error-resolver（项目 agent） | 验证失败时自动修复 build/lint/type 错误 |
| plan-reviewer | code-architect（项目 agent） | 零上下文方案审查 |
| reviewer | code-reviewer（项目 agent） | 前端 CR |
| blind-reviewer | code-reviewer（项目 agent） | 零上下文盲审 |
| security-reviewer | security-reviewer（项目 agent） | 前端安全审查（XSS、敏感数据暴露、CSP，条件触发） |

**流水线：**

```
设计系统生成（lead）
  → UI 方案预研（lead）
  → 方案审查（plan-reviewer）
  → 任务分解 + 计划写入（lead）
  → 前端开发（developer）
  → 全量验证 + 自动修复（lead + build-fixer）
  → UI/UX 打磨（polisher）
  → 多维代码审查（reviewer + blind-reviewer + security-reviewer）
  → 报告
```

---

## 快速开始

### 一键全流程开发

```bash
/backend-team       # 现有项目开发
/framework-team     # 从零搭建新项目
/frontend-team      # 前端开发
```

### 手动逐步执行

```bash
/plan-init           # 需求分析和任务分解（自适应深度）
/plan-write          # 写入任务列表
/plan-next           # 执行任务（循环）
```

### 代码质量

```bash
/code-review         # 审查变更
/code-fixer          # 修复规范问题
/code-simplifier     # 简化优化
```

### 测试与验证

```bash
/unit-test           # 生成单元测试
/backend-test        # 后端测试验证（基于 features.json）
/frontend-test       # 前端测试验证（基于 features.json）
```

---

## 目录结构

```
ai_messy/
├── .claude-plugin/        # Plugin 清单
│   ├── plugin.json
│   └── marketplace.json
├── agents/                # 项目级 Agent 定义
│   ├── build-error-resolver.md
│   ├── code-architect.md
│   ├── code-reviewer.md
│   └── security-reviewer.md
├── skills/                # 所有 Claude Code Skills (27 个)
│   ├── plan-init/
│   ├── plan-write/
│   ├── plan-next/
│   ├── backend-team/
│   ├── framework-team/
│   ├── frontend-team/
│   ├── code-review/
│   ├── code-fixer/
│   ├── code-simplifier/
│   ├── unit-test/
│   ├── backend-test/
│   ├── frontend-test/
│   ├── git-quick/
│   ├── git-worktree/
│   ├── learn/
│   ├── instinct/
│   ├── add_or_update_skill/
│   ├── setup-permissions/
│   ├── claude-md-manager/
│   ├── skill-creator/
│   ├── find-skills/
│   ├── frontend-design/
│   ├── ui-ux-pro-max/
│   ├── markitdown/
│   ├── notebooklm-skill/
│   └── planning-with-files/
├── common/                # 共享参考文档
│   ├── spock-test-guide.md
│   ├── go_test_spock.md
│   ├── workTeam.md
│   └── zshrc.md
├── CLAUDE.md
├── LICENSE
└── README.md
```

---

## 设计原则

1. **资深开发视角** — 考虑复用性、扩展性、健壮性
2. **精准执行** — 只改该改的，不碰不该碰的
3. **TDD 优先** — 测试驱动开发，先 RED 后 GREEN
4. **上下文恢复** — 日志设计支持新会话快速恢复
5. **Token 高效** — 统一日志文件，结构化标签保证可检索

---

## 许可证

[MIT](LICENSE)
