# Java Review Checklist (阿里巴巴规范)

基于《阿里巴巴 Java 开发手册》的代码审查检查项。

添加以下分类到汇总表：
- 代码格式 (Java)
- 命名规约 (Java)
- OOP 规约
- 集合处理
- 并发处理
- 异常日志
- MySQL 规约
- 安全规约 (Java)

---

## Category: 代码格式 (Java)

### 方法行数限制

**检查方式**:
```bash
# 统计每个方法的行数，找出超过 70 行的方法
awk '/^\s*(public|private|protected).*\(.*\)\s*\{/{start=NR; name=$0} /^\s*\}/{if(start && NR-start>70) print FILENAME":"start": "name" ("NR-start" lines)"; start=0}' *.java
```

**通过标准**: 单个方法不超过 70 行
**严重级别**: Medium
**建议**: 超过 70 行的方法应拆分为多个小方法

---

### 单行字符数限制

**检查方式**:
```bash
# 找出超过 120 字符的行
awk 'length > 120 {print FILENAME":"NR": ("length" chars)"}' *.java
```

**通过标准**: 单行字符数不超过 120 个，超过时在合适位置换行
**严重级别**: Low
**自动修复**: 在运算符、逗号、点号后换行，下一行适当缩进

```java
// 超过 120 字符时换行示例
String result = someService.processData(param1, param2,
    param3, param4);

boolean isValid = StringUtils.isNotEmpty(name) && value > 0
    && status == Status.ACTIVE;

// 长字符串用 + 分行连接
String message = "This is a very long error message that exceeds "
    + "the maximum line length limit and needs to be split "
    + "into multiple lines for better readability";
```

---

### 方法调用必要注释

**检查要点**:
- 复杂业务逻辑的方法调用需注释说明目的
- 非直观的参数含义需注释
- 外部服务/RPC 调用需注释

**通过标准**: 关键方法调用有必要的注释说明
**严重级别**: Low

```java
// 推荐：关键调用添加注释
// 校验用户权限，无权限会抛出 AuthException
permissionService.checkPermission(userId, resourceId);

// 发送异步通知，失败会重试3次
notifyService.sendAsync(notification);

// 不推荐：复杂调用无注释
userService.process(data, 1, true, null);
```

---

## Category: 命名规约 (Java)

### 禁止特殊字符开头结尾

**搜索模式**:
```bash
# 下划线或美元符开头的变量/方法名
grep -rE "(private|public|protected)?\s*(static)?\s*\w+\s+[_$]\w+\s*[=;(]" --include="*.java"

# 下划线结尾
grep -rE "\w+_\s*[=;)]" --include="*.java"
```

**通过标准**: 命名不以下划线或美元符开头/结尾
**严重级别**: High

---

### 布尔属性禁止 is 前缀

**搜索模式**:
```bash
# POJO 类中 is 开头的布尔属性
grep -rE "(private|public)\s+(boolean|Boolean)\s+is[A-Z]\w*\s*[=;]" --include="*.java"
```

**通过标准**: POJO 类布尔属性不以 is 开头（避免序列化问题）
**严重级别**: High

---

### 常量命名规范

**搜索模式**:
```bash
# 常量未使用全大写
grep -rE "static\s+final\s+\w+\s+[a-z]" --include="*.java" | grep -v "serialVersionUID"

# 小写字母 l 作为 long 后缀
grep -rE "=\s*\d+l\s*;" --include="*.java"
```

**通过标准**: 常量全大写下划线分隔；long 使用大写 L
**严重级别**: Medium

---

### 魔法值

**搜索模式**:
```bash
# 直接使用数字（非 0、1、-1）
grep -rE "==\s*[2-9]\d*|[2-9]\d*\s*==" --include="*.java"
grep -rE "if\s*\([^)]*[2-9]\d*[^)]*\)" --include="*.java"
```

**通过标准**: 不允许魔法值直接出现在代码中，应定义为常量
**严重级别**: Medium

---

## Category: OOP 规约

### @Override 注解

**搜索模式**:
```bash
# 重写方法缺少 @Override（检查父类方法同名）
grep -rE "^\s*(public|protected)\s+\w+\s+\w+\s*\([^)]*\)\s*\{" --include="*.java" -B 1 | grep -v "@Override"
```

**通过标准**: 所有覆写方法必须加 @Override 注解
**严重级别**: Medium

