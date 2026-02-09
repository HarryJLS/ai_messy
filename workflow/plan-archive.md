# Plan Archive - 归档工作流

**指令**: `/plan-archive`

**描述**: 归档已完成的功能、日志和相关文档

## ⚠️ 范围边界

此命令只处理归档。完成后：
- **停止**并等待用户下一个命令
- 不要自动运行其他命令

## 归档隔离原则

⚠️ **关键**：归档是只读快照，与活动工作流隔离：
- 活动工作流只使用根目录的 `./features.json` 和 `./dev-YYYY-MM-DD.log`
- `archives/` 目录**永远不会**被 `plan-init`、`plan-next` 或 `plan-log` 扫描
- 恢复只能手动进行

---

## 何时使用

- 多个功能完成，想要重新开始
- 里程碑/冲刺结束
- 开发日志文件过大，需要归档重新开始
- 开始新的开发阶段
- 项目迭代完成

## 归档结构

```
archives/YYYY-MM-DD-HHMMSS/
├── features.json
├── dev-YYYY-MM-DD.log
├── ARCHIVE_INFO.md
└── docs/agents/*.md  (可选)
```

---

## 协议

### 阶段 1: 分析

1. 检查根目录是否存在 `features.json`
2. 检查根目录是否存在 `dev-*.log` 文件
3. 统计 features.json 中的任务数
4. 扫描 `agents/` 目录中的文档文件（可选）
5. 显示简要摘要

⛔ **门控**：如果 features.json 和 dev-*.log 文件都不存在，停止并显示错误消息

### 阶段 2: 创建归档

**默认行为（无需确认）**：

1. 创建 `archives/YYYY-MM-DD-HHMMSS/` 目录
2. 复制 `features.json` 到归档（如果存在）
3. 复制 `dev-*.log` 文件到归档（如果存在）
4. 创建 `ARCHIVE_INFO.md`:
```markdown
# 归档: [ISO 时间戳]

## 摘要
- 归档任务: X 个总计（Y 个完成，Z 个待处理）
- 日志文件: dev-YYYY-MM-DD.log（统一开发日志）
- 创建时间: [带时区的 ISO 时间戳]

## 归档的日志文件
- dev-YYYY-MM-DD.log - 统一开发日志

## 文档
参见 docs/agents/（如适用）
```

⛔ **门控**：在继续阶段 3 之前验证归档创建成功

### 阶段 3: 文档处理

**如果 `agents/` 目录存在且有 .md 文件**：

询问用户一个问题：
```
问题："在 agents/ 目录找到 N 个文档文件。归档它们吗？"
选项：
  - "是，移动到归档" → 移动 agents/*.md 到 archive/docs/agents/，删除原文件
  - "是，复制到归档" → 复制 agents/*.md 到 archive/docs/agents/，保留原文件
  - "否，跳过" → 不归档文档
```

⛔ **等待用户回答**，然后执行选定操作

**如果 `agents/` 目录不存在或为空**：

显示消息：
```
ℹ️ 在 agents/ 目录未找到文档文件。

如果你有相关文档：
1. 在项目根目录创建 agents/ 目录
2. 添加你的 .md 文件
3. 再次运行 /plan-archive 以包含它们
```

然后无需等待继续阶段 4。

### 阶段 4: 清理和删除

⚠️ **关键安全检查**：删除任何原文件之前必须验证文件存在于归档中。

**验证步骤**：
1. 检查 `archives/[timestamp]/features.json` 存在且是有效 JSON（如果原文件存在）
2. 验证 `archives/[timestamp]/dev-*.log` 存在
3. 检查 `archives/[timestamp]/ARCHIVE_INFO.md` 存在

**如果验证通过**：
1. **删除** 根目录的 `./features.json`（如果已归档）
2. **删除** 根目录的 `./dev-*.log` 文件（如果已归档）
3. 如果用户选择"移动"文档：**删除** `./agents/*.md` 文件

**如果验证失败**：
- ❌ 立即停止
- 显示错误："归档验证失败。为安全起见，原文件未删除。"
- 保持所有原文件完整
- 显示验证失败的内容

⛔ **门控**：如果归档验证失败，绝不删除原文件

### 阶段 5: 报告

显示完成摘要：
```
✅ 归档成功完成！

归档到: archives/[YYYY-MM-DD-HHMMSS]/
• features.json - X 个任务已归档（Y 个完成，Z 个待处理）
• dev-YYYY-MM-DD.log - 统一开发日志已归档
• 文档 - [N 个文件已归档 / 跳过 / 未找到]

工作区已清理:
• 从根目录删除了 features.json
• 从根目录删除了 dev-*.log 文件
• [已删除/保留] agents/ 文档

Token 节省:
→ 归档的日志不再在未来会话中消耗上下文
→ 新的 /plan-init 将从干净的日志结构开始
→ 旧项目保存在 archives/ 中供参考

下一步:
• 运行 /plan-init 开始新项目
• 或手动从 archives/ 恢复（如需要）：
  → 复制 archives/[timestamp]/features.json 到根目录
  → 复制 archives/[timestamp]/dev-*.log 到根目录
```

---

## 规则

- **自动**：无需确认 - 立即归档和删除
- **隔离**：命令只从根目录读取，永不从 `archives/` 读取
- **安全**：删除任何原文件前必须验证归档完整性
- **格式**：时间戳 `YYYY-MM-DD-HHMMSS` 用于按时间排序
- **完整性**：每个归档必须有 ARCHIVE_INFO.md
- **文档**：仅在 agents/ 文件存在时提示
- **清理**：成功归档后始终删除原始 features.json 和 dev-*.log 文件
- **日志保留**：归档日志文件完整保留

## 成功标准

全部必须为真：
1. ✅ 归档目录已创建: `archives/YYYY-MM-DD-HHMMSS/`
2. ✅ `features.json` 已复制到归档（如果根目录存在）
3. ✅ `dev-*.log` 文件已复制到归档（如果根目录存在）
4. ✅ `ARCHIVE_INFO.md` 已创建，包含完整元数据
5. ✅ 归档完整性已验证（文件数匹配）
6. ✅ 原始 `features.json` 已从根目录**删除**（如果已归档）
7. ✅ 原始 `dev-*.log` 文件已从根目录**删除**（如果已归档）
8. ✅ 文档按用户选择处理（如果存在）
