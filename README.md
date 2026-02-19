# AI Messy Project

Claude Code Skills 和 Workflow 工具集，提供结构化的 TDD 开发工作流、多语言单元测试支持和 UI/UX 设计智能。


## 项目概览

本项目是一个 **Claude Code 增强工具集**，包含：

- **Agent 工作流**：基于 TDD 的结构化开发流程，支持任务管理、统一日志、上下文恢复
- **Dev Team**：多 Agent 团队编排，自动化串联预研→初始化→开发→优化→双层 Code Review 全流程，支持跨项目代码参考
- **代码质量工具**：Code Review、Code Fixer、Code Simplifier
- **单元测试工具**：自动检测项目语言，生成符合最佳实践的单元测试
- **UI/UX 设计智能**：50+ 风格、97+ 配色方案、57+ 字体搭配
- **文件化规划**：Manus 风格的 `planning-with-files` 工作流，支持复杂任务的"磁盘记忆"
- **Superpowers**：完整的软件开发工作流框架，内置 14 个可组合 skills
- **Skill 管理**：创建、打包、同步 Claude Code Skills
- **CLAUDE.md 管理**：结构化沉淀开发经验、踩坑记录、代码规范到项目 CLAUDE.md
- **WorkTeam 工作流**：5 人角色分工的产品开发流水线

## 目录结构

```text
ai_messy_project/
├── skills/                 # Claude Code Skills (可安装的技能)
├── other_skills/           # 第三方扩展技能 (superpowers, planning-with-files)
├── workflow/               # Workflow 文档 (独立使用的工作流)
├── common/                 # 共享参考文档
├── CLAUDE.md               # Claude Code 项目指南
├── .claudeignore           # Claude Code 忽略配置
└── .gitignore              # Git 忽略配置
```

---

## 📁 skills/ - Claude Code Skills

可安装到 Claude Code 的技能模块，通过 `/skill-name` 命令调用。

### Skills 总览

| 分类 | Skill | 命令 | 用途 |
|------|-------|------|------|
| **Agent 工作流** | plan-preview | `/plan-preview` | 方案预研，输出可直接喂给 `/plan-init` 的 `task.md` |
| | plan-init | `/plan-init` | 初始化项目，创建 `features.json` 和 `dev-YYYY-MM-DD.log` |
| | plan-next | `/plan-next` | 执行下一个任务 (TDD: RED → GREEN → COMMIT) |
| | plan-log | `/plan-log` | 手动记录架构决策、紧急修复等 |
| | plan-archive | `/plan-archive` | 归档已完成工作 |
| | dev-team | `/dev-team` | 多 Agent 团队全流程编排（preview→init→next→simplifier→fixer→CR） |
| **代码质量** | code-review | `/code-review` | 审查代码变更，生成审查报告 |
| | code-fixer | `/code-fixer` | 自动修复代码规范问题 |
| | code-simplifier | `/code-simplifier` | 简化优化代码，提升可维护性 |
| **测试** | unit-test | `/unit-test` | 自动检测语言，生成单元测试 |
| **Skill 管理** | add_or_update_skill | `/add_or_update_skill` | 同步 skill 到多个平台 |
| | setup-permissions | `/setup-permissions` | 配置 skill 权限 |
| | claude-md-manager | `/update-claude-md` | 管理项目 CLAUDE.md，结构化沉淀开发经验 |

### 目录结构

