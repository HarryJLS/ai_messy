---
name: e2e-test
description: 前端 E2E 验证，启动 Dev Server 后用 Playwright 逐页面验证（控制台错误、响应式、截图）。可被 /frontend-team 阶段 3.5 调用，也可单独使用 /e2e-test。
---

# E2E Test - 前端端到端验证

启动 Dev Server → 等待就绪 → 逐页面/组件验证 → 截图 → 生成报告 → 关闭服务。

## 核心流程

```
检测框架 → 启动 Dev Server → 等待就绪 → 逐页面/组件验证 → 响应式检查 → 截图 → 生成报告 → 关闭服务
```

---

## Step 0: 环境检测

### 框架检测

检查 `package.json` 判断前端框架：

| 框架 | 检测条件 | 启动命令 | 默认端口 |
|------|---------|---------|---------|
| Next.js | `next.config.*` 存在 | `npm run dev` | 3000 |
| Vite (React/Vue3) | `vite.config.*` 存在 | `npm run dev` | 5173 |
| Vue CLI (Vue2) | `vue.config.js` 存在 | `npm run serve` | 8080 |
| CRA | `package.json` 含 `react-scripts` | `npm start` | 3000 |

如无法自动判定，AskUserQuestion 询问用户启动命令和端口。

### Playwright 检测

```bash
npx playwright --version
```

- 已安装 → 继续
- 未安装 → 提示用户执行：
  ```bash
  npm install -D @playwright/test && npx playwright install chromium
  ```
  等待用户确认后继续

---

## Step 1: 启动 Dev Server

1. 根据 Step 0 检测结果确定启动命令和端口
2. 后台启动服务：
   ```bash
   nohup <启动命令> &
   ```
   记录 PID（`echo $!`）
3. 轮询等待服务就绪（超时 60s）：
   ```bash
   # 每 2s 检测一次，最多 30 次
   curl -s -o /dev/null -w "%{http_code}" http://localhost:<端口>
   ```
   - 返回 200 → 服务就绪，继续
   - 超时 → 输出最近的服务日志，停止流程，报告启动失败

---

## Step 2: 页面验证

### 确定验证页面列表

按优先级获取：
1. 用户通过参数指定的 URL 列表
2. `task.md` 中的页面/路由列表
3. 扫描 `src/pages/` 或 `src/app/` 目录自动发现路由
4. 默认仅验证 `/`（首页）

### 逐页面验证

对每个页面/路由，使用 Playwright 执行：

```javascript
// 伪代码，实际通过 Bash 调用 npx playwright test 或编写临时脚本
const page = await browser.newPage();

// 1. 打开页面
await page.goto(`http://localhost:<端口>${route}`, { waitUntil: 'networkidle' });

// 2. 检查控制台错误
page.on('console', msg => {
  if (msg.type() === 'error') errors.push(msg.text());
});

// 3. 检查页面是否有视觉内容（非空白页）
const bodyText = await page.evaluate(() => document.body.innerText.trim());
const hasContent = bodyText.length > 0;

// 4. 基础交互验证
// - 按钮：检查可点击（visible + enabled）
// - 链接：检查 href 非空
// - 表单：检查 input 可聚焦

// 5. 截图
await page.screenshot({ path: `e2e-results/screenshots/${routeName}-desktop.png`, fullPage: true });
```

**实际执行方式**：编写临时 Playwright 测试脚本（`e2e-results/temp-test.spec.js`），通过 `npx playwright test` 运行，运行后删除临时脚本。

---

## Step 3: 响应式验证（默认开启）

对每个页面在 3 个视口下截图和检查：

| 视口 | 宽度 | 用途 |
|------|------|------|
| 手机 | 375px | 移动端适配 |
| 平板 | 768px | 中等屏幕适配 |
| 桌面 | 1440px | 大屏适配 |

每个视口检查：
- 截图保存到 `e2e-results/screenshots/{routeName}-{viewport}.png`
- 检查是否有横向滚动条：
  ```javascript
  const hasHorizontalScroll = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth
  );
  ```

---

## Step 4: 生成报告

输出格式：

```
E2E 验证报告
===========
Dev Server:   [PASS/FAIL] ({框架} on port {端口})
页面验证:     [X/Y 通过]
  - /           [PASS] (截图: e2e-results/screenshots/home-desktop.png)
  - /about      [PASS]
  - /dashboard  [FAIL] (控制台错误: TypeError: Cannot read property 'map' of undefined)
响应式检查:   [PASS/FAIL]
  - 375px:  无横向滚动 [PASS/FAIL]
  - 768px:  无横向滚动 [PASS/FAIL]
  - 1440px: 无横向滚动 [PASS/FAIL]

结论: [通过/不通过]
截图目录: e2e-results/screenshots/
```

**判定规则：**
- 任一页面有控制台 error → 该页面 FAIL
- 任一页面空白（无内容）→ 该页面 FAIL
- 任一视口有横向滚动 → 响应式 FAIL
- 全部通过 → 结论: 通过
- 任一项 FAIL → 结论: 不通过

---

## Step 5: 清理

1. Kill Dev Server 进程：
   ```bash
   kill <PID>
   ```
   如 PID 无效，尝试通过端口查找并终止：
   ```bash
   lsof -ti:<端口> | xargs kill -9
   ```
2. 删除临时测试脚本（如有）
3. **保留截图目录**（`e2e-results/screenshots/`），供后续 CR 参考
4. **保留报告内容**，可追加到 dev log

---

## 用户交互点

### 环境未就绪

```
检测到项目未安装 Playwright。

请执行以下命令安装：
  npm install -D @playwright/test && npx playwright install chromium

安装完成后回复 "已安装" 继续。
```

### 启动命令不确定

```
无法自动检测 Dev Server 启动命令。

请提供：
1. 启动命令（如 npm run dev）
2. 服务端口（如 3000）
```

### 页面列表为空

```
未找到可验证的页面路由。

请提供需要验证的 URL 路径列表（如 /, /about, /dashboard）。
```

---

## 错误处理

| 错误 | 处理 |
|------|------|
| Playwright 未安装 | 提示用户安装，等待确认 |
| Dev Server 启动失败 | 输出错误日志，停止流程 |
| Dev Server 启动超时（>60s） | 输出最近日志，停止流程 |
| 页面加载超时 | 标记该页面 FAIL，继续下一页 |
| Playwright 执行报错 | 捕获错误信息，标记 FAIL，继续 |
| 进程清理失败 | 通过端口号强制 kill |
