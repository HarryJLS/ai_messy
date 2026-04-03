---
name: backend-test
description: 后端测试验证，基于 .plan/features.json 已完成任务驱动：运行单元测试 + 启动服务验证 API 契约 + 逐任务检查验收标准。支持读取 .plan/test-cases.json 执行用户提供的独立测试用例。当用户说 "/backend-test"、"后端测试"、"跑后端测试"、"验证后端"、"API 测试"、"跑测试用例" 时触发。
---

# Backend Test - 后端测试验证

基于 `.plan/features.json` 已完成的后端任务，执行三层验证：单元测试 → API 契约验证 → 验收标准检查。

## 核心流程

```
读取 features.json + test-cases.json → 框架检测 → 运行单元测试 → 启动服务 → API 契约验证 → 测试用例执行 → 验收标准检查 → 生成报告 → 清理
```

## Step 0: 读取任务 + 框架检测

### 读取已完成任务

读取 `.plan/features.json`，过滤目标任务：
- 有 `domain` 字段：只取 `domain=backend` 且 `passes: true` 的任务
- 如果用户指定了 app（如 `/backend-test order-service`）：进一步只取 `app` 匹配的任务
- 无 `domain` 字段：取所有 `passes: true` 的任务

**appPath 路由**：如果任务含 `appPath` 字段，在对应目录下执行测试。

如果无已完成任务，提示用户先完成开发，停止流程。

### 读取测试用例（可选）

读取 `.plan/test-cases.json`（如存在）。

- 存在 → 提取 serviceConfig、testSuites、variables，在 Step 2.5 执行
- 不存在 → 跳过 Step 2.5（向后兼容，不影响现有流程）

**appPath 路由**：如果 test-cases.json 含 `serviceConfig.appPath`，在对应目录下执行。

**独立运行模式**：如果 features.json 不存在或无已完成任务，但 test-cases.json 存在，则跳过 Step 1-2（单元测试和 API 契约验证），直接执行 Step 2.5（测试用例），仍然生成报告。

### 框架检测

| 框架 | 检测条件 | 测试命令 | 启动命令 | 默认端口 | 健康检查路径 |
|------|---------|---------|---------|---------|------------|
| Spring Boot | `pom.xml` / `build.gradle` 含 `spring-boot` | `mvn test` / `./gradlew test` | `mvn spring-boot:run` / `./gradlew bootRun` | 8080 | `/actuator/health` |
| Go (Gin/Echo/Fiber) | `go.mod` + `main.go` | `go test ./...` | `go run .` | 8080 | `/health` 或 `/` |
| FastAPI | `requirements.txt` 含 `fastapi` | `pytest` | `uvicorn app.main:app --port 8000` | 8000 | `/docs` 或 `/health` |
| Flask | `requirements.txt` 含 `flask` | `pytest` | `flask run --port 5000` | 5000 | `/` |
| Express | `package.json` 含 `express` | `npm test` | `npm run dev` 或 `node app.js` | 3000 | `/` |
| NestJS | `package.json` 含 `@nestjs/core` | `npm test` | `npm run start:dev` | 3000 | `/` |

无法自动检测时，AskUserQuestion 询问启动命令、端口、健康检查路径。

---

## Step 1: 运行单元测试

执行框架对应的测试命令，收集结果：

```bash
<测试命令> 2>&1
```

记录：通过数 / 失败数 / 跳过数 / 总耗时。

如果测试全部通过 → 继续 Step 2。
如果有失败 → 记录失败详情，继续 Step 2（不中断流程）。

---

## Step 2: API 契约验证

### 2.1 收集测试用例

扫描已完成任务中的 `apiContracts` 字段，同时收集测试用例：

**测试用例来源（按优先级）**：
1. **用户提供的测试用例**：如果用户在触发时附带了测试数据（请求参数、预期响应），直接使用
2. **任务中的 `dataSamples` 字段**：使用预定义的测试数据
3. **自动生成**：根据 apiContracts 的 request/response 结构自动构造合理的测试数据

对于业务逻辑复杂的接口（涉及具体业务规则、权限校验、状态机等），优先询问用户是否要提供测试用例：

```
以下接口涉及业务逻辑，建议提供测试用例以确保验证准确：

1. POST /api/orders - 创建订单（涉及库存校验、价格计算）
2. PUT /api/users/:id/role - 修改用户角色（涉及权限校验）

请提供测试数据（JSON 格式），或回复"自动生成"让我根据代码逻辑构造。
```

如果任务中没有 apiContracts，跳过此步。

### 2.2 启动服务

```bash
nohup <启动命令> > /tmp/backend-test-server.log 2>&1 &
```

记录 PID，轮询健康检查（每 3s 一次，超时 90s）。

### 2.3 逐接口验证

对每个 apiContract 中的接口，用收集到的测试用例发请求：

```bash
curl -s -w "\n%{http_code}\n%{time_total}" \
  -X <METHOD> \
  -H "Content-Type: application/json" \
  -d '<request body>' \
  http://localhost:<端口><path>
```

**验证规则**：

| 维度 | 验证内容 | PASS 条件 |
|------|---------|----------|
| 状态码 | 与 apiContracts.response.code 对比 | 匹配 |
| 响应结构 | 检查响应 JSON 是否包含契约定义的字段 | 所有必需字段存在 |
| 响应类型 | Content-Type 检查 | application/json |
| 响应时间 | 记录耗时 | < 10s |

**通用 FAIL 条件**：状态码 5xx、连接拒绝、响应超时(>10s)。

### 2.4 关闭服务