```text
skills/
├── plan-preview/            # 方案预研，输出 task.md
│   └── SKILL.md
├── plan-init/              # 初始化 Agent 框架
│   └── SKILL.md
├── plan-next/              # 执行下一个待处理任务 (TDD 循环)
│   └── SKILL.md
├── plan-log/               # 手动记录非任务进度
│   └── SKILL.md
├── plan-archive/           # 归档已完成的工作
│   └── SKILL.md
├── dev-team/              # 多 Agent 团队编排（全流程自动化 + 双层 CR）
│   └── SKILL.md
├── code-review/            # 代码审查
│   ├── SKILL.md
│   ├── java.md             # 阿里巴巴 Java 规范检查清单
│   ├── go.md               # 字节跳动 Go 规范检查清单
│   ├── frontend.md         # React/TypeScript 检查清单
│   └── backend.md          # Python/FastAPI 检查清单
├── code-fixer/             # 代码自动修复
│   ├── SKILL.md
│   └── references/
│       ├── java.md         # Java 修复规则
│       ├── go.md           # Go 修复规则
│       ├── frontend.md     # Frontend 修复规则
│       └── backend.md      # Backend 修复规则
├── code-simplifier/        # 代码简化优化
│   └── SKILL.md
├── unit-test/              # 单元测试生成
│   ├── SKILL.md
│   └── references/
│       ├── go-mockey-testify.md    # Go 测试指南
│       ├── java-spock.md           # Spock 测试指南
│       ├── java-junit.md           # JUnit 5 测试指南
│       └── java-dependencies.md    # Java 依赖配置
├── add_or_update_skill/    # Skill 管理工具
│   └── SKILL.md
├── setup-permissions/      # Skill 权限配置
│   └── SKILL.md
├── claude-md-manager/     # CLAUDE.md 管理工具
│   ├── SKILL.md
│   └── references/
│       └── category-guide.md  # 分类标准参考
└── *.skill                 # 打包后的技能文件 (ZIP 格式)
```

---

## Skill 详细说明

### 1. Agent 工作流 (plan-*)

基于 TDD 的结构化开发工作流，核心特性：

- **抗遗忘**：通过任务日志恢复上下文
- **抗范围蔓延**：JSON 定义范围，日志提供详情
- **统一日志**：所有条目写入 `dev-YYYY-MM-DD.log`，通过结构化标签区分来源
- **TDD 强制**：必须先 RED 再 GREEN

**完整流程：**

```text
/plan-preview → /plan-init → /plan-next (循环) → /plan-archive
```

**执行流程（单个任务）：**

```text
READ → EXPLORE → PLAN → RED 🔴 → IMPLEMENT → GREEN 🟢 → COMMIT
```

| 命令 | 触发词 | 说明 |
|------|--------|------|
| `/plan-preview` | "方案预研"、"技术方案"、"架构评审"、"需求分析" | 以架构师视角进行方案预研，输出 `task.md` |
| `/plan-init` | "初始化项目"、"开始新项目"、"创建任务列表" | 创建 `features.json` 和 `dev-YYYY-MM-DD.log`，交互式定义任务 |
| `/plan-next` | "执行下一个任务"、"继续任务"、"开始开发" | 执行七阶段 TDD 循环 |
| `/plan-log` | "记录进度"、"写日志"、"记录决策" | 手动记录非任务进度 |
| `/plan-archive` | "归档项目"、"清理工作区"、"备份任务" | 归档到 `archives/YYYY-MM-DD-HHMMSS/` |

#### plan-preview 方案预研

`/plan-preview` 是 `/plan-init` 的**前置环节**，以资深架构师视角通过代码探索 + 多轮问答输出技术方案。

**五大场景**：新功能开发、性能/逻辑优化、线上问题修复、项目结构优化、中间件/工具创建

**协议流程**（6 步）：

```text
步骤 0: 进入 Plan Mode
步骤 1: 需求收集与场景识别 → ⛔ 用户确认
步骤 2: 代码探索与现状分析 → ⛔ 用户确认
步骤 3: 协作式方案构建（技术决策 + 任务拆解）→ ⛔ 用户确认
步骤 4: 完善方案文档（风险、数据流、接口设计）
步骤 5: ExitPlanMode 提交审批 → ⛔ 用户审批
步骤 6: 写入 task.md（审批后执行）
```

**核心特性**：
- **渐进式文档输出**：每步完成后写入 Plan Mode plan file（草稿区），用户实时可查
- **门控机制**：步骤 1/2/3/5 都有显式用户确认门控
- **格式兼容**：输出的 task.md 与 `/plan-init` 完全兼容，含 `implementationGuide` 增强字段
- **快速模式**：用户已有部分前置工作时可跳过对应步骤
- **category 超集**：`core|ui|feature|optimization|bugfix|refactor|middleware`（兼容 plan-init）

**核心文件：**

- `features.json` - 任务的单一事实来源
- `dev-YYYY-MM-DD.log` - 统一开发日志

#### dev-team 团队编排

