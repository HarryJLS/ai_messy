# Go 简化模式

## 1. 表驱动替代多 if-else

```go
// Before
func getStatusText(code int) string {
    if code == 200 {
        return "OK"
    } else if code == 404 {
        return "Not Found"
    } else if code == 500 {
        return "Internal Server Error"
    }
    return "Unknown"
}

// After
var statusText = map[int]string{
    200: "OK",
    404: "Not Found",
    500: "Internal Server Error",
}

func getStatusText(code int) string {
    if text, ok := statusText[code]; ok {
        return text
    }
    return "Unknown"
}
```

数据和逻辑分离，新增状态码只需加一行 map 条目。

## 2. 错误处理链简化

```go
// Before
func processOrder(id string) (*Order, error) {
    user, err := getUser(id)
    if err != nil {
        return nil, fmt.Errorf("failed to get user: %w", err)
    }
    order, err := createOrder(user)
    if err != nil {
        return nil, fmt.Errorf("failed to create order: %w", err)
    }
    err = sendNotification(order)
    if err != nil {
        return nil, fmt.Errorf("failed to send notification: %w", err)
    }
    return order, nil
}

// After — 当 wrap message 没有提供额外信息时直接返回
func processOrder(id string) (*Order, error) {
    user, err := getUser(id)
    if err != nil {
        return nil, err
    }
    order, err := createOrder(user)
    if err != nil {
        return nil, err
    }
    if err := sendNotification(order); err != nil {
        return nil, err
    }
    return order, nil
}
```

只在 wrap 能提供调用方无法推断的上下文时才用 `fmt.Errorf`。函数名本身已经说明了上下文。

## 3. defer 简化资源管理

```go
// Before
func readConfig(path string) ([]byte, error) {
    f, err := os.Open(path)
    if err != nil {
        return nil, err
    }
    data, err := io.ReadAll(f)
    if err != nil {
        f.Close()
        return nil, err
    }
    f.Close()
    return data, nil
}

// After
func readConfig(path string) ([]byte, error) {
    f, err := os.Open(path)
    if err != nil {
        return nil, err
    }
    defer f.Close()
    return io.ReadAll(f)
}
```

defer 消除了每个错误路径上的手动关闭。

## 4. 避免不必要的 interface

```go
// Before — 只有一个实现，且无测试替换需求
type UserRepository interface {
    FindByID(id string) (*User, error)
}

type userRepo struct{ db *sql.DB }
func (r *userRepo) FindByID(id string) (*User, error) { ... }

// After — 直接用具体类型
type UserRepo struct{ db *sql.DB }
func (r *UserRepo) FindByID(id string) (*User, error) { ... }
```

Go 的 interface 是隐式实现的。消费方在需要时自己定义 interface，生产方不需要预先声明。

## 5. 利用命名返回值简化复杂函数

```go
// Before
func parse(input string) (string, int, error) {
    name := ""
    age := 0
    // ... 复杂解析逻辑，多个 return 点
    if err != nil {
        return "", 0, err
    }
    return name, age, nil
}

// After
func parse(input string) (name string, age int, err error) {
    // ... 复杂解析逻辑
    if err != nil {
        return // 零值自动返回
    }
    return
}
```

命名返回值在多返回值 + 多错误路径时减少重复。注意：简单函数不需要这样做。

## 6. 方法提取

将多职责函数拆分为 unexported 辅助函数。提取后在调用链的跳转处加注释。

**Go 特有考虑**：
- 提取的函数用小写开头（unexported）
- struct 方法提取为同 struct 的 unexported 方法
- error 返回值保持在调用链中传播

```go
// Before — 一个方法做四件事
func (s *UserService) CreateUser(req CreateUserReq) (*User, error) {
    // 校验
    if req.Email == "" {
        return nil, errors.New("email is required")
    }
    if !isValidEmail(req.Email) {
        return nil, errors.New("invalid email format")
    }

    // 查重
    existing, err := s.repo.FindByEmail(req.Email)
    if err != nil {
        return nil, err
    }
    if existing != nil {
        return nil, ErrDuplicateEmail
    }

    // 创建
    user := &User{
        Email:     req.Email,
        Name:      req.Name,
        CreatedAt: time.Now(),
    }
    if err := s.repo.Save(user); err != nil {
        return nil, err
    }

    // 发欢迎邮件
    s.mailer.SendWelcome(user.Email, user.Name)
    return user, nil
}

// After — 编排入口 + unexported 方法
func (s *UserService) CreateUser(req CreateUserReq) (*User, error) {
    if err := s.validateCreateUser(req); err != nil {
        return nil, err
    }
    // 重复注册返回 ErrDuplicateEmail，调用方据此决定是否走登录流程
    if err := s.checkDuplicateEmail(req.Email); err != nil {
        return nil, err
    }
    user, err := s.saveUser(req)
    if err != nil {
        return nil, err
    }
    // 异步发送，失败不影响注册结果
    s.sendWelcomeEmail(user)
    return user, nil
}

func (s *UserService) validateCreateUser(req CreateUserReq) error {
    if req.Email == "" {
        return errors.New("email is required")
    }
    if !isValidEmail(req.Email) {
        return errors.New("invalid email format")
    }
    return nil
}

func (s *UserService) checkDuplicateEmail(email string) error {
    existing, err := s.repo.FindByEmail(email)
    if err != nil {
        return err
    }
    if existing != nil {
        return ErrDuplicateEmail
    }
    return nil
}

func (s *UserService) saveUser(req CreateUserReq) (*User, error) {
    user := &User{
        Email:     req.Email,
        Name:      req.Name,
        CreatedAt: time.Now(),
    }
    if err := s.repo.Save(user); err != nil {
        return nil, err
    }
    return user, nil
}

func (s *UserService) sendWelcomeEmail(user *User) {
    s.mailer.SendWelcome(user.Email, user.Name)
}
```

注释加在两个跳转处：`checkDuplicateEmail` 的错误会影响调用方的分支决策，`sendWelcomeEmail` 是非关键路径。

## 语言特有反模式

- `init()` 中做复杂初始化 — 改为显式调用的 `Setup()` 函数
- channel 只用于同步而无数据传输 — 考虑用 `sync.WaitGroup` 或 `sync.Mutex`
- 过度使用 `interface{}` / `any` — 尽可能用泛型（Go 1.18+）或具体类型
- 字符串拼接循环 — 用 `strings.Builder`
- 忽略 error（`_ = doSomething()`）— 至少 log 一下或写注释解释为什么安全忽略
