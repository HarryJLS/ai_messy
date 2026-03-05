# Spock 单元测试写法指南

> 基于项目实际代码总结，适用于 Java/Groovy 项目的 BDD 风格单元测试

## 1. 基础结构

```groovy
import spock.lang.Specification

class XxxServiceTest extends Specification {

    // 1. 声明 Mock 对象
    def xxxRepository = Mock(XxxRepository)
    def yyyService = Mock(YyyService)

    // 2. 创建被测对象
    def target = new XxxServiceImpl()

    // 3. 初始化依赖注入（两种方式任选）
    // 方式一：setup() 方法
    def setup() {
        target.xxxRepository = xxxRepository
        target.yyyService = yyyService
    }

    // 方式二：直接在构造时注入（适用于构造器注入）
    // def target = new XxxServiceImpl(
    //     xxxRepository: xxxRepository,
    //     yyyService: yyyService
    // )
}
```

## 1.1 优先原则

> **多场景测试优先使用 `where` 数据驱动：** 当同一个方法需要测试多种输入/输出组合时，优先使用 `@Unroll` + `where` 数据表枚举所有场景，而非为每个场景写独立的测试方法。这样更简洁、可读性更好、易于扩展新场景。仅当不同场景的 Mock 行为或验证逻辑差异很大时，才拆分为独立方法。

## 2. 测试方法结构 (given-when-then)

```groovy
def "测试方法的中文描述"() {
    given: "准备测试数据"
    def input = new InputDTO(id: 1L, name: "test")

    and: "模拟依赖行为"
    xxxRepository.getById(1L) >> new Entity(id: 1L)

    when: "调用被测方法"
    def result = target.doSomething(input)

    then: "验证结果"
    result != null
    result.id == 1L
}
```

**关键字说明：**
| 关键字 | 作用 |
|--------|------|
| `given:` | 准备测试数据和前置条件 |
| `and:` | 补充说明，可多次使用 |
| `when:` | 执行被测方法 |
| `then:` | 验证结果和断言 |
| `where:` | 数据驱动测试的数据表 |

## 3. Mock 对象操作

### 3.1 创建 Mock
```groovy
def mockService = Mock(SomeService)
```

### 3.2 模拟返回值 (使用 `>>`)
```groovy
// 固定返回值
mockService.findById(1L) >> new Entity(id: 1L)

// 返回 null
mockService.findById(999L) >> null

// 返回列表
mockService.findAll() >> [entity1, entity2]

// 根据参数动态返回
mockService.process(_) >> { args -> args[0].toUpperCase() }
```

### 3.3 验证方法调用次数 (在 then 块中)
```groovy
then: "验证调用"
1 * mockService.save(_)           // 调用了1次
0 * mockService.delete(_)         // 没有调用
(1..3) * mockService.update(_)    // 调用1-3次
_ * mockService.notify(_)         // 任意次数
```

### 3.4 验证调用参数
```groovy
then:
1 * mockService.save({ it.name == "test" })  // 验证参数满足条件
1 * mockService.update(_ as Entity)          // 验证参数类型

// _ as Type 常用于 mock 返回值时匹配参数类型
and: "mock 依赖行为"
repository.pageByQuery(_ as QueryDTO) >> Pagination.empty()
service.process(_ as String) >> "result"
```

## 4. 数据驱动测试 (where 块)

### 4.1 @Unroll 注解 + 动态标题（推荐）
```groovy
import spock.lang.Unroll

@Unroll
def "test getValidAsinMap with #description"() {
    // #description 会被 where 块中的 description 变量值替换
    // 每行数据会显示为独立的测试用例，如：
    // - test getValidAsinMap with empty list
    // - test getValidAsinMap with single item

    given: "准备测试数据"
    def entity = new Entity(value: inputValue)

    when: "执行方法"
    def result = target.process(entity)

    then: "验证结果"
    result == expectedResult

    where:
    description    | inputValue | expectedResult
    "empty list"   | []         | 0
    "single item"  | [1]        | 1
    "multi items"  | [1, 2, 3]  | 3
}
```

