---
name: instinct
description: 基于 hooks 自动观察会话行为，创建原子级 instinct（带置信度），可演化为 skill/command/agent。支持项目隔离。
user-invocable: true
version: 1.0.0
---

# /instinct - 自动观察 + 原子级学习 + 演化

通过 PreToolUse/PostToolUse hooks 100% 捕获工具调用事件，后台分析模式，创建原子级"直觉"（instinct），可聚类演化为 skill/command/agent。

**与 `/learn` 的区别**：`/learn` 是手动触发的会话回顾，`/instinct` 是自动观察 + 后台分析，两者互补。

## 触发方式

运行 `/instinct` 加子命令参数。

## 子命令

| 命令 | 功能 |
|------|------|
| `/instinct status` | 显示所有 instincts（项目级 + 全局），按领域分组 |
| `/instinct export` | 导出 instincts 到文件 |
| `/instinct import <file>` | 从文件/URL 导入 instincts |
| `/instinct evolve` | 聚类 instincts，生成 skill/command/agent |
| `/instinct promote` | 升级项目 instinct 到全局 |
| `/instinct projects` | 列出已知项目及 instinct 统计 |

## Instinct 模型

Instinct 是一个小型已学习行为单元：

```yaml
---
id: prefer-functional-style
trigger: "when writing new functions"
confidence: 0.7
domain: "code-style"
source: "session-observation"
scope: project
project_id: "a1b2c3d4e5f6"
project_name: "my-react-app"
---

# Prefer Functional Style

## Action
在适当时使用函数式模式替代类。

## Evidence
- 在 session abc123 中观察到 5 次
- 用户在 2025-01-15 将类方法纠正为函数式
```

**属性**：
- **原子级** — 一个触发条件，一个动作
- **置信度加权** — 0.3 = 试探性, 0.7 = 强确信, 0.9 = 近乎确定
- **领域标签** — code-style, testing, git, debugging, workflow, file-patterns
- **证据支撑** — 追踪观察来源
- **作用域感知** — `project`（默认）或 `global`

## 工作原理

```
会话活动（在 git 仓库中）
      |
      | Hooks 捕获提示 + 工具调用（100% 可靠）
      | + 检测项目上下文（git remote / 仓库路径）
      v
+---------------------------------------------+
|  projects/<项目哈希>/observations.jsonl       |
|   （提示、工具调用、结果、项目信息）            |
+---------------------------------------------+
      |
      | Observer agent 后台读取（Haiku 模型）
      v
+---------------------------------------------+
|          模式检测                              |
|   * 用户纠正 → instinct                       |
|   * 错误解决 → instinct                       |
|   * 重复工作流 → instinct                     |
|   * 作用域决策：项目级还是全局？                |
+---------------------------------------------+
      |
      | 创建/更新
      v
+---------------------------------------------+
|  projects/<哈希>/instincts/personal/          |
|   * prefer-functional.yaml (0.7) [project]   |
|  instincts/personal/  (GLOBAL)               |
|   * always-validate-input.yaml (0.85) [global]|
+---------------------------------------------+
      |
      | /instinct evolve 聚类 + /instinct promote
      v
+---------------------------------------------+
|  evolved/ (项目级或全局)                       |
|   * commands/new-feature.md                   |
|   * skills/testing-workflow.md                |
|   * agents/refactor-specialist.md             |
+---------------------------------------------+
```

## 快速开始

### 1. 启用观察 Hooks

