# Java 简化模式

## 1. Optional 替代 null 检查链

```java
// Before
public String getCityName(User user) {
    if (user != null) {
        Address address = user.getAddress();
        if (address != null) {
            City city = address.getCity();
            if (city != null) {
                return city.getName();
            }
        }
    }
    return "Unknown";
}

// After
public String getCityName(User user) {
    return Optional.ofNullable(user)
            .map(User::getAddress)
            .map(Address::getCity)
            .map(City::getName)
            .orElse("Unknown");
}
```

Optional 链式调用消除了嵌套 null 检查。注意：Optional 用于返回值，不要用于字段或参数。

## 2. Stream API 替代命令式循环

```java
// Before
List<String> activeUserNames = new ArrayList<>();
for (User user : users) {
    if (user.isActive()) {
        String name = user.getName().toUpperCase();
        if (!activeUserNames.contains(name)) {
            activeUserNames.add(name);
        }
    }
}
Collections.sort(activeUserNames);

// After
List<String> activeUserNames = users.stream()
        .filter(User::isActive)
        .map(User::getName)
        .map(String::toUpperCase)
        .distinct()
        .sorted()
        .toList();
```

filter/map/collect 管道比循环+条件+手动去重更清晰。但超过 3-4 个操作时考虑拆分为多步。

## 3. Record 替代纯数据 POJO（Java 16+）

```java
// Before
public class Point {
    private final int x;
    private final int y;

    public Point(int x, int y) {
        this.x = x;
        this.y = y;
    }

    public int getX() { return x; }
    public int getY() { return y; }

    @Override
    public boolean equals(Object o) { ... }
    @Override
    public int hashCode() { ... }
    @Override
    public String toString() { ... }
}

// After
public record Point(int x, int y) {}
```

Record 自动生成构造函数、访问方法、equals、hashCode、toString。适用于不可变数据载体。

## 4. switch 表达式替代 switch 语句（Java 14+）

```java
// Before
String label;
switch (status) {
    case ACTIVE:
        label = "Active";
        break;
    case INACTIVE:
        label = "Inactive";
        break;
    case PENDING:
        label = "Pending Review";
        break;
    default:
        label = "Unknown";
        break;
}

// After
String label = switch (status) {
    case ACTIVE -> "Active";
    case INACTIVE -> "Inactive";
    case PENDING -> "Pending Review";
    default -> "Unknown";
};
```

switch 表达式有返回值、不需要 break、编译器检查是否穷尽所有分支。

## 5. Lombok 减少样板代码

```java
// Before
public class UserDTO {
    private String name;
    private String email;
    private int age;

    public UserDTO() {}

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public int getAge() { return age; }
    public void setAge(int age) { this.age = age; }

    // equals, hashCode, toString ...
}

// After
@Data
public class UserDTO {
    private String name;
    private String email;
    private int age;
}
```

项目已引入 Lombok 时，用 `@Data`、`@Builder`、`@RequiredArgsConstructor` 替代手写样板。未引入 Lombok 时不建议为此引入依赖。

## 语言特有反模式

- 过度使用继承 — 优先组合，继承层级不超过 2 层
- 为每个类写 interface — 只在有多实现或测试替换需求时才建 interface
- catch Exception — 捕获具体异常，避免吞掉意外错误
- 手写 Builder — 项目有 Lombok 时用 `@Builder`
- StringBuffer 在非多线程场景 — 用 StringBuilder
- 日期用 `java.util.Date` — 用 `java.time` API（LocalDate、Instant 等）
