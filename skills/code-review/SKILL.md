---
name: code-review
description: Comprehensive code review for diffs. Analyzes changed code for security vulnerabilities, anti-patterns, and quality issues. Auto-detects domain (Java/Go/Frontend/Backend) from file extensions. Supports 阿里巴巴 Java 开发规范 and 字节跳动 Go 开发规范. 也可作为 code-fixer 自动修复代码规范问题。触发：用户说 "/code-review"、"审查代码"、"代码审查" 进入 review 模式；用户说 "/code-fixer"、"修复代码"、"fix code"、"自动修复"、"规范化代码" 进入 fix 模式。
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, Task
---

# Code Review Skill

You are performing a comprehensive code review on a diff. Your task is to analyze the changed code for security vulnerabilities, anti-patterns, and quality issues.

## 运行模式

本 skill 支持两种模式，根据触发方式自动判断：

| 触发 | 模式 | 行为 |
|------|------|------|
| `/code-review`、"审查代码"、"代码审查" | **review** | 只读分析 → 输出 markdown 报告 |
| `/code-fixer`、"修复代码"、"fix code"、"自动修复"、"规范化代码" | **fix** | 检测问题 + 自动修复代码 |

**review 模式**: 执行全部检查，输出报告文件，不修改任何代码。
**fix 模式**: 执行全部检查，按 AUTO/CONFIRM/SKIP 三档执行修复（详见下方 Fix 模式章节）。

## Input Model

This skill expects a **diff** to be provided in context before invocation. The caller is responsible for generating the diff.

**Example invocations:**
- User pastes PR diff, then runs `/code-review`
- Agent runs `git diff HEAD~1`, then invokes this skill
- CI tool provides diff content for review

If no diff is present in context, ask the user to provide one or offer to generate one (e.g., `git diff`, `git diff main..HEAD`).

---

## Domain Detection

Auto-detect which checklists to apply based on file extensions and directory paths in the diff:

| Pattern | Domain | Checklist |
|---------|--------|-----------|
| `*.java` | Java | Read `java.md` |
| `*.go` | Go | Read `go.md` |
| `designer/` | Frontend | Read `frontend.md` |
| `*.tsx`, `*.jsx` | Frontend | Read `frontend.md` |
| `server/` | Backend (Python) | Read `backend.md` |
| `rag/` | Backend (Python) | Read `backend.md` |
| `runtimes/universal/` | Backend (Python) | Read `backend.md` |
| `*.py` | Backend (Python) | Read `backend.md` |
| `cli/` | CLI/Go | Read `go.md` |
| `config/` | Config | Generic checks only |

**Detection priority**:
1. File extension (`.java`, `.go`, `.py`, `.tsx`)
2. Directory path (`server/`, `designer/`)

If the diff spans multiple domains, load all relevant checklists.

---

## Review Process

### Step 1: Parse the Diff

Extract from the diff:
- List of changed files
- Changed lines (additions and modifications)
- Detected domains based on file paths

### Step 2: Initialize the Review Document

Create a review document using the **temp-files pattern**:

```bash
SANITIZED_PATH=$(echo "$PWD" | tr '/' '-')
REPORT_DIR="/tmp/claude/${SANITIZED_PATH}/reviews"
mkdir -p "$REPORT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
FILEPATH="${REPORT_DIR}/code-review-${TIMESTAMP}.md"
```

Initialize with this schema:

```markdown
# Code Review Report

**Date**: {current date}
**Reviewer**: Code Review Agent
**Source**: {e.g., "PR diff", "unstaged changes", "main..HEAD"}
**Files Changed**: {count}
**Domains Detected**: {list}
**Status**: In Progress

## Summary

| Category | Items Checked | Passed | Failed | Findings |
|----------|---------------|--------|--------|----------|
| Security | 0 | 0 | 0 | 0 |
| Code Quality | 0 | 0 | 0 | 0 |
| LLM Code Smells | 0 | 0 | 0 | 0 |
| Impact Analysis | 0 | 0 | 0 | 0 |
| Simplification | 0 | 0 | 0 | 0 |
{domain-specific categories added based on detected domains}

## Detailed Findings

{findings added here as review progresses}
```

