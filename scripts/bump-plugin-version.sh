#!/bin/bash
# 在 git commit 时自动 bump .claude-plugin/plugin.json 版本号
# 规则：YYYYMMDD.N，同天 +1，跨天重置为 .1

INPUT=$(cat)
[[ "$INPUT" == *'"git commit'* && "$INPUT" != *'--amend'* ]] || exit 0

PLUGIN="${CLAUDE_PROJECT_DIR:-$PWD}/.claude-plugin/plugin.json"
[ -f "$PLUGIN" ] || exit 0

CUR=$(grep -oE '"version":[[:space:]]*"[^"]+"' "$PLUGIN" | grep -oE '[0-9.]+')
TODAY=$(date +%Y%m%d)
[ "${CUR%.*}" = "$TODAY" ] && NEW="$TODAY.$((${CUR##*.}+1))" || NEW="$TODAY.1"

sed -i.bak "s/\"version\": *\"$CUR\"/\"version\": \"$NEW\"/" "$PLUGIN" && rm -f "$PLUGIN.bak"
echo "[bump] $CUR -> $NEW" >&2
