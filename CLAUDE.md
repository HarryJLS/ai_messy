# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 提供项目指导。

## 交互语言

- 思考过程和回复一律使用中文

## 项目概览

这是一个 AI Agent 工作流和开发指南的合集（主要为中文）。包含：

- **Agent 工作流** (`workflow/plan-*.md`) - 基于 TDD 的结构化开发工作流，带任务管理
- **代码审查** (`workflow/code-review.md`) - 基于 diff 的代码审查，附带语言特定检查清单
- **代码修复** (`workflow/code-fixer.md`) - 自动修复代码风格问题（小修自动，大改需确认）
- **团队工作流** (`common/workTeam.md`) - 基于角色的产品开发流水线
- **Skills** (`skills/`) - Agent 工作流使用的 Claude Code 技能
- **测试指南** (`common/`) - Java/Groovy 的 Spock 测试指南和 Go 测试指南

## Agent 工作流

基于 TDD 的结构化开发主工作流。

**工作流文件：**
- `workflow/plan-init.md` - 初始化项目
- `workflow/plan-next.md` - 执行任务（TDD 循环）
- `workflow/plan-log.md` - 手动记录日志
- `workflow/plan-archive.md` - 归档已完成的工作

**核心命令：**

| 命令 | 用途 |
|------|------|
| `/plan-preview` | 预研技术方案，输出 `task.md` 供 `/plan-init` 使用 |
| `/plan-init` | 初始化项目，创建 `features.json` 和 `dev-YYYY-MM-DD.log` |
| `/plan-next` | 执行下一个待处理任务，使用 TDD 循环（RED → GREEN → COMMIT） |
| `/plan-log` | 手动记录非任务进度（架构决策、紧急修复等） |
| `/plan-archive` | 将已完成的工作归档到 `archives/YYYY-MM-DD-HHMMSS/` |
| `/dev-team` | 全流程编排：预研 + 初始化 + 开发 + 简化 + 修复 |

## 开发团队（Agent 团队编排）

详见 `skills/dev-team/SKILL.md`。

多 Agent 团队，自动编排完整开发流水线：

**团队角色：**

| 角色 | Agent | 职责 |
|------|-------|------|
| lead | self | 方案预研、项目初始化、编排协调、用户沟通、决策 |
| developer | general-purpose (bypassPermissions) | TDD 任务执行循环 |
| polisher | general-purpose (bypassPermissions) | 代码简化 + 风格修复 |
| reviewer | feature-dev:code-reviewer | 生产级 CR，拥有完整代码上下文 |
| blind-reviewer | feature-dev:code-reviewer | 零上下文盲审，仅基于 PR 描述 + diff |

**流水线：** 方案预研（lead）→ 项目初始化（lead）→ TDD 开发循环（developer）→ 代码打磨（polisher）→ 双重代码审查（reviewer + blind-reviewer）→ 报告

**关键设计：lead 负责决策阶段。** lead 直接执行 `/plan-preview` 和 `/plan-init`，与用户直接交互无需中转。团队（developer、polisher）仅在进入开发阶段时创建。

**跨项目引用支持：**
- 阶段 0：lead 从用户输入中识别参考项目路径
- 阶段 1：lead 探索参考项目代码，将关键文件路径写入 `task.md` 的 references
- 阶段 3：developer 通过 plan-next 的引用学习流程自动读取参考（定位 → 分析 → 追踪调用 → 适配）

**自动恢复：** 重新运行 `/dev-team` 会检测已有文件（`task.md`、`features.json`），自动跳转到对应阶段。

## 代码审查与修复

| 命令 | 用途 |
|------|------|
| `/code-review` | 审查代码变更，生成审查报告 |
| `/code-fixer` | 自动修复代码风格问题（保留变量名不变） |

**支持的规范：**
- Java：阿里巴巴 Java 开发规范
- Go：字节跳动 Go 开发规范
- 前端：React/TypeScript 最佳实践
- 后端：Python/FastAPI 最佳实践

### 关键文件
- `features.json` - 任务唯一数据源（任务对象数组，包含 `passes: boolean`）
- `dev-YYYY-MM-DD.log` - 统一开发日志（所有条目按时间顺序追加，带结构化标签）

### 任务执行流程（plan-next）
1. **READ** - 找到第一个 `passes: false` 的任务
2. **EXPLORE** - 分析现有代码（新功能可跳过）
3. **PLAN** - 审查步骤、验收标准、确认边界
4. **RED** - 先写失败的测试
5. **IMPLEMENT** - 用最少代码通过测试
6. **GREEN** - 验证所有测试通过，检查验收标准
7. **COMMIT** - 设置 `passes: true`，写入最终日志

### 设计原则
- 防遗忘：通过搜索 dev-YYYY-MM-DD.log 的任务条目恢复上下文
- 防范围蔓延：JSON 定义范围，日志提供细节
- 精准修改：只改需要改的，绝不碰无关代码
- 高级开发者视角：考虑可复用性、可扩展性、健壮性

## 测试指南

### Java/Groovy（Spock 框架）
详见 `common/spock-test-guide.md`。

```groovy
// BDD 结构：given-when-then
def "测试描述"() {
    given: "准备"
    def mock = Mock(Service)

    when: "执行"
    def result = target.method()

    then: "验证"
    result == expected
}
```

关键模式：
- 使用 `Mock(Interface)` 创建 Mock
- 使用 `mock.method(_) >> value` 打桩返回值
- 在 then 块中使用 `1 * mock.method(_)` 验证调用
- 使用 `where:` 块和 `@Unroll` 进行数据驱动测试

### Go（Mockey + Testify）
详见 `common/go_test_spock.md`。

```go
// 表格驱动测试 + 运行时 Mock
func TestMethod(t *testing.T) {
    defer mockey.OffAll()

    tests := []struct{
        name string
        // ... 字段
    }{
        // 测试用例
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            mockey.Mock(SomeFunc).To(...).Build()
            // 测试逻辑
        })
    }
}
```

**Go 测试使用 Mockey 时必须加的 flag：**
```bash
go test -gcflags="all=-l -N" -v ./...
```

## 团队工作流（基于角色）

包含 5 个专业角色的产品开发流水线：

1. `/pm` - 产品经理：收集需求，输出 `prd.md`
2. `/ui` - UI 设计师：设计提示词，输出 `ui-prompts.md`
3. `/nano` - Nano Banana：生成 UI 图片到 `assets/`
4. `/fe` - 前端工程师：构建前端
5. `/full` - 全栈工程师：后端开发和迭代
