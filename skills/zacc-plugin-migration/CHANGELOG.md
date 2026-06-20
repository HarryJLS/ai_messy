# 更新日志

## 更新日志

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
