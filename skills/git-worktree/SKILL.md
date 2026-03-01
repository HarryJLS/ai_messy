---
name: git-worktree
description: 简单的 git worktree 创建/删除/列出。创建后返回绝对路径。当用户说 "/git-worktree"、"创建 worktree"、"删除 worktree"、"列出 worktree" 时触发。
---

# Git Worktree 管理

轻量级 worktree 操作，不做依赖安装、不跑测试、不检查 CLAUDE.md。

## 操作识别

根据用户输入判断操作类型：

| 关键词 | 操作 |
|--------|------|
| 创建/create/new/添加 + 功能名 | **创建** |
| 删除/remove/rm/清理 + 路径或名称 | **删除** |
| 列出/list/ls/查看 | **列出** |
| 无明确指令 | **询问用户** |

## 创建 Worktree

### 步骤

1. **确定功能名**：从用户输入提取，如 `fix-login`、`add-auth`
2. **检查 `.gitignore`**：
   ```bash
   grep -q '\.worktrees/' .gitignore 2>/dev/null || echo '.worktrees/' >> .gitignore
   ```
3. **创建 worktree**：
   ```bash
   git worktree add .worktrees/<功能名> -b wt/<功能名>
   ```
4. **获取并输出绝对路径**：
   ```bash
   realpath .worktrees/<功能名>
   ```

### 输出格式

```
Worktree 已创建：
  分支: wt/<功能名>
  路径: /absolute/path/to/.worktrees/<功能名>
```

**必须输出绝对路径。**

### 错误处理

- 分支已存在 → 提示用户选择：复用已有分支 or 换名
- 目录已存在 → 提示用户先删除或换名

## 删除 Worktree

### 步骤

1. **删除 worktree**：
   ```bash
   git worktree remove .worktrees/<功能名>
   ```
2. **询问是否删除分支**（默认否）：
   ```bash
   git branch -d wt/<功能名>
   ```

### 输出格式

```
Worktree 已删除：.worktrees/<功能名>
分支 wt/<功能名>：已保留 / 已删除
```

## 列出 Worktree

```bash
git worktree list
```

以表格形式展示结果：

```
| 路径 | 分支 | HEAD |
|------|------|------|
| /abs/path/main | main | abc1234 |
| /abs/path/.worktrees/fix-login | wt/fix-login | def5678 |
```