### Step 3: Review Changed Code

For EACH checklist item:

1. **Scope feedback to diff lines only** - Only flag issues in the changed code
2. **Use file context** - Read full file content to understand surrounding code
3. **Apply relevant checks** - Use domain-appropriate checklist items
4. **Document findings** - Record each violation found in changed code

**Key principle**: The diff is what gets reviewed. The rest of the file provides context to make that review accurate.

### Step 4: Impact Analysis

Check if the diff might affect other parts of the codebase:

- **Changed exports/interfaces** - Search for usages elsewhere that may break
- **Modified API signatures** - Check for callers that need updating
- **Altered shared utilities** - Look for consumers that may be affected
- **Config/schema changes** - Find code that depends on old structure

Report any unaccounted-for impacts as findings with severity based on risk.

### Step 5: Document Each Finding

For each issue found, add an entry:

```markdown
### [{CATEGORY}] {Item Name}

**Status**: FAIL
**Severity**: Critical | High | Medium | Low
**Scope**: Changed code | Impact analysis

#### Violation

- **File**: `path/to/file.ext`
- **Line(s)**: 42-48 (from diff)
- **Code**:
```
// problematic code snippet from diff
```
- **Issue**: {explanation of what's wrong}
- **Recommendation**: {how to fix it}
```

### Step 6: Finalize the Report

After completing all checks:

1. Update the summary table with final counts
2. Add an executive summary:
   - Total issues found
   - Critical issues requiring immediate attention
   - Impact analysis results
   - Recommended priority order for fixes
3. Update status to "Complete"
4. Inform the user of the report location

---

## Generic Review Categories

These checks apply to ALL changed code regardless of domain.

---

## Category: Security Fundamentals

### Hardcoded Secrets

**Check diff for**:
- API keys, passwords, secrets in changed code
- Patterns: `api_key`, `apiKey`, `password`, `secret`, `token`, `credential` with literal values

**Pass criteria**: No hardcoded secrets in diff (should use environment variables)
**Severity**: Critical

---

### Eval and Dynamic Code Execution

**Check diff for**:
- JavaScript/TypeScript: `eval(`, `new Function(`, `setTimeout("`, `setInterval("`
- Python: `eval(`, `exec(`, `compile(`

**Pass criteria**: No dynamic code execution in changed lines
**Severity**: Critical

---

### Command Injection

**Check diff for**:
- Python: `subprocess` with `shell=True`, `os.system(`
- Go: `exec.Command(` with unsanitized input

**Pass criteria**: No unvalidated user input in shell commands
**Severity**: Critical

---

## Category: Code Quality

### Console/Print Statements

**Check diff for**:
- JavaScript/TypeScript: `console.log`, `console.debug`, `console.info`
- Python: `print(` statements

**Pass criteria**: No debug statements in production code changes
**Severity**: Low

---

### TODO/FIXME Comments

**Check diff for**:
- `TODO:`, `FIXME:`, `HACK:`, `XXX:` comments

**Pass criteria**: New TODOs should be tracked in issues
**Severity**: Low

---

### Empty Catch/Except Blocks

**Check diff for**:
- JavaScript/TypeScript: `catch { }` or `catch(e) { }`
- Python: `except: pass` or empty except blocks

**Pass criteria**: All error handlers log or rethrow
**Severity**: High

---

## Category: LLM Code Smells

### Placeholder Implementations

**Check diff for**:
- `TODO`, `PLACEHOLDER`, `IMPLEMENT`, `NotImplemented`
- Functions that just `return None`, `return []`, `return {}`

**Pass criteria**: No placeholder implementations in production code
**Severity**: High

---

### Overly Generic Abstractions

**Check diff for**:
- New classes/functions with names like `GenericHandler`, `BaseManager`, `AbstractFactory`
- Abstractions without clear reuse justification

