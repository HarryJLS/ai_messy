#!/bin/bash
# 在 git commit 时自动 bump 插件版本号
# 支持 .claude-plugin/plugin.json 和 .codex-plugin/plugin.json
# 版本格式：YYYYMMDD-N，当天首次提交为 -0，每次累计 +1，跨天重置为 -0
# 兼容从旧格式 YYYYMMDD.N 自动迁移到 YYYYMMDD-N

INPUT=$(cat)
[[ "$INPUT" == *'"git commit'* && "$INPUT" != *'--amend'* ]] || exit 0

TODAY=$(date +%Y%m%d)

bump_plugin() {
  local PLUGIN="$1"
  [ -f "$PLUGIN" ] || return 0

  # 提取当前版本号
  CUR=$(grep -oE '"version":[[:space:]]*"[^"]+"' "$PLUGIN" | grep -oE '[0-9]{8}[-.][0-9]+')

  # 版本号为空则跳过
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
  echo "[bump] $(basename "$(dirname "$PLUGIN")"): $CUR → $NEW" >&2
}

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

# bump 两个插件
bump_plugin "$PROJECT_DIR/.claude-plugin/plugin.json"
bump_plugin "$PROJECT_DIR/.codex-plugin/plugin.json"

exit 0
