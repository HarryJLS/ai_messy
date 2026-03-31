---
name: plan-next
description: 自动循环执行所有待处理任务（passes: false），失败跳过并继续，最终输出汇总报告。当用户说 "/plan-next"、"执行下一个任务"、"继续任务"、"开始开发" 时触发。必须先运行 /plan-init 创建 .plan/features.json。执行 READ → EXPLORE → PLAN → RED → IMPLEMENT → GREEN → REFACTOR → COMMIT 八阶段循环。
---

# Plan Next

自动循环执行所有待处理任务，失败跳过并继续，最终输出汇总报告。

## 循环控制

### 过滤参数

plan-next 支持通过调用方传入过滤条件，只执行符合条件的任务：

| 参数 | 说明 | 示例 |
|------|------|------|
| `domain` | 只执行指定 domain 的任务 | `domain=backend` |
| `app` | 只执行指定 app 的任务 | `app=order-service` |

**过滤规则**：
- 调用方指定了 domain：跳过 domain 不匹配的任务
- 调用方指定了 app：跳过 app 不匹配的任务
- 未指定过滤条件：执行所有 `passes: false` 的任务（默认行为）
- 任务本身没有 domain/app 字段时，视为匹配任何过滤条件（兼容单应用项目）
- 过滤条件在整个循环周期内持续生效，每次回到 READ 阶段都按同样的条件筛选

**调用示例**：
```
Skill("plan-next", args: "domain=backend app=order-service")
```

backend-single/frontend-single/fullstack-single 调用 plan-next 时应传入对应的 domain 和 app 参数。

### 初始化

1. **多应用模式检测**：检查当前目录 `.plan/app-registry.json` 是否存在
   - 存在 → **多应用模式**：读取 app-registry.json，遍历所有 app 的 `{appPath}/.plan/features.json`，合并后按过滤条件筛选统计
   - 不存在 → **单应用模式**：读取当前目录 `.plan/features.json`（原有逻辑）
2. 按过滤条件筛选后统计总任务数、待处理数（`passes: false` 且 `skipped` 不为 `true`）
3. 如果 features.json 不存在（单应用模式下 `.plan/features.json` 不存在，或多应用模式下所有 app 的 features.json 均不存在）：输出"⚠️ 任务未写入，请先运行 /plan-init 初始化项目" → 停止
4. 输出循环开始信息："🔄 开始循环执行，共 N 个任务，待处理 M 个"（如有过滤条件，显示过滤范围；多应用模式下显示涉及的 app 列表）

### 失败处理

当任务在任意阶段失败（测试无法通过、实现遇到阻塞等）：

1. 在对应的 features.json 中为该任务添加 `"skipped": true` 和 `"skipReason": "失败原因描述"`
2. 写跳过日志到对应 app 的 dev log（`{appPath}/.plan/dev-YYYY-MM-DD.log` 或 `.plan/dev-YYYY-MM-DD.log`）
3. 输出："⏭️ 任务 [ID] 跳过：[原因]，继续下一个"
4. **继续下一个任务**，不中断循环

### 循环结束条件

- 所有任务已处理（完成或跳过）
- 用户主动中断

## 关键规则

- **循环执行**：一次调用自动执行所有待处理任务，失败跳过继续
- **TDD 强制**：必须先看到 RED 再看 GREEN
- **TDD 弹性**：根据任务 category 调整严格度
  | category | TDD 模式 |
  |----------|----------|
  | core / feature | 完整 TDD（RED → GREEN → REFACTOR 强制） |
  | optimization / bugfix | 标准 TDD（RED → GREEN → REFACTOR） |
  | refactor | 先确保现有测试通过，重构后验证不变 |
  | config / docs / middleware | 简化模式：跳过 RED，直接实现 + 验证 |
- **复杂度分层**：根据任务 complexity 调整流水线深度（与 category TDD 弹性正交叠加）
  | complexity | EXPLORE | PLAN | RED/GREEN | REFACTOR |
  |-----------|---------|------|-----------|----------|
  | trivial   | 跳过    | 精简（只看 steps） | 按 category TDD 弹性 | 跳过 |
  | small     | 条件执行（同原有规则） | 标准 | 按 category TDD 弹性 | 精简（只检查 DRY） |
  | medium    | 标准    | 标准 | 标准 | 标准 |
  | large     | 标准 + 影响分析 | 标准 + 回滚方案 | 标准 | 标准 + De-Sloppify |
