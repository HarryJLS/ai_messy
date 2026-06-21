# 更新日志

## 更新日志

### v1.3.0（2026-06-21）

#### 变更

- **版本号 Bump Hook 方案改为原生 git `pre-commit` 钩子**（第 9 节整节重写）：
  - 触发时机从 push 改回 `git commit`，机制从 `.claude/settings.local.json` PreToolUse 钩子 + `scripts/bump-plugin-version.sh` 改为 `.git/hooks/pre-commit`，对终端/Codex/Claude 的任意提交都生效。
  - 版本格式从短横线 `YYYYMMDD-N` 改回点号 `YYYYMMDD.N`（与常见 CLAUDE.md Commit 规范一致），读取仍兼容短横线格式。
  - 钩子同步 bump 两个插件到同一版本（取两者今日最大尾数 +1），修复双插件版本号长期不同步问题；支持从非日期版本（如 `1.0.0`）首次迁移。
- 标准目录移除 `scripts/bump-plugin-version.sh`，可选目录新增 `.git/hooks/pre-commit` 说明。

#### 新增

- **第 9.5 节「快速设置提示词」**：提供一段可直接复制给 Claude Code / Codex 的提示词，在其他项目一键设置版本号自动 bump 钩子。

### v1.2.0（2026-06-20）

#### 变更

- **取消默认 `master` 分支约束**：安装命令、manifest `repository` 字段、marketplace 示例统一不再写分支后缀（`#master`、`--ref master`），改为让工具使用仓库默认分支。
- **版本号 Bump Hook 触发时机从 commit 改为 push**：
  - 脚本匹配条件从 `git commit` 改为 `git push`，开发期间普通提交不再改动版本号，仅在推送（发布）时 bump。
  - 脚本 bump 后会 `git add` + `git commit` 版本变更，使其随本次 push 一起推送。
  - Hook matcher 从 `Bash(git commit:*)` 改为 `Bash(git push:*)`。
- 版本格式说明中"提交"措辞同步更新为"推送"。
- manifest 模板的 `author.email` / `owner.email` 默认值从占位符 `<email>` 改为 `moxiao726@gmail.com`。

### v1.1.0（2026-06-20）

#### 新增

- **版本号自动 Bump Hook 功能**
  - 新增 `scripts/bump-plugin-version.sh` 脚本，支持 `.claude-plugin/plugin.json` 和 `.codex-plugin/plugin.json` 双插件版本号自动升级。
  - 版本格式改为 `YYYYMMDD-N`（当天首次提交为 `-0`，累计递增，跨天重置）。
  - 兼容旧格式 `YYYYMMDD.N` 的自动迁移。
- **完整的 Hook 配置文档**
  - 在 SKILL.md 新增第 9 节"版本号自动 Bump Hook"，包含脚本代码、Hook 配置、触发条件说明和权限配置。
- **标准目录新增 `scripts/` 条目**，用于存放自动化脚本。

#### 变更

- `.claude/settings.local.json` Hook matcher 从 `Bash` 优化为 `Bash(git commit:*)`，减少不必要的 hook 触发。

### v1.0.0（2026-06-20）

#### 新增

- **zacc-plugin-migration 技能首次发布**
  - 总结现有双 runtime 插件配置模式，覆盖 `.claude-plugin`、`.codex-plugin`、`.agents/plugins`、`package.json` 与 README。
  - 明确迁移其他 Skill 项目时的标准目录、manifest 模板、marketplace 模板和校验步骤。
  - 将默认分支约束为 `master`，避免沿用当前仓库历史中的 `dev` 分支安装说明。