`/dev-team` 使用 Agent Team 自动编排上述 skill 的全流程执行，无需手动逐个调用。

**团队角色：**

| 角色 | Agent | 职责 |
|------|-------|------|
| lead | 自身 | 方案预研、项目初始化、编排调度、用户沟通、决策 |
| developer | general-purpose | TDD 循环开发所有任务 |
| polisher | general-purpose | 代码简化 + 规范修复 |
| reviewer | feature-dev:code-reviewer | 上线前正式 CR，有完整代码上下文 |
| blind-reviewer | feature-dev:code-reviewer | 零上下文盲审，仅依据 PR 描述 + diff |

**执行流水线：**

```text
阶段 0: 初始化与跳入点判断（识别需求、检测跳入点）
阶段 1: 方案预研（lead 执行 /plan-preview，生成 pr-description.md）
阶段 2: 项目初始化（lead 执行 /plan-init）
阶段 3: 任务开发（developer 循环执行 /plan-next）
阶段 4: 代码优化（polisher 执行 /code-simplifier + /code-fixer）
阶段 5: Code Review（reviewer + blind-reviewer 并行审查，lead 汇总去重）
阶段 6: 收尾（清理团队、输出报告）
```

**双层 Code Review：**
- **Production CR（reviewer）**：读取完整代码上下文，按安全/逻辑/性能/质量/测试维度审查
- **Blind CR（blind-reviewer）**：零上下文盲审，仅依据 PR 描述 + git diff，消除确认偏差
- 双方一致的发现标记为**高置信度**，lead 汇总后展示给用户决策

**跨项目代码参考：**
- 阶段 0：lead 识别并记录参考项目路径
- 阶段 1：lead 探索参考项目代码流程，将关键文件路径写入 `task.md` 的 `references` 字段
- 阶段 3：developer 按 references 自动读取参考代码（定位→分析→搜索调用→改写适配）

**自动恢复：** 重新执行 `/dev-team` 时，根据已有文件（`task.md`、`features.json`）自动跳到对应阶段。

---

### 2. Planning with Files (Manus 风格)

模仿 Manus 工作流，将“上下文”持久化到磁盘，适用于需要 5 次以上工具调用或复杂研究的任务。

**核心理念**：`Context Window = RAM` (易失), `Filesystem = Disk` (持久)。

**三大工作文件**：

1. `task_plan.md`：阶段规划、进度跟踪、重大决策。
2. `findings.md`：研究发现、代码片段、探索结论（遵循 **2-Action 规则**：每 2 次查看/搜索操作后必须记录）。
3. `progress.md`：执行记录、测试结果、详细会话日志。

**错误修复协议 (3-Strike Rule)**：

- **Strike 1**: 诊断并尝试精准修复。
- **Strike 2**: 换一种方法（不同工具、不同库），禁止重复失败操作。
- **Strike 3**: 重新思考核心假设或搜索外部方案。
- **失败后**: 向用户寻求指导。

| 命令 | 触发词 | 说明 |
|------|--------|------|
| `/planning-with-files` | "复杂任务规划"、"开始研究"、"Manus 模式" | 初始化三个规划文件并启动任务 |

---

### 3. Code Review

基于 diff 的代码审查，自动检测语言并应用对应规范。

| 触发词 | 说明 |
|--------|------|
| `/code-review` | 审查代码变更 |

**自动检测域：**

| 文件模式 | 域 | 规范 |
|----------|-----|------|
| `*.java` | Java | 阿里巴巴 Java 开发规范 |
| `*.go` | Go | 字节跳动 Go 开发规范 |
| `*.tsx`, `*.jsx`, `designer/` | Frontend | React/TypeScript 最佳实践 |
| `*.py`, `server/`, `rag/` | Backend | Python/FastAPI 最佳实践 |

**审查类别：**

- Security (Critical): 硬编码密钥、命令注入、eval 执行
- Code Quality: console.log、TODO 注释、空 catch 块
- LLM Code Smells: 占位实现、过度泛化抽象
- Impact Analysis: 破坏性变更、API 签名修改
- Simplification: 重复逻辑、不必要复杂度
- 控制流: if 嵌套 >3 层、for 嵌套 >2 层、循环内查询 (N+1)

---

### 4. Code Fixer

