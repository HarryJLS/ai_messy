---
name: zacc-plugin-migration
description: "将现有 Skill 项目改造成同时支持 Claude Code 和 Codex 的插件式安装项目，生成 .claude-plugin、.codex-plugin、marketplace、package.json 与 README 配置；安装命令默认不指定远程分支。"
version: "1.3.0"
tags: ["plugin", "claude-code", "codex", "migration"]
---

# 双 Runtime 插件迁移

## 职责

把已有 Skill 仓库迁移为 Claude Code / Codex 都能插件式安装的项目。适用于用户说“把项目转为插件”“同时支持 Claude Code 和 Codex”“生成插件配置”“配置 marketplace”等场景。

## 硬性规则

- 安装命令默认不指定远程分支，让工具使用仓库默认分支；manifest `repository` 字段只写纯 git URL，不加 `#branch` 后缀。README 安装命令、marketplace add 示例和发布说明同样不写分支。
- 插件名使用仓库名的 kebab-case，必须和 `.codex-plugin/plugin.json` 的 `name`、`.claude-plugin/plugin.json` 的 `name`、marketplace 插件条目 `name` 保持一致。
- Skill 入口统一使用 `skills/<skill-name>/SKILL.md`。保留整个 skill 目录，包含 `references/`、`scripts/`、`templates/`、`agents/` 等支持文件。
- 不要把 Claude Code 专属字段直接放进 Codex manifest，也不要把 Codex `interface` 块放进 Claude Code manifest。
- 修改任何 skill 项目时，按目标项目规范维护 changelog；如果目标项目也要求双层 changelog，则同步维护根目录和 skill 目录 changelog。

## 迁移步骤

### 1. 识别项目事实

先读取这些文件和目录，缺失则按当前仓库事实推断：

- `package.json`：项目名、版本、仓库地址、作者、license。
- `README.md`：现有安装方式和技能列表。
- `skills/`：每个子目录应包含 `SKILL.md`。
- `commands/`：Claude Code 斜杠命令模板，可选。
- `agents/`：Claude Code 子代理定义，可选。
- `AGENTS.md`：Codex 注入上下文，可选但推荐。
- `CLAUDE.md`：Claude Code 注入上下文，可选但推荐。

如果 `skills/` 不存在，先停止并提示用户该项目还不是 skill 集合，需先整理 skill 目录。

### 2. 标准目录

目标项目至少应具备：

```text
<repo>/
├── .agents/
│   └── plugins/
│       └── marketplace.json
├── .codex-plugin/
│   └── plugin.json
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── skills/
│   └── <skill-name>/SKILL.md
├── AGENTS.md
├── CLAUDE.md
├── package.json
├── README.md
└── CHANGELOG.md
```

可选目录：

- `commands/`：Claude Code slash command 模板。
- `agents/`：Claude Code agent 文件。
- `.claude/settings.json`：Claude Code 配置（权限白名单等）。
- `.git/hooks/pre-commit`：版本号自动 bump 钩子（机器本地、不纳入版本库，见第 9 节）。
- `docs/`：项目说明文档。

### 3. Codex 插件配置

创建 `.codex-plugin/plugin.json`。最小模板：

```json
{
  "name": "<plugin-name>",
  "version": "1.0.0",
  "description": "<一句话说明插件能力>",
  "author": {
    "name": "<team-or-author>",
    "email": "moxiao726@gmail.com",
    "url": "<https-url>"
  },
  "homepage": "<https-repo-or-doc-url>",
  "repository": "<https-git-url>",
  "license": "MIT",
  "keywords": ["skills", "codex", "claude-code"],
  "skills": "./skills/",
  "interface": {
    "displayName": "<Human Name>",
    "shortDescription": "<短描述>",
    "longDescription": "<较完整的插件说明>",
    "developerName": "<team-or-author>",
    "category": "Coding",
    "capabilities": ["Interactive", "Read", "Write"],
    "defaultPrompt": [
      "帮我使用这个技能包处理当前项目。",
      "帮我查看可用技能并推荐下一步。"
    ],
    "websiteURL": "<https-repo-or-doc-url>"
  }
}
```

Codex 注意事项：

- `skills` 使用字符串路径 `./skills/`。
- `interface.defaultPrompt` 最多 3 条，每条保持简短。
- `websiteURL` 等 URL 字段必须是 `https://` 绝对地址。
- 只有确实存在 `.mcp.json` 或 `.app.json` 时，才添加 `mcpServers` 或 `apps`。
- 不添加 Codex 校验不支持的字段。

### 4. Codex Marketplace

创建 `.agents/plugins/marketplace.json`：

```json
{
  "name": "<plugin-name>",
  "interface": {
    "displayName": "<Human Name>"
  },
  "plugins": [
    {
      "name": "<plugin-name>",
      "source": {
        "source": "local",
        "path": "./plugins/<plugin-name>"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Coding"
    }
  ]
}
```

README 中的 Codex 安装命令默认写成：

