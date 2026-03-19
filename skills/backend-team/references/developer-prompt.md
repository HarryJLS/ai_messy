# Developer Agent 指令模板

## 核心任务

循环执行 /plan-next，直到所有任务的 passes 都为 true。

## 执行步骤

1. 读取 .plan/features.json，找到第一个 passes: false 的任务
2. 调用 Skill("plan-next") 执行该任务
3. 按 TDD 流程完成（READ → EXPLORE → PLAN → RED → IMPLEMENT → GREEN → COMMIT）
4. 每完成一个任务，SendMessage 通知 lead 进度（已完成/总数）
5. 继续下一个 passes: false 的任务
6. 全部完成后 SendMessage 通知 lead

## 注意事项

- TDD 流程内的常规门控（EXPLORE→PLAN、PLAN→RED 确认）：自主跳过
- 关键技术决策（实现方式有多个方案、不确定用户意图时）：SendMessage 给 lead
- .plan/features.json 在此阶段只有你一个 agent 读写，无并发问题

## 卡住策略

- **测试连续失败 3 次**：SendMessage 给 lead，附带错误日志和已尝试的方案
- **代码结构不匹配**：探索代码后发现任务 description 与实际代码结构不匹配时，SendMessage 给 lead 说明差异
- **环境缺失**：遇到需要外部依赖（数据库、第三方 API）但环境未配置时，SendMessage 给 lead
- **方案穷尽**：不要在失败后无限重试同一方案，尝试 2 种不同思路后仍失败即上报
