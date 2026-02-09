# Plan Next - 任务执行工作流

**指令**: `/plan-next`

**描述**: 使用 Feature-Dev 工作流和 TDD 循环执行下一个待处理任务

## 设计原则

- **抗遗忘**：通过读取相关任务日志恢复上下文
- **抗范围蔓延**：JSON 定义范围，日志提供详细上下文
- **精准执行**：只改该改的，不碰不该碰的
- **资深开发视角**：考虑复用性、扩展性、健壮性

---

⚠️ **角色提醒**：整个执行过程中，始终以**资深开发**的视角思考问题。根据项目技术栈（Go/Java/Python/前端）考虑：代码质量、边界情况、错误处理、性能优化、可维护性等。

## 关键规则

- **一次一个任务**，仅在验证后设置 `passes: true`
- **TDD 强制**：必须先看到 RED 再看 GREEN
- **日志用于恢复**：每条日志必须能在新会话中恢复上下文

## 日志格式（恢复优化）

每条日志必须回答：**"如果我在新会话中只读这条日志，能否继续？"**

```
[时间戳] [阶段] Task N: 一句话概述
├─ 状态: exploring|planning|red|green|blocked|done
├─ 决策: 关键决策（为什么这样做，避免重复决策）
├─ 文件: file1.ts, file2.ts（已改/将改）
├─ 问题: 遇到的问题 → 解决方案（或 none）
└─ 下一步: 具体下一步操作
---
```

---

## 阶段 1: READ

1. 读取 `features.json`，找到第一个 `passes: false`
2. 如果没有："所有任务已完成 🎉" → 停止
3. 宣布："开始任务 [ID]: [描述]"

## 阶段 2: EXPLORE（条件执行）

**仅当任务修改现有代码时执行**，新功能跳过。

判断标准：
- 修改现有功能 → 必须 Explore
- 全新功能 → 跳过，直接阶段 3

**执行时**：用文件搜索和阅读工具分析现有代码

**日志**:
```
[时间戳] [Explore] Task N: 分析 XXX 模块
├─ 状态: exploring → planning
├─ 决策: 发现 XXX 模式，计划复用/扩展
├─ 文件: existing1.ts, existing2.ts（将修改）
├─ 问题: none
└─ 下一步: 制定实现计划
---
```

## 阶段 3: PLAN

1. 查看任务的 `steps`, `acceptance`, `test`, `boundary` 字段
2. 如果模糊 → 先更新 features.json
3. **影响范围确认**（资深开发视角）：
   - 列出将要修改的文件/类/方法
   - 列出相似但**不应修改**的文件/类/方法
   - 如果有 `boundary` 字段，确认理解边界
4. 写日志

**日志**:
```
[时间戳] [Plan] Task N: 计划 XXX 功能
├─ 状态: planning → red
├─ 决策: 技术选型/架构决策要点
├─ 文件: new1.ts, new2.ts（将创建）| existing.ts（将修改）
├─ 问题: 预见的挑战 → 应对方案
└─ 下一步: 编写测试用例，确认 RED 状态
---
```

## 阶段 4: TDD RED 🔴

⚠️ **必须先看到测试失败，再写业务代码**

1. 根据任务 `test` 字段选择验证方式：
   - `unit/integration/e2e` → **调用 `/unit-test` 工作流**
   - `manual` → 写验证检查清单

2. **调用 `/unit-test` 工作流**（非 manual 类型时）：
   - `/unit-test` 会自动检测项目语言（Go/Java）
   - 根据项目现有测试风格生成测试代码
   - 完成后自动返回，继续 `plan-next` 后续阶段

3. 运行测试，**确认失败**

**日志**:
```
[时间戳] [Red] Task N: 测试准备完成
├─ 状态: red → implementing
├─ 决策: 选择 XXX 测试方式，因为 YYY
├─ 文件: test.spec.ts（已创建）
├─ 测试框架: [Go: Mockey+Testify | Java: Spock/JUnit]（由 /unit-test 检测）
├─ 问题: none
└─ 下一步: 实现功能代码，让测试通过
---
```