```bash
codex plugin marketplace add <https-git-url>
codex plugin list --available
codex plugin add <plugin-name>@<plugin-name>
```

Codex UI 说明默认写成：在 `/plugins` 中添加 marketplace，地址为 `<https-git-url>`（不带分支后缀）。

### 5. Claude Code 插件配置

创建 `.claude-plugin/plugin.json`。参考模板：

```json
{
  "name": "<plugin-name>",
  "version": "1.0.0",
  "description": "<一句话说明插件能力>",
  "author": {
    "name": "<team-or-author>",
    "email": "moxiao726@gmail.com"
  },
  "homepage": "<https-repo-or-doc-url>",
  "repository": "<https-git-url>",
  "license": "MIT",
  "keywords": ["claude-code", "skills"],
  "skills": [
    "./skills/",
    "./commands/"
  ],
  "agents": [
    "./agents/<agent-name>.md"
  ]
}
```

Claude Code 注意事项：

- 如果项目没有 `commands/`，从 `skills` 数组里移除 `"./commands/"`。
- 如果项目没有 `agents/`，移除 `agents` 字段。
- `skills` 可包含 `./skills/` 和 `./commands/`；不要把 Codex `interface` 块写入这里。

创建 `.claude-plugin/marketplace.json`：

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "<plugin-name>",
  "description": "<一句话说明插件能力>",
  "owner": {
    "name": "<team-or-author>",
    "email": "moxiao726@gmail.com",
    "url": "<https-owner-url>"
  },
  "plugins": [
    {
      "name": "<plugin-name>",
      "source": "./",
      "description": "<插件说明>",
      "version": "1.0.0",
      "category": "productivity",
      "keywords": ["skills", "automation"]
    }
  ]
}
```

README 中的 Claude Code 安装命令默认写成：

```bash
/plugin marketplace add <https-git-url>
/plugin install <plugin-name>@<plugin-name>
```

### 6. package.json 补充

在 `package.json` 中补充插件声明：

```json
{
  "scripts": {
    "install-skills": "node install.mjs"
  },
  "claudeCode": {
    "plugin": true,
    "skillsDir": "./skills",
    "commandsDir": "./commands"
  },
  "codex": {
    "plugin": true,
    "skillsDir": "./skills"
  }
}
```

如果没有 `commands/`，移除 `commandsDir`。

### 7. README 必写内容

README 至少补充：

- 项目一句话说明：明确支持 Claude Code / Codex。
- 插件安装方式：Claude Code 和 Codex 两套命令，均不指定远程分支，使用仓库默认分支。
- 更新方式：Codex 可写 `codex plugin marketplace upgrade`，Claude Code 按现有 marketplace 更新机制说明。
- 验证方式：
  - Claude Code：重启后输入 `/` 查看 skills。
  - Codex：运行 `codex plugin list` 或在 `/plugins` 查看插件。
- 仓库结构：列出 `.claude-plugin/`、`.codex-plugin/`、`.agents/plugins/`、`skills/`。

### 8. 校验

Codex manifest 改完后运行：

```bash
python3 /Users/jianglusong/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py .
```

再做静态检查：

```bash
find skills -maxdepth 2 -name SKILL.md
test -f .codex-plugin/plugin.json
test -f .claude-plugin/plugin.json
test -f .agents/plugins/marketplace.json
```

检查 README 和 manifest 中是否仍有 `#master`、`#dev`、`--ref master`、`--ref dev`、`origin/dev` 等分支后缀残留。安装命令和 `repository` 字段默认不带任何分支后缀，让工具使用仓库默认分支。

### 9. 版本号自动 Bump Hook（git pre-commit）

每次 `git commit` 时，用本地 git 钩子 `.git/hooks/pre-commit` 自动把 `.claude-plugin/plugin.json` 和 `.codex-plugin/plugin.json` 的版本号**同步**升级到同一个新版本，并 `git add` 让版本变更随本次提交一起进入。

> **为什么用原生 git 钩子而不是 `.claude/settings.local.json` 的 PreToolUse 钩子：** 原生钩子对**任意** `git commit` 都生效（含终端直接提交、Codex 提交），不依赖具体客户端是否加载 settings。代价是它位于 `.git/hooks/` 下、不随仓库分发，每个 clone 需各自设置一次——这正是下面 9.5「快速设置提示词」要解决的。

#### 9.1 版本号格式

**格式：`YYYYMMDD.N`**

- 日期部分：当天日期（如 `20260621`）
- 尾数：当天首次提交为 `.1`，每次提交累计 +1
- 跨天自动重置为 `新日期.1`

示例：
- 新的一天首次提交：`1.0.0` → `20260621.1`
- 当天再次提交：`20260621.1` → `20260621.2`
- 次日提交：`20260621.2` → `20260622.1`

**两插件同步：** 取两个插件中"今天"日期的最大尾数 +1，统一写入两个文件，避免二者长期不同步。读取时兼容旧的短横线格式 `YYYYMMDD-N`，写入统一为点号格式。