在 `~/.claude/settings.json` 中添加：

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/instinct/hooks/observe.sh pre"
      }]
    }],
    "PostToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/instinct/hooks/observe.sh post"
      }]
    }]
  }
}
```

> **注意**：也可通过 `/setup-permissions` 扩展来配置。

### 2. 目录结构自动创建

系统在首次使用时自动创建目录，也可手动初始化：

```bash
mkdir -p ~/.claude/homunculus/{instincts/{personal,inherited},evolved/{agents,skills,commands},projects}
```

### 3. 使用子命令

```bash
/instinct status      # 查看所有 instincts
/instinct evolve      # 聚类分析，演化为 skill/command/agent
/instinct export      # 导出到文件
/instinct import      # 从文件/URL 导入
/instinct promote     # 项目级 → 全局
/instinct projects    # 列出所有项目
```

## 子命令详细说明

当用户调用 `/instinct` 时，根据参数执行对应的 CLI 命令：

### status

```bash
python3 ~/.claude/skills/instinct/scripts/instinct-cli.py status
```

显示项目级和全局 instincts，按领域分组，包含置信度条形图。

### export

```bash
python3 ~/.claude/skills/instinct/scripts/instinct-cli.py export [-o output.yaml] [--scope project|global|all] [--domain <domain>] [--min-confidence <float>]
```

### import

```bash
python3 ~/.claude/skills/instinct/scripts/instinct-cli.py import <file-or-url> [--scope project|global] [--dry-run] [--force] [--min-confidence <float>]
```

### evolve

```bash
python3 ~/.claude/skills/instinct/scripts/instinct-cli.py evolve [--generate]
```

分析 instinct 聚类，识别 skill/command/agent 候选。加 `--generate` 自动生成。

### promote

```bash
python3 ~/.claude/skills/instinct/scripts/instinct-cli.py promote [instinct_id] [--force] [--dry-run]
```

- 指定 ID：将特定 instinct 从项目级提升到全局
- 不指定：自动检测符合条件的候选（出现在 2+ 项目，平均置信度 >= 0.8）

### projects

```bash
python3 ~/.claude/skills/instinct/scripts/instinct-cli.py projects
```

## 项目检测

自动检测当前项目上下文：

1. `CLAUDE_PROJECT_DIR` 环境变量（最高优先级）
2. `git remote get-url origin` — 哈希后生成跨机器唯一 ID
3. `git rev-parse --show-toplevel` — 回退方案，机器特定
4. 全局回退 — 未检测到项目时使用全局作用域

## 置信度评分

| 分数 | 含义 | 行为 |
|------|------|------|
| 0.3 | 试探性 | 建议但不强制 |
| 0.5 | 中等 | 相关时应用 |
| 0.7 | 强 | 自动应用 |
| 0.9 | 近乎确定 | 核心行为 |

**增强**：重复观察到、用户未纠正、其他来源一致
**衰减**：用户明确纠正、长期未观察、出现矛盾证据

## 作用域决策

| 模式类型 | 作用域 | 示例 |
|----------|--------|------|
| 语言/框架约定 | 项目 | "使用 React Hooks"、"遵循 Django REST 模式" |
| 文件结构偏好 | 项目 | "测试放 `__tests__/`"、"组件放 src/components/" |
| 代码风格 | 项目 | "使用函数式风格"、"偏好 dataclasses" |
| 安全实践 | 全局 | "验证用户输入"、"SQL 参数化" |
| 通用最佳实践 | 全局 | "先写测试"、"总是处理错误" |
| 工具工作流偏好 | 全局 | "Edit 前先 Grep"、"Write 前先 Read" |

**原则**：拿不准时默认项目级 — 项目级提升到全局比反过来安全。

## Observer Agent

后台 Observer 使用 Haiku 模型分析观察数据，成本效率高。

**启动/停止/状态**：
```bash
~/.claude/skills/instinct/agents/start-observer.sh         # 启动
~/.claude/skills/instinct/agents/start-observer.sh stop     # 停止
~/.claude/skills/instinct/agents/start-observer.sh status   # 检查状态
```

需要 `claude` CLI 可用。默认关闭，需在 `config.json` 中启用。

## 配置

编辑 `~/.claude/skills/instinct/config.json`：

```json
{
  "version": "1.0",
  "observer": {
    "enabled": false,
    "run_interval_minutes": 5,
    "min_observations_to_analyze": 20
  }
}
```

## 文件结构

```
~/.claude/homunculus/
+-- projects.json            # 项目注册表：哈希 → 名称/路径/远程地址
+-- observations.jsonl       # 全局观察数据（回退用）
+-- instincts/
|   +-- personal/            # 全局自动学习的 instincts
|   +-- inherited/           # 全局导入的 instincts
+-- evolved/
|   +-- agents/skills/commands/  # 全局演化产物
+-- projects/
    +-- <project-hash>/      # 按项目隔离
        +-- observations.jsonl
        +-- instincts/personal/
        +-- instincts/inherited/
        +-- evolved/
```

## 隐私

- 观察数据只保存在本地
- 项目级 instincts 按项目隔离
- 只有 instincts（模式）可导出，原始观察数据不可
- 不包含实际代码内容
