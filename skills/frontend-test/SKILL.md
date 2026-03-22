---
name: frontend-test
description: 前端测试验证，基于 .plan/features.json 已完成任务驱动：运行已有测试 + Playwright E2E 验证（控制台错误、响应式、截图）+ 逐任务检查验收标准。当用户说 "/frontend-test"、"前端测试"、"跑前端测试"、"验证前端"、"E2E 测试" 时触发。
---

# Frontend Test - 前端测试验证

基于 `.plan/features.json` 已完成的前端任务，执行三层验证：已有测试 → E2E 验证 → 验收标准检查。

## 核心流程

```
读取 features.json → 框架检测 → 运行已有测试 → 启动 Dev Server → E2E 验证 → 验收标准检查 → 生成报告 → 清理
```

## Step 0: 读取任务 + 框架检测

### 读取已完成任务

读取 `.plan/features.json`，过滤目标任务：
- 有 `domain` 字段：只取 `domain=frontend` 且 `passes: true` 的任务
- 如果用户指定了 app（如 `/frontend-test admin-web`）：进一步只取 `app` 匹配的任务
- 无 `domain` 字段：取所有 `passes: true` 的任务

**appPath 路由**：如果任务含 `appPath` 字段，在对应目录下执行测试。

如果无已完成任务，提示用户先完成开发，停止流程。

### 框架检测

| 框架 | 检测条件 | 测试命令 | 启动命令 | 默认端口 |
|------|---------|---------|---------|---------|
| Next.js | `next.config.*` 存在 | `npm test` | `npm run dev` | 3000 |
| Vite (React/Vue3) | `vite.config.*` 存在 | `npx vitest run` 或 `npm test` | `npm run dev` | 5173 |
| Vue CLI (Vue2) | `vue.config.js` 存在 | `npm test` | `npm run serve` | 8080 |
| CRA | `package.json` 含 `react-scripts` | `npm test` | `npm start` | 3000 |

无法自动判定时，AskUserQuestion 询问启动命令和端口。

### Playwright 检测

```bash
npx playwright --version
```

- 已安装 → 继续
- 未安装 → 提示用户执行 `npm install -D @playwright/test && npx playwright install chromium`，等待确认

---

## Step 1: 运行已有测试

执行框架对应的测试命令：

```bash
<测试命令> 2>&1
```

记录：通过数 / 失败数 / 跳过数 / 总耗时。

如果测试全部通过 → 继续。有失败 → 记录详情，继续（不中断）。

---

## Step 2: E2E 验证

### 2.1 确定验证页面列表

按优先级获取：
1. 已完成任务的描述中提到的路由/页面路径
2. `.plan/task.md` 中的页面/路由列表
3. 扫描 `src/pages/` 或 `src/app/` 目录自动发现路由
4. 默认仅验证 `/`（首页）

### 2.2 启动 Dev Server

```bash
nohup <启动命令> > /tmp/frontend-test-server.log 2>&1 &
```

记录 PID，轮询等待服务就绪（每 2s 一次，超时 60s）。

### 2.3 逐页面验证

对每个页面，编写临时 Playwright 脚本执行：

**验证项**：
1. **页面加载**：打开页面，等待 networkidle
2. **控制台错误**：捕获所有 console.error
3. **内容检查**：页面非空白（body.innerText.trim().length > 0）
4. **基础交互**：按钮可点击、链接 href 非空、input 可聚焦
5. **截图**：保存到 `e2e-results/screenshots/{routeName}-desktop.png`

### 2.4 响应式验证

对每个页面在 3 个视口下截图和检查：

| 视口 | 宽度 | 检查项 |
|------|------|--------|
| 手机 | 375px | 无横向滚动、内容可见 |
| 平板 | 768px | 无横向滚动、布局正常 |
| 桌面 | 1440px | 无横向滚动、布局正常 |

截图保存到 `e2e-results/screenshots/{routeName}-{viewport}.png`。

### 2.5 关闭 Dev Server

```bash
kill <PID>
# 如 PID 无效
lsof -ti:<端口> | xargs kill -9
```

---

## Step 3: 验收标准检查

逐任务检查 `acceptance` 字段中的每条验收标准：

1. 读取任务的 acceptance 数组
2. 对每条标准，检查实现是否满足：
   - 可通过代码搜索验证的（如"新增了 XXX 组件"）→ 用 Grep/Read 验证
   - 可通过 E2E 结果验证的（如"页面无控制台错误"）→ 引用 Step 2 的结果
   - 可通过截图验证的（如"响应式布局正常"）→ 引用截图路径
   - 需要人工判断的 → 标记为"待人工确认"
3. 记录每条标准的通过/失败/待确认状态

---

## Step 4: 生成报告

```
前端测试报告
===========
框架:         {框架名}
已完成任务:   {N} 个

1. 已有测试:   [PASS/FAIL] ({通过数}/{总数} 通过, 耗时 {X}s)

2. E2E 验证:   [X/Y 页面通过]
   - /           [PASS] (截图: e2e-results/screenshots/home-desktop.png)
   - /about      [PASS]
   - /dashboard  [FAIL] (控制台错误: TypeError: Cannot read property 'map' of undefined)

3. 响应式检查:  [PASS/FAIL]
   - 375px:  无横向滚动 [PASS]
   - 768px:  无横向滚动 [PASS]
   - 1440px: 无横向滚动 [PASS]

4. 验收标准:   [X/Y 通过]
   任务 3 "用户列表页面": 3/3 通过
   任务 4 "订单详情页": 2/3 通过
   - [FAIL] "订单状态标签显示正确颜色"

截图目录: e2e-results/screenshots/
结论: [通过/不通过]
```

**判定规则**：
- 已有测试有失败 → 结论: 不通过
- 任一页面有控制台 error → 该页面 FAIL
- 任一页面空白 → 该页面 FAIL
- 任一视口有横向滚动 → 响应式 FAIL
- 验收标准有未通过项 → 结论: 不通过
- 全部通过 → 结论: 通过

---

## 错误处理

| 错误 | 处理 |
|------|------|
| features.json 不存在 | 提示先运行 /plan-init + /frontend-single |
| 无已完成任务 | 提示先完成开发 |
| Playwright 未安装 | 提示安装，等待确认 |
| Dev Server 启动失败/超时 | 输出日志，跳过 E2E，继续验收检查 |
| 页面加载超时 | 标记该页面 FAIL，继续下一页 |
| 进程清理失败 | 通过端口号强制 kill |