```bash
kill <PID>
# 如 PID 无效
lsof -ti:<端口> | xargs kill -9
```

清理临时日志。

---

## Step 2.5: 测试用例执行（来自 test-cases.json）

跳过条件：`.plan/test-cases.json` 不存在。

### 2.5.1 服务启动

如果 Step 2 已启动服务且端口相同 → 复用（不重复启动）。

否则：
1. 执行 `serviceConfig.setupCommands`（如有）
2. 框架检测：`serviceConfig.framework` 为 `"auto"` 时使用 Step 0 的检测结果填充 startCommand/port/healthCheck；用户在 serviceConfig 中指定的值优先
3. 设置环境变量：应用 `serviceConfig.envVars`
4. 启动服务：`nohup <startCommand> > /tmp/backend-test-tc-server.log 2>&1 &`
5. 记录 PID，轮询健康检查（每 3s，超时 90s）

### 2.5.2 变量解析

构建变量上下文：
1. `variables` 全局变量作为初始值
2. 每个测试的 `saveAs` 在执行后追加到变量上下文

替换所有 `{{variableName}}` 占位符（出现在 path、headers、body 中）。

### 2.5.3 逐套件执行

对 testSuites 中的每个套件：
- `sequential: true` → 按数组顺序执行测试
- `sequential: false` → 测试可按任意顺序执行

对套件中的每个测试：
1. 检查 `dependsOn` — 如果前置测试失败或被跳过，标记 SKIP 并记录原因
2. 解析请求中的 `{{变量}}` 占位符
3. 发送 HTTP 请求：
   ```bash
   curl -s -w "\n%{http_code}\n%{time_total}" \
     -X <method> \
     -H "<header>: <value>" \
     -d '<body>' \
     http://localhost:<port><path>
   ```
4. 验证响应：
   - `expected.status` → 状态码匹配
   - `expected.bodyContains` → 响应体包含指定字符串列表中的每一项
   - `expected.bodyMatch` → 响应体字段值匹配（深度比较）
   - `expected.maxResponseTime` → 响应时间不超过阈值（默认 10s）
5. 如果有 `saveAs`：从响应 JSON 中提取值，加入变量上下文
   - JSONPath 提取：`echo $response | jq -r '<jsonpath>'`
6. 记录 PASS/FAIL/SKIP 及详情

### 2.5.4 服务清理

如果 2.5.1 中新启动了服务（非复用 Step 2 的）：
```bash
kill <PID>
# 如 PID 无效
lsof -ti:<端口> | xargs kill -9
```

清理临时日志。

---

## Step 3: 验收标准检查

逐任务检查 `acceptance` 字段中的每条验收标准：

1. 读取任务的 acceptance 数组
2. 对每条标准，检查代码实现是否满足：
   - 可通过代码搜索验证的（如"新增了 XXX 方法"）→ 用 Grep/Read 验证
   - 可通过测试结果验证的（如"返回 200"）→ 引用 Step 1/2 的结果
   - 需要人工判断的 → 标记为"待人工确认"
3. 记录每条标准的通过/失败/待确认状态

---

## Step 4: 生成报告

```
后端测试报告
===========
框架:         {框架名}
已完成任务:   {N} 个

1. 单元测试:   [PASS/FAIL] ({通过数}/{总数} 通过, 耗时 {X}s)

2. API 契约验证: [X/Y 通过]
   任务 2 "用户 API 实现":
   - GET  /api/users      [PASS] (200, 45ms)
   - POST /api/users      [PASS] (201, 62ms)
   任务 3 "订单 API 实现":
   - POST /api/orders     [FAIL] (500, 120ms, "NullPointerException")

3. 测试用例:   [X/Y 通过, Z 个套件]                    ← 仅有 test-cases.json 时显示
   套件 "订单 API 集成测试" (顺序执行):
   - tc-1 创建订单-正常数据       [PASS] (200, 62ms)
   - tc-2 查询已创建订单          [PASS] (200, 35ms)
   - tc-3 创建订单-无效数据       [PASS] (400, 28ms)
   套件 "数据校验":
   - tc-4 重复订单检测            [FAIL] (200 ≠ 409, 41ms)

4. 验收标准:   [X/Y 通过]
   任务 2: 3/3 通过
   任务 3: 2/3 通过
   - [FAIL] "订单创建成功后返回 order_id"

响应时间:     平均 {X}ms, 最慢 {X}ms ({接口名})

结论: [通过/不通过]
```

**判定规则**：
- 单元测试有失败 → 结论: 不通过
- 任一 API 返回 5xx → 结论: 不通过
- 测试用例有失败（不含 SKIP）→ 结论: 不通过
- 验收标准有未通过项（不含"待人工确认"）→ 结论: 不通过
- 全部通过 → 结论: 通过

---

## 错误处理

| 错误 | 处理 |
|------|------|
| features.json 不存在 | 提示先运行 /plan-init + /backend-single |
| 无已完成任务 | 提示先完成开发 |
| 框架无法检测 | AskUserQuestion 询问 |
| 服务启动失败/超时 | 输出日志，跳过 API 验证，继续验收检查 |
| 接口返回 5xx | 标记 FAIL，继续下一个 |
| 进程清理失败 | 通过端口号强制 kill |
| test-cases.json 格式错误 | 输出解析错误，跳过 Step 2.5，继续后续步骤 |
| 测试用例依赖的前置测试失败 | 标记 SKIP，记录原因，继续下一个测试 |
| 变量 `{{xxx}}` 未定义 | 输出警告，保留占位符原文发送请求 |
