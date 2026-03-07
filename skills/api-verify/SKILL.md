---
name: api-verify
description: 后端 API 运行时验证，启动服务后逐接口发送请求验证状态码和响应结构。可被 /backend-team 阶段 3.5 调用，也可单独使用 /api-verify。
---

# API Verify - 后端 API 运行时验证

启动后端服务 → 等待就绪 → 逐接口验证 → 生成报告 → 关闭服务。

## 核心流程

```
检测框架 → 启动后端服务 → 等待就绪 → 接口发现 → 逐接口验证 → 生成报告 → 关闭服务
```

---

## Step 0: 环境检测

### 框架检测

| 框架 | 检测条件 | 启动命令 | 默认端口 | 健康检查路径 |
|------|---------|---------|---------|------------|
| Spring Boot | `pom.xml` / `build.gradle` 含 `spring-boot` | `mvn spring-boot:run` / `./gradlew bootRun` | 8080 | `/actuator/health` |
| Go (Gin/Echo/Fiber) | `go.mod` + `main.go` | `go run .` | 8080 | `/health` 或 `/` |
| FastAPI | `requirements.txt` / `pyproject.toml` 含 `fastapi` | `uvicorn app.main:app --port 8000` | 8000 | `/docs` 或 `/health` |
| Flask | `requirements.txt` / `pyproject.toml` 含 `flask` | `flask run --port 5000` | 5000 | `/` |
| Express | `package.json` 含 `express` | `npm run dev` 或 `node app.js` | 3000 | `/` |
| NestJS | `package.json` 含 `@nestjs/core` | `npm run start:dev` | 3000 | `/` |

如无法自动检测，AskUserQuestion 询问：
1. 启动命令
2. 服务端口
3. 健康检查路径

---

## Step 1: 启动后端服务

1. 根据 Step 0 检测结果确定启动命令和端口
2. 后台启动服务：
   ```bash
   nohup <启动命令> > /tmp/api-verify-server.log 2>&1 &
   ```
   记录 PID（`echo $!`），记录启动时间戳
3. 轮询等待健康检查通过（超时 90s）：
   ```bash
   # 每 3s 检测一次，最多 30 次
   curl -s -o /dev/null -w "%{http_code}" http://localhost:<端口><健康检查路径>
   ```
   - 返回 200 → 服务就绪，记录启动耗时，继续
   - 超时 → 输出 `/tmp/api-verify-server.log` 最后 50 行，停止流程，报告启动失败

---

## Step 2: 接口发现

按优先级自动发现接口：

### 优先级 1: task.md 中的接口列表

读取 `task.md`，查找接口定义（如 `GET /api/users`、`POST /api/orders` 等格式）。

### 优先级 2: OpenAPI/Swagger

依次尝试访问：
- `http://localhost:<端口>/swagger-ui.html`（Spring Boot）
- `http://localhost:<端口>/docs`（FastAPI）
- `http://localhost:<端口>/api-docs`（Express/NestJS）
- `http://localhost:<端口>/swagger/index.html`（Go Swag）

如可访问，解析接口列表。

### 优先级 3: 路由文件扫描

| 框架 | 扫描目标 | 匹配模式 |
|------|---------|---------|
| Spring Boot | `src/main/java/**/*Controller.java` | `@RequestMapping`、`@GetMapping`、`@PostMapping` 等 |
| Go (Gin) | `*.go` | `r.GET`、`r.POST`、`r.PUT`、`r.DELETE`、`r.Group` |
| Go (Echo) | `*.go` | `e.GET`、`e.POST`、`e.PUT`、`e.DELETE`、`e.Group` |
| FastAPI | `**/*.py` | `@app.get`、`@app.post`、`@router.get`、`@router.post` |
| Flask | `**/*.py` | `@app.route`、`@blueprint.route` |
| Express | `**/*.js` / `**/*.ts` | `router.get`、`router.post`、`app.get`、`app.post` |
| NestJS | `**/*.controller.ts` | `@Get`、`@Post`、`@Put`、`@Delete` |

