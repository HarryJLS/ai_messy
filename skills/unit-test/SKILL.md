
---
name: unit-test
description: Auto-detect project language and generate unit tests using appropriate patterns. Supports Go (Mockey + Testify) and Java (Spock or JUnit). Use when asked to write tests, create test cases, or add unit tests.
---

# Unit Test Skill

Auto-detect project language and generate unit tests using appropriate patterns and frameworks.

## Supported Languages

| Language | Detection | Framework | Reference |
|----------|-----------|-----------|-----------|
| Go | `go.mod` | Mockey + Testify (Table-Driven) | [go-mockey-testify.md](references/go-mockey-testify.md) |
| Java | `pom.xml` or `build.gradle` | Spock or JUnit 5 | [java-spock.md](references/java-spock.md) / [java-junit.md](references/java-junit.md) |

---

## Workflow

### Step 1: Language Detection

Check project root for build files:

```
┌─ go.mod exists?
│  └─ YES → Go Project → Use Mockey + Testify
│
├─ pom.xml exists?
│  └─ YES → Java (Maven) → Proceed to Java Flow
│
├─ build.gradle exists?
│  └─ YES → Java (Gradle) → Proceed to Java Flow
│
└─ None found → Ask user to specify language
```

### Step 2: Go Project Flow

**If Go project detected:**

1. Read `references/go-mockey-testify.md` for patterns
2. Generate tests using:
   - Table-Driven Tests (`[]struct` + `t.Run`)
   - Mockey for mocking (`mockey.Mock().To().Build()`)
   - Testify for assertions (`assert.Equal`, `assert.NoError`)
3. Remind user about required flags:
   ```bash
   go test -gcflags="all=-l -N" -v ./...
   ```

### Step 3: Java Project Flow

```
Detect Java project
    │
    ├─ Check for existing Spock
    │   - Search pom.xml/build.gradle for "spock-core"
    │   - Check for src/test/groovy/**/*.groovy files
    │
    │   ┌─ Has Spock?
    │   │  └─ YES → Use Spock style
    │   │          Read references/java-spock.md
    │   │
    │   └─ NO → Prompt user
    │
    └─ User prompt: "Add Spock dependencies?"
        │
        ├─ YES → Detect JDK version
        │        Add dependencies (see Step 3a)
        │        Use Spock style
        │
        └─ NO → Check for existing JUnit style
                Use JUnit 5 style
                Read references/java-junit.md
```

### Step 3a: JDK Version Detection (for Spock)

When adding Spock dependencies, detect **编译版本** (compile version):

> **重要**: 项目通常使用 Java 8 编译，但在 JDK 21 环境运行。Spock 依赖版本由**编译版本**决定，而非运行时版本。

**检测优先级:**

```
1. pom.xml / build.gradle 中的编译版本 (主要)
2. Dockerfile 中的运行时版本 (参考)
```

**Maven (`pom.xml`):**
```xml
<!-- 检查这些属性 -->
<java.version>1.8</java.version>
<!-- 或 -->
<maven.compiler.source>1.8</maven.compiler.source>
<maven.compiler.target>1.8</maven.compiler.target>
```

**Gradle (`build.gradle`):**
```groovy
sourceCompatibility = JavaVersion.VERSION_1_8
targetCompatibility = JavaVersion.VERSION_1_8
```

**Dockerfile (运行时环境参考):**
```dockerfile
# 常见模式: Java 8 编译 + JDK 21 运行
FROM openjdk:21-jdk-slim
# 或
FROM eclipse-temurin:21-jre
# 或 Java 8 编译 + JDK 8 运行
FROM openjdk:8-jdk-alpine
```

**版本选择规则:**

| 编译版本 | 运行时 | Spock 版本 | Groovy GroupId |
|---------|--------|-----------|----------------|
| Java 8 | JDK 8/21 | `2.3-groovy-3.0` | `org.codehaus.groovy` |
| Java 11 | JDK 11/21 | `2.3-groovy-3.0` | `org.codehaus.groovy` |
| Java 17+ | JDK 17/21 | `2.4-M4-groovy-4.0` | `org.apache.groovy` |

> **默认推荐**: 大多数项目使用 Java 8 编译，应使用 **Spock 2.3 + Groovy 3.x**

Read `references/java-dependencies.md` for full configuration.

### Step 3b: 检测现有测试文件

**根据源文件路径，确定对应的测试文件位置：**

| 语言 | 源文件 | 测试文件 |
|------|--------|----------|
| Go | `foo/bar.go` | `foo/bar_test.go` |
| Java (JUnit) | `src/main/java/.../Service.java` | `src/test/java/.../ServiceTest.java` |
| Java (Spock) | `src/main/java/.../Service.java` | `src/test/groovy/.../ServiceSpec.groovy` |

**检测逻辑：**

```
检查测试文件是否存在?
├─ 存在 → 读取现有测试文件，在其基础上追加新测试方法
│         注意：保持现有测试风格和结构
│
└─ 不存在 → 创建新测试文件
```

> **重要**: 如果测试文件已存在，必须先读取其内容，在现有方法列表末尾追加新的测试方法，而非覆盖创建新文件。

### Step 4: Scan Existing Tests

