# Go Review Checklist (字节跳动规范)

基于字节跳动 Go 语言编码规范的代码审查检查项。

添加以下分类到汇总表：
- 代码格式 (Go)
- 命名规范 (Go)
- 错误处理
- 并发安全
- 性能优化
- 控制流

---

## Category: 代码格式 (Go)

### 代码格式化

**检查方式**:
```bash
# 检查是否通过 gofmt 格式化
gofmt -d *.go
```

**通过标准**: 所有代码必须通过 gofmt 格式化
**严重级别**: High

---

### 函数行数限制

**检查方式**:
```bash
# 统计函数行数，找出超过 50 行的函数
awk '/^func /{start=NR; name=$0} /^\}/{if(start && NR-start>50) print FILENAME":"start": "name" ("NR-start" lines)"; start=0}' *.go
```

**通过标准**: 单个函数不超过 50 行
**严重级别**: Medium
**建议**: 超过 50 行的函数应拆分为多个小函数

---

### 单行字符数限制

**检查方式**:
```bash
# 找出超过 120 字符的行
awk 'length > 120 {print FILENAME":"NR": ("length" chars)"}' *.go
```

**通过标准**: 单行字符数不超过 120 个
**严重级别**: Low
**自动修复**: 在合适位置换行

```go
// 超过 120 字符时换行示例
result, err := someService.ProcessData(ctx, param1, param2,
    param3, param4)

// 长字符串分行
message := "This is a very long error message that exceeds " +
    "the maximum line length limit"
```

---

### 依赖注入使用构造函数

**搜索模式**:
```bash
# 直接赋值结构体字段（非构造函数注入）
grep -rE "^\s+\w+\.\w+\s*=\s*&?\w+\{" --include="*.go"

# 检查是否有 New 构造函数
grep -rE "^func\s+New\w+\(" --include="*.go"
```

**通过标准**: 依赖通过构造函数（NewXxx）注入，不直接赋值字段
**严重级别**: Medium

```go
// 推荐：构造函数注入
func NewUserService(repo UserRepository, cache Cache) *UserService {
    return &UserService{
        repo:  repo,
        cache: cache,
    }
}

// 不推荐：直接赋值字段
svc := &UserService{}
svc.repo = repo
svc.cache = cache
```

---

## Category: 命名规范 (Go)

### 包名规范

**搜索模式**:
```bash
# 包名含下划线或大写
grep -rE "^package\s+[A-Z_]" --include="*.go"
grep -rE "^package\s+\w*_\w*" --include="*.go"
```

**通过标准**: 包名全小写，不含下划线，简短有意义
**严重级别**: Medium

---

### 导出命名

**搜索模式**:
```bash
# 导出函数/类型未使用大驼峰
grep -rE "^func\s+[a-z]" --include="*.go" | grep -v "^func\s+(.*)\s+"
grep -rE "^type\s+[a-z]" --include="*.go"
```

**通过标准**: 导出的函数、类型、常量首字母大写
**严重级别**: Medium

---

### 缩写命名

**搜索模式**:
```bash
# ID/URL/HTTP 等缩写未全大写
grep -rE "\b(Id|Url|Http|Api|Sql|Json|Xml)\b" --include="*.go"
```

**通过标准**: 缩写词全大写（ID, URL, HTTP, API）
**严重级别**: Low

---

### 变量命名简洁

**检查要点**:
- 局部变量名简短
- 循环变量用单字母 i, j, k
- 接收者名用类型首字母小写

**通过标准**: 变量名简洁有意义，避免冗长
**严重级别**: Low

```go
// 推荐
for i, v := range items {}
func (s *Server) Start() {}

// 不推荐
for index, value := range items {}
func (server *Server) Start() {}
```

---

## Category: 错误处理

### 错误必须处理

**搜索模式**:
```bash
# 忽略错误返回值
grep -rE "\w+,\s*_\s*:?=\s*\w+\(" --include="*.go"
grep -rE "^\s*\w+\([^)]*\)\s*$" --include="*.go"
```

**通过标准**: 所有返回 error 的函数调用必须检查错误
**严重级别**: Critical

---

### 错误包装

**搜索模式**:
```bash
# 直接返回错误未包装
grep -rE "return\s+err\s*$" --include="*.go"
grep -rE "return\s+nil,\s*err\s*$" --include="*.go"
```

**通过标准**: 错误需用 fmt.Errorf + %w 包装，提供上下文
**严重级别**: Medium

