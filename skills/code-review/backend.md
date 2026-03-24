# Backend Review Checklist

Domain-specific review items for Python, FastAPI, and async codebases.

Add these categories to the summary table:
- Security (Backend)
- FastAPI Patterns
- Pydantic Validation
- Async Patterns
- Error Handling (Backend)
- Database/ORM

---

## Category: Security (Backend)

### SQL Injection

**Search patterns**:
```bash
# Raw SQL with string formatting
grep -rE "execute\(.*%|execute\(.*\.format\(|execute\(.*f['\"]" --include="*.py"

# String concatenation in queries
grep -rE "SELECT.*\+|INSERT.*\+|UPDATE.*\+|DELETE.*\+" --include="*.py"
```

**Pass criteria**: All queries use parameterized statements or ORM
**Severity**: Critical

---

### Path Traversal

**Search patterns**:
```bash
# Unsanitized file paths
grep -rE "open\(.*\+|Path\(.*\+|os\.path\.join\(.*request" --include="*.py"

# Direct user input in file operations
grep -rE "with open\(|\.read\(|\.write\(" --include="*.py" -B 3 | grep -E "request\.|params\.|query\."
```

**Pass criteria**: All file paths validated and sanitized
**Severity**: Critical

---

### SSRF (Server-Side Request Forgery)

**Search patterns**:
```bash
# HTTP requests with user-controlled URLs
grep -rE "requests\.(get|post|put|delete)\(.*request\.|httpx\.(get|post)\(.*request\." --include="*.py"

# aiohttp with user input
grep -rE "session\.(get|post)\(" --include="*.py" -B 5 | grep -E "request\.|params\."
```

**Pass criteria**: All external URLs validated against allowlist
**Severity**: High

---

### Insecure Deserialization

**Search patterns**:
```bash
# Pickle usage
grep -rE "pickle\.(load|loads)\(|cPickle\." --include="*.py"

# YAML unsafe load (must use SafeLoader or safe_load)
grep -rE "yaml\.load\(" --include="*.py" | grep -v "Loader=SafeLoader\|Loader=yaml\.SafeLoader\|safe_load"
```

**Pass criteria**: No pickle with untrusted data; YAML uses safe_load
**Severity**: Critical

---

### Weak Cryptography

**Search patterns**:
```bash
# MD5/SHA1 for passwords
grep -rE "md5\(|sha1\(" --include="*.py" | grep -iE "password|secret|token"

# Hardcoded crypto keys
grep -rE "key\s*=\s*['\"][^'\"]{8,}" --include="*.py"
```

**Pass criteria**: Use bcrypt/argon2 for passwords; no hardcoded keys
**Severity**: High

---

## Category: FastAPI Patterns

### Missing response_model

**Search patterns**:
```bash
# Routes without response_model
grep -rE "@(app|router)\.(get|post|put|patch|delete)\(" --include="*.py" | grep -v "response_model"
```

**Pass criteria**: All endpoints have explicit response_model
**Severity**: Medium

---

### Untyped Request Bodies

**Search patterns**:
```bash
# Route handlers with untyped parameters (missing Pydantic models)
grep -rE "@(app|router)\.(post|put|patch)\(" --include="*.py" -A 3 | grep -E "def\s+\w+\([^)]*:\s*(dict|Dict|Any)\b"

# Body() without type annotation
grep -rE "Body\(\.\.\.\)" --include="*.py"

# Parameters with generic dict type in route handlers
grep -rE "def\s+\w+\([^)]*:\s*dict\b" --include="*.py"
```

**Pass criteria**: All request bodies have Pydantic model types
**Severity**: High

---

### Missing Status Codes

**Search patterns**:
```bash
# POST without 201, DELETE without 204
grep -rE "@(app|router)\.post\(" --include="*.py" | grep -v "status_code"
grep -rE "@(app|router)\.delete\(" --include="*.py" | grep -v "status_code"
```

**Pass criteria**: Appropriate HTTP status codes for each operation
**Severity**: Low

---

### Sync Functions in Async Routes