Before generating tests, scan for existing test patterns:

```
src/test/
├─ groovy/  → Check for Spock patterns
├─ java/    → Check for JUnit patterns
└─ resources/
```

**Match existing style:**
- If project uses `@DisplayName` → Continue with that style
- If project uses Chinese descriptions in Spock → Continue with that style
- If project has specific assertion library → Use same library

---

## Test Generation Guidelines

### For All Languages

1. **Understand the code first**: Read the source file thoroughly
2. **Identify test scenarios**:
   - Happy path (normal flow)
   - Edge cases (null, empty, boundary values)
   - Error cases (exceptions, failures)
3. **Use meaningful test names**: Describe what is being tested and expected outcome
4. **Keep tests isolated**: Each test should be independent

### Go Specific

> **注意**: 生成测试时，注释中的路径和函数名需替换为实际值（如 `./pkg/service/...` 和 `Test_OrderService_CreateOrder`）

```go
// 运行命令：go test -gcflags="all=-l -N" -v ./path/to/package/... -run Test_FunctionName
func Test_MethodName(t *testing.T) {
    defer mockey.OffAll()  // 清理所有 Mock

    type args struct { /* 输入参数 */ }
    type mocks struct { /* Mock 行为控制 */ }

    tests := []struct {
        name    string  // 测试场景描述（使用中文）
        args    args
        mocks   mocks
        want    interface{}
        wantErr bool
    }{
        {
            name: "正常流程_成功返回",  // 描述测试场景
            // ...
        },
        {
            name: "异常流程_无效输入",  // 描述预期失败场景
            // ...
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Given: 准备测试数据和 Mock
            // When: 执行被测方法
            // Then: 验证返回结果
        })
    }
}
```

### Java Spock Specific

> **优先原则：当存在多个测试场景时，优先使用 `@Unroll` + `where` 数据表枚举，而非写多个独立测试方法。** 这样更简洁、可读性更好、易于扩展新场景。

```groovy
@Unroll
def "测试下单流程_#scenario"() {
    given: "准备测试数据"
    def input = new InputDTO(userId: userId, amount: amount)

    and: "模拟依赖行为"
    mockService.checkInventory(_) >> hasInventory

    when: "执行被测方法 - 调用下单接口"
    def result = target.placeOrder(input)

    then: "验证结果"
    result.success == expectedSuccess
    result.status == expectedStatus

    where: "枚举多种下单场景"
    scenario       | userId | amount  | hasInventory || expectedSuccess | expectedStatus
    "正常下单"     | 1L     | 100.00  | true         || true            | "CREATED"
    "库存不足"     | 1L     | 100.00  | false        || false           | "OUT_OF_STOCK"
    "零金额订单"   | 1L     | 0       | true         || false           | "INVALID_AMOUNT"
}
```

### Java JUnit Specific

```java
@Test
@DisplayName("测试正常流程_用户成功下单")
void testNormalFlow_UserPlaceOrderSuccess() {
    // Given: 准备测试数据
    var input = new InputDTO(...);
    when(mockService.method(any())).thenReturn(expected);  // 模拟依赖返回值

    // When: 执行被测方法
    var result = target.method(input);

    // Then: 验证结果
    assertThat(result).isEqualTo(expected);  // 验证返回值
    verify(mockService, times(1)).save(any());  // 验证保存方法被调用 1 次
}
```

---

## User Interaction Points

### Prompt 1: Spock Installation

When Java project without Spock is detected:

```
检测到 Java 项目，但未发现 Spock 依赖。

是否添加 Spock 测试框架？
- Spock 提供更简洁的 BDD 风格语法
- 支持数据驱动测试（where 表格）
- 内置强大的 Mock 功能

[ 是，添加 Spock ] [ 否，使用 JUnit ]
```

### Prompt 2: Test Coverage Scope

When generating tests for a class with many methods:

```
检测到目标类有 [N] 个公共方法。

请选择测试覆盖范围：
[ 全部方法 ] [ 仅核心方法 ] [ 让我选择 ]
```

---

## Quick Reference

### Go Commands
```bash
# Run all tests with Mockey flags
go test -gcflags="all=-l -N" -v ./...

# Run specific test
go test -gcflags="all=-l -N" -v ./... -run TestFunctionName
```

### Java Commands
```bash
# Maven
mvn test
mvn test -Dtest=XxxServiceTest

# Gradle
./gradlew test
./gradlew test --tests XxxServiceTest
```

---

## Error Handling

### Go: Mock not working
- Ensure `-gcflags="all=-l -N"` flags are used
- Check that `defer mockey.OffAll()` is at the start

### Java: Spock tests not running
- Verify `gmavenplus-plugin` is configured
- Check that test files are in `src/test/groovy/`
- Ensure file names end with `Test.groovy` or `Spec.groovy`

### Java: Groovy version conflict
- **Java 8 编译** (无论运行时是 JDK 8 还是 21): 使用 `org.codehaus.groovy:groovy-all:3.0.x`
- **Java 17+ 编译**: 使用 `org.apache.groovy:groovy-all:4.0.x`
- 检查 Dockerfile 确认运行时环境，但依赖版本由编译版本决定