```go
// 推荐
if err != nil {
    return fmt.Errorf("failed to process user %d: %w", userID, err)
}

// 不推荐
if err != nil {
    return err
}
```

---

### panic 使用限制

**搜索模式**:
```bash
# 业务代码中使用 panic
grep -rE "\bpanic\(" --include="*.go" | grep -v "_test.go\|main.go"
```

**通过标准**: panic 仅用于不可恢复的启动失败，业务代码禁用
**严重级别**: High

---

### recover 使用

**搜索模式**:
```bash
# recover 未在 defer 中
grep -rE "\brecover\(\)" --include="*.go" -B 3 | grep -v "defer"
```

**通过标准**: recover 只能在 defer 函数中使用
**严重级别**: High

---

## Category: 并发安全

### 数据竞争

**检查方式**:
```bash
# 使用 race detector
go test -race ./...
```

**通过标准**: 无数据竞争
**严重级别**: Critical

---

### goroutine 泄漏

**搜索模式**:
```bash
# 无限制启动 goroutine
grep -rE "go\s+func\(" --include="*.go" | grep -v "sync.WaitGroup\|context\|select"
```

**通过标准**: goroutine 必须有退出机制（context/channel/WaitGroup）
**严重级别**: High

---

### channel 未关闭

**搜索模式**:
```bash
# make(chan) 后未 close
grep -rE "make\(chan\s+" --include="*.go" -l | xargs grep -L "close\("
```

**通过标准**: 发送方负责关闭 channel
**严重级别**: Medium

---

### 锁使用

**搜索模式**:
```bash
# Lock 后未 defer Unlock
grep -rE "\.Lock\(\)" --include="*.go" -A 1 | grep -v "defer.*Unlock"
```

**通过标准**: Lock 后立即 defer Unlock
**严重级别**: High

```go
// 推荐
mu.Lock()
defer mu.Unlock()

// 不推荐
mu.Lock()
// ... 代码 ...
mu.Unlock()
```

---

### 原子操作

**搜索模式**:
```bash
# 简单计数器使用锁而非 atomic
grep -rE "sync\.Mutex" --include="*.go" -A 10 | grep -E "\+\+|--|\+="
```

**通过标准**: 单变量操作优先使用 atomic
**严重级别**: Low

---

### WaitGroup.Add 位置不当

**搜索模式**: `grep -rE "go\s+func" --include="*.go" -A 3 | grep "wg\.Add"`
**通过标准**: wg.Add() 必须在 go func 之前调用，禁止在 goroutine 内部调用
**严重级别**: High

```go
// 不推荐：goroutine 内 Add，可能 Wait 先于 Add 执行
for _, item := range items {
    go func(it Item) {
        wg.Add(1)  // 错误位置
        defer wg.Done()
        process(it)
    }(item)
}

// 推荐
for _, item := range items {
    wg.Add(1)
    go func(it Item) {
        defer wg.Done()
        process(it)
    }(item)
}
```

---

### goroutine 闭包变量捕获

**搜索模式**: `grep -rE "for\s+.*:=\s*range" --include="*.go" -A 5 | grep "go\s+func"`（Go < 1.22）
**通过标准**: for 循环中启动 goroutine 必须通过参数传递循环变量
**严重级别**: High

```go
// 不推荐（Go < 1.22）
for _, item := range items {
    go func() {
        process(item)  // item 始终是最后一个值
    }()
}

// 推荐
for _, item := range items {
    item := item  // 或通过参数传递
    go func() {
        process(item)
    }()
}
```

---

### map 并发读写

**搜索模式**: `grep -rE "map\[" --include="*.go"` 结合上下文检查是否被多 goroutine 访问
**通过标准**: 多 goroutine 读写 map 必须用 sync.Map 或 mutex 保护
**严重级别**: Critical

---

### Context 取消未检查

**搜索模式**: `grep -rE "go\s+func" --include="*.go" -A 20 | grep -v "ctx\.Done\|ctx\.Err\|select"`
**通过标准**: 长时间运行的 goroutine 必须检查 ctx.Done()
**严重级别**: Medium

```go
// 不推荐
go func() {
    for {
        doWork()  // 永远不会退出
    }
}()

// 推荐
go func() {
    for {
        select {
        case <-ctx.Done():
            return
        default:
            doWork()
        }
    }
}()
```

---

### sync.Once 中的 panic

**搜索模式**: `grep -rE "sync\.Once" --include="*.go" -A 5 | grep -v "recover"`
**通过标准**: 注意 sync.Once.Do 中 panic 后，后续调用不会重试执行
**严重级别**: Medium

