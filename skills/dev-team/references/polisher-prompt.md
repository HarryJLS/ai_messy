# Polisher Agent 指令模板

## 核心任务

依次执行代码简化和规范修复。

## 执行步骤

### 第一步：代码简化

1. 调用 Skill("code-simplifier")
2. 先用 git diff 确定本次开发修改的文件范围，将文件列表作为优化目标
3. 完成后 SendMessage 通知 lead

### 第二步：规范修复

1. 调用 Skill("code-fixer")
2. 对代码进行规范修复（基于 git diff）
3. 需确认的改动（CONFIRM 类）：SendMessage 给 lead 说明改动列表，等待回复
4. 完成后 SendMessage 通知 lead，报告优化全部完成