**Search patterns**:
```bash
# Async route calling sync functions
grep -rE "async def.*:" --include="*.py" -A 20 | grep -E "time\.sleep|requests\.(get|post)|open\("
```

**Pass criteria**: Async routes use async I/O (httpx, aiofiles, asyncio.sleep)
**Severity**: High

---

### Missing Dependency Injection

**Search patterns**:
```bash
# Direct instantiation in routes
grep -rE "def\s+\w+\(" --include="*.py" -A 10 | grep -E "^\s+\w+\s*=\s*\w+Service\(|^\s+\w+\s*=\s*\w+Repository\("
```

**Pass criteria**: Services/repos injected via Depends()
**Severity**: Medium

---

### N+1 Query Patterns

**Search technique**:
- Look for loops that execute queries
- Check for missing eager loading

**Search patterns**:
```bash
# Queries inside loops
grep -rE "for\s+\w+\s+in" --include="*.py" -A 5 | grep -E "\.query\(|\.filter\(|\.get\("
```

**Pass criteria**: No queries inside loops; use eager loading
**Severity**: High

---

## Category: Pydantic Validation

### Missing Field Validators

**Search patterns**:
```bash
# Models without validators for sensitive fields
grep -rE "email:|password:|url:|phone:" --include="*.py" -B 5 -A 5 | grep -v "@validator\|@field_validator"
```

**Pass criteria**: Sensitive fields have validation
**Severity**: Medium

---

### Overly Permissive Models

**Search patterns**:
```bash
# Models that accept extra fields
grep -rE "extra\s*=\s*['\"]allow['\"]|Config:.*extra\s*=\s*'allow'" --include="*.py"

# Models with Any type
grep -rE ":\s*Any\b" --include="*.py"
```

**Pass criteria**: Models are strict; no arbitrary field acceptance
**Severity**: Medium

---

### Missing Field Constraints

**Search patterns**:
```bash
# String fields without max_length
grep -rE ":\s*str\s*$|:\s*str\s*=" --include="*.py" | grep -v "max_length\|Field\("

# Numeric fields without bounds
grep -rE ":\s*int\s*$|:\s*float\s*$" --include="*.py" | grep -v "ge=\|le=\|gt=\|lt=\|Field\("
```

**Pass criteria**: Fields have appropriate constraints
**Severity**: Low

---

### Untyped Optional Fields

**Search patterns**:
```bash
# Optional without explicit type
grep -rE "Optional\[Any\]|:\s*Optional\s*$" --include="*.py"

# None default without Optional
grep -rE "=\s*None\s*$" --include="*.py" | grep -v "Optional\|None\s*\|"
```

**Pass criteria**: Optional fields have explicit inner types
**Severity**: Medium

---

## Category: Async Patterns

### Blocking Calls in Async Functions

**Search patterns**:
```bash
# Blocking I/O in async
grep -rE "async def" --include="*.py" -A 30 | grep -E "time\.sleep\(|requests\.|open\(|\.read\(\)|\.write\("

# Blocking database calls
grep -rE "async def" --include="*.py" -A 30 | grep -E "\.execute\(|\.query\(" | grep -v "await"
```

**Pass criteria**: All I/O in async functions is awaited
**Severity**: Critical

---

### Missing Await Keywords

**Search patterns**:
```bash
# Find async function calls without await (two-step process):
# Step 1: Extract async function names defined in the codebase
grep -rE "async def (\w+)\(" --include="*.py" -ho | sed 's/async def //' | sed 's/($//' | sort -u

# Step 2: For each async function name, check for calls without await
# Example: if 'fetch_data' is async, search for calls not preceded by await
grep -rE "\bfetch_data\s*\(" --include="*.py" | grep -v "await\s\+fetch_data\|await fetch_data"

# Common async methods called without await
grep -rE "\.(read|write|execute|commit|send|recv|connect|close)\s*\(" --include="*.py" | grep -v "await"
```

**Pass criteria**: All coroutines are awaited
**Severity**: Critical

---

### Improper Task Handling