---

### equals 空指针风险

**搜索模式**:
```bash
# 变量调用 equals 与常量比较
grep -rE '\w+\.equals\s*\(\s*"[^"]*"\s*\)' --include="*.java"

# 可能为 null 的对象调用 equals
grep -rE "(\w+)\s*!=\s*null\s*&&\s*\1\.equals" --include="*.java"
```

**通过标准**: 使用常量或确定非空对象调用 equals，如 `"constant".equals(variable)`
**严重级别**: High

---

### 包装类比较

**搜索模式**:
```bash
# Integer/Long 等包装类使用 == 比较
grep -rE "(Integer|Long|Short|Byte|Character|Boolean)\s+\w+.*==\s*(Integer|Long|Short|Byte|Character|Boolean|\w+)" --include="*.java"
```

**通过标准**: 包装类对象间比较必须使用 equals 方法
**严重级别**: High

---

### POJO 属性使用包装类

**搜索模式**:
```bash
# POJO 类中使用基本类型
grep -rE "private\s+(int|long|double|float|boolean|short|byte|char)\s+\w+\s*;" --include="*DTO.java" --include="*VO.java" --include="*DO.java" --include="*Entity.java"
```

**通过标准**: POJO 类属性必须使用包装数据类型
**严重级别**: High

---

### 构造方法含业务逻辑

**搜索模式**:
```bash
# 构造方法中调用业务方法
grep -rE "public\s+\w+\s*\([^)]*\)\s*\{" --include="*.java" -A 10 | grep -E "\.(save|insert|update|delete|query|find|get\w+From|send|call)"
```

**通过标准**: 构造方法禁止加入任何业务逻辑
**严重级别**: Medium

---

### POJO 缺少 toString

**搜索技术**:
- 检查 DTO/VO/DO/Entity 类是否有 toString 方法
- 或是否使用 @Data/@ToString 注解

**通过标准**: POJO 类必须写 toString 方法
**严重级别**: Low

---

## Category: 集合处理

### hashCode 一致性

**搜索模式**:
```bash
# 重写 equals 但未重写 hashCode
grep -rE "public\s+boolean\s+equals\s*\(" --include="*.java" -l | xargs grep -L "public\s+int\s+hashCode\s*\("
```

**通过标准**: 重写 equals 必须重写 hashCode
**严重级别**: Critical

---

### subList 强转

**搜索模式**:
```bash
# subList 结果强转为 ArrayList
grep -rE "\(ArrayList[^)]*\)\s*\w+\.subList\(" --include="*.java"
```

**通过标准**: ArrayList.subList() 结果不可强转成 ArrayList
**严重级别**: High

---

### Arrays.asList 修改

**搜索模式**:
```bash
# asList 结果调用修改方法
grep -rE "Arrays\.asList\([^)]+\)\s*\.(add|remove|clear)" --include="*.java"
grep -rE "\w+\s*=\s*Arrays\.asList" --include="*.java" -A 3 | grep -E "\.(add|remove|clear)\("
```

**通过标准**: Arrays.asList() 返回的集合禁止调用修改方法
**严重级别**: High

---

### foreach 中 remove/add

**搜索模式**:
```bash
# foreach 循环中调用 remove/add
grep -rE "for\s*\([^:]+:\s*\w+\)" --include="*.java" -A 5 | grep -E "\.(remove|add)\("
```

**通过标准**: 不要在 foreach 循环里进行元素的 remove/add 操作，使用 Iterator
**严重级别**: High

---

## Category: 并发处理

### 线程池创建方式

**搜索模式**:
```bash
# 使用 Executors 创建线程池
grep -rE "Executors\.(newFixedThreadPool|newSingleThreadExecutor|newCachedThreadPool|newScheduledThreadPool)\(" --include="*.java"
```

**通过标准**: 禁止使用 Executors 创建线程池，必须通过 ThreadPoolExecutor 方式
**严重级别**: Critical

---

### SimpleDateFormat 线程安全

**搜索模式**:
```bash
# static SimpleDateFormat
grep -rE "static\s+(final\s+)?SimpleDateFormat" --include="*.java"

# 成员变量 SimpleDateFormat
grep -rE "private\s+(final\s+)?SimpleDateFormat" --include="*.java"
```

