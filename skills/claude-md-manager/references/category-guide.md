# CLAUDE.md 内容分类指南

## 分类标准

根据内容的性质和用途，将知识条目归入以下分类。每条知识应放在最匹配的分类下。

### 1. Repository Overview / 项目概述

**定义：** 项目整体结构、模块划分、核心文件说明。

**适用内容：**
- 目录结构说明
- 核心模块功能描述
- 关键文件路径和用途
- 技术栈说明

**示例：**
```markdown
## Repository Overview

- `src/core/` - 核心业务逻辑
- `src/adapters/` - 外部服务适配器
- `config/` - 配置文件，环境变量通过 .env 加载
```

### 2. Design Principles / 设计原则

**定义：** 项目遵循的架构决策、设计模式、编码哲学。

**适用内容：**
- 架构决策及其原因（ADR）
- 设计模式选择
- 编码哲学和约定
- 性能/安全/可维护性的权衡取舍

**示例：**
```markdown
## Design Principles

- 优先使用组合而非继承
- Repository 层不抛业务异常，统一返回 Optional/null
- 所有外部 API 调用必须设置超时（默认 5s）
```

### 3. Coding Conventions / 编码规范

**定义：** 代码风格、命名约定、格式要求。

**适用内容：**
- 命名规范（变量、函数、文件）
- 代码格式偏好
- import 排序规则
- 注释规范
- 错误处理模式

**示例：**
```markdown
## Coding Conventions

- Go 错误处理使用 `fmt.Errorf("xxx: %w", err)` wrap
- Java DTO 命名: XxxReqDTO / XxxRespDTO
- 禁止在 Controller 层写业务逻辑
```

### 4. Core Commands / 常用命令

**定义：** 开发、构建、测试、部署相关的常用命令。

**适用内容：**
- 构建命令及必要参数
- 测试执行命令（含特殊 flags）
- 部署流程命令
- 常用开发工具命令
- 数据库迁移命令

**示例：**
```markdown
## Core Commands

| Command | Purpose |
|---------|---------|
| `make build` | 构建项目 |
| `go test -gcflags="all=-l -N" -v ./...` | 运行测试（Mockey 需要禁用内联） |
| `npm run lint:fix` | 自动修复 lint 问题 |
```

### 5. Common Pitfalls / 踩坑记录

**定义：** 已知的陷阱、容易犯的错误、排查经验。

**适用内容：**
- 曾经遇到的 bug 及根因
- 容易误解的 API 行为
- 环境配置中的坑
- 第三方库的已知问题
- 并发/竞态条件陷阱

**示例：**
```markdown
## Common Pitfalls

- `time.After` 在 for-select 循环中会内存泄漏，应使用 `time.NewTimer` + `Reset`
- MySQL `DATETIME` 不存储时区信息，存取时确保统一使用 UTC
- Spring `@Transactional` 在 private 方法上无效（代理机制限制）
```

### 6. Testing Guidelines / 测试指南

**定义：** 测试相关的约定、框架用法、最佳实践。

**适用内容：**
- 测试框架和工具选择
- 测试命名和组织约定
- Mock/Stub 使用规范
- 测试数据管理
- CI 中测试执行的特殊配置

**示例：**
```markdown
## Testing Guidelines

- 使用 Spock 框架，BDD 风格 given-when-then
- Mock 外部依赖，不 Mock 被测对象内部方法
- 集成测试使用 Testcontainers 启动数据库
```

### 7. Workflow / 工作流

**定义：** 开发流程、分支策略、CI/CD、发布流程。

**适用内容：**
- Git 分支策略
- PR/MR 规范
- CI/CD 流程说明
- 发布和回滚流程
- 环境管理（dev/staging/prod）

**示例：**
```markdown
## Workflow

- 分支命名: `feature/xxx`, `fix/xxx`, `hotfix/xxx`
- PR 必须至少 1 人 approve
- main 分支合并自动触发部署到 staging
```

### 8. Dependencies & Environment / 依赖与环境

**定义：** 项目依赖、环境配置、版本要求。

**适用内容：**
- 关键依赖的版本约束
- 环境变量说明
- 本地开发环境搭建
- 容器/虚拟化配置

**示例：**
```markdown
## Dependencies & Environment

- Go >= 1.21 (使用了 slog 标准库)
- 本地需安装 protoc 3.x + protoc-gen-go
- Redis 6.x（使用了 Stream 特性）
```

## 格式规范

### 层级结构
- H2 (`##`) 用于主分类
- H3 (`###`) 用于子分类
- Bullet list 用于具体条目
- Table 用于命令/映射等结构化数据

### 写作风格
- 简洁明了，每条记录一句话说清楚
- 包含"为什么"而不仅是"是什么"
- 如果有反例，同时给出正确做法
- 使用代码块展示具体的代码示例

### 新增 Section 的判断
当内容不适合放入以上任何分类时，可创建新的 H2 section。新 section 应：
- 名称清晰，能概括该类内容
- 与现有 section 不重叠
- 至少有 2-3 条内容支撑（避免过于碎片化）