**Search patterns**:
```bash
# Fire-and-forget tasks
grep -rE "asyncio\.create_task\(" --include="*.py" | grep -v "await\|tasks\.append\|gather"

# Missing exception handling in tasks
grep -rE "create_task\(" --include="*.py" -A 10 | grep -v "try:\|except:"
```

**Pass criteria**: Background tasks are tracked and exceptions handled
**Severity**: High

---

### Missing Timeout Handling

**Search patterns**:
```bash
# HTTP requests without timeout
grep -rE "httpx\.(get|post|put|delete)\(|requests\.(get|post)" --include="*.py" | grep -v "timeout="

# aiohttp without timeout
grep -rE "session\.(get|post)\(" --include="*.py" | grep -v "timeout="
```

**Pass criteria**: All external calls have timeouts
**Severity**: High

---

### asyncio.gather 异常处理

**搜索模式**: `grep -rE "asyncio\.gather\(" --include="*.py" | grep -v "return_exceptions"`
**通过标准**: gather 需显式处理异常（return_exceptions=True 或 try/except 包裹每个 coroutine）
**严重级别**: High

---

### 全局可变状态

**搜索模式**: `grep -rE "^[a-zA-Z_]+\s*:\s*(dict|list|set|Dict|List|Set)\s*=" --include="*.py"` 或 `grep -rE "^[a-zA-Z_]+\s*=\s*(\{|\[)" --include="*.py"`
**通过标准**: ASGI 应用中禁止模块级可变变量在并发请求间共享（使用 contextvars 或依赖注入）
**严重级别**: Critical

```python
# 不推荐：模块级可变状态，多个请求并发修改
_cache: dict = {}

@app.get("/data")
async def get_data(key: str):
    if key not in _cache:
        _cache[key] = await fetch_data(key)  # 竞态条件
    return _cache[key]

# 推荐：使用依赖注入 + 线程安全容器
from cachetools import TTLCache
from asyncio import Lock

class CacheService:
    def __init__(self):
        self._cache = TTLCache(maxsize=100, ttl=300)
        self._lock = Lock()

    async def get(self, key: str):
        async with self._lock:
            if key not in self._cache:
                self._cache[key] = await fetch_data(key)
            return self._cache[key]
```

---

### 数据库连接池耗尽

**搜索模式**: `grep -rE "async_session\(|AsyncSession\(" --include="*.py" | grep -v "async with"`
**通过标准**: 数据库 session 必须使用 `async with` 确保归还连接池
**严重级别**: High

---

### asyncio.Lock 缺失

**搜索模式**: 检查异步函数中对共享资源的读写是否有 asyncio.Lock 保护
**通过标准**: 异步环境中保护共享可变资源需使用 asyncio.Lock
**严重级别**: Medium

---

### 异步生成器未清理

**搜索模式**: `grep -rE "async\s+def\s+\w+.*->.*AsyncGenerator|async\s+for" --include="*.py"`
**通过标准**: async generator 使用完毕需 aclose() 或通过 async with 清理
**严重级别**: Medium

---

### 并发写同一资源

**搜索模式**: 多个 async 函数写同一文件/缓存/共享变量
**通过标准**: 并发写操作需加 asyncio.Lock 或 asyncio.Semaphore
**严重级别**: High

---

## Category: Error Handling (Backend)

### Generic Exception Catches

**Search patterns**:
```bash
# Bare except or Exception catch
grep -rE "except\s*:|except\s+Exception:" --include="*.py"
```

**Pass criteria**: Catch specific exceptions, not bare Exception
**Severity**: Medium

---

### Missing HTTPException Usage

**Search patterns**:
```bash
# Routes that raise generic exceptions
grep -rE "raise\s+\w+Error\(|raise\s+Exception\(" --include="*.py" | grep -v "HTTPException"
```

**Pass criteria**: Routes raise HTTPException with proper status codes
**Severity**: Medium

---

### Swallowed Exceptions

**Search patterns**:
```bash
# Except with pass or continue
grep -rE "except.*:\s*$" --include="*.py" -A 1 | grep -E "pass$|continue$"

# Except with only logging
grep -rE "except.*:" --include="*.py" -A 2 | grep -E "logger\.(error|warning|info)" | grep -v "raise"
```