- **日志用于恢复**：每条日志必须能在新会话中恢复上下文
- **参考方法必查**：`references` 字段的方法必须在 PLAN 阶段查找并学习
- **数据样例必验**：`dataSamples` 字段必须在 RED 阶段基于样例编写测试
- **强制完整注释**：注释的核心价值是传递业务意图（"为什么这样做"），而非重复代码已经表达的信息
- **不确定必询问**：关键技术决策不确定时，必须向用户询问
- **问题收集机制**：问题不立即中断，记录后在阶段结束时统一确认

## 日志格式

追加到 `.plan/dev-YYYY-MM-DD.log`，每个任务写 2 条日志（进入 + 完成）：

```
[时间戳] [阶段] Task N: 一句话概述
├─ 状态: exploring|planning|red|green|refactoring|done
├─ 关键决策/问题: 最重要的一个（无则省略）
├─ 改动文件: file1.ts, file2.ts（GREEN/COMMIT 阶段才写）
└─ 下一步: 具体操作
---
```

## 问题收集

**类型**：`[技术选型]` `[实现方式]` `[边界确认]` `[资源缺失]` `[样例歧义]`

各阶段收集问题，阶段结束时统一向用户确认。格式：编号 + 类型标签 + 问题描述 + 背景 + 选项（含 ⭐推荐）。

---

## 阶段 1: READ

1. 读取 features.json（单应用模式读当前目录，多应用模式按 app-registry.json 合并所有 app），按过滤条件筛选后，找到第一个 `passes: false` 且 `skipped` 不为 `true` 的任务
2. 如果没有：退出循环，进入汇总报告
3. **依赖阻塞检查**：
   a. 读取该任务的 `dependsOn` 数组，为空则通过
   b. 对每个依赖项解析：
      - 纯 ID（如 `"1"`）→ 在当前任务所在的 features.json 中查找
      - `app:id` 格式（如 `"order-api:3"`）→ 从 `.plan/app-registry.json` 获取该 app 的 appPath，读取 `{appPath}/.plan/features.json`，查找对应 ID 的任务
   c. 检查所有依赖任务的 `passes` 字段：
      - 全部 `passes: true` → 通过，继续执行
      - 有未完成的 → 输出阻塞提醒并跳过该任务：
        ```
        ⛔ 任务 [ID] 被阻塞，依赖的任务未完成：
        - [dep-ref]: [描述] (未完成，位于 {appPath}/.plan/features.json)
        请先执行: /plan-next app=xxx
        ```
      - 继续查找下一个未阻塞的 `passes: false` 任务
   d. 如果所有 `passes: false` 的任务都被依赖阻塞 → 输出：
      ```
      ⚠️ 所有待处理任务均被依赖阻塞，请先完成以下应用的任务：
      - app=xxx: N 个任务未完成
      ```
      → 退出循环
4. 宣布："开始任务 [ID]: [描述]（第 X/N 个）"（如有 app 字段，显示应用名）
5. **appPath 路由**：如果任务含 `appPath` 字段，记录当前目录，cd 到 appPath 指向的项目目录执行后续阶段。**多应用模式下，后续阶段读写 features.json 和 dev log 均路由到 `{appPath}/.plan/` 目录**。

## 阶段 2: EXPLORE（条件执行）

**跳过条件**：
- 完全新建的代码（无需探索现有实现）
- `complexity: trivial` 的任务（改动量极小，不需要探索）

| 场景 | 是否 Explore |
|------|-------------|
| 修改现有方法/类 | ✅ |
| 在现有类中添加新方法 | ✅ |
| 创建全新的类/模块 | ❌ |
| complexity: trivial | ❌ |

`complexity: large` 时额外执行**影响分析**：列出所有可能受影响的上下游模块和调用方。

如有待确认问题，必须在进入 PLAN 前向用户确认。

## 阶段 3: PLAN

**complexity: trivial 精简模式**：只查看任务的 `steps` 字段，跳过 3.0-3.2 的详细分析，直接进入下一阶段。

**标准流程**（small/medium/large）：

1. 查看任务的 `steps`, `acceptance`, `test`, `boundary` 字段
2. 如果任务包含 `implementationGuide` 字段，优先参考：
   - `targetFiles`：定位要修改的精确文件和方法
   - `approach`：理解预研阶段确定的实现思路
   - `referenceCode`：找到可参考的现有实现
   - `dataFlow`：理解数据流向
   - `keyInterfaces`：确认需要实现/调用的接口
