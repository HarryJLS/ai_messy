#!/bin/bash
# Instinct - 项目检测辅助脚本
#
# 检测当前项目上下文，供 observe.sh 和 start-observer.sh 使用。
#
# 导出变量：
#   PROJECT_ID     - 项目短哈希（或 "global"）
#   PROJECT_NAME   - 项目名称
#   PROJECT_ROOT   - 项目根目录绝对路径
#   PROJECT_DIR    - 项目数据存储目录
#
# 检测优先级：
#   1. CLAUDE_PROJECT_DIR 环境变量
#   2. git remote URL（跨机器唯一哈希）
#   3. git 仓库根路径（机器特定）
#   4. "global"（无项目上下文）

_INST_HOMUNCULUS_DIR="${HOME}/.claude/homunculus"
_INST_PROJECTS_DIR="${_INST_HOMUNCULUS_DIR}/projects"
_INST_REGISTRY_FILE="${_INST_HOMUNCULUS_DIR}/projects.json"

_inst_detect_project() {
  local project_root=""
  local project_name=""
  local project_id=""
  local source_hint=""

  # 1. CLAUDE_PROJECT_DIR 环境变量
  if [ -n "$CLAUDE_PROJECT_DIR" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
    project_root="$CLAUDE_PROJECT_DIR"
    source_hint="env"
  fi

  # 2. git 仓库根目录
  if [ -z "$project_root" ] && command -v git &>/dev/null; then
    project_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
    if [ -n "$project_root" ]; then
      source_hint="git"
    fi
  fi

  # 3. 无项目 — 全局回退
  if [ -z "$project_root" ]; then
    PROJECT_ID="global"
    PROJECT_NAME="global"
    PROJECT_ROOT=""
    PROJECT_DIR="${_INST_HOMUNCULUS_DIR}"
    return 0
  fi

  project_name=$(basename "$project_root")

  # 通过 git remote URL 或路径生成项目 ID
  local remote_url=""
  if command -v git &>/dev/null; then
    if [ "$source_hint" = "git" ] || [ -d "${project_root}/.git" ]; then
      remote_url=$(git -C "$project_root" remote get-url origin 2>/dev/null || true)
    fi
  fi

  local hash_input="${remote_url:-$project_root}"
  project_id=$(printf '%s' "$hash_input" | python3 -c "import sys,hashlib; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest()[:12])" 2>/dev/null)

  # python3 失败时回退
  if [ -z "$project_id" ]; then
    project_id=$(printf '%s' "$hash_input" | shasum -a 256 2>/dev/null | cut -c1-12 || \
                 printf '%s' "$hash_input" | sha256sum 2>/dev/null | cut -c1-12 || \
                 echo "fallback")
  fi

  PROJECT_ID="$project_id"
  PROJECT_NAME="$project_name"
  PROJECT_ROOT="$project_root"
  PROJECT_DIR="${_INST_PROJECTS_DIR}/${project_id}"

  # 确保项目目录结构存在
  mkdir -p "${PROJECT_DIR}/instincts/personal"
  mkdir -p "${PROJECT_DIR}/instincts/inherited"
  mkdir -p "${PROJECT_DIR}/observations.archive"
  mkdir -p "${PROJECT_DIR}/evolved/skills"
  mkdir -p "${PROJECT_DIR}/evolved/commands"
  mkdir -p "${PROJECT_DIR}/evolved/agents"

  # 更新项目注册表
  _inst_update_registry "$project_id" "$project_name" "$project_root" "$remote_url"
}

_inst_update_registry() {
  local pid="$1"
  local pname="$2"
  local proot="$3"
  local premote="$4"

  mkdir -p "$(dirname "$_INST_REGISTRY_FILE")"

  _INST_REG_PID="$pid" \
  _INST_REG_PNAME="$pname" \
  _INST_REG_PROOT="$proot" \
  _INST_REG_PREMOTE="$premote" \
  _INST_REG_FILE="$_INST_REGISTRY_FILE" \
  python3 -c '
import json, os
from datetime import datetime, timezone

registry_path = os.environ["_INST_REG_FILE"]
try:
    with open(registry_path) as f:
        registry = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    registry = {}

registry[os.environ["_INST_REG_PID"]] = {
    "name": os.environ["_INST_REG_PNAME"],
    "root": os.environ["_INST_REG_PROOT"],
    "remote": os.environ["_INST_REG_PREMOTE"],
    "last_seen": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
}

with open(registry_path, "w") as f:
    json.dump(registry, f, indent=2)
' 2>/dev/null || true
}

# 加载时自动检测
_inst_detect_project
