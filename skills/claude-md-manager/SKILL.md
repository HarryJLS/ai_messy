---
name: claude-md-manager
description: 管理和更新项目级 CLAUDE.md 文件，将开发经验、踩坑记录、代码规范等知识结构化沉淀。当用户说 "/update-claude-md"、"更新 CLAUDE.md"、"记录到 CLAUDE.md"、"沉淀经验" 时触发。也在完成 bug 修复、功能开发、代码重构等关键节点后自动建议使用。
---

# CLAUDE.md Manager

将开发中积累的经验、踩坑记录、代码规范等知识结构化沉淀到项目级 CLAUDE.md，形成项目的"外挂大脑"。

## 核心原则

- **仅管理项目级 CLAUDE.md**（项目根目录下的 CLAUDE.md）
- **追加优先**：在现有结构上追加，不重写已有内容
- **变更可控**：写入前必须展示预览，用户确认后才执行
- **保持风格一致**：沿用项目现有的格式和语气

---

## 工作流

### Phase 1: 分析现有 CLAUDE.md

1. 读取项目根目录的 `CLAUDE.md`
2. 解析现有结构：
   - 识别所有 H2/H3 section 及其层级关系
   - 记录每个 section 的用途和内容密度
   - 识别使用的格式风格（bullet list / table / code block）
3. 如果 CLAUDE.md **不存在**，询问用户是否创建，提供基础模板：

```markdown
# CLAUDE.md

## Repository Overview

[项目简介]

## Core Commands

| Command | Purpose |
|---------|---------|

## Design Principles

## Common Pitfalls
```

### Phase 2: 收集待写入内容

根据触发方式收集内容：

**手动模式**（用户主动调用）：
- 从用户消息中提取要记录的知识点
- 如果用户描述模糊，追问具体内容和上下文

**自动提醒模式**（关键节点后建议）：
- 回顾当前会话上下文，识别值得沉淀的内容：
  - 修复过的 bug 及其根因分析
  - 新发现的项目约定或代码模式
  - 踩坑经验和对应的解决方案
  - 有用的命令、配置、环境信息
  - 代码风格偏好或团队约定
- 整理为候选条目列表，让用户选择要记录哪些

### Phase 3: 去重检查

对每条待写入内容，在现有 CLAUDE.md 中检查：

1. **关键词搜索**：提取条目的核心关键词（技术术语、类名、命令等），在 CLAUDE.md 中搜索
2. **判断结果**：
   - **完全重复** → 跳过，告知用户"已存在相同记录于 [section 名]"
   - **部分重复**（同一主题但信息不同）→ 建议合并，展示新旧内容对比
   - **无重复** → 继续下一步

### Phase 4: 分类与写入

1. **智能分类**：读取 `references/category-guide.md` 的分类标准，将每条内容匹配到最合适的 section

   常见映射关系：
   | 内容类型 | 目标 Section |
   |---------|-------------|
   | 目录结构、关键文件 | Repository Overview |
   | 架构决策、设计模式 | Design Principles |
   | 命名规范、代码风格 | Coding Conventions |
   | 构建/测试/部署命令 | Core Commands |
   | Bug 根因、已知陷阱 | Common Pitfalls |
   | 测试框架、Mock 用法 | Testing Guidelines |
   | 分支策略、CI/CD | Workflow |
   | 依赖版本、环境配置 | Dependencies & Environment |

2. **匹配现有 section**：优先放入已存在的 section。如果现有 section 名称不同但语义匹配，沿用现有名称
3. **创建新 section**：仅当确实没有匹配的 section 时，在合适的位置插入新 H2 section
4. **展示变更预览**：

   ```
   📝 CLAUDE.md 变更预览：

   在 "## Common Pitfalls" 末尾追加：
   + - `time.After` 在 for-select 循环中会内存泄漏，应使用 `time.NewTimer` + `Reset`

   在 "## Core Commands" 表格中追加：
   + | `go test -gcflags="all=-l -N" -v ./...` | 运行测试（Mockey 需要） |

   确认写入？(y/n)
   ```

5. 用户确认后，使用 Edit 工具执行写入

### Phase 5: 验证

1. 读取修改后的 CLAUDE.md，确认：
   - Markdown 格式正确（无断裂的表格、未闭合的代码块）
   - 新内容位于正确的 section
   - 整体结构保持一致
2. 输出变更摘要：
   ```
   ✅ CLAUDE.md 已更新：
   - [Common Pitfalls] 新增 1 条记录
   - [Core Commands] 新增 1 条命令
   ```

---

## 自动提醒时机

在以下场景完成后，**主动建议**用户使用此 skill：

| 场景 | 可能沉淀的内容 |
|------|---------------|
| 修复了一个 bug | 根因分析 → Common Pitfalls |
| 发现了新的项目约定 | 约定内容 → Coding Conventions / Design Principles |
| 配置了新的开发环境 | 环境要求 → Dependencies & Environment |
| 执行了特殊的构建/测试命令 | 命令 → Core Commands |
| 完成了架构重构 | 决策原因 → Design Principles |

提醒方式（简短、非侵入）：
```
💡 这次修复的经验可能值得记录到 CLAUDE.md。需要我帮你沉淀吗？
```

---

## 注意事项

- **不删除现有内容**：只追加或更新，不擅自删除
- **保持简洁**：每条记录力求一句话说清楚，必要时附代码示例
- **包含 "为什么"**：不仅记录"是什么"，还记录"为什么这样做"
- **尊重现有风格**：如果项目 CLAUDE.md 用中文，新内容也用中文；用英文则用英文