3. **参考资源查找**（如果有 `references` 或 `dataSamples`）：

### 3.0: API 契约确认

当任务有 `apiContracts` 字段时（通常是后端 API 任务），实现时必须严格按照契约定义的 method、path、request、response 结构。当前端任务通过 `implementationGuide.keyInterfaces` 引用了后端任务 ID 的 apiContracts 时，开发时直接按契约调用后端接口（前端任务无需 dependsOn 后端任务，不同 domain 通过 apiContracts 约定接口即可并行开发）。

### 3.1: 参考方法学习流程

当任务有 `references` 字段时：

**步骤一：精确定位参考方法**
- 使用 Grep 和 Read 找到参考方法的完整实现
- 记录方法签名、参数类型、返回值类型、异常声明
- 分析方法所在的类/包的整体设计意图

**步骤二：深度分析写法模式**
- **命名规范**：方法命名风格、参数命名规律
- **参数处理**：参数校验模式、参数转换逻辑、默认值处理
- **异常处理**：异常类型选择、异常信息格式、错误传播方式
- **返回值构造**：成功/失败的返回值格式、包装类使用模式
- **日志记录**：日志级别选择、日志内容格式

**步骤三：学习项目集成模式**
- 搜索所有调用示例：`Grep pattern="methodName" output_mode="content"`
- 分析不同场景下的调用方式差异
- 理解方法在项目架构中的位置和职责

**步骤四：改写适配当前需求**
- 保持相同的代码风格和结构模式
- 适配当前业务场景的具体需求
- 继承相同的错误处理和日志记录方式

### 3.2: 数据样例分析

当任务有 `dataSamples` 字段时：

**步骤一：结构解析**
- 阅读样例的整体结构（JSON/XML/CSV 等）
- 识别顶层字段及其含义
- 确认数据编码方式（UTF-8、GBK 等）

**步骤二：字段分析**
- **必填字段**：哪些字段必须存在
- **可选字段**：哪些字段可能缺失，缺失时的默认值
- **嵌套结构**：数组、对象嵌套的层级关系
- **特殊格式**：日期格式、枚举值、编码规则

**步骤三：边界确认**
- 字段值的取值范围（最大/最小、长度限制）
- 异常数据的处理方式（空值、格式错误）
- 样例是否覆盖所有业务场景

⚠️ 样例不完整或有歧义 → 记录 `[样例歧义]` 问题
⚠️ 找不到 references 中的方法 → 记录 `[资源缺失]` 问题

3. **影响范围确认**：列出要改/不改的文件
4. **Service 架构预评估**：评估是否需要抽取
5. **回滚方案**（仅 `complexity: large`）：简要说明如果实现失败，如何安全回退到改动前状态

如有待确认问题，必须在进入 RED 前向用户确认。

## 阶段 4: TDD RED 🔴

⚠️ **必须先看到测试失败**

**跳过条件**：如果任务 category 为 `config / docs / middleware`（TDD 弹性简化模式），跳过 RED 阶段，直接进入 IMPLEMENT。

1. 根据 `test` 字段选择方式：`unit/integration/e2e` → 调用 `/unit-test`
2. 基于 `dataSamples` 编写测试用例
3. 运行测试，**确认失败**

## 阶段 5: IMPLEMENT

写最小代码让测试通过，只做当前任务。

### 5.1: 参考方法使用规范

- **必须**使用 PLAN 阶段查找到的方法，按其封装方式调用
- 禁止绕过已有封装重新实现

### 5.2: 代码注释规范

写代码前，**必须先读取** [references/code-style.md](references/code-style.md) 中的注释相关章节。

**三条原则**：
- 公开 API 需要 doc 注释 — 消费者需要知道怎么用
- 非显而易见的逻辑需要行内注释 — 下一个读者需要知道为什么
- 简单直观的代码不需要注释 — `user.getName()` 不需要注释说"获取用户名"

### 5.3: 异常处理规范

只在必要时用 try-catch（外部 I/O、解析外部输入、第三方库抛异常），详见 [references/code-style.md](references/code-style.md)。日志必须包含业务标识、操作描述、关键参数、异常堆栈。

### 5.4: 变量命名规范

写代码时，**必须遵循** [references/code-style.md](references/code-style.md) 中的变量命名规范：