自动修复代码以符合编码规范。

| 触发词 | 说明 |
|--------|------|
| `/code-fixer`、"修复代码"、"fix code"、"规范化代码" | 自动修复 |

**修复分类：**

| 类型 | AUTO (自动修复) | CONFIRM (需确认) | SKIP (禁止) |
|------|----------------|-----------------|-------------|
| 格式 | 换行、缩进、空格 | - | - |
| 重构 | 冗余 else、early return | 方法拆分、if 嵌套优化 | - |
| 缺失 | @Override、defer Close | 新增构造函数 | - |
| 命名 | - | - | 变量名、函数名 |

**重要原则：** 绝对禁止修改用户定义的变量名、函数名、类名。

---

### 5. Code Simplifier

简化和优化代码，提升清晰度、一致性和可维护性。

| 触发词 | 说明 |
|--------|------|
| `/code-simplifier`、"简化代码"、"优化代码"、"重构代码"、"清理代码" | 代码简化 |

**支持语言：** Go、Java、Python

**核心原则：**

1. 保持功能不变
2. 提升清晰度（选择清晰而非简短）
3. 避免过度简化
4. 聚焦范围（默认只优化最近修改的代码）

---

### 6. Unit Test

自动检测项目语言，生成符合最佳实践的单元测试。

| 触发词 | 说明 |
|--------|------|
| `/unit-test`、"帮我写单元测试"、"写测试"、"添加单元测试" | 生成单元测试 |

**支持的语言和框架：**

| 语言 | 检测文件 | 测试框架 | 风格 |
|------|---------|---------|------|
| Go | `go.mod` | Mockey + Testify | Table-Driven Tests |
| Java | `pom.xml` / `build.gradle` | Spock 或 JUnit 5 | BDD / Given-When-Then |

**Java Spock 版本选择：**

| 编译版本 | Spock 版本 | Groovy GroupId |
|---------|-----------|----------------|
| Java 8/11 | `2.3-groovy-3.0` | `org.codehaus.groovy` |
| Java 17+ | `2.4-M4-groovy-4.0` | `org.apache.groovy` |

**Go 测试命令：**

```bash
go test -gcflags="all=-l -N" -v ./...
```

---

### 7. Skill Creator

创建和打包高质量的 Claude Code Skill（已迁移至 `other_skills/skill-creator/`）。

| 触发词 | 说明 |
|--------|------|
| `/skill-creator`、"创建 skill"、"新建 skill"、"打包 skill" | Skill 创建 |

---

### 8. Add or Update Skill

管理 Claude 和 Gemini 的 skill 同步。

| 触发词 | 行为 |
|--------|------|
| "添加 skill"、"add skill" | 将指定文件夹添加到两个目录（已存在则跳过）|
| "更新 skill"、"update skill"、"同步 skill" | 同步更新，自动处理单边存在的情况 |

**目标目录：**

- Claude: `~/.claude/skills/`
- Gemini: `~/.gemini/antigravity/skills/`
- 项目本地: `./skills/`

---

### 9. CLAUDE.md Manager

管理和更新项目级 CLAUDE.md，将开发经验结构化沉淀为项目的"外挂大脑"。

| 触发词 | 说明 |
|--------|------|
| `/update-claude-md`、"更新 CLAUDE.md"、"记录到 CLAUDE.md"、"沉淀经验" | 管理 CLAUDE.md |

**核心特性：**

- **智能分类**：自动将内容匹配到合适的 section（Common Pitfalls、Core Commands、Design Principles 等）
- **去重检查**：写入前检查是否已存在相同记录
- **变更预览**：展示预览，用户确认后才执行写入
- **自动提醒**：在 bug 修复、架构重构等关键节点后主动建议沉淀经验

---

## 📁 workflow/ - Workflow 文档

独立的工作流定义文档，可以直接复制到项目中使用。

```text
workflow/
├── plan-init.md            # 初始化工作流
├── plan-next.md            # 任务执行工作流 (TDD 循环)
├── plan-log.md             # 手动日志工作流
├── plan-archive.md         # 归档工作流
├── code-review.md          # 代码审查工作流
├── code-fixer.md           # 代码自动修复工作流
├── unit-test.md            # 单元测试工作流
└── agent.md                # Agent 完整工作流文档 (汇总)
```