## 阶段 5: IMPLEMENT

- 写最小代码让测试通过
- 只做当前任务，不做额外"改进"
- **代码行长度**：单行不超过 120 字符，超过时换行：
  - 在运算符、逗号、点号后换行
  - 下一行适当缩进（4 空格或 1 tab）
  - 长字符串用 `+` 分行连接
- **疑似确认**（防止误改）：
  - 如果发现相似但不确定是否要改的地方，**停下来列出**
  - 格式：`⚠️ 疑似需要修改：[位置] - [原因] - 请确认是否处理`
  - ⛔ **等待用户确认** 后再继续

**换行示例**：
```java
// 方法调用换行
String result = someService.processData(param1, param2,
    param3, param4);

// 条件表达式换行
boolean isValid = StringUtils.isNotEmpty(name) && value > 0
    && status == Status.ACTIVE;

// 长字符串换行
String message = "This is a very long error message that exceeds "
    + "the maximum line length limit";
```

```go
// Go 方法调用换行
result, err := someService.ProcessData(ctx, param1, param2,
    param3, param4)

// Go 长字符串
message := "This is a very long error message that exceeds " +
    "the maximum line length limit"
```

## 阶段 6: GREEN 🟢

1. 运行测试 → 必须全部通过
2. 检查 `acceptance` 数组每项是否满足
3. **边界验证**（防止误改）：
   - 确认只修改了应该修改的内容
   - 确认没有误改相似但不相关的代码
4. 快速 self-check：
   - ✓ 边界：API 兼容？跨模块调用正常？
   - ✓ 健壮：错误处理？边界情况？
   - ✓ 精准：只改了该改的？没碰不该碰的？

**日志**:
```
[时间戳] [Green] Task N: 实现完成
├─ 状态: green → committing
├─ 决策: 实现要点/权衡取舍
├─ 文件: impl.ts, test.spec.ts（已完成）
├─ 问题: 遇到 XXX → 通过 YYY 解决（或 none）
└─ 下一步: 标记任务完成，提交
---
```

## 阶段 7: COMMIT

1. 设置 `passes: true` 在 features.json
2. 写最终日志

**日志**:
```
[时间戳] [Done] Task N: ✅ 完成
├─ 状态: done
├─ 决策: 关键架构决策总结（供后续任务参考）
├─ 文件: 所有变更文件列表
├─ 问题: 主要问题及解决方案总结
└─ 下一步: /plan-next 继续下一任务
---
```

---

## 成功标准

任务完成前必须满足：
1. ✅ 测试通过（RED → GREEN）
2. ✅ `acceptance` 全部满足
3. ✅ `passes: true` 已设置
4. ✅ `dev-YYYY-MM-DD.log` 中包含该任务的 3-4 条日志

## 恢复指南

**新会话恢复流程**：
```
1. 读 features.json → 找到当前任务
2. 读 dev-YYYY-MM-DD.log → 搜索该 Task ID 的最后一条日志 → 查看"状态"和"下一步"
3. 从"下一步"继续执行
```

## 状态对应表

| 状态 | 含义 | 下一步 |
|------|------|--------|
| exploring | 正在分析 | 继续分析或进入 planning |
| planning | 正在规划 | 写测试，进入 red |
| red | 测试已写，待实现 | 写实现代码 |
| implementing | 正在实现 | 继续实现，然后测试 |
| green | 测试通过 | 检查 acceptance，提交 |
| blocked | 遇到阻塞 | 解决问题后继续 |
| done | 完成 | /plan-next |

## 完成后输出

```
✅ 任务 [ID] 完成！

📄 日志: dev-YYYY-MM-DD.log
→ 运行 /plan-next 继续下一任务
```
