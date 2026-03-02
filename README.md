# AI Messy Project

Claude Code Plugin — AI Agent 工作流和开发指南技能合集（中文）。

## 安装

```bash
# 1. 添加 marketplace
/plugin marketplace add HarryJLS/ai_messy_project

# 2. 安装插件
/plugin install ai_messy_project
```

安装后即可通过 `/skill-name` 命令调用所有技能。

---

## Skills 总览

### Agent 工作流

基于 TDD 的结构化开发工作流，支持任务管理、统一日志、上下文恢复。

| 命令 | 用途 |
|------|------|
| `/plan-preview` | 方案预研，输出 `task.md` 供 `/plan-init` 使用 |
| `/plan-init` | 初始化项目，创建 `features.json` 和 `dev-YYYY-MM-DD.log` |
| `/plan-next` | 执行下一个任务（TDD: RED → GREEN → COMMIT） |
| `/plan-log` | 手动记录架构决策、紧急修复等 |
| `/plan-archive` | 归档已完成工作 |
| `/dev-team` | 多 Agent 团队全流程编排（预研→初始化→开发→优化→双层 CR） |

**完整流程：**

```
/plan-preview → /plan-init → /plan-next (循环) → /plan-archive
```

**单个任务执行：**

```
READ → EXPLORE → PLAN → RED 🔴 → IMPLEMENT → GREEN 🟢 → COMMIT
```

### Dev Team 团队编排

`/dev-team` 使用 Agent Team 自动编排全流程，无需手动逐个调用。

**团队角色：**

| 角色 | Agent | 职责 |
|------|-------|------|
| lead | 自身 | 方案预研、项目初始化、编排调度、用户沟通、决策 |
| developer | general-purpose | TDD 循环开发所有任务 |
| polisher | general-purpose | 代码简化 + 规范修复 |
| reviewer | feature-dev:code-reviewer | 上线前正式 CR，有完整代码上下文 |
| blind-reviewer | feature-dev:code-reviewer | 零上下文盲审，仅依据 PR 描述 + diff |

**执行流水线：**

```
阶段 0: 初始化与跳入点判断
阶段 1: 方案预研（lead 执行 /plan-preview）
阶段 2: 项目初始化（lead 执行 /plan-init）
阶段 3: 任务开发（developer 循环执行 /plan-next）
阶段 4: 代码优化（polisher 执行 /code-simplifier + /code-fixer）
阶段 5: 双层 Code Review（reviewer + blind-reviewer 并行）
阶段 6: 收尾报告
```

**特性：** 跨项目代码参考、自动恢复（重新运行自动跳到对应阶段）。

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

### 测试

| 命令 | 用途 |
|------|------|
| `/unit-test` | 自动检测语言，生成符合最佳实践的单元测试 |

支持 Go（Mockey + Testify）和 Java（Spock / JUnit 5）。

### Git 工具

| 命令 | 用途 |
|------|------|
| `/git-quick` | 快捷 pull/commit/push/checkout 一键完成 |
| `/git-worktree` | Git worktree 创建/删除/列出 |

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

## 快速开始

### 一键全流程开发

```bash
/dev-team
```

### 手动逐步执行

```bash
/plan-preview        # 方案预研（可选）
/plan-init           # 初始化项目
/plan-next           # 执行任务（循环）
/plan-archive        # 归档
```

### 代码质量

```bash
/code-review         # 审查变更
/code-fixer          # 修复规范问题
/code-simplifier     # 简化优化
```

### 生成测试

```bash
/unit-test           # 自动检测语言并生成
```

---

## 目录结构

```
ai_messy_project/
├── .claude-plugin/        # Plugin 清单
│   └── plugin.json
├── skills/                # 所有 Claude Code Skills
│   ├── plan-preview/
│   ├── plan-init/
│   ├── plan-next/
│   ├── plan-log/
│   ├── plan-archive/
│   ├── dev-team/
│   ├── code-review/
│   ├── code-fixer/
│   ├── code-simplifier/
│   ├── unit-test/
│   ├── git-quick/
│   ├── git-worktree/
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
│   └── workTeam.md
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
