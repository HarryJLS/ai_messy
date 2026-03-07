#!/bin/bash
# Instinct - 观察 Hook
#
# 捕获工具调用事件用于模式分析。
# Claude Code 通过 stdin 传入 JSON 格式的 hook 数据。
#
# 支持项目隔离：检测当前项目上下文，将观察数据写入项目特定目录。
#
# 注册方式：在 ~/.claude/settings.json 中配置 hooks。

set -e

# Hook 阶段：来自 CLI 参数，"pre"（PreToolUse）或 "post"（PostToolUse）
HOOK_PHASE="${1:-post}"

# ─────────────────────────────────────────────
# 先读取 stdin（在项目检测之前）
# ─────────────────────────────────────────────

INPUT_JSON=$(cat)

if [ -z "$INPUT_JSON" ]; then
  exit 0
fi

# ─────────────────────────────────────────────
# 从 stdin 提取 cwd 用于项目检测
# ─────────────────────────────────────────────

STDIN_CWD=$(echo "$INPUT_JSON" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    cwd = data.get("cwd", "")
    print(cwd)
except(KeyError, TypeError, ValueError):
    print("")
' 2>/dev/null || echo "")

if [ -n "$STDIN_CWD" ] && [ -d "$STDIN_CWD" ]; then
  export CLAUDE_PROJECT_DIR="$STDIN_CWD"
fi

# ─────────────────────────────────────────────
# 项目检测
# ─────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "${SKILL_ROOT}/scripts/detect-project.sh"

# ─────────────────────────────────────────────
# 配置
# ─────────────────────────────────────────────

CONFIG_DIR="${HOME}/.claude/homunculus"
OBSERVATIONS_FILE="${PROJECT_DIR}/observations.jsonl"
MAX_FILE_SIZE_MB=10

# 禁用检查
if [ -f "$CONFIG_DIR/disabled" ]; then
  exit 0
fi

# 解析 JSON
PARSED=$(echo "$INPUT_JSON" | HOOK_PHASE="$HOOK_PHASE" python3 -c '
import json
import sys
import os

try:
    data = json.load(sys.stdin)

    hook_phase = os.environ.get("HOOK_PHASE", "post")
    event = "tool_start" if hook_phase == "pre" else "tool_complete"

    tool_name = data.get("tool_name", data.get("tool", "unknown"))
    tool_input = data.get("tool_input", data.get("input", {}))
    tool_output = data.get("tool_output", data.get("output", ""))
    session_id = data.get("session_id", "unknown")
    tool_use_id = data.get("tool_use_id", "")
    cwd = data.get("cwd", "")

    if isinstance(tool_input, dict):
        tool_input_str = json.dumps(tool_input)[:5000]
    else:
        tool_input_str = str(tool_input)[:5000]

    if isinstance(tool_output, dict):
        tool_response_str = json.dumps(tool_output)[:5000]
    else:
        tool_response_str = str(tool_output)[:5000]

    print(json.dumps({
        "parsed": True,
        "event": event,
        "tool": tool_name,
        "input": tool_input_str if event == "tool_start" else None,
        "output": tool_response_str if event == "tool_complete" else None,
        "session": session_id,
        "tool_use_id": tool_use_id,
        "cwd": cwd
    }))
except Exception as e:
    print(json.dumps({"parsed": False, "error": str(e)}))
')

# 检查解析是否成功
PARSED_OK=$(echo "$PARSED" | python3 -c "import json,sys; print(json.load(sys.stdin).get('parsed', False))" 2>/dev/null || echo "False")

if [ "$PARSED_OK" != "True" ]; then
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  export TIMESTAMP="$timestamp"
  echo "$INPUT_JSON" | python3 -c "
import json, sys, os
raw = sys.stdin.read()[:2000]
print(json.dumps({'timestamp': os.environ['TIMESTAMP'], 'event': 'parse_error', 'raw': raw}))
" >> "$OBSERVATIONS_FILE"
  exit 0
fi

# 文件过大时归档
if [ -f "$OBSERVATIONS_FILE" ]; then
  file_size_mb=$(du -m "$OBSERVATIONS_FILE" 2>/dev/null | cut -f1)
  if [ "${file_size_mb:-0}" -ge "$MAX_FILE_SIZE_MB" ]; then
    archive_dir="${PROJECT_DIR}/observations.archive"
    mkdir -p "$archive_dir"
    mv "$OBSERVATIONS_FILE" "$archive_dir/observations-$(date +%Y%m%d-%H%M%S)-$$.jsonl" 2>/dev/null || true
  fi
fi

# 构建并写入观察记录
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

export PROJECT_ID_ENV="$PROJECT_ID"
export PROJECT_NAME_ENV="$PROJECT_NAME"
export TIMESTAMP="$timestamp"

echo "$PARSED" | python3 -c "
import json, sys, os

parsed = json.load(sys.stdin)
observation = {
    'timestamp': os.environ['TIMESTAMP'],
    'event': parsed['event'],
    'tool': parsed['tool'],
    'session': parsed['session'],
    'project_id': os.environ.get('PROJECT_ID_ENV', 'global'),
    'project_name': os.environ.get('PROJECT_NAME_ENV', 'global')
}

if parsed['input']:
    observation['input'] = parsed['input']
if parsed['output'] is not None:
    observation['output'] = parsed['output']

print(json.dumps(observation))
" >> "$OBSERVATIONS_FILE"

# 如果 observer 正在运行，发送信号
for pid_file in "${PROJECT_DIR}/.observer.pid" "${CONFIG_DIR}/.observer.pid"; do
  if [ -f "$pid_file" ]; then
    observer_pid=$(cat "$pid_file")
    if kill -0 "$observer_pid" 2>/dev/null; then
      kill -USR1 "$observer_pid" 2>/dev/null || true
    fi
  fi
done

exit 0