**通过标准**: SimpleDateFormat 不要定义为 static 或成员变量，使用 DateTimeFormatter
**严重级别**: High

---

### 线程命名

**搜索模式**:
```bash
# 未指定线程名的 Thread 创建
grep -rE "new\s+Thread\s*\(\s*[^,)]*\s*\)" --include="*.java" | grep -v "\".*\""

# ThreadFactory 未设置名称
grep -rE "ThreadPoolExecutor\s*\(" --include="*.java" | grep -v "ThreadFactory\|NamedThreadFactory"
```

**通过标准**: 创建线程或线程池必须指定有意义的线程名称
**严重级别**: Medium

---

### 显式创建线程

**搜索模式**:
```bash
# 直接 new Thread
grep -rE "new\s+Thread\s*\(" --include="*.java"
grep -rE "\.start\s*\(\s*\)" --include="*.java" -B 2 | grep "new\s+Thread"
```

**通过标准**: 线程资源必须通过线程池提供，不允许显式创建线程
**严重级别**: High

---

### 双重检查锁

**搜索模式**:
```bash
# 单例模式检查 volatile
grep -rE "private\s+static\s+\w+\s+instance" --include="*.java" | grep -v "volatile"
```

**通过标准**: 双重检查锁的单例需要 volatile 修饰
**严重级别**: High

---

### HashMap 多线程使用

**搜索模式**: `grep -rE "new\s+HashMap<|HashMap<.*>\s+\w+\s*=" --include="*.java"` 结合上下文检查是否被多线程访问
**通过标准**: 多线程场景不使用 HashMap，改用 ConcurrentHashMap
**严重级别**: Critical
**示例**: `HashMap` → `ConcurrentHashMap` 或加锁保护

---

### ArrayList 多线程使用

**搜索模式**: `grep -rE "new\s+ArrayList<" --include="*.java"` 结合上下文检查
**通过标准**: 多线程写入场景不使用 ArrayList，改用 CopyOnWriteArrayList 或加锁
**严重级别**: High

---

### ConcurrentModificationException 风险

**搜索模式**: `grep -rE "for\s*\([^:]+:\s*\w+\)" --include="*.java" -A 5 | grep -E "\.(remove|add|clear)\("`
**通过标准**: 遍历时不直接修改集合，使用 Iterator.remove() 或 ConcurrentHashMap
**严重级别**: High

---

### synchronized 锁对象不当

**搜索模式**: `grep -rE "synchronized\s*\(\s*(\"[^\"]*\"|[A-Z].*\.valueOf|Integer|Long|Boolean)" --include="*.java"`
**通过标准**: 禁止使用 String 常量、包装类缓存实例作为锁对象
**严重级别**: High

```java
// 不推荐：String 常量池导致不同逻辑共享同一个锁
synchronized ("lock") { ... }
synchronized (Integer.valueOf(1)) { ... }

// 推荐：使用专用锁对象
private final Object lock = new Object();
synchronized (lock) { ... }
```

---

### synchronized 范围过大

**搜索模式**: `grep -rE "synchronized\s+(public|private|protected)" --include="*.java"`
**通过标准**: 避免整个方法加 synchronized，应缩小到最小临界区
**严重级别**: Medium

---

### volatile 不保证原子性

**搜索模式**: `grep -rE "volatile\s+" --include="*.java"` 结合检查是否有 `++`/`--`/`+=` 复合操作
**通过标准**: volatile 变量不做复合操作（如 count++），应使用 AtomicInteger
**严重级别**: High

```java
// 不推荐：volatile 不保证 ++ 原子性
private volatile int count;
count++;  // 非原子操作

// 推荐
private final AtomicInteger count = new AtomicInteger();
count.incrementAndGet();
```

---

### ThreadLocal 未清理

**搜索模式**: `grep -rE "ThreadLocal<" --include="*.java"` + 检查是否有 `.remove()` 调用
**通过标准**: 线程池环境下 ThreadLocal 必须在 finally 中 remove()
**严重级别**: High

```java
// 不推荐
threadLocal.set(value);
doSomething();

// 推荐
threadLocal.set(value);
try {
    doSomething();
} finally {
    threadLocal.remove();
}
```

---

### Spring 单例 Bean 含可变状态