---

### errgroup 错误处理

**搜索模式**: `grep -rE "errgroup" --include="*.go" -l | xargs grep -L "\.Wait()"` 或 `Wait() 返回值未检查`
**通过标准**: errgroup.Wait() 返回的 error 必须检查
**严重级别**: Medium

---

### 无缓冲 channel 死锁

**搜索模式**: `grep -rE "make\(chan\s+\w+\s*\)" --include="*.go"` 检查同一函数内发送和接收
**通过标准**: 无缓冲 channel 的发送和接收不能在同一 goroutine
**严重级别**: High

---

### 共享 slice append

**搜索模式**: 多 goroutine 对同一 slice 使用 append
**通过标准**: 并发 append 到同一 slice 不安全，需 mutex 保护或使用 channel 收集
**严重级别**: High

---

### time.After 循环泄漏

**搜索模式**: `grep -rE "for\s*\{" --include="*.go" -A 10 | grep "time\.After"`
**通过标准**: for-select 循环中禁止使用 time.After（每次创建新 timer），改用 time.NewTimer + Reset
**严重级别**: Medium

```go
// 不推荐：每次循环创建新 timer，旧 timer 不会被 GC 直到触发
for {
    select {
    case <-ch:
        handle()
    case <-time.After(5 * time.Second):  // 泄漏
        timeout()
    }
}

// 推荐
timer := time.NewTimer(5 * time.Second)
defer timer.Stop()
for {
    select {
    case <-ch:
        handle()
        if !timer.Stop() {
            <-timer.C
        }
        timer.Reset(5 * time.Second)
    case <-timer.C:
        timeout()
        timer.Reset(5 * time.Second)
    }
}
```

---

### mutex 拷贝

**搜索模式**: `go vet` 可检测，或 `grep -rE "func\s+\(\w+\s+\w+\)" --include="*.go"` 值接收者包含 mutex
**通过标准**: 包含 sync.Mutex/sync.WaitGroup 的结构体禁止值拷贝，使用指针接收者
**严重级别**: Critical

---

## Category: 性能优化

### slice 预分配

**搜索模式**:
```bash
# append 循环未预分配
grep -rE "for.*\{" --include="*.go" -A 5 | grep "append\("
```

**通过标准**: 已知长度的 slice 应预分配容量
**严重级别**: Medium

```go
// 推荐
result := make([]int, 0, len(items))
for _, item := range items {
    result = append(result, item.Value)
}

// 不推荐
var result []int
for _, item := range items {
    result = append(result, item.Value)
}
```

---

### map 预分配

**搜索模式**:
```bash
# 循环中填充 map 未预分配
grep -rE "make\(map\[" --include="*.go" | grep -v ",\s*\d"
```

**通过标准**: 已知大小的 map 应预分配容量
**严重级别**: Low

```go
// 推荐
m := make(map[string]int, len(items))

// 不推荐
m := make(map[string]int)
```

---

### 字符串拼接

**搜索模式**:
```bash
# 循环中使用 + 拼接字符串
grep -rE "for.*\{" --include="*.go" -A 5 | grep -E '\+.*string|string.*\+'
```

**通过标准**: 多次拼接使用 strings.Builder
**严重级别**: Medium

```go
// 推荐
var builder strings.Builder
for _, s := range items {
    builder.WriteString(s)
}
result := builder.String()

// 不推荐
var result string
for _, s := range items {
    result += s
}
```

---

### 空 struct 占位

**搜索模式**:
```bash
# map 用于 set 时 value 非 struct{}
grep -rE "map\[.*\]bool" --include="*.go"
```

**通过标准**: 用 map 实现 set 时，value 使用 struct{}
**严重级别**: Low

---

## Category: 控制流

### if 嵌套禁止超过 3 层

**搜索技术**:
- 检查嵌套深度超过 3 层的 if 语句
- 使用缩进分析或 AST 工具

**通过标准**: if 嵌套不超过 3 层
**严重级别**: Medium
**建议**: 使用提前 return 优化嵌套深度

```go
// 不推荐：嵌套超过 3 层
func process(data *Data) error {
    if data != nil {
        if data.Valid {
            if data.Ready {
                if data.Complete {  // 第 4 层，违规
                    // ...
                }
            }
        }
    }
    return nil
}

// 推荐：提前 return 减少嵌套
func process(data *Data) error {
    if data == nil {
        return errors.New("data is nil")
    }
    if !data.Valid {
        return errors.New("data is invalid")
    }
    if !data.Ready {
        return errors.New("data is not ready")
    }
    if data.Complete {
        // ...
    }
    return nil
}
```