### Agent 工作流 (plan-*.md)

结构化的 TDD 开发工作流，核心特性：

- **抗遗忘**：通过任务日志恢复上下文
- **抗范围蔓延**：JSON 定义范围，日志提供详情
- **统一日志**：所有条目写入 `dev-YYYY-MM-DD.log`，通过结构化标签区分来源
- **TDD 强制**：必须先 RED 再 GREEN

**执行流程：**

```text
READ → EXPLORE → PLAN → RED 🔴 → IMPLEMENT → GREEN 🟢 → COMMIT
```

### code-review.md - 代码审查工作流

基于 diff 的代码审查，自动检测语言并应用对应规范：

- **Java**：阿里巴巴 Java 开发规范
- **Go**：字节跳动 Go 开发规范
- **Frontend**：React/TypeScript 最佳实践
- **Backend**：Python/FastAPI 最佳实践

### code-fixer.md - 代码自动修复工作流

自动修复代码规范问题：

- **AUTO**：小问题自动修复（格式、注解、defer Close）
- **CONFIRM**：大改动需确认（方法拆分、新增构造函数）
- **SKIP**：禁止修改用户定义的变量名

### unit-test.md - 单元测试工作流

自动检测项目类型，生成符合最佳实践的单元测试：

- **Go**：Table-Driven Tests + Mockey + Testify
- **Java**：Spock (BDD) 或 JUnit 5 + Mockito + AssertJ

---

## 📁 common/ - 共享参考文档

可复用的测试指南和工作流定义。

```text
common/
├── spock-test-guide.md     # Spock 单元测试完整指南 (中文)
├── go_test_spock.md        # Go 测试指南 (Mockey + Testify)
└── workTeam.md             # WorkTeam 角色分工工作流
```

### spock-test-guide.md

Java/Groovy 项目的 Spock BDD 测试指南：

- 基础结构 (given-when-then)
- Mock 对象操作
- 数据驱动测试 (where 块)
- 异常测试
- Maven 依赖配置

### go_test_spock.md

Go 项目的单元测试指南（字节跳动风格）：

- Table-Driven Tests 结构
- Mockey 运行时 Mock
- Testify 断言
- 必须的编译参数 `-gcflags="all=-l -N"`

### workTeam.md

5 人角色分工的产品开发流水线：

| 角色 | 命令 | 职责 |
|------|------|------|
| PM | `/pm` | 收集需求，输出 `prd.md` |
| UI 设计师 | `/ui` | 设计提示词，输出 `ui-prompts.md` |
| Nano Banana | `/nano` | 生成 UI 图片到 `assets/` |
| 前端工程师 | `/fe` | 构建前端界面 |
| 全栈工程师 | `/full` | 后端开发和迭代 |

---

## 📁 other_skills/ - 第三方扩展技能

包含从外部引入、已迁移或实验性的扩展能力。

### Superpowers (v4.1.1)

完整的软件开发工作流框架，内置 14 个可组合 skills，支持 Claude Code、Codex、OpenCode 多平台。

**核心理念**：TDD 驱动、系统化优于临时方案、复杂度简化、验证优于声称。

**基本工作流**：

```text
brainstorming → using-git-worktrees → writing-plans → subagent-driven-development → finishing-a-development-branch
```

**包含的 Skills**：

| 分类 | Skill | 说明 |
|------|-------|------|
| **测试** | test-driven-development | RED-GREEN-REFACTOR 循环 |
| **调试** | systematic-debugging | 4 阶段根因分析流程 |
| | verification-before-completion | 确保问题真正修复 |
| **协作** | brainstorming | 苏格拉底式设计精炼 |
| | writing-plans | 详细实现计划 |
| | executing-plans | 批量执行 + 检查点 |
| | dispatching-parallel-agents | 并发子 Agent 工作流 |
| | requesting-code-review | 代码审查前检查清单 |
| | receiving-code-review | 响应审查反馈 |
| | using-git-worktrees | 并行开发分支 |
| | finishing-a-development-branch | Merge/PR 决策工作流 |
| | subagent-driven-development | 两阶段审查的快速迭代 |
| **元** | writing-skills | 创建新 skills |
| | using-superpowers | 系统介绍 |