**`@Unroll` 的作用：**
- 不加 `@Unroll`：所有数据行作为一个测试用例，只显示方法名
- 加 `@Unroll`：每行数据独立显示，`#变量名` 会被替换为实际值

### 4.2 表格形式 + 双竖线分隔（推荐）
```groovy
def "测试多种场景"() {
    given: "准备测试数据"
    def entity = new Entity(value: inputValue)

    when: "执行方法"
    def result = target.process(entity)

    then: "验证结果"
    result == expectedResult

    where: "测试数据表"
    scenario       | inputValue | expectedResult
    "正常值"       | 100        | true
    "边界值-零"    | 0          | false
    "边界值-负数"  | -1         | false
}

// 使用 || 双竖线分隔输入参数和期望结果（推荐，更清晰）
where: "cases"
desc     | mock_input              | mock_response              || exp_size | exp_value
"empty"  | new QueryDTO()          | []                         || 0        | null
"normal" | new QueryDTO(id: 1L)    | [new Entity(val: "test")]  || 1        | "test"
```

### 4.3 复杂数据表格（JSON场景）
```groovy
where: "JSON场景测试"
scenario           | newJson                          | oldJson                          | expected
"策略变更"         | '{"strategy":"AUTO"}'            | '{"strategy":"LEGACY"}'          | true
"配置相同"         | '{"strategy":"AUTO","val":10}'   | '{"strategy":"AUTO","val":10}'   | false
"添加新配置"       | '{"strategy":"AUTO","extra":1}'  | '{"strategy":"AUTO"}'            | true
```

### 4.4 复杂嵌套数据结构（List/Map）
```groovy
@Unroll
def "test with #description"() {
    given: "使用 collect 将 Map 列表转换为实体对象"
    def entities = inputData.collect { Map map ->
        new AdGroupEntity(
            tenantId: map.tenantId,
            profileId: map.profileId,
            asinList: map.asinList
        )
    }

    when: "执行方法"
    def result = target.process(entities)

    then: "验证结果"
    result.size() == expectedSize

    where:
    description        | inputData                                                          | expectedSize
    "empty list"       | []                                                                 | 0
    "single item"      | [[tenantId: "t1", profileId: "p1", asinList: ["asin1"]]]           | 1
    "multiple items"   | [
            [tenantId: "t1", profileId: "p1", asinList: ["asin1", "asin2"]],
            [tenantId: "t1", profileId: "p2", asinList: ["asin3"]]
    ]                                                                                       | 3
}
```

### 4.5 Groovy 集合转换技巧
```groovy
given: "准备测试数据"

// collect: List<Map> -> List<Entity>
def entities = mapList.collect { Map map ->
    new Entity(id: map.id, name: map.name)
}

// collectEntries: List -> Map
def resultMap = entityList.collectEntries { entity ->
    [(entity.key): entity.value]
}

// collectEntries: Map -> Map（转换格式）
def newMap = oldMap.collectEntries { key, value ->
    [(key): new Entity(data: value)]
}

// find: 查找单个元素
def found = list.find { it.id == targetId }

// findAll: 过滤列表
def filtered = list.findAll { it.status == "ACTIVE" }
```

## 5. 异常测试

### 5.1 验证抛出异常
```groovy
def "测试异常场景"() {
    given: "准备异常触发条件"
    mockService.query(_) >> null

    when: "调用方法"
    target.process(invalidInput)

    then: "验证抛出异常"
    thrown(NullPointerException)
}
```

### 5.2 验证异常消息
```groovy
then: "验证异常详情"
def ex = thrown(CommonException)
ex.message.contains("查询不到需要回撤的任务")
```

### 5.3 数据驱动的异常测试
```groovy
def "测试多种异常场景"() {
    given:
    mockService.query(_) >> taskList

    when:
    target.process(input)

    then:
    def ex = thrown(CommonException)
    ex.message.contains("无需回撤")

    where:
    scenario       | taskList
    "查询为null"   | null
    "查询为空列表" | []
}
```

## 6. 断言方式

