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

### Step 2: 备份已有配置

如果 `$TARGET/.claude/settings.local.json` 已存在，备份为 `.bak`。

### Step 3: 写入权限

创建 `$TARGET/.claude/` 目录（如不存在），写入以下配置：

```json
{
  "permissions": {
    "allow": [
      "Edit",
      "Write",
      "Bash(git *)",
      "Bash(go test *)",
      "Bash(go build *)",
      "Bash(go run *)",
      "Bash(go vet *)",
      "Bash(mvn *)",
      "Bash(gradle *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(pytest *)",
      "Bash(python *)",
      "Bash(mkdir *)",
      "Bash(cp *)",
      "Bash(mv *)",
      "Bash(rm features*)",
      "Bash(rm dev-*)",
      "Bash(rm task.md*)",
      "Bash(ls *)",
      "Bash(cat *)",
      "Bash(find *)",
      "Bash(wc *)",
      "Bash(head *)",
      "Bash(tail *)",
      "WebSearch",
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
      "mcp__feishu-mcp__create_feishu_folder"
    ]
  }
}
```

### Step 4: 输出结果

```
权限配置完成！

目标: {target}/.claude/settings.local.json
备份: {有/无}

已配置权限:
• Edit / Write - 文件读写
• Bash - git, go, mvn, gradle, npm, python 等常用命令
• WebSearch - 网页搜索
• 飞书 MCP - 文档创建/编辑/搜索、白板、图片、表格、文件夹管理
```
