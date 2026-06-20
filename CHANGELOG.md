# 更新日志

## 20260620.1（2026-06-20）

### 新增

- **Codex 插件支持**：新增 `.codex-plugin/plugin.json`、`.agents/plugins/marketplace.json`、`AGENTS.md`、`package.json`，实现同时支持 Claude Code 和 Codex 的双 runtime 插件安装。
- **版本号自动 Bump Hook**：`scripts/bump-plugin-version.sh` 重构，版本格式改为 `YYYYMMDD-N`（当天首次提交为 `-0`），同时支持 `.claude-plugin` 和 `.codex-plugin` 双插件自动 bump。
- **zacc-plugin-migration skill v1.1.0**：新增第 9 节「版本号自动 Bump Hook」完整文档。

### 变更

- Hook matcher 从 `Bash` 优化为 `Bash(git commit:*)`，减少不必要的 hook 触发。
- README 增加 Codex 安装命令、Codex badge 和完整目录结构。
- `.claude-plugin/marketplace.json` 补充 `$schema` 和 `keywords`。