**Pass criteria**: Exceptions are handled or re-raised
**Severity**: High

---

### Missing Error Response Schemas

**Search patterns**:
```bash
# HTTPException without detail structure
grep -rE "HTTPException\(" --include="*.py" | grep -v "detail={"
```

**Pass criteria**: Error responses have consistent, typed structure
**Severity**: Low

---

## Category: Database/ORM

### N+1 Query Patterns

**Search technique**:
- Look for loops that execute queries
- Check for missing eager loading

**Search patterns**:
```bash
# Queries inside loops
grep -rE "for\s+\w+\s+in" --include="*.py" -A 5 | grep -E "\.query\(|\.filter\(|\.get\("
```

**Pass criteria**: No queries inside loops; use eager loading
**Severity**: High

---

## Category: 控制流

### if 嵌套禁止超过 3 层

**搜索技术**:
- 检查嵌套深度超过 3 层的 if 语句
- 使用缩进分析

**通过标准**: if 嵌套不超过 3 层
**严重级别**: Medium
**建议**: 使用提前 return 优化嵌套深度

```python
# 不推荐：嵌套超过 3 层
def process(data):
    if data is not None:
        if data.valid:
            if data.ready:
                if data.complete:  # 第 4 层，违规
                    # ...
    return None

# 推荐：提前 return 减少嵌套
def process(data):
    if data is None:
        return None
    if not data.valid:
        return None
    if not data.ready:
        return None
    if data.complete:
        # ...
    return result
```

---

### for 嵌套禁止超过 2 层

**搜索技术**:
- 检查嵌套深度超过 2 层的 for 循环
- 使用缩进分析

**通过标准**: for 循环嵌套不超过 2 层
**严重级别**: Medium
**建议**: 通过抽取方法或使用字典优化搜索

```python
# 不推荐：嵌套超过 2 层
for user in users:
    for order in user.orders:
        for item in order.items:  # 第 3 层，违规
            # ...

# 推荐方案1：抽取方法
def process_order_items(order):
    for item in order.items:
        # ...

for user in users:
    for order in user.orders:
        process_order_items(order)

# 推荐方案2：使用字典优化搜索
item_map = {item.id: item for item in items}
for order in orders:
    item = item_map.get(order.item_id)  # O(1) 查找
    # ...
```

---

### 条件表达式过长

**搜索模式**:
```bash
# 搜索 if 条件中包含超过 3 个 and 或 or 的语句
grep -rE "if\s+.*\s+(and|or)\s+.*\s+(and|or)\s+.*\s+(and|or)" --include="*.py"
```

**通过标准**: if 条件表达式中的条件数不超过 3 个
**严重级别**: Medium
**建议**: 将复杂条件提取为局部布尔变量，提高可读性

```python
# 不推荐：条件表达式过长
if user is not None and user.is_active and user.age > 18 and user.has_permission:
    # ...

# 推荐：提取局部布尔变量
is_valid_user = user is not None and user.is_active
is_adult_with_permission = user.age > 18 and user.has_permission
if is_valid_user and is_adult_with_permission:
    # ...
```

---

### 循环内数据库查询 (N+1 问题)

**搜索模式**:
```bash
# 搜索 for 循环内的数据库查询调用
grep -rE "for\s+\w+\s+in" --include="*.py" -A 5 | grep -E "\.query\(|\.filter\(|\.get\(|await.*find"
```

**通过标准**: 禁止在循环内执行数据库查询
**严重级别**: High
**建议**: 批量查询后转为字典进行处理

```python
# 不推荐：循环内查询（N+1 问题）
for user_id in user_ids:
    user = await user_repo.find_by_id(user_id)  # 每次循环都查询数据库
    # ...

# 推荐：批量查询 + 字典
users = await user_repo.find_by_ids(user_ids)  # 一次查询
user_map = {user.id: user for user in users}
for user_id in user_ids:
    user = user_map.get(user_id)  # 内存查找 O(1)
    # ...
```

---

### Missing Session Management