**搜索模式**: `grep -rE "@(Service|Component|Repository|Controller|RestController)" --include="*.java" -A 20 | grep -E "private\s+(List|Map|Set|int|long|boolean|String)\s+\w+\s*[=;]" | grep -v "final"`
**通过标准**: @Service/@Component 等单例 Bean 禁止定义非 final 可变成员变量
**严重级别**: Critical

```java
// 不推荐：单例 Bean 中的可变状态
@Service
public class UserService {
    private Map<String, User> cache = new HashMap<>();  // 多线程共享，非线程安全
}

// 推荐方案1：使用线程安全容器
private final ConcurrentHashMap<String, User> cache = new ConcurrentHashMap<>();

// 推荐方案2：使用 ThreadLocal
private final ThreadLocal<Map<String, User>> cache = ThreadLocal.withInitial(HashMap::new);
```

---

### ReentrantLock 未在 finally 释放

**搜索模式**: `grep -rE "\.lock\(\)" --include="*.java" -A 5 | grep -v "finally" | grep -v "try"`
**通过标准**: ReentrantLock.lock() 后必须在 try-finally 中 unlock()
**严重级别**: Critical

```java
// 不推荐
lock.lock();
doSomething();
lock.unlock();  // 如果 doSomething 抛异常，锁永远不释放

// 推荐
lock.lock();
try {
    doSomething();
} finally {
    lock.unlock();
}
```

---

### CompletableFuture 异常丢失

**搜索模式**: `grep -rE "CompletableFuture\." --include="*.java" | grep -v "exceptionally\|handle\|whenComplete"`
**通过标准**: CompletableFuture 链必须处理异常
**严重级别**: High

---

### CountDownLatch 异常路径未 countDown

**搜索模式**: `grep -rE "CountDownLatch" --include="*.java"` 结合检查 countDown 是否在 finally 中
**通过标准**: countDown() 必须在 finally 中调用，防止异常导致 await 永久阻塞
**严重级别**: High

---

## Category: 异常日志

### 空 catch 块

**搜索模式**:
```bash
# 空的 catch 块
grep -rE "catch\s*\([^)]+\)\s*\{\s*\}" --include="*.java"

# catch 只有注释
grep -rE "catch\s*\([^)]+\)\s*\{" --include="*.java" -A 2 | grep -E "^\s*//.*\s*\}$"
```

**通过标准**: 捕获异常必须处理，不能吞掉
**严重级别**: High

---

### finally 中 return

**搜索模式**:
```bash
# finally 块中 return
grep -rE "finally\s*\{" --include="*.java" -A 10 | grep -E "^\s*return\s+"
```

**通过标准**: 不能在 finally 块中使用 return
**严重级别**: Critical

---

### 日志框架直接使用

**搜索模式**:
```bash
# 直接使用 Log4j/Logback API
grep -rE "import\s+org\.apache\.log4j\." --include="*.java"
grep -rE "import\s+ch\.qos\.logback\." --include="*.java"
grep -rE "Logger\.getLogger\(" --include="*.java"
```

**通过标准**: 使用 SLF4J 门面，不直接使用日志实现 API
**严重级别**: Medium

---

### 日志占位符

**搜索模式**:
```bash
# 字符串拼接打日志
grep -rE "log\.(debug|info|trace)\s*\([^)]*\+" --include="*.java"
grep -rE "logger\.(debug|info|trace)\s*\([^)]*\+" --include="*.java"
```

**通过标准**: debug/info/trace 级别日志使用占位符 {}，不使用字符串拼接
**严重级别**: Medium

---

### 异常日志信息完整

**搜索模式**:
```bash
# catch 中只打印 message，丢失堆栈
grep -rE "catch\s*\([^)]+\s+(\w+)\s*\)" --include="*.java" -A 3 | grep -E "log\.(error|warn)\([^,]+\)$"
```

**通过标准**: 异常日志必须包含案发现场信息和异常堆栈（第二个参数传 e）
**严重级别**: High

---

## Category: MySQL 规约

### 表必备字段

**搜索技术**:
- 检查建表语句是否包含 id, gmt_create, gmt_modified
- 检查 Entity 类是否有这三个字段

**通过标准**: 表必备三字段: id, gmt_create, gmt_modified
**严重级别**: Medium

---

### 禁止 SELECT *

**搜索模式**:
```bash
# SQL 中使用 SELECT *
grep -rE "SELECT\s+\*\s+FROM" --include="*.java" --include="*.xml" -i
grep -rE '"\s*SELECT\s+\*' --include="*.java" -i
```

