---
name: setup-permissions
description: 为 Claude Code 配置 settings.local.json 权限白名单，免去每次 Edit/Write/Bash 手动确认。当用户说 "/setup-permissions"、"配置权限"、"设置权限"、"初始化权限"、"免确认" 时触发。支持指定目标目录，默认当前目录。
---

# Setup Permissions

在目标目录的 `.claude/settings.local.json` 中写入权限白名单。

## 流程

### Step 1: 确定目标目录

- 用户指定了目录 → 使用该目录
- 未指定 → 使用当前工作目录

### Step 2: 读取已有配置

- 如果 `$TARGET/.claude/settings.local.json` 已存在，读取其 `permissions.allow` 数组，记为 `existingPerms`
- 如果文件不存在或解析失败，`existingPerms` 为空数组

### Step 3: 合并权限

创建 `$TARGET/.claude/` 目录（如不存在）。

将以下**预设权限**与 `existingPerms` 合并去重后写入：

```json
{
  "permissions": {
    "allow": [
      "Edit",
      "Write",

      "Bash(ls *)",
      "Bash(cat *)",
      "Bash(find *)",
      "Bash(wc *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(mkdir *)",
      "Bash(cp *)",
      "Bash(mv *)",
      "Bash(rm *)",
      "Bash(grep *)",
      "Bash(echo *)",
      "Bash(touch *)",
      "Bash(chmod *)",
      "Bash(xargs *)",
      "Bash(which *)",
      "Bash(sort *)",
      "Bash(uniq *)",
      "Bash(diff *)",
      "Bash(sed *)",
      "Bash(awk *)",
      "Bash(curl *)",
      "Bash(tar *)",
      "Bash(zip *)",
      "Bash(unzip *)",

      "Bash(git *)",

      "Bash(mvn *)",
      "Bash(gradle *)",
      "Bash(go *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(yarn *)",
      "Bash(pnpm *)",
      "Bash(bun *)",
      "Bash(python *)",
      "Bash(python3 *)",
      "Bash(pytest *)",
      "Bash(pip *)",
      "Bash(uv *)",
      "Bash(cargo *)",
      "Bash(make *)",
      "Bash(docker *)",
      "Bash(docker-compose *)",

      "WebSearch",
      "WebFetch",

      "mcp__feishu-mcp__create_feishu_document",
      "mcp__feishu-mcp__get_feishu_document_info",
      "mcp__feishu-mcp__get_feishu_document_blocks",
      "mcp__feishu-mcp__search_feishu_documents",
      "mcp__feishu-mcp__get_feishu_whiteboard_content",
      "mcp__feishu-mcp__update_feishu_block_text",
      "mcp__feishu-mcp__batch_create_feishu_blocks",
      "mcp__feishu-mcp__delete_feishu_document_blocks",
      "mcp__feishu-mcp__get_feishu_image_resource",
      "mcp__feishu-mcp__upload_and_bind_image_to_block",
      "mcp__feishu-mcp__create_feishu_table",
      "mcp__feishu-mcp__fill_whiteboard_with_plantuml",
      "mcp__feishu-mcp__get_feishu_root_folder_info",
      "mcp__feishu-mcp__get_feishu_folder_files",
      "mcp__feishu-mcp__create_feishu_folder",

      "mcp__context7__resolve-library-id",
      "mcp__context7__query-docs"
    ]
  }
}
```

**合并逻辑：**

1. 以上述预设列表为基础
2. 遍历 `existingPerms`，将不在预设列表中的条目追加到末尾
3. 最终数组去重后写入文件（保留已有配置中 `permissions` 以外的其他字段不变）
4. 记录统计：`addedCount`（新增条目数）、`keptCount`（保留的已有条目数）、`totalCount`（总条目数）

### Step 4: 输出结果

```
权限配置完成！

目标: {target}/.claude/settings.local.json

合并统计:
• 新增 {addedCount} 条权限
• 保留 {keptCount} 条已有权限
• 总计 {totalCount} 条

已配置权限:
• Edit / Write — 文件读写
• Bash 通用 — ls, cat, find, grep, sort, diff, sed, awk, curl 等
• Bash Git — git
• Bash 构建 — mvn, gradle, go, npm, yarn, pnpm, bun, python, cargo, make, docker
• WebSearch / WebFetch — 网页搜索与抓取
• 飞书 MCP — 文档创建/编辑/搜索、白板、图片、表格、文件夹管理
• Context7 MCP — 库文档查询
```