**安装 (Claude Code)**：

```bash
# 注册 marketplace
/plugin marketplace add obra/superpowers-marketplace

# 安装插件
/plugin install superpowers@superpowers-marketplace
```

**命令**：

| 命令 | 说明 |
|------|------|
| `/superpowers:brainstorm` | 交互式设计精炼 |
| `/superpowers:write-plan` | 创建实现计划 |
| `/superpowers:execute-plan` | 批量执行计划 |

---

### Planning with Files (Manus 风格)

位于 `other_skills/planning-with-files-x.x.x/`，提供高级任务规划能力。

---

### Frontend Design

位于 `other_skills/frontend-design/`，创建高质量的前端界面。

### Skill Creator

从 `skills/` 迁移至 `other_skills/skill-creator/`，用于创建和打包 Claude Code Skill。

### UI/UX Pro Max

从 `skills/` 迁移至 `other_skills/ui-ux-pro-max/`，UI/UX 设计智能助手，提供 50+ 风格、97+ 配色方案、57+ 字体搭配。

### Find Skills

位于 `other_skills/find-skills/`，帮助用户发现和安装 agent skills。

### MarkItDown

位于 `other_skills/markitdown/`，文件格式转换工具，将各种文档转换为 Markdown。

### NotebookLM Skill

位于 `other_skills/notebooklm-skill-1.3.0/`，NotebookLM 集成能力。

---

## 快速开始

### 1. 使用 Agent 开发

```bash
# 一键全流程（推荐）
/dev-team

# 或手动逐步执行：

# 0. 方案预研（可选，适合复杂需求）
/plan-preview

# 1. 初始化项目（基于 task.md 或交互式定义）
/plan-init

# 2. 定义任务后，开始执行
/plan-next

# 3. 继续下一个任务
/plan-next

# 4. 里程碑完成，归档
/plan-archive
```

### 2. 生成单元测试

```bash
# 自动检测语言并生成测试
/unit-test

# 或直接说
"帮我给 OrderService 写单元测试"
```

### 3. 代码质量工具

```bash
# 代码审查（需要先提供 diff）
git diff HEAD~1 | /code-review

# 自动修复代码规范
/code-fixer

# 简化优化代码
/code-simplifier
```

### 4. Superpowers 工作流

```bash
# 安装 (首次)
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace

# 开始头脑风暴设计
/superpowers:brainstorm

# 创建实现计划
/superpowers:write-plan

# 执行计划
/superpowers:execute-plan
```

### 5. Skill 管理

```bash
# 创建新 skill
/skill-creator

# 同步 skill 到 Claude/Gemini
/add_or_update_skill
# 然后说 "添加 skill" 或 "更新 skill"
```

### 6. CLAUDE.md 管理

```bash
# 手动更新 CLAUDE.md
/update-claude-md

# 或直接说
"把这个踩坑经验记录到 CLAUDE.md"
"沉淀一下刚才的修复经验"
```

### 7. 运行测试

**Go:**

```bash
go test -gcflags="all=-l -N" -v ./...
```

**Java (Maven):**

```bash
mvn test
```

**Java (Gradle):**

```bash
./gradlew test
```

---

## 设计原则

1. **资深开发视角**：考虑复用性、扩展性、健壮性
2. **精准执行**：只改该改的，不碰不该碰的
3. **TDD 优先**：测试驱动开发，先 RED 后 GREEN
4. **上下文恢复**：日志设计支持新会话快速恢复
5. **Token 高效**：统一日志文件，结构化标签保证可检索

---

## 文件说明

| 文件 | 用途 |
|------|------|
| `CLAUDE.md` | Claude Code 读取的项目指南，定义命令和规范 |
| `task_plan.md` | (在使用 /planning-with-files 时) 任务总案 |
| `findings.md` | (在使用 /planning-with-files 时) 研究发现记录 |
| `progress.md` | (在使用 /planning-with-files 时) 会话进度日志 |
| `.claudeignore` | Claude Code 忽略的文件（.git, .DS_Store, *.skill） |
| `.gitignore` | Git 忽略的文件（构建产物、依赖、敏感信息） |

---

## 许可证

MIT License