**通过标准**: 查询一律不使用 * 作为查询字段列表
**严重级别**: High

---

### SQL 注入风险

**搜索模式**:
```bash
# MyBatis 使用 ${}
grep -rE "\$\{[^}]+\}" --include="*.xml"

# 字符串拼接 SQL
grep -rE '"\s*(SELECT|INSERT|UPDATE|DELETE).*"\s*\+' --include="*.java" -i
```

**通过标准**: SQL 参数使用 #{} 绑定，禁止使用 ${} 或字符串拼接
**严重级别**: Critical

---

### 禁止三表以上 JOIN

**搜索模式**:
```bash
# 多表 JOIN
grep -rE "JOIN.*JOIN.*JOIN" --include="*.xml" --include="*.java" -i
```

**通过标准**: 超过三个表禁止 join
**严重级别**: Medium

---

### 更新必改 gmt_modified

**搜索模式**:
```bash
# UPDATE 语句未更新 gmt_modified
grep -rE "UPDATE\s+\w+" --include="*.xml" -i -A 5 | grep -v "gmt_modified"
```

**通过标准**: 更新数据表记录时，必须同时更新 gmt_modified 字段值
**严重级别**: Medium

---

## Category: 安全规约 (Java)

### SQL 参数绑定

**搜索模式**:
```bash
# PreparedStatement 使用字符串拼接
grep -rE "Statement\s*\(" --include="*.java"
grep -rE "createQuery\s*\([^)]*\+" --include="*.java"
```

**通过标准**: 用户输入的 SQL 参数严格使用参数绑定，禁止字符串拼接
**严重级别**: Critical

---

### XSS 防护

**搜索模式**:
```bash
# 直接输出用户数据到 HTML
grep -rE "response\.getWriter\(\)\.write\(" --include="*.java"
grep -rE "out\.print\(" --include="*.jsp"
```

**通过标准**: 禁止向 HTML 页面输出未经安全过滤或未正确转义的用户数据
**严重级别**: Critical

---

### 敏感数据脱敏

**搜索模式**:
```bash
# 日志打印敏感字段
grep -rE "log\.(info|debug|error)\([^)]*\b(password|idCard|phone|mobile|bankCard|credit)" --include="*.java" -i
```

**通过标准**: 用户敏感数据禁止直接展示，必须脱敏
**严重级别**: High

---

### 权限校验

**搜索技术**:
- 检查 Controller 方法是否有权限注解
- 检查是否验证用户对资源的所有权

**搜索模式**:
```bash
# Controller 方法无权限注解
grep -rE "@(GetMapping|PostMapping|PutMapping|DeleteMapping)" --include="*.java" -B 3 | grep -v "@PreAuthorize\|@Secured\|@RequiresPermission"
```

**通过标准**: 用户相关页面或功能必须进行权限控制校验
**严重级别**: High

---

## Category: 控制语句

### switch 缺少 default

**搜索模式**:
```bash
# switch 无 default
grep -rE "switch\s*\([^)]+\)\s*\{" --include="*.java" -A 30 | grep -v "default\s*:"
```

**通过标准**: switch 块必须包含 default 语句
**严重级别**: Medium

---

### if/else 缺少大括号

**搜索模式**:
```bash
# if 后无大括号
grep -rE "if\s*\([^)]+\)\s*[^{]" --include="*.java" | grep -v "//"
grep -rE "else\s+[^{]" --include="*.java" | grep -v "else\s+if"
```

**通过标准**: if/else/for/while/do 语句必须使用大括号
**严重级别**: Medium

---

### if 嵌套禁止超过 3 层

**搜索技术**:
- 检查嵌套深度超过 3 层的条件语句
- 使用缩进分析或 AST 工具

**通过标准**: if 嵌套不超过 3 层
**严重级别**: Medium
**建议**: 使用提前 return 优化嵌套深度

```java
// 不推荐：嵌套超过 3 层
if (condition1) {
    if (condition2) {
        if (condition3) {
            if (condition4) {  // 第 4 层，违规
                // ...
            }
        }
    }
}

// 推荐：提前 return 减少嵌套
if (!condition1) {
    return;
}
if (!condition2) {
    return;
}
if (!condition3) {
    return;
}
if (condition4) {
    // ...
}
```