---

### for 嵌套禁止超过 2 层

**搜索技术**:
- 检查嵌套深度超过 2 层的 for 循环
- 使用缩进分析或 AST 工具

**通过标准**: for 循环嵌套不超过 2 层
**严重级别**: Medium
**建议**: 通过抽取方法或使用 map 优化搜索

```go
// 不推荐：嵌套超过 2 层
for _, user := range users {
    for _, order := range user.Orders {
        for _, item := range order.Items {  // 第 3 层，违规
            // ...
        }
    }
}

// 推荐方案1：抽取方法
for _, user := range users {
    for _, order := range user.Orders {
        processOrderItems(order)  // 抽取内层循环
    }
}

// 推荐方案2：使用 map 优化搜索
itemMap := make(map[int64]*Item, len(items))
for _, item := range items {
    itemMap[item.ID] = item
}
for _, order := range orders {
    item := itemMap[order.ItemID]  // O(1) 查找
    // ...
}
```

---

### 条件表达式过长

**搜索模式**:
```bash
# 搜索 if 条件中包含超过 3 个 && 或 || 的语句
grep -rE "if\s+[^{]*(\&\&|\|\|)[^{]*(\&\&|\|\|)[^{]*(\&\&|\|\|)" --include="*.go"
```

**通过标准**: if 条件表达式中的条件数不超过 3 个
**严重级别**: Medium
**建议**: 将复杂条件提取为局部布尔变量，提高可读性

```go
// 不推荐：条件表达式过长
if user != nil && user.Active && user.Age > 18 && user.HasPermission {
    // ...
}

// 推荐：提取局部布尔变量
isValidUser := user != nil && user.Active
isAdultWithPermission := user.Age > 18 && user.HasPermission
if isValidUser && isAdultWithPermission {
    // ...
}
```

---

### 循环内数据库查询 (N+1 问题)

**搜索模式**:
```bash
# 搜索 for 循环内的数据库查询调用
grep -rE "for\s+.*range" --include="*.go" -A 10 | grep -E "\.(Find|Query|Get|First|Select|Where).*\("
```

**通过标准**: 禁止在循环内执行数据库查询
**严重级别**: High
**建议**: 批量查询后转为 map 进行处理

```go
// 不推荐：循环内查询（N+1 问题）
for _, userID := range userIDs {
    user, err := repo.FindByID(ctx, userID)  // 每次循环都查询数据库
    if err != nil {
        return err
    }
    // ...
}

// 推荐：批量查询 + map
users, err := repo.FindByIDs(ctx, userIDs)  // 一次查询
if err != nil {
    return err
}
userMap := make(map[int64]*User, len(users))
for _, user := range users {
    userMap[user.ID] = user
}
for _, userID := range userIDs {
    user := userMap[userID]  // 内存查找 O(1)
    // ...
}
```

---

### 减少嵌套

**搜索技术**:
- 检查 if 嵌套超过 3 层
- 检查是否可用早返回减少嵌套

**通过标准**: 优先处理错误/特殊情况并尽早返回
**严重级别**: Medium

```go
// 推荐：早返回
func process(data *Data) error {
    if data == nil {
        return errors.New("data is nil")
    }
    if !data.Valid {
        return errors.New("data is invalid")
    }
    // 正常逻辑
    return nil
}

// 不推荐：深嵌套
func process(data *Data) error {
    if data != nil {
        if data.Valid {
            // 正常逻辑
            return nil
        }
        return errors.New("data is invalid")
    }
    return errors.New("data is nil")
}
```

---

### 冗余 else

**搜索模式**:
```bash
# if return 后有 else
grep -rE "return.*\n\s*\}\s*else\s*\{" --include="*.go"
```

**通过标准**: if 分支有 return，去掉 else
**严重级别**: Low

```go
// 推荐
if err != nil {
    return err
}
return nil

// 不推荐
if err != nil {
    return err
} else {
    return nil
}
```

---

## Category: 资源管理

### defer 关闭资源

**搜索模式**:
```bash
# Open 后未 defer Close
grep -rE "\.Open\(|os\.Open\(" --include="*.go" -A 3 | grep -v "defer.*Close"
```

**通过标准**: 打开的资源必须 defer 关闭
**严重级别**: High