**Pass criteria**: Abstractions are justified by actual reuse
**Severity**: Low

---

## Category: Impact Analysis

### Breaking Changes

**Check if diff modifies**:
- Exported functions/classes - search for imports elsewhere
- API endpoints - search for callers
- Shared types/interfaces - search for usages
- Config schemas - search for consumers

**Pass criteria**: All impacted code identified and accounted for
**Severity**: High (if unaccounted impacts found)

---

## Category: Simplification

### Duplicate Logic

**Check diff for**:
- Repeated code patterns (not just syntactic similarity)
- Copy-pasted code with minor variations
- Similar validation, transformation, or formatting logic

**Pass criteria**: No obvious duplication in changed code
**Severity**: Medium
**Suggestion**: Extract shared logic into reusable functions

---

### Unnecessary Complexity

**Check diff for**:
- Deeply nested conditionals (more than 3 levels)
- Functions doing multiple unrelated things
- Overly complex control flow

**Pass criteria**: Code is reasonably flat and focused
**Severity**: Medium
**Suggestion**: Use early returns, extract helper functions

---

### Verbose Patterns

**Check diff for**:
- Patterns that have simpler alternatives in the language
- Redundant null checks or type assertions
- Unnecessary intermediate variables

**Pass criteria**: Code uses idiomatic patterns
**Severity**: Low
**Suggestion**: Simplify using language built-ins

---

## Category: 方法复杂度

### 大方法检测

**检查 diff 中**:
- Go 函数 > 50 行
- Java 方法 > 70 行
- Python 函数 > 50 行
- TypeScript/JavaScript 函数/组件 > 50 行（React 组件 > 300 行）

**通过标准**: 变更的方法/函数行数不超过阈值
**严重级别**: Medium

**review 模式**: 列出超限方法、当前行数、建议拆分点
**fix 模式**: 走 CONFIRM 流程，提供拆分方案等待确认

---

### 原子方法拆分

大方法不仅仅是行数问题，更重要的是单一职责。即使方法未超限，如果承担多个独立职责也应建议拆分。

**检查 diff 中**:
- 方法内包含多个独立逻辑段落（空行/注释分隔的代码块各自完成不同任务）
- 方法承担多个职责（如：参数校验 + 业务逻辑 + 持久化 + 结果转换混在一起）
- 方法内有可被其他方法复用的代码片段

**通过标准**: 每个方法只做一件事（单一职责原则）
**严重级别**: Medium
**建议**: 按职责拆分为私有方法，原方法作为编排入口依次调用。命名采用动词+名词描述该段落的单一职责。

```java
// 拆分前：一个方法做三件事
public OrderResult createOrder(OrderRequest request) {
    // 校验（20行）...
    // 创建订单（30行）...
    // 发送通知（15行）...
}

// 拆分后：编排入口 + 原子方法
public OrderResult createOrder(OrderRequest request) {
    validateOrder(request);
    Order order = buildAndSaveOrder(request);
    notifyOrderCreated(order);
    return toResult(order);
}
```

--- (Control Flow)

### if 嵌套禁止超过 3 层

**检查 diff 中**:
- 嵌套深度超过 3 层的 if/条件语句
- 可以通过提前 return 优化的深嵌套代码

**通过标准**: if 嵌套不超过 3 层
**严重级别**: Medium
**建议**: 使用提前 return 减少嵌套深度

---

### for 嵌套禁止超过 2 层

**检查 diff 中**:
- 嵌套深度超过 2 层的 for/循环语句
- 可以通过抽取方法或使用 Map 优化的循环

**通过标准**: for 循环嵌套不超过 2 层
**严重级别**: Medium
**建议**: 抽取内层循环为独立方法，或使用 Map/字典优化搜索

---

### 条件表达式过长

**检查 diff 中**:
- 包含超过 3 个 `&&` 或 `||` 的条件表达式
- 难以阅读理解的复杂条件判断

**通过标准**: if 条件表达式中的条件数不超过 3 个
**严重级别**: Medium
**建议**: 将复杂条件提取为命名良好的局部布尔变量