---

### for 嵌套禁止超过 2 层

**搜索技术**:
- 检查嵌套深度超过 2 层的 for 循环
- 使用缩进分析或 AST 工具

**通过标准**: for 循环嵌套不超过 2 层
**严重级别**: Medium
**建议**: 通过抽取方法或使用 Map 优化搜索

```java
// 不推荐：嵌套超过 2 层
for (User user : users) {
    for (Order order : user.getOrders()) {
        for (Item item : order.getItems()) {  // 第 3 层，违规
            // ...
        }
    }
}

// 推荐方案1：抽取方法
for (User user : users) {
    for (Order order : user.getOrders()) {
        processOrderItems(order);  // 抽取内层循环
    }
}

// 推荐方案2：使用 Map 优化搜索
Map<Long, Item> itemMap = items.stream()
    .collect(Collectors.toMap(Item::getId, Function.identity()));
for (Order order : orders) {
    Item item = itemMap.get(order.getItemId());  // O(1) 查找
    // ...
}
```

---

### 条件表达式过长

**搜索模式**:
```bash
# 搜索 if 条件中包含超过 3 个 && 或 || 的语句
grep -rE "if\s*\([^)]*(\&\&|\|\|)[^)]*(\&\&|\|\|)[^)]*(\&\&|\|\|)" --include="*.java"
```

**通过标准**: if 条件表达式中的条件数不超过 3 个
**严重级别**: Medium
**建议**: 将复杂条件提取为局部布尔变量，提高可读性

```java
// 不推荐：条件表达式过长
if (user != null && user.isActive() && user.getAge() > 18 && user.hasPermission()) {
    // ...
}

// 推荐：提取局部布尔变量
boolean isValidUser = user != null && user.isActive();
boolean isAdultWithPermission = user.getAge() > 18 && user.hasPermission();
if (isValidUser && isAdultWithPermission) {
    // ...
}
```

---

### 循环内 SQL 查询 (N+1 问题)

**搜索模式**:
```bash
# 搜索 for/while 循环内的 SQL 查询调用
grep -rE "for\s*\([^)]+\)\s*\{" --include="*.java" -A 10 | grep -E "\.(find|query|select|get).*\("
grep -rE "while\s*\([^)]+\)\s*\{" --include="*.java" -A 10 | grep -E "\.(find|query|select|get).*\("
```

**通过标准**: 禁止在循环内执行 SQL 查询
**严重级别**: High
**建议**: 批量查询后转为 Map 进行处理

```java
// 不推荐：循环内查询（N+1 问题）
for (Long userId : userIds) {
    User user = userRepository.findById(userId);  // 每次循环都查询数据库
    // ...
}

// 推荐：批量查询 + Map
List<User> users = userRepository.findByIdIn(userIds);  // 一次查询
Map<Long, User> userMap = users.stream()
    .collect(Collectors.toMap(User::getId, Function.identity()));
for (Long userId : userIds) {
    User user = userMap.get(userId);  // 内存查找 O(1)
    // ...
}
```

---

### 连续 if 判断转 switch

**搜索模式**:
```bash
# 连续 3 个以上对同一变量的 if-else if 判断
grep -rE "if\s*\(\s*\w+\s*(==|\.equals)" --include="*.java" -A 2 | grep -E "else\s+if.*\1"
```

**通过标准**: 超过 3 个连续的同类型 if 判断应转为 switch
**严重级别**: Low
**建议**: 使用 switch 提高可读性和性能

```java
// 不推荐：连续 if 判断
if (type == 1) {
    // ...
} else if (type == 2) {
    // ...
} else if (type == 3) {
    // ...
} else if (type == 4) {
    // ...
}

// 推荐：转为 switch
switch (type) {
    case 1: // ...
        break;
    case 2: // ...
        break;
    case 3: // ...
        break;
    case 4: // ...
        break;
    default: // ...
}
```

---

## Category: 正则表达式

### Pattern 预编译

**搜索模式**:
```bash
# 方法内部编译正则
grep -rE "Pattern\.compile\s*\(" --include="*.java" -B 5 | grep -E "(public|private|protected)\s+\w+\s+\w+\s*\("
```

**通过标准**: 正则表达式使用预编译，不要在方法体内定义 Pattern
**严重级别**: Medium

---
