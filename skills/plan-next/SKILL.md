---
name: plan-next
description: 自动循环执行所有待处理任务（passes: false），失败跳过并继续，最终输出汇总报告。当用户说 "/plan-next"、"执行下一个任务"、"继续任务"、"开始开发" 时触发。必须先运行 /plan-init 创建 .plan/features.json。
---

# Plan Next

自动循环执行所有待处理任务，失败跳过继续，最终输出汇总报告。

## 循环控制

### 过滤参数

plan-next 支持通过调用方传入过滤条件：

| 参数 | 说明 | 示例 |
|------|------|------|
| `domain` | 只执行指定 domain | `domain=backend` |
| `app` | 只执行指定 app | `app=order-service` |

任务无 domain/app 字段时视为匹配任何过滤条件。过滤在整个循环周期持续生效。

### 初始化

1. 检查 `.plan/app-registry.json` 是否存在 → 多应用模式则合并所有 app 的 features.json
2. 按过滤条件筛选，统计待处理数（`passes: false` 且 `skipped` 不为 `true`）
3. features.json 不存在 → 输出"请先运行 /plan-init" → 停止
4. 输出："🔄 开始循环执行，共 N 个任务，待处理 M 个"

### 失败处理

任务在任意阶段失败时：
1. 在 features.json 中添加 `"skipped": true` 和 `"skipReason": "原因"`
2. 写跳过日志
3. 输出："⏭️ 任务 [ID] 跳过：[原因]"
4. 继续下一个任务，不中断循环

### 循环结束条件

所有任务已处理（完成或跳过）或用户主动中断。

## 关键规则

- **TDD 强制**：先写测试看到失败，再写代码让测试通过
- **参考必查**：任务有 `references`/`dataSamples`/`implementationGuide` 必须在 PLAN 阶段查阅
- **契约必遵**：任务有 `apiContracts` 必须按 method/path/request/response 实现
- **验收必过**：实现后逐项检查 `acceptance` 标准
- **不确定必问**：关键技术决策不确定时向用户确认（提供选项 + 优缺点 + 推荐）
- **代码质量**：消除重复、有意义注释、合理错误处理
- **复杂度感知**：trivial 任务精简处理（跳过探索和清理），large 任务加深处理（影响分析 + 回滚检查）

## READ

1. 读取 features.json，按过滤条件找到第一个 `passes: false` 且 `skipped` 不为 `true` 的任务
2. 无则退出循环，进入汇总报告
3. **依赖阻塞检查**：
   - 读 `dependsOn`，为空则通过
   - 纯 ID → 在当前 features.json 查找；`app:id` → 通过 app-registry.json 跨应用查找
   - 全部 `passes: true` → 通过；有未完成 → 跳过该任务，找下一个
   - 所有待处理任务均被阻塞 → 输出阻塞清单 → 退出循环
4. 宣布："开始任务 [ID]: [描述]（第 X/N 个）"
5. **appPath 路由**：任务含 `appPath` 则 cd 到该目录，后续读写 features.json 和 dev log 均路由到 `{appPath}/.plan/`

## PLAN

1. **探索判断**（在修改开始前）：
   | 场景 | 是否需要探索 |
   |------|-------------|
   | 修改现有方法/类 | ✅ grep + 阅读理解现有实现 |
   | 在现有类中新增方法 | ✅ 理解类职责和现有方法模式 |
   | 创建全新的类/模块 | ❌ 跳过 |
   | complexity: trivial | ❌ 跳过 |
   complexity: large 时额外做**影响分析**：列出可能受影响的上游调用方和下游依赖。
2. `references` → **三步学习**：
   - **定位**：grep 找到参考方法的完整实现，记录方法签名、参数类型、返回值
   - **分析**：理解命名风格、参数校验模式、异常处理方式、返回值构造方式
   - **适配**：保持相同风格和模式，适配当前业务场景
3. `dataSamples` → 基于样例数据结构编写测试用例
4. `implementationGuide` → 参考 `targetFiles`、`approach`、`referenceCode`、`dataFlow`
5. `apiContracts` → 按契约实现接口
6. 确认改动文件范围，不改无关文件

## RED

1. 根据 `test` 字段写失败的测试（`unit`/`integration` 调用 `/unit-test`；`e2e` 写端到端测试）
2. 运行测试，确认失败（必须看到 RED）

## GREEN

1. 写最小代码让测试通过，只做当前任务
2. 运行测试，确认全部通过
3. 逐项检查 `acceptance` 验收标准
4. 清理代码：消除重复（DRY）、改进命名、补充必要注释（公开 API doc、非显而易见的 why 注释、实现的接口方法的注释）、删除废话注释
5. **De-Sloppify 检查**（AI 生成代码常见问题）：
   - 测试是否在测业务逻辑而非语言特性（如测试 null 参数等语言保证的行为）
   - 是否存在过度防守校验（内部方法间重复校验同一参数）
   - 是否存在不必要的 try-catch（catch 后仅重新抛出或只记日志）
   - 是否存在一次性抽象（只有一个实现的 interface/abstract class）
   - 发现问题直接清理
6. 再次运行测试，确认仍然通过

## COMMIT

1. 在 features.json 中设 `passes: true`
2. 写完成日志到 dev log
3. 输出："✅ 任务 [ID] 完成（已完成 X/N）"
4. 如果切换了目录则 cd 回原目录
5. 返回 READ，继续下一个待处理任务

## 日志格式

```
[HH:MM] TASK_START id=N desc="任务描述"
[HH:MM] TASK_DONE id=N status=done|skipped reason="原因" files=file1,file2
```

写入 `.plan/dev-YYYY-MM-DD.log`（多应用模式写入 `{appPath}/.plan/dev-YYYY-MM-DD.log`）。

## 汇总报告

循环结束后输出：

```
📊 循环执行汇总
✅ 已完成: X 个
⏭️ 已跳过: Y 个
⏳ 未处理: Z 个

[跳过详情，如有]
- 任务 [ID]: [skipReason]

→ [下一步建议]
```

- 全部完成：建议运行后续 skill（code-simplifier、code-fixer）
- 有跳过：建议检查跳过的任务，修复后重新运行 /plan-next