---

### context 传递

**搜索模式**:
```bash
# 函数缺少 context 参数
grep -rE "^func\s+\w+\([^)]*\)" --include="*.go" | grep -v "ctx\s+context\.Context\|_test\.go"
```

**通过标准**: 涉及 IO/RPC 的函数第一个参数应为 context.Context
**严重级别**: Medium

---

### HTTP 响应体关闭

**搜索模式**:
```bash
# http.Get 后未关闭 Body
grep -rE "http\.(Get|Post|Do)\(" --include="*.go" -A 5 | grep -v "resp\.Body\.Close\|defer"
```

**通过标准**: HTTP 响应使用后必须关闭 Body
**严重级别**: High

```go
// 推荐
resp, err := http.Get(url)
if err != nil {
    return err
}
defer resp.Body.Close()
```

---

## Category: 测试

### 表驱动测试

**检查要点**:
- 测试用例使用 table-driven 风格
- 使用 t.Run 进行子测试

**通过标准**: 多场景测试使用表驱动方式
**严重级别**: Low

---

### 测试覆盖率

**检查方式**:
```bash
go test -cover ./...
```

**通过标准**: 核心逻辑测试覆盖率 > 60%
**严重级别**: Medium

---

## 自动修复项 (Fix 模式 AUTO)

以下规则在 fix 模式下自动修复，review 模式下仅报告。

### 1. gofmt 格式化

**检测**: 代码未通过 gofmt
**修复**: 运行 `gofmt -w <file>`

### 2. 冗余 else 删除

**检测**: if 块已 return，else 块多余
**修复**: 删除 else，将代码提升到外层

### 3. 错误包装

**检测**: `return err` 或 `return nil, err`
**修复**: `return fmt.Errorf("描述操作失败: %w", err)`

### 4. defer Close

**检测**: `os.Open`/`os.Create`/`http.Get` 等返回需关闭资源后无 defer Close
**修复**: 添加 `defer f.Close()`

### 5. defer Unlock

**检测**: `mu.Lock()` 后手动 `mu.Unlock()`
**修复**: 改用 `defer mu.Unlock()`

### 6. slice 预分配

**检测**: `var result []T` + 循环 append
**修复**: `result := make([]T, 0, len(items))`

### 7. map 预分配

**检测**: `make(map[K]V)` 后循环填充
**修复**: `make(map[K]V, len(items))`

### 8. strings.Builder

**检测**: 循环内字符串 `+=` 拼接
**修复**: 改用 `strings.Builder`

### 9. HTTP Body 关闭

**检测**: `http.Get/Post/Do` 后无 `resp.Body.Close()`
**修复**: 添加 `defer resp.Body.Close()`

### 10. WaitGroup.Add 位置修正

**检测**: `wg.Add()` 在 goroutine 内部
**修复**: 移动到 `go func` 之前

### 11. 闭包变量捕获修正

**检测**: for-range + go func 引用循环变量
**修复**: 添加 `item := item` 或通过函数参数传递

### 12. time.After 循环泄漏修正

**检测**: for-select 中使用 `time.After`
**修复**: 改用 `time.NewTimer` + Reset

---

## 需确认修复项 (Fix 模式 CONFIRM)

以下改动在 fix 模式下需用户确认后执行，review 模式下作为建议输出。

### 1. 新增构造函数

**检测**: 直接 `&Struct{}` 赋值多字段
**建议**: 添加 `NewXxx()` 构造函数

### 2. 添加 context 参数

**检测**: 函数涉及 IO/RPC 但第一个参数非 `ctx context.Context`
**建议**: 添加 `ctx context.Context` 作为第一个参数

### 3. 抽取公共函数

**检测**: 重复代码块（>5 行相似）
**建议**: 抽取为独立函数

### 4. map → sync.Map 或加 mutex

**检测**: 多 goroutine 读写普通 map
**建议**: 改用 sync.Map 或添加 sync.RWMutex 保护

### 5. 共享 slice → mutex 保护

**检测**: 多 goroutine append 同一 slice
**建议**: 添加 mutex 保护或使用 channel 收集结果

---

## SKIP 项 (禁止修改)

### 变量命名
即使不符合规范也不修改：
- `userCnt` 不改 `userCount`
- `Id` 不改 `ID`
- `Url` 不改 `URL`

**仅在报告中提示**:
```
[SKIP] service.go:15 变量 `userCnt` 建议改为 `userCount`（已跳过，不修改变量名）
```
