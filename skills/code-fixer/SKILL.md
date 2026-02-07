---
name: code-fixer
description: 自动修复代码以符合编码规范（阿里巴巴 Java 规范 / 字节跳动 Go 规范）。检测 diff 中的代码问题并自动修复。小问题（格式、缩进、冗余 else、缺失注解等）自动修复；大改动（方法抽离、新增构造函数、架构调整）需用户确认。严格禁止修改用户定义的变量名。触发：用户说 "修复代码"、"fix code"、"自动修复"、"规范化代码"、"/code-fixer"。
---

# Code Fixer

自动修复代码以符合编码规范。基于阿里巴巴 Java 规范和字节跳动 Go 规范。

## 核心原则

### 保持功能不变

**绝不改变代码的行为。** 这是 code-fixer 的根本约束。

- 所有原有功能、输出和行为必须保持完整
- 只改变"怎么做"，不改变"做什么"

### 绝对禁止

**禁止修改用户定义的变量名、函数名、类名、参数名。** 这是最高优先级规则。

```go
// 即使 userCnt 不符合规范，也禁止修改
userCnt := 10  // 不改成 userCount
```

```java
// 即使 isValid 不符合 POJO 规范，也禁止修改
private Boolean isValid;  // 不改成 valid
```

### 修复分类

| 类型 | 自动修复 | 需确认 |
|------|---------|--------|
| 格式问题 | 换行、缩进、空格 | - |
| 简单重构 | 冗余 else、early return | 方法拆分 |
| 缺失元素 | @Override、defer Close | 新增构造函数 |
| 错误处理 | 错误包装格式 | 逻辑重构 |
| 性能优化 | slice/map 预分配 | 大规模改动 |

---

## 修复流程

### Step 1: 获取 Diff

如无 diff，询问用户或生成：
```bash
git diff          # 未暂存
git diff --cached # 已暂存
git diff HEAD~1   # 最近提交
```

### Step 2: 域检测

| 扩展名 | 域 | 参考 |
|--------|-----|------|
| `*.java` | Java | `references/java.md` |
| `*.go` | Go | `references/go.md` |
| `*.tsx/jsx` | Frontend | `references/frontend.md` |
| `*.py` | Backend | `references/backend.md` |

### Step 3: 分类问题

- **AUTO**: 直接修复
- **CONFIRM**: 需用户确认
- **SKIP**: 涉及命名，禁止修改

### Step 4: 执行修复

1. AUTO 类：直接用 Edit 工具修复
2. CONFIRM 类：用 AskUserQuestion 汇总询问
3. SKIP 类：仅在报告中提示

### Step 5: 输出报告

```markdown
## 修复完成

### 自动修复 (已完成)
- [file:line] 描述

### 用户确认 (已执行/已跳过)
- [file:line] 描述 - 状态

### 跳过 (禁止修改)
- [file:line] 原因
```

---

## 自动修复项 (AUTO)

### 通用

#### 单行超长
超过 120 字符，在运算符/逗号后换行。

#### 冗余 else
```go
// 前                    // 后
if err != nil {         if err != nil {
    return err              return err
} else {                }
    return nil          return nil
}
```

#### 空 catch 块
```java
// 前                           // 后
catch (Exception e) {}          catch (Exception e) {
                                    log.error("Error", e);
                                }
```

### Java

| 问题 | 修复 |
|------|------|
| 缺少 @Override | 自动添加 |
| `100l` | 改 `100L` |
| `log.info("x" + y)` | 改 `log.info("x {}", y)` |
| switch 无 default | 添加 default |
| if/else 无大括号 | 添加大括号 |

### Go

| 问题 | 修复 |
|------|------|
| 格式不规范 | 运行 gofmt |
| `return err` | 改 `return fmt.Errorf("...: %w", err)` |
| Open 后无 defer Close | 添加 `defer f.Close()` |
| Lock 后无 defer Unlock | 添加 `defer mu.Unlock()` |
| append 循环无预分配 | 添加 `make([]T, 0, len)` |
| 字符串循环拼接 | 改用 `strings.Builder` |

### Frontend

| 问题 | 修复 |
|------|------|
| map 无 key | 添加 `key={item.id}` |
| index 作为 key | 改用唯一 id |

### Backend

| 问题 | 修复 |
|------|------|
| requests 无 timeout | 添加 `timeout=30` |
| yaml.load | 改 `yaml.safe_load` |

---

## 需确认项 (CONFIRM)

以下改动需用户确认后执行：

### 方法拆分
- Go 函数 > 50 行
- Java 方法 > 70 行
- 提供拆分方案，等待确认

### if 嵌套优化
- 检测到 if 嵌套超过 3 层
- 建议使用提前 return 减少嵌套
- 提供重构方案，等待确认

```go
// 检测到深嵌套
if a {
    if b {
        if c {
            if d {  // 第 4 层
                // ...
            }
        }
    }
}

// 建议重构为
if !a { return }
if !b { return }
if !c { return }
if d {
    // ...
}
```

### for 嵌套优化
- 检测到 for 嵌套超过 2 层
- 建议抽取方法或使用 Map 优化
- 提供重构方案，等待确认

```java
// 检测到深嵌套
for (User user : users) {
    for (Order order : user.getOrders()) {
        for (Item item : order.getItems()) {  // 第 3 层
            // ...
        }
    }
}

// 建议重构为
for (User user : users) {
    for (Order order : user.getOrders()) {
        processOrderItems(order);  // 抽取方法
    }
}
```

### 条件表达式拆分
- 检测到 if 条件超过 3 个条件
- 建议提取为局部布尔变量
- 提供重构方案，等待确认

```java
// 检测到复杂条件
if (user != null && user.isActive() && user.getAge() > 18 && user.hasPermission()) {
    // ...
}

// 建议重构为
boolean isValidUser = user != null && user.isActive();
boolean isAdultWithPermission = user.getAge() > 18 && user.hasPermission();
if (isValidUser && isAdultWithPermission) {
    // ...
}
```

### 循环内查询优化
- 检测到循环内 SQL/数据库查询
- 建议批量查询后转 Map
- 提供重构方案，等待确认

```java
// 检测到 N+1 问题
for (Long userId : userIds) {
    User user = userRepository.findById(userId);
    // ...
}

// 建议重构为
List<User> users = userRepository.findByIdIn(userIds);
Map<Long, User> userMap = users.stream()
    .collect(Collectors.toMap(User::getId, Function.identity()));
for (Long userId : userIds) {
    User user = userMap.get(userId);
    // ...
}
```

### 新增构造函数 (Go)
```go
// 检测到直接赋值
svc := &UserService{}
svc.repo = repo

// 建议添加
func NewUserService(repo Repository) *UserService {
    return &UserService{repo: repo}
}
```

### 抽取公共逻辑
检测到重复代码，建议抽取为独立函数。

### 添加 context 参数
Go 函数涉及 IO/RPC 但无 context，建议添加。

### 架构调整
- 依赖注入改造
- 跨文件改动

---

## 确认交互

存在 CONFIRM 项时：

```
检测到需确认的改动：

1. [file.go:45] processData (68行) 建议拆分
2. [service.go:12] 建议添加 NewUserService 构造函数

请选择要执行的改动：
□ 1. 拆分 processData
□ 2. 添加构造函数
□ 全部执行
□ 全部跳过
```

---

## 注意事项

1. **变量名绝对不改** - 只在报告中提示
2. **保持功能不变** - 只改形式不改逻辑
3. **增量修改** - 每次修改后验证
4. **建议先 commit** - 便于回滚
5. **透明度** - 所有修改都列出