```groovy
then: "各种断言写法"
// 直接比较（推荐）
result == expected
result != null
result.size() == 2

// 安全导航符 ?.（避免空指针，推荐用于可能为 null 的场景）
result?.list?.size() == exp_size
result?.list?.getAt(0)?.name == exp_name
result?.collectEntries { [(it.key): it] }?."KEY"?.value == exp_value

// 显式 assert（用于复杂条件）
assert result == expected

// 集合断言
result.every { it.status == "SUCCESS" }
result.any { it.id == 1L }
result.findAll { it.active }.size() == 3

// 条件断言
if (hasValidData) {
    result.size() > 0
}
```

## 7. 完整示例

```groovy
class OrderServiceTest extends Specification {

    def orderRepository = Mock(OrderRepository)
    def paymentService = Mock(PaymentService)

    def target = new OrderServiceImpl()

    def setup() {
        target.orderRepository = orderRepository
        target.paymentService = paymentService
    }

    @Unroll
    def "测试创建订单_#scenario"() {
        given: "准备订单数据"
        def orderDTO = new OrderDTO(userId: userId, amount: amount)

        and: "模拟依赖行为"
        orderRepository.save(_) >> { Order order ->
            order.id = 1L
            return order
        }
        paymentService.charge(_, _) >> chargeResult

        when: "创建订单"
        def result = target.createOrder(orderDTO)

        then: "验证订单创建结果"
        result.status == expectedStatus
        saveCount * orderRepository.save(_)
        chargeCount * paymentService.charge(_, _)

        where: "多种下单场景"
        scenario       | userId | amount  | chargeResult || expectedStatus | saveCount | chargeCount
        "正常下单"     | 1L     | 100.00  | true         || "CREATED"      | 1         | 1
        "小额订单"     | 2L     | 0.01    | true         || "CREATED"      | 1         | 1
        "大额订单"     | 1L     | 9999.99 | true         || "CREATED"      | 1         | 1
    }

    def "测试订单状态转换"() {
        given: "准备不同状态的订单"
        def order = new Order(id: 1L, status: oldStatus)
        orderRepository.getById(1L) >> order

        when: "执行状态转换"
        def result = target.canTransition(1L, newStatus)

        then: "验证转换结果"
        result == canTransition

        where: "状态转换矩阵"
        oldStatus   | newStatus    | canTransition
        "CREATED"   | "PAID"       | true
        "CREATED"   | "CANCELLED"  | true
        "PAID"      | "SHIPPED"    | true
        "PAID"      | "CREATED"    | false
        "CANCELLED" | "PAID"       | false
    }

    def "测试支付失败抛出异常"() {
        given: "模拟支付失败"
        paymentService.charge(_, _) >> { throw new PaymentException("余额不足") }

        when: "创建订单"
        target.createOrder(new OrderDTO(userId: 1L, amount: 100.00))

        then: "验证抛出业务异常"
        def ex = thrown(BusinessException)
        ex.message.contains("支付失败")
    }
}
```

## 8. 常用技巧速查

| 场景 | 写法 |
|------|------|
| Mock对象 | `def mock = Mock(Interface)` |
| 模拟返回值 | `mock.method(arg) >> value` |
| 模拟抛异常 | `mock.method(_) >> { throw new Ex() }` |
| 验证调用1次 | `1 * mock.method(_)` |
| 验证未调用 | `0 * mock.method(_)` |
| 任意参数 | `mock.method(_)` |
| 参数类型匹配 | `mock.method(_ as QueryDTO)` |
| 参数条件 | `mock.method({ it.id > 0 })` |
| 验证异常 | `thrown(ExceptionClass)` |
| 捕获异常 | `def ex = thrown(Exception)` |
| 数据驱动 | `where:` 块 + 表格 |
| 输入输出分隔 | `input1 \| input2 \|\| expected` |
| 独立显示每行 | `@Unroll` 注解 |
| 动态测试名 | `def "test #desc"()` + `where: desc` |
| 安全导航符 | `result?.list?.size()` |
| 安全取值 | `result?.getAt(0)?.name` |
| Map转实体 | `list.collect { new Entity(id: it.id) }` |
| 列表转Map | `list.collectEntries { [(it.key): it] }` |