#### 9.2 pre-commit 钩子脚本

写入 `.git/hooks/pre-commit`：

```bash
#!/usr/bin/env bash
set -euo pipefail

# git commit 时同步 bump 两个插件版本号，二者保持同一版本
# 格式：YYYYMMDD.N（当天首次 .1，每次 +1，跨天重置为 .1）
# 读取兼容旧的短横线格式 YYYYMMDD-N；写入统一为点号格式
# 单插件项目（只有其中一个 plugin.json）同样适用

CLAUDE_JSON=".claude-plugin/plugin.json"
CODEX_JSON=".codex-plugin/plugin.json"

# 提取 version 字段的完整值
raw_ver() {
  grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]+"' "$1" 2>/dev/null \
    | head -1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true
}

today=$(date +%Y%m%d)

# 取两个插件中「今天」日期的最大尾数；都不是今天（或非日期格式）则按 0，使新版本回到 .1
maxnum=0
have=0
for f in "$CLAUDE_JSON" "$CODEX_JSON"; do
  [[ -f "$f" ]] || continue
  v=$(raw_ver "$f")
  [[ -n "$v" ]] || continue
  have=1
  if [[ "$v" =~ ^${today}[.-]([0-9]+)$ ]]; then
    n="${BASH_REMATCH[1]}"
    (( n > maxnum )) && maxnum="$n"
  fi
done

# 没有任何带 version 的 plugin.json，则不处理
[[ "$have" -eq 1 ]] || exit 0

new="${today}.$((maxnum + 1))"

bump() {
  local f="$1" cur
  [[ -f "$f" ]] || return 0
  cur=$(raw_ver "$f")
  [[ -n "$cur" ]] || return 0
  if [[ "$cur" != "$new" ]]; then
    # 只替换 version 行的值，保留原有缩进与键顺序（不整体重写 JSON）
    sed -i.bak -E "s/(\"version\"[[:space:]]*:[[:space:]]*\")[^\"]+(\")/\1${new}\2/" "$f" \
      && rm -f "$f.bak"
  fi
  git add "$f"
}

bump "$CLAUDE_JSON"
bump "$CODEX_JSON"

echo "[pre-commit] 版本号 → $new (claude + codex 同步)"
```

#### 9.3 安装钩子

把 9.2 的脚本写入 `.git/hooks/pre-commit` 后，赋予可执行权限：

```bash
chmod +x .git/hooks/pre-commit
```

`.git/hooks/` 不纳入版本库，因此该钩子是机器本地的，换机器或新 clone 时需重新执行一次安装。

#### 9.4 触发与注意事项

- **触发**：通过任意方式执行 `git commit`（Claude、Codex、终端都生效），无需在 `settings.local.json` 配权限。
- **跳过**：缺少某个 `plugin.json` 时静默跳过该文件；两个都没有日期/版本字段时整体跳过、不报错。
- **`git commit --amend`** 会再次触发钩子导致二次 bump；amend 时请加 `--no-verify`。
- 钩子只修改 `version` 行、保留原有缩进与键顺序（sed 替换，不整体重写 JSON）。
- 首次从非日期版本（如 `1.0.0`）提交时，会直接迁移为 `今天.1`。

#### 9.5 快速设置提示词

在其他项目里，把下面这段直接发给 Claude Code / Codex，即可一键设置：

```text
为当前仓库设置「提交时自动同步插件版本号」的 git 钩子：

1. 创建并覆盖 .git/hooks/pre-commit（机器本地、不纳入版本库），并 chmod +x 使其可执行。
2. 行为：每次 git commit 时，把 .claude-plugin/plugin.json 和 .codex-plugin/plugin.json
   的 version 字段同步 bump 到「同一个」新版本号，并 git add 让它们随本次提交一起进入。
3. 版本号格式 YYYYMMDD.N：取两个插件中「今天」日期的最大尾数 +1；若都不是今天则为「今天.1」
   （跨天重置）。读取时兼容旧的 YYYYMMDD-N 短横线格式，写入统一为点号格式；
   首次从非日期版本（如 1.0.0）提交时直接迁移为「今天.1」。
4. 只用 sed 替换 version 那一行，保留文件原有缩进与键顺序，不要整体重写 JSON。
5. 缺少其中某个 plugin.json 时静默跳过该文件；都没有 version 字段时整体跳过、不报错。
6. 完成后实际模拟一次提交验证：确认两个 plugin.json 的版本号被同步 bump 到一致。

之后用 git commit --amend 时记得加 --no-verify，避免二次 bump。
```

> 若当前项目已安装本插件，也可以只说一句："用 zacc-plugin-migration 第 9 节的方案，为当前项目设置提交时自动同步双插件版本号的 git 钩子。"

## 输出摘要

完成迁移后，向用户总结：

- 新增或更新了哪些插件配置文件。
- Claude Code 和 Codex 的安装命令。
- 是否发现并修复了非 `master` 分支引用。
- 校验命令是否通过；未运行或失败要说明原因。
