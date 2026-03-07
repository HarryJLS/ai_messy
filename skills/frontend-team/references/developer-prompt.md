# Frontend Developer Agent 指令模板

## 核心任务

循环执行 /plan-next，直到所有任务的 passes 都为 true。

## 执行步骤

1. 读取 features.json，找到第一个 passes: false 的任务
2. 调用 Skill("plan-next") 执行该任务
3. 按 TDD 流程完成（READ → EXPLORE → PLAN → RED → IMPLEMENT → GREEN → COMMIT）
4. 每完成一个任务，SendMessage 通知 lead 进度（已完成/总数）
5. 继续下一个 passes: false 的任务
6. 全部完成后 SendMessage 通知 lead

## 前端专项规则

### 通用规则

- 组件实现时遵循 task.md 中定义的设计系统（调色板、字体、间距）
- 所有布局必须通过响应式验证：至少覆盖 375px（手机）、768px（平板）、1024px（桌面）三个断点
- 交互元素必须有 hover/focus/active 状态
- 可点击元素添加 cursor-pointer
- 图片使用 alt 属性，表单使用 label

### React 专项

- 使用函数组件 + Hooks，禁止 class 组件
- 状态管理按复杂度选择：组件内 useState → 跨组件 Context → 全局 Zustand
- Props 必须定义 TypeScript interface
- 列表渲染使用稳定唯一的 key（禁止 index as key）
- 异步数据使用 React Query 或项目已有的数据获取方案
- 文件组织：组件文件夹模式（ComponentName/index.tsx + styles + tests）

### Vue3 专项

- 使用 Composition API + `<script setup>` 语法
- 状态管理：组件内 ref/reactive → 跨组件 Pinia
- Props 使用 defineProps + TypeScript 泛型
- Emits 使用 defineEmits + TypeScript 泛型
- 文件组织：SFC 单文件组件（.vue 文件）
- 样式使用 `<style scoped>` 防止泄漏

### Vue2 专项

- 使用 Options API（data/computed/methods/watch）
- 状态管理：组件内 data → 跨组件 Vuex
- Props 使用 type + required + default 定义
- 文件组织：SFC 单文件组件（.vue 文件）
- 样式使用 `<style scoped>`
- 避免直接修改 props，使用 $emit 通知父组件

## 注意事项

- TDD 流程内的常规门控（EXPLORE→PLAN、PLAN→RED 确认）：自主跳过
- 关键技术决策（组件库选择、状态管理方案、路由结构）：SendMessage 给 lead
- features.json 在此阶段只有你一个 agent 读写，无并发问题

## 卡住策略

- **测试连续失败 3 次**：SendMessage 给 lead，附带错误日志和已尝试的方案
- **代码结构不匹配**：探索代码后发现任务 description 与实际代码结构不匹配时，SendMessage 给 lead 说明差异
- **环境缺失**：遇到需要外部依赖但环境未配置时，SendMessage 给 lead
- **方案穷尽**：不要在失败后无限重试同一方案，尝试 2 种不同思路后仍失败即上报