**Search patterns**:
```bash
# Sessions not closed or context-managed
grep -rE "Session\(\)" --include="*.py" | grep -v "with\s|yield"

# Raw connections not closed
grep -rE "\.connect\(\)" --include="*.py" -A 10 | grep -v "\.close\(\)|with\s"
```

**Pass criteria**: All sessions/connections properly managed
**Severity**: High

---

### Transactions Not Committed/Rolled Back

**Search patterns**:
```bash
# Begin without commit/rollback
grep -rE "\.begin\(\)" --include="*.py" -A 20 | grep -v "\.commit\(\)|\.rollback\(\)"

# Multiple writes without transaction
grep -rE "\.add\(|\.delete\(" --include="*.py" -B 5 | grep -v "begin\|transaction"
```

**Pass criteria**: Transactions explicitly committed or rolled back
**Severity**: High

---

### Lazy Loading in Async Context

**Search patterns**:
```bash
# Accessing relationships in async code
grep -rE "async def" --include="*.py" -A 30 | grep -E "\.\w+\.\w+\s*$|\.\w+\[" | grep -v "await"
```

**Pass criteria**: Use eager loading or explicit queries in async
**Severity**: High

---

### Missing Database Indexes

**Search technique**:
- Review model definitions for commonly queried fields
- Check if foreign keys and filter fields have indexes

**Search patterns**:
```bash
# Filter/order fields without index
grep -rE "\.filter\(.*==|\.order_by\(" --include="*.py"
# Compare with index definitions in models
```

**Pass criteria**: Frequently queried fields have indexes
**Severity**: Medium

---

### Raw SQL Without Parameterization

**Search patterns**:
```bash
# text() without bind parameters
grep -rE "text\(['\"].*\{|text\(f['\"]" --include="*.py"

# execute with string formatting
grep -rE "\.execute\(.*%.*%" --include="*.py"
```

**Pass criteria**: All raw SQL uses bind parameters
**Severity**: Critical

---

## 自动修复项 (Fix 模式 AUTO)

以下规则在 fix 模式下自动修复，review 模式下仅报告。

### 1. HTTP 请求 timeout

**检测**: `requests.get(url)` 无 timeout
**修复**: 添加 `timeout=30`

### 2. yaml.safe_load

**检测**: `yaml.load(data)`
**修复**: `yaml.safe_load(data)`

### 3. 空 except 块

**检测**: `except Exception: pass`
**修复**: 添加 `logger.error("Error occurred", exc_info=e)`

### 4. bare except

**检测**: `except:` 无异常类型
**修复**: `except Exception as e:`

### 5. f-string 日志

**检测**: `logger.info(f"User {user_id} logged in")`
**修复**: `logger.info("User %s logged in", user_id)`

### 6. 类型注解补充

**检测**: 函数参数无类型注解
**修复**: 根据使用推断添加类型

### 7. asyncio.gather 异常处理

**检测**: `asyncio.gather(...)` 无 `return_exceptions=True`
**修复**: 添加 `return_exceptions=True`

### 8. async session 上下文管理

**检测**: `session = async_session()` 未用 `async with`
**修复**: 改用 `async with async_session() as session:`

---

## 需确认修复项 (Fix 模式 CONFIRM)

以下改动在 fix 模式下需用户确认后执行，review 模式下作为建议输出。

### 1. 依赖注入

**检测**: 路由中直接实例化服务
**建议**: 使用 `Depends()`

### 2. Pydantic 模型

**检测**: dict 类型的请求体
**建议**: 创建 Pydantic 模型

### 3. async 改造

**检测**: sync 路由中使用阻塞 IO
**建议**: 改为 async + await

### 4. 抽取公共函数

**检测**: 重复代码块
**建议**: 抽取为独立函数

### 5. 全局可变状态重构

**检测**: 模块级 dict/list 被请求处理函数修改
**建议**: 改用依赖注入 + asyncio.Lock 或 contextvars

---

## SKIP 项 (禁止修改)

### 变量命名
即使不符合 PEP8 也不修改：函数名、变量名、参数名、类名

**仅在报告中提示**:
```
[SKIP] service.py:15 变量 `userName` 建议改为 `user_name`（已跳过，不修改变量名）
```
