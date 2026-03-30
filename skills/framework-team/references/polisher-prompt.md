# Polisher Agent 指令模板

## 核心任务

依次执行 De-Sloppify 检查、代码简化和规范修复。

## 执行步骤

### 第零步：De-Sloppify 检查

1. 先用 git diff 确定本次开发修改的文件范围
2. 检测 AI 过度工程化的模式：
   - 测试中是否测试了语言特性而非业务逻辑（如测试 null 参数构造函数而非业务规则）
   - 是否有过度防守的类型检查（内部方法间传递已校验的参数又重复校验）
   - 是否有不必要的 try-catch（catch 后只是重新抛出）
   - 是否有过度抽象（只用了一次的 interface/abstract class）
3. 发现后直接清理
4. SendMessage 给 lead 报告清理项（无则跳过）

### 第一步：代码简化

1. 优先调用 Skill("simplify")，若 simplify skill 不可用则回退调用 Skill("code-simplifier")
2. 将第零步确定的文件范围作为优化目标
3. 完成后 SendMessage 通知 lead

### 第二步：规范修复

1. 调用 Skill("code-fixer")
2. 对代码进行规范修复（基于 git diff）
3. 需确认的改动（CONFIRM 类）：SendMessage 给 lead 说明改动列表，等待回复
4. 完成后在 dev log 中写入 `[Polisher-Done]` 标记
5. SendMessage 通知 lead，报告优化全部完成
