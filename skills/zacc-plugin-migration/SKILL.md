---
name: zacc-plugin-migration
description: "将现有 Skill 项目改造成同时支持 Claude Code 和 Codex 的插件式安装项目，生成 .claude-plugin、.codex-plugin、marketplace、package.json 与 README 配置；安装命令默认不指定远程分支。"
version: "1.2.0"
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
├── scripts/
│   └── bump-plugin-version.sh
├── AGENTS.md
├── CLAUDE.md
├── package.json
├── README.md
└── CHANGELOG.md
```

可选目录：

- `commands/`：Claude Code slash command 模板。
- `agents/`：Claude Code agent 文件。
- `.claude/settings.json`：Hook 等 Claude Code 配置。
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

### 9. 版本号自动 Bump Hook

每次 `git push` 时自动升级 `.claude-plugin/plugin.json` 和 `.codex-plugin/plugin.json` 的版本号，并把版本变更提交进去，使推送出去的内容带上最新版本号。开发过程中正常 `git commit` 不会改动版本号，只有真正推送（发布）时才 bump，避免开发期间版本号频繁抖动。

#### 9.1 版本号格式

**格式：`YYYYMMDD-N`**

- 日期部分：当天日期（如 `20260620`）
- 尾数：当天首次推送为 `-0`，每次推送累计 +1
- 跨天自动重置为 `-0`

示例：
- 当天首次推送：`1.0.0` → `20260620-0`
- 当天第二次推送：`20260620-0` → `20260620-1`
- 次日推送：`20260620-1` → `20260621-0`

**兼容旧格式：** 如果现有版本使用旧格式 `YYYYMMDD.N`（从 `.1` 开始），脚本自动识别并迁移到新格式。

#### 9.2 Bump 脚本

创建 `scripts/bump-plugin-version.sh`：

```bash
#!/bin/bash
# 在 git push 时自动 bump 插件版本号并提交版本变更
# 支持 .claude-plugin/plugin.json 和 .codex-plugin/plugin.json
# 版本格式：YYYYMMDD-N，当天首次推送为 -0，每次累计 +1，跨天重置为 -0
# 兼容从旧格式 YYYYMMDD.N 自动迁移到 YYYYMMDD-N

INPUT=$(cat)
# 仅在 git push 时触发
[[ "$INPUT" == *'"git push'* ]] || exit 0

TODAY=$(date +%Y%m%d)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
CHANGED=()
NEW=""

bump_plugin() {
  local PLUGIN="$1"
  [ -f "$PLUGIN" ] || return 0

  # 提取当前版本号
  CUR=$(grep -oE '"version":[[:space:]]*"[^"]+"' "$PLUGIN" | grep -oE '[0-9]{8}[-.][0-9]+')

  # 版本号为空（非 YYYYMMDD 格式）则跳过
  [ -n "$CUR" ] || return 0

  # 提取日期部分和尾数
  local DATE_PART="${CUR:0:8}"
  local NUM_PART="${CUR:9}"

  # 同天则尾数 +1，跨天重置为 0
  if [ "$DATE_PART" = "$TODAY" ]; then
    NEW="$TODAY-$((NUM_PART + 1))"
  else
    NEW="$TODAY-0"
  fi

  sed -i.bak "s/\"version\": *\"$CUR\"/\"version\": \"$NEW\"/" "$PLUGIN" && rm -f "$PLUGIN.bak"
  CHANGED+=("$PLUGIN")
  echo "[bump] $(basename "$(dirname "$PLUGIN")"): $CUR → $NEW" >&2
}

# bump 两个插件
bump_plugin "$PROJECT_DIR/.claude-plugin/plugin.json"
bump_plugin "$PROJECT_DIR/.codex-plugin/plugin.json"

# 有版本变更则提交，使其随本次 push 一起推送
if [ "${#CHANGED[@]}" -gt 0 ]; then
  git -C "$PROJECT_DIR" add "${CHANGED[@]}"
  git -C "$PROJECT_DIR" commit -m "chore: bump plugin version to $NEW" >&2
fi

exit 0
```

#### 9.3 Hook 配置

在 `.claude/settings.local.json` 的 `hooks` 中配置 `PreToolUse` hook，匹配 `Bash(git push:*)` 时触发：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash(git push:*)",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/scripts/bump-plugin-version.sh"
          }
        ]
      }
    ]
  }
}
```

**说明：**

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `matcher` | `Bash(git push:*)` | 仅在 `git push` 时触发，不拦截普通 commit 和其他 Bash 调用 |
| `type` | `command` | 执行外部脚本 |
| `command` | `$CLAUDE_PROJECT_DIR/scripts/bump-plugin-version.sh` | 脚本路径，使用环境变量保证可迁移 |

**触发条件：**

- 触发：`git push`（任意形式）
- 跳过：`git commit`、`git commit --amend` 等非 push 命令（脚本只匹配 `git push`）
- 跳过：项目中没有 `.claude-plugin/plugin.json` 或 `.codex-plugin/plugin.json`
- 跳过：版本号不是 `YYYYMMDD` 格式

**注意事项：**

- Hook 在 `PreToolUse` 阶段执行，先 bump 版本并提交，再由后续的 `git push` 把这个版本提交一起推送。
- 脚本只会 `git add` 改动的 plugin.json 文件并单独提交，不会带上工作区里其他未提交改动。
- 如果只有一个插件（没有 `.codex-plugin/`），脚本静默跳过不存在的文件。
- 若两个插件版本号当天提交次数不同步，脚本会按各自当前版本独立计算，commit message 使用最后一个 bump 的版本号。
- Hook 配置中 `permissions.allow` 需包含脚本路径以绕过权限提示。

#### 9.4 权限配置

在 `.claude/settings.local.json` 的 `permissions.allow` 中添加：

```json
"Bash(./scripts/bump-plugin-version.sh)"
```

## 输出摘要

完成迁移后，向用户总结：

- 新增或更新了哪些插件配置文件。
- Claude Code 和 Codex 的安装命令。
- 是否发现并修复了非 `master` 分支引用。
- 校验命令是否通过；未运行或失败要说明原因。