- List 类型变量后缀 `List`（如 `userList`、`orderItemList`）
- Map 类型变量后缀 `Map`（如 `orderMap`、`userRoleMap`）
- Set 类型变量后缀 `Set`（如 `activeUserSet`、`tagSet`）
- Boolean 变量以 `is`/`has`/`can`/`should` 开头
- 计数变量以 `count`/`total` 结尾

### 5.4: 用户交互

询问时提供具体建议方案（选项 + 优缺点 + ⭐推荐），不抛开放性问题。

如有待确认问题，必须在进入 GREEN 前向用户确认。

## 阶段 6: GREEN 🟢

1. 运行测试 → 必须全部通过
2. 检查 `acceptance` 每项是否满足
3. 验证 `dataSamples` 和 `references` 使用正确
4. 边界验证：只改了该改的

## 阶段 7: REFACTOR 🔧

**跳过条件**：`complexity: trivial` 的任务跳过整个 REFACTOR 阶段。

在测试保持绿色的前提下优化刚写的代码：

1. 消除重复代码（DRY）
2. 提取过长方法为更小的职责单一方法
3. 改进命名（变量、方法、类）
4. 简化条件表达式
5. 运行测试 → 确认仍然全部通过

**De-Sloppify 检查**（仅 `complexity: medium/large` 时执行）：

识别并清理 AI 生成代码中常见的过度工程化模式：
- 测试中测试了语言特性而非业务逻辑（如测试 null 参数等语言保证的行为）
- 过度防守校验（内部方法间传递已校验参数又重复校验）
- 不必要的 try-catch（catch 后只是重新抛出或仅记录日志）
- 只有一个实现的 interface/abstract class（一次性抽象）

发现问题直接清理，运行测试确认仍然通过。

**精简模式**（`complexity: small`）：只执行第 1 项（DRY），跳过其余。

⚠️ REFACTOR 只优化结构，不改变行为。如果测试变红，立即回退。

## 阶段 8: COMMIT

1. 设置 `passes: true` 在对应的 features.json 中（单应用模式写 `.plan/features.json`，多应用模式写 `{appPath}/.plan/features.json`）
2. 写最终日志（写入对应 app 的 dev log）
3. 输出进度："✅ 任务 [ID] 完成（已完成 X/N）"
4. **appPath 还原**：如果阶段 1 切换了目录，cd 回原目录
5. **返回阶段 1**，继续下一个待处理任务

---

## 成功标准

1. ✅ 测试通过（RED → GREEN → REFACTOR）
2. ✅ `acceptance` 全部满足
3. ✅ `passes: true` 已设置
4. ✅ `.plan/dev-YYYY-MM-DD.log` 中包含该任务的 2 条日志（进入 + 完成）

## 恢复指南

```
1. 读 .plan/features.json → 找到当前任务
2. 读 .plan/dev-YYYY-MM-DD.log → 搜索该 Task ID 的最后一条日志 → 查看"状态"和"下一步"
3. 从"下一步"继续执行
```

## 状态对应表

| 状态 | 下一步 |
|------|--------|
| exploring | 继续分析或进入 planning |
| planning | 写测试，进入 red |
| red | 写实现代码 |
| green | 重构优化，进入 refactoring |
| refactoring | 检查 acceptance，提交 |
| done | 自动循环到下一个 passes:false 的任务 |

## 完成后输出（汇总报告）

循环结束后：

**1. 写入完成信号到 dev log**（供下游 skill 读取）：

```
[时间戳] [CYCLE-DONE] 循环执行完成
├─ 范围: domain=xxx app=xxx
├─ 完成: X | 跳过: Y | 未处理: Z
└─ 结论: ALL_DONE | HAS_SKIPPED | HAS_REMAINING
---
```

**2. 输出汇总报告**：

```
📊 循环执行汇总
━━━━━━━━━━━━━━━
[如有过滤条件]
📋 范围: domain=xxx [app=xxx]
━━━━━━━━━━━━━━━
✅ 已完成: X 个
⏭️ 已跳过: Y 个
⏳ 未处理: Z 个
━━━━━━━━━━━━━━━

[如有跳过任务]
⏭️ 跳过详情:
- 任务 [ID]: [skipReason]

[下一步建议]
→ 所有完成: "所有任务已完成 🎉"
→ 有跳过: "建议检查跳过的任务，修复后重新运行 /plan-next"
→ 有未处理: "剩余任务可运行 /plan-next 继续"
```