## 9. Maven 依赖配置

### 9.1 父 pom.xml 配置（dependencyManagement）

```xml
<properties>
    <!-- Spock 版本 -->
    <spock.version>2.4-M5-groovy-4.0</spock.version>
</properties>

<dependencyManagement>
    <dependencies>
        <!-- Spock 核心框架 -->
        <dependency>
            <groupId>org.spockframework</groupId>
            <artifactId>spock-core</artifactId>
            <version>${spock.version}</version>
            <scope>test</scope>
        </dependency>

        <!-- Groovy 运行时 -->
        <dependency>
            <groupId>org.apache.groovy</groupId>
            <artifactId>groovy-all</artifactId>
            <version>4.0.14</version>
            <type>pom</type>
            <scope>test</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<build>
    <plugins>
        <!-- Groovy 编译插件 -->
        <plugin>
            <groupId>org.codehaus.gmavenplus</groupId>
            <artifactId>gmavenplus-plugin</artifactId>
            <version>4.1.1</version>
            <executions>
                <execution>
                    <goals>
                        <goal>compileTests</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>

        <!-- 测试运行插件 -->
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <version>2.22.2</version>
            <configuration>
                <includes>
                    <include>**/*Test.java</include>
                    <include>**/*Test.groovy</include>
                    <include>**/*Spec.groovy</include>
                </includes>
            </configuration>
        </plugin>
    </plugins>
</build>
```

### 9.2 子模块 pom.xml 配置

```xml
<dependencies>
    <!-- Spock 核心框架 -->
    <dependency>
        <groupId>org.spockframework</groupId>
        <artifactId>spock-core</artifactId>
        <scope>test</scope>
    </dependency>

    <!-- Groovy 运行时 -->
    <dependency>
        <groupId>org.apache.groovy</groupId>
        <artifactId>groovy-all</artifactId>
        <type>pom</type>
        <scope>test</scope>
    </dependency>

    <!-- JUnit Platform（Spock 2.x 必需，基于 JUnit 5 平台运行） -->
    <dependency>
        <groupId>org.junit.platform</groupId>
        <artifactId>junit-platform-engine</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.junit.platform</groupId>
        <artifactId>junit-platform-launcher</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.junit.platform</groupId>
        <artifactId>junit-platform-commons</artifactId>
        <scope>test</scope>
    </dependency>

    <!-- 可选：PowerMock（用于 mock 静态方法，Spock 原生不支持） -->
    <!--
    <dependency>
        <groupId>org.powermock</groupId>
        <artifactId>powermock-module-junit4</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.powermock</groupId>
        <artifactId>powermock-api-mockito2</artifactId>
        <scope>test</scope>
    </dependency>
    -->
</dependencies>
```

**依赖说明：**
| 依赖 | 必需性 | 说明 |
|------|--------|------|
| spock-core | 必需 | Spock 核心框架 |
| groovy-all | 必需 | Groovy 运行时 |
| junit-platform-* | 必需 | Spock 2.x 基于 JUnit 5 平台运行 |
| powermock-* | 可选 | mock 静态方法时使用 |
| junit-jupiter-* | 可选 | 同时写 JUnit 5 测试时使用 |
| junit-vintage-engine | 可选 | 兼容 JUnit 4 测试时使用 |

### 9.3 测试文件目录结构

```
src/
├── main/
│   └── java/           # Java 源代码
└── test/
    ├── java/           # Java 测试类
    ├── groovy/         # Groovy/Spock 测试类
    │   └── com/xxx/
    │       └── XxxServiceTest.groovy
    └── resources/      # 测试资源文件
```

### 9.4 运行测试命令

```bash
# 运行所有测试
mvn test

# 运行单个测试类
mvn test -Dtest=XxxServiceTest

# 运行指定方法
mvn test -Dtest=XxxServiceTest#"测试方法名"
```