---

### 循环内数据查询 (N+1 问题)

**检查 diff 中**:
- 在 for/while/map 循环内执行数据库查询
- 在循环内发起 API 请求

**通过标准**: 禁止在循环内执行数据库查询或 API 调用
**严重级别**: High
**建议**: 批量查询后转为 Map/字典进行 O(1) 查找

---

## Domain-Specific Review Items

Based on detected domains, read and apply the appropriate checklists:

- **Java detected** (`*.java`): Read `java.md` and apply 阿里巴巴 Java 开发规范 checks
- **Go detected** (`*.go`, `cli/`): Read `go.md` and apply 字节跳动 Go 开发规范 checks
- **Frontend detected** (`designer/`, `*.tsx`, `*.jsx`): Read `frontend.md` and apply React/TypeScript checks
- **Backend detected** (`server/`, `rag/`, `runtimes/`, `*.py`): Read `backend.md` and apply Python/FastAPI checks

---

## Final Summary Template

```markdown
## Executive Summary

**Review completed**: {timestamp}
**Total findings**: {count}

### Critical Issues (Must Fix)
1. {issue 1}
2. {issue 2}

### Impact Analysis Results
- {summary of any breaking changes or unaccounted impacts}

### High Priority (Should Fix)
1. {issue 1}
2. {issue 2}

### Recommendations
{Overall recommendations based on the changes reviewed}
```

---

## Notes for the Agent

1. **Scope to diff**: Only flag issues in the changed lines. Don't review unchanged code.

2. **Use context**: Read full files to understand the changes, but feedback targets the diff only.

3. **Check impacts**: When changes touch exports, APIs, or shared code, search for affected consumers.

4. **Be specific**: Include file paths, line numbers (from diff), and code snippets for every finding.

5. **Prioritize**: Flag critical security issues immediately.

6. **Provide solutions**: Each finding should include a recommendation for how to fix it.

7. **Update incrementally**: Update the review document after each category, not at the end.

---

## Fix 模式（/code-fixer 触发）

当以 fix 模式运行时，在完成上述所有检查后，根据检查结果执行修复。

### 核心原则

1. **保持功能不变** — 绝不改变代码行为，只改变"怎么做"
2. **禁止修改命名** — 严禁修改用户定义的变量名、函数名、类名、参数名（最高优先级）

### 修复分类

| 类型 | 动作 | 示例 |
|------|------|------|
| **AUTO** | 直接用 Edit 工具修复 | 格式问题、缺失注解、冗余 else、预分配 |
| **CONFIRM** | 汇总后用 AskUserQuestion 询问 | 方法拆分、架构调整、新增构造函数 |
| **SKIP** | 仅在报告中提示 | 变量命名不规范 |

### 通用自动修复项

| 问题 | 修复 |
|------|------|
| 单行超长 (>120字符) | 在运算符/逗号后换行 |
| 冗余 else | 删除，使用 early return |
| 空 catch/except 块 | 添加日志记录 |

语言专属的 AUTO/CONFIRM/SKIP 规则详见对应领域参考文件（java.md / go.md / frontend.md / backend.md）末尾的修复项章节。

### 确认交互

存在 CONFIRM 项时，汇总展示：

```
检测到需确认的改动：

1. [file.go:45] processData (68行) 建议拆分为原子方法
2. [service.go:12] 建议添加 NewUserService 构造函数

请选择要执行的改动：
□ 1. 拆分 processData
□ 2. 添加构造函数
□ 全部执行
□ 全部跳过
```

### 输出报告

```markdown
## 修复完成

### 自动修复 (已完成)
- [file:line] 描述

### 用户确认 (已执行/已跳过)
- [file:line] 描述 - 状态

### 跳过 (禁止修改)
- [file:line] 原因
```

### 注意事项

1. **变量名绝对不改** — 只在报告中提示
2. **保持功能不变** — 只改形式不改逻辑
3. **增量修改** — 每次修改后验证
4. **建议先 commit** — 便于回滚
