---
name: git-quick
description: 快捷 pull/commit/push/checkout 一键完成。自动生成简洁 commit message。当用户说 "/git-quick"、"快速提交"、"提交推送"、"quick commit"、"拉取分支"、"切换分支" 时触发。
---

# Git Quick

快捷 pull → commit → push 流程。

## 操作识别

根据用户输入判断操作类型：

| 关键词 | 操作 |
|--------|------|
| pull/拉取 | 仅 **Pull** |
| commit/提交 | 仅 **Commit** |
| push/推送 | 仅 **Push** |
| checkout/切换分支/拉取分支 + 分支名 | **Checkout** |
| 无明确指令 / quick / 一键 | **Pull → Commit → Push** 全流程 |

## Pull

```bash
git pull --rebase
```

- 成功 → 继续下一步（或结束）
- 冲突 → **停止**，输出冲突文件列表，提示用户手动解决

## Checkout

拉取并切换到指定分支。

### 步骤

1. **获取最新远程信息**：
   ```bash
   git fetch origin
   ```

2. **判断分支位置**：
   ```bash
   git branch -a | grep <分支名>
   ```

3. **切换分支**：
   - 本地已有 → `git checkout <分支名>`
   - 仅远程有 → `git checkout -b <分支名> origin/<分支名>`
   - 都不存在 → 提示用户确认是否新建：`git checkout -b <分支名>`

4. **拉取最新代码**（非新建分支时）：
   ```bash
   git pull --rebase
   ```

### 输出格式

```
[Checkout] ✓ 已切换到分支 <分支名>（来源: origin/<分支名>）
```

或新建时：

```
[Checkout] ✓ 已新建并切换到分支 <分支名>
```

## Commit

### 1. 检查变更

```bash
git status
git diff
git diff --cached
```

- 无变更 → 提示 "没有需要提交的变更"，跳过 commit
- 有未暂存变更 → 询问用户是否 `git add -A`，或让用户选择文件

### 2. 分析 diff 生成 commit message

查看 staged diff：

```bash
git diff --cached
```

如果没有 staged 内容，查看所有变更：

```bash
git diff
```

同时查看最近 5 条 commit 了解项目风格：

```bash
git log --oneline -5
```

### 3. Commit Message 规则

格式：

```
<type>: <描述>

- 关键改动点 1
- 关键改动点 2
```

**Type 选择：**

| type | 场景 |
|------|------|
| feat | 新功能 |
| fix | 修复 bug |
| refactor | 重构（不改变行为） |
| docs | 文档变更 |
| test | 测试相关 |
| chore | 构建、配置、依赖等杂项 |
| style | 格式调整（不影响逻辑） |

**Subject 规则：**
- subject 行 ≤ 72 字符，仅一行
- 具体但简短：`fix: UserService.login NPE` 而非 `fix: 修复了一个bug`
- 看 diff 主要改动决定 type
- 语言跟随项目已有 commit（中文项目用中文，英文项目用英文）
- Co-Authored-By 行不计入字符限制

**Body 规则：**
- 默认添加 body，subject 与 body 之间空一行
- 用 `- ` bullet list 列出关键改动（1-3 条）
- 每条说明"改了什么"而非"怎么改的"
- 如果变更很小（单文件单处修改），可以省略 body

### 4. 确认并提交

向用户展示生成的 commit message，等待确认：

```
提交信息:
feat: 添加用户登录验证

- UserService 新增 login 方法，支持账号密码校验
- 添加登录失败重试次数限制（最多 5 次）

确认提交？(Y/n)
```

用户确认后执行：

```bash
git add -A  # 如果用户同意暂存所有
git commit -m "$(cat <<'EOF'
feat: 添加用户登录验证

- UserService 新增 login 方法，支持账号密码校验
- 添加登录失败重试次数限制（最多 5 次）

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

**注意：使用 HEREDOC 格式传递多行 commit message。**

## Push

```bash
git push
```

- 无上游分支 → 自动设置：
  ```bash
  git push -u origin <当前分支名>
  ```
- 成功 → 输出推送结果
- 失败 → 输出错误信息，提示用户处理

## 输出格式

每步完成后简要报告：

```
[Pull] ✓ 已拉取最新代码（rebase）
[Commit] ✓ feat: 添加用户登录验证
[Push] ✓ 已推送到 origin/main
```

或遇到问题时：

```
[Pull] ✗ 存在冲突，请手动解决：
  - src/auth/login.ts
  - src/auth/types.ts
```