### 优先级 4: 用户提供

如以上方式均无法获取接口列表，AskUserQuestion：

```
未找到可验证的 API 接口。

请提供接口列表，格式如：
  GET /api/users
  POST /api/users
  GET /api/users/:id
  DELETE /api/users/:id
```

---

## Step 3: 逐接口验证

对每个接口发送请求并验证：

```bash
# 记录响应详情
curl -s -w "\n%{http_code}\n%{time_total}" \
  -X <METHOD> \
  -H "Content-Type: application/json" \
  http://localhost:<端口><path>
```

### 验证规则

| 请求类型 | 期望结果 | PASS 条件 | FAIL 条件 |
|----------|---------|----------|----------|
| GET | 正常响应 | 200，响应体为有效 JSON/HTML | 5xx、连接拒绝、超时(>10s) |
| POST/PUT（无 body） | 参数校验或认证 | 400（参数校验）或 401（需认证） | 5xx、连接拒绝、超时 |
| 健康检查 | 200 | 200 | 非 200 |
| DELETE（无参数） | 参数校验或认证 | 400/401/404 均合理 | 5xx、连接拒绝、超时 |

**通用 FAIL 条件**（任何请求类型）：
- 状态码 5xx（服务端错误）
- 连接拒绝（Connection refused）
- 响应超时（>10s）

### 记录内容

每个接口记录：
- HTTP 方法和路径
- 状态码
- 响应时间（ms）
- 响应 Content-Type
- 响应体前 500 字符（用于排查）

---

## Step 4: 生成报告

输出格式：

```
API 验证报告
===========
服务启动:     [PASS/FAIL] ({框架} on port {端口}, 启动耗时 {X}s)
接口验证:     [X/Y 通过]
  - GET  /api/users      [PASS] (200, 45ms, JSON)
  - GET  /api/users/:id  [PASS] (200, 32ms, JSON)
  - POST /api/users      [PASS] (400, 28ms, "缺少必填字段" - 参数校验正常)
  - GET  /api/orders     [FAIL] (500, 120ms, "NullPointerException")
响应时间:     平均 {X}ms, 最慢 {X}ms ({接口名})

结论: [通过/不通过]
```

**判定规则：**
- 服务启动失败 → 结论: 不通过（跳过接口验证）
- 任一接口返回 5xx → 结论: 不通过
- 任一接口连接拒绝或超时 → 结论: 不通过
- 全部接口符合期望 → 结论: 通过

---

## Step 5: 清理

1. Kill 后端服务进程：
   ```bash
   kill <PID>
   ```
   如 PID 无效，尝试通过端口查找并终止：
   ```bash
   lsof -ti:<端口> | xargs kill -9
   ```
2. 清理临时日志（`/tmp/api-verify-server.log`）
3. **保留报告内容**，可追加到 dev log

---

## 用户交互点

### 启动命令不确定

```
无法自动检测后端框架和启动命令。

请提供：
1. 启动命令（如 mvn spring-boot:run）
2. 服务端口（如 8080）
3. 健康检查路径（如 /actuator/health，留空则用 /）
```

### 接口列表为空

```
未找到可验证的 API 接口。

请提供接口列表，格式如：
  GET /api/users
  POST /api/users
  GET /api/users/:id
```

### 5xx 错误详情

当接口返回 5xx 时，展示响应体前 500 字符供排查。

---

## 错误处理

| 错误 | 处理 |
|------|------|
| 框架无法检测 | AskUserQuestion 询问启动命令和端口 |
| 服务启动失败 | 输出错误日志，停止流程 |
| 服务启动超时（>90s） | 输出最近日志，停止流程 |
| 接口返回 5xx | 标记 FAIL，记录响应体，继续下一个接口 |
| 接口连接拒绝 | 标记 FAIL（服务可能已崩溃），尝试继续 |
| 接口响应超时（>10s） | 标记 FAIL，继续下一个接口 |
| 进程清理失败 | 通过端口号强制 kill |
