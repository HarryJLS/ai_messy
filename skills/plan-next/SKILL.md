---

name: plan-next
description: 使用 TDD 循环执行下一个待处理任务。当用户说 "/plan-next"、"执行下一个任务"、"继续任务"、"开始开发" 时触发。必须先运行 /plan-init 创建 features.json。执行 READ → EXPLORE → PLAN → RED → IMPLEMENT → GREEN → COMMIT 七阶段流程。
---

# Plan Next

使用 Feature-Dev 工作流和 TDD 循环执行下一个待处理任务。

## 关键规则

- **一次一个任务**，仅在验证后设置 `passes: true`
- **TDD 强制**：必须先看到 RED 再看 GREEN
- **日志用于恢复**：每条日志必须能在新会话中恢复上下文
- **资深开发视角**：考虑代码质量、边界情况、错误处理、可维护性
- **参考方法/工具必查**：如果任务的 `references` 字段列出了方法、工具类、API 或文档，**必须**在 PLAN 阶段查找其源码或文档，理解其封装方式和调用方法，在 IMPLEMENT 阶段严格按照其设计使用，禁止绕过或重新实现
- **数据样例必验**：如果任务的 `dataSamples` 字段提供了数据样例，**必须**在 RED 阶段基于样例编写测试用例，在 GREEN 阶段用样例数据验证解析和处理逻辑的正确性
- **强制完整注释**：每个新写的方法必须有完整注释，每个方法跳转必须有说明注释，不可跳过
- **不确定必询问**：遇到多种实现方式或关键技术决策不确定时，必须向用户询问，禁止擅自决定
- **问题收集机制**：开发过程中遇到的问题不立即中断，而是记录到问题列表，在当前阶段结束时统一向用户确认

## 反合理化检查 - 停止并重新开始

这些想法意味着你在合理化跳过增强要求：

| 借口 | 现实 |
|------|------|
| "这个参考方法太简单了，不需要深度分析" | 简单的方法也有调用规范和项目模式，必须学习 |
| "项目里没找到使用示例，我自己理解就行" | 没找到说明搜索不充分，必须继续搜索或询问用户 |
| "注释太繁琐了，代码本身就很清楚" | 代码清楚 ≠ 意图清楚，注释是为了说明业务意图 |
| "这种简单的跳转不需要注释" | 所有方法跳转都需要注释，为后续维护者考虑 |
| "接口方法签名已经很清楚了，不需要注释" | 签名说明"是什么"，注释说明"为什么"和"怎么用" |
| "实现类直接继承接口注释就行" | 实现类需要补充具体实现策略和特殊逻辑说明 |
| "私有方法是内部的，不需要那么详细的注释" | 私有方法同样需要注释，说明抽取原因和调用时机 |
| "调用行注释会让代码太长" | 可读性比简洁更重要，必要时换行 |
| "我确信这个实现方式是对的，不需要问用户" | 确信 ≠ 正确，涉及架构的决策必须征得用户同意 |
| "询问用户太频繁，会打断流程" | 错误的假设比询问的成本更高 |
| "我可以稍后补充注释" | 稍后 = 永远不会，必须在写代码时同步写注释 |

**所有这些都意味着：停止合理化，严格按照增强要求执行。**

## 日志格式

每条日志写入 `logs/task-{id}.log`，必须回答：**"如果我在新会话中只读这条日志，能否继续？"**

```
[时间戳] [阶段] Task N: 一句话概述
├─ 状态: exploring|planning|red|green|blocked|done
├─ 决策: 关键决策（为什么这样做）
├─ 文件: file1.ts, file2.ts（已改/将改）
├─ 问题: 遇到的问题 → 解决方案（或 none）
└─ 下一步: 具体下一步操作
---
```

## 问题收集规范

开发过程中遇到不确定的问题时，不立即中断流程，而是记录到问题列表，在当前阶段结束时统一向用户确认。

### 问题记录格式

在执行过程中，使用以下格式记录问题：

```
📋 待确认问题列表：

1. [类型] 问题描述
   - 背景：为什么会遇到这个问题
   - 选项 A：方案描述 → 优点/缺点
   - 选项 B：方案描述 → 优点/缺点
   - ⭐ 推荐：方案 X，理由是...

2. [类型] 问题描述
   ...
```

### 问题类型

| 类型标签 | 说明 | 示例 |
|---------|------|------|
| `[技术选型]` | 多种技术方案选择 | 用 Jackson 还是 Gson？ |
| `[实现方式]` | 具体实现细节决策 | 同步调用还是异步？ |
| `[边界确认]` | 修改范围不确定 | 这个相似方法是否也需要改？ |
| `[资源缺失]` | 找不到指定的参考资源 | references 中的方法找不到 |
| `[样例歧义]` | 数据样例理解有分歧 | 这个字段是可选还是必填？ |

### 收集时机与确认时机

| 阶段 | 收集时机 | 确认时机 |
|------|---------|---------|
| EXPLORE | 分析代码时发现不确定点 | EXPLORE 结束、进入 PLAN 前 |
| PLAN | 规划实现方案时遇到多种选择 | PLAN 结束、进入 RED 前 |
| RED | 编写测试时对预期行为不确定 | RED 结束、进入 IMPLEMENT 前 |
| IMPLEMENT | 实现代码时遇到技术决策 | IMPLEMENT 结束、进入 GREEN 前 |

### 日志中记录问题

每个阶段的日志需要包含问题收集情况：

```
[时间戳] [阶段] Task N: 一句话概述
├─ 状态: xxx → yyy
├─ 决策: 关键决策
├─ 文件: file1.ts, file2.ts
├─ 待确认问题: N 个（已在阶段结束时向用户确认）
├─ 用户决策: 问题1→选择A | 问题2→选择B | ...
└─ 下一步: 具体下一步操作
---
```

## 阶段 1: READ

1. 读取 `features.json`，找到第一个 `passes: false`
2. 如果没有："所有任务已完成 🎉" → 停止
3. 宣布："开始任务 [ID]: [描述]"

## 阶段 2: EXPLORE（条件执行）

**仅当任务修改现有代码时执行**，新功能跳过。

**判断标准：**
| 场景 | 是否 Explore | 理由 |
|------|-------------|------|
| 修改现有方法/类的逻辑 | ✅ 必须 | 需理解现有实现 |
| 在现有类中添加新方法 | ✅ 必须 | 需了解类的职责和风格 |
| 修复现有代码的 bug | ✅ 必须 | 需理解原有逻辑和上下文 |
| 创建全新的类/模块 | ❌ 跳过 | 无现有代码需分析 |
| 添加全新的独立功能文件 | ❌ 跳过 | 无依赖需分析 |
| 在现有模块中添加新文件 | ⚠️ 视情况 | 如需遵循模块规范则 Explore |

**简化判断：** 如果任务涉及的文件/类/方法已存在 → Explore；完全新建 → 跳过

**执行时**：用文件搜索和阅读工具分析现有代码

**日志**:
```
[时间戳] [Explore] Task N: 分析 XXX 模块
├─ 状态: exploring → planning
├─ 决策: 发现 XXX 模式，计划复用/扩展
├─ 文件: existing1.ts, existing2.ts（将修改）
├─ 待确认问题: N 个
├─ 用户决策: 问题1→选择X | 问题2→选择Y
└─ 下一步: 制定实现计划
---
```

⛔ **阶段门控**：如有待确认问题，必须在进入 PLAN 阶段前向用户统一确认

## 阶段 3: PLAN

1. 查看任务的 `steps`, `acceptance`, `test`, `boundary` 字段
2. 如果模糊 → 先更新 features.json
3. **参考资源查找**（如果任务有 `references` 或 `dataSamples` 字段）：

### 3.1: 参考方法学习流程
当任务要求参考指定方法时：

**步骤一：精确定位参考方法**
- 使用 Grep 和 Read 工具找到参考方法的完整实现
- 记录方法签名、参数类型、返回值类型、异常声明
- 分析方法所在的类/包的整体设计意图

**步骤二：深度分析写法模式**
- **命名规范分析**：方法命名风格、参数命名规律、返回值命名
- **参数处理方式**：参数校验模式、参数转换逻辑、默认值处理
- **异常处理模式**：异常类型选择、异常信息格式、错误传播方式
- **返回值构造方式**：成功/失败的返回值格式、包装类使用模式
- **日志记录方式**：日志级别选择、日志内容格式、关键节点记录

**步骤三：学习项目集成模式**
- 在项目中搜索此方法的所有调用示例：`Grep pattern="methodName" output_mode="content"`
- 分析不同场景下的调用方式差异
- 理解方法在项目架构中的位置和职责
- 学习与其他组件的协作方式

**步骤四：改写适配当前需求**
- 保持相同的代码风格和结构模式
- 适配当前业务场景的具体需求
- 确保与项目整体架构一致
- 继承相同的错误处理和日志记录方式

### 3.2: 工具类方法使用学习

**寻找使用示例**
- 在项目中搜索工具类的使用示例：`Grep pattern="ToolClass\." output_mode="content"`
- 分析不同场景下的调用方式
- 理解参数传递的最佳实践
- 学习常见的使用组合模式

**学习调用模式**
- **静态方法调用方式**：类名.方法名() 的使用规范
- **实例方法的创建和使用**：构造器选择、配置模式
- **链式调用的使用场景**：builder 模式的正确使用
- **异常处理的标准做法**：项目中的统一异常处理模式

**不确定时的处理机制**
- 当遇到多种可能的写法时，优先选择项目中使用最多的方式
- 对于关键决策（如文件处理、数据库操作、外部API调用），准备建议方案询问用户
- 列出候选方案及其优缺点，**不可擅自决定**

   - 逐一查找 `references` 中列出的方法/工具类/API：
     - 按照上述参考方法学习流程深度分析
     - 记录其封装模式（如工厂方法、Builder 模式、静态工具类等）
     - 如果是第三方库，查阅其文档了解正确用法
   - 检查 `dataSamples` 中列出的数据样例：
     - 阅读样例数据的结构和字段含义
     - 确认数据格式（JSON/XML/CSV 等）和编码方式
     - 识别特殊字段、嵌套结构、可选字段
   - ⚠️ 如果找不到 references 中指定的方法或工具，记录到问题列表（类型：`[资源缺失]`），阶段结束时统一确认
4. **影响范围确认**：
   - 列出将要修改的文件/类/方法
   - 列出相似但**不应修改**的文件/类/方法
   - 如果有 `boundary` 字段，确认理解边界
5. **Service 架构预评估**：
   - 评估新增功能的复杂度和职责归属
   - 检查是否有合适的现有 service 可以扩展
   - 预判是否需要新建 service 或方法抽取
   - 列出候选的 service 方案：`现有ServiceA.newMethod()` 或 `新建ServiceB`
6. 写日志

**日志**:
```
[时间戳] [Plan] Task N: 计划 XXX 功能
├─ 状态: planning → red（或 pending-confirm）
├─ 决策: 技术选型/架构决策要点
├─ 文件: new1.ts, new2.ts（将创建）| existing.ts（将修改）
├─ 参考资源: 已查找 XxxUtil.method()（位于 src/utils/）| 数据样例已分析（JSON 格式，N 个字段）
├─ Service 方案: 扩展 XxxService | 新建 YyyService | 保留在 Controller（原因）
├─ 待确认问题: N 个
├─ 用户决策: 问题1→选择A | 问题2→选择B | ...
├─ 问题: 预见的挑战 → 应对方案
└─ 下一步: 编写测试用例，确认 RED 状态
---
```

⛔ **阶段门控**：如有待确认问题，必须在进入 RED 阶段前向用户统一确认

## 阶段 4: TDD RED 🔴

⚠️ **必须先看到测试失败，再写业务代码**

1. 根据任务 `test` 字段选择验证方式：
   - `unit/integration/e2e` → **调用 `/unit-test` skill**
   - `manual` → 写验证检查清单

2. **基于数据样例编写测试**（如果任务有 `dataSamples` 字段）：
   - 将数据样例直接作为测试输入数据
   - 根据样例的结构编写解析/处理逻辑的断言
   - 覆盖样例中的正常字段、可选字段、嵌套结构
   - 补充边界情况：空值、缺失字段、异常格式

3. **调用 `/unit-test` skill**（非 manual 类型时）：
   - `/unit-test` 会自动检测项目语言（Go/Java）
   - 根据项目现有测试风格生成测试代码
   - 完成后自动返回，继续后续阶段

4. 运行测试，**确认失败**

**日志**:
```
[时间戳] [Red] Task N: 测试准备完成
├─ 状态: red → implementing
├─ 决策: 选择 XXX 测试方式，因为 YYY
├─ 文件: test.spec.ts（已创建）
├─ 测试框架: [Go: Mockey+Testify | Java: Spock/JUnit]（由 /unit-test 检测）
├─ 问题: none
└─ 下一步: 实现功能代码，让测试通过
---
```

## 阶段 5: IMPLEMENT

- 写最小代码让测试通过
- 只做当前任务，不做额外"改进"

### 5.1: 参考方法/工具使用规范

**使用参考方法/工具**（如果任务有 `references` 字段）：
- **必须**使用 PLAN 阶段已查找到的方法/工具，按其封装方式调用
- 禁止绕过已有封装重新实现相同功能
- 如果参考方法的接口不完全匹配需求，优先扩展已有方法，而非新建
- 调用方式需与项目中其他地方的使用方式保持一致

**工具类方法使用实施指导**：
- **保持一致性**：严格按照项目中已有的调用模式使用
- **参数传递**：复用相同的参数校验、转换、包装方式
- **异常处理**：使用相同的异常处理模式，不可随意更改
- **返回值处理**：按照项目惯例处理返回值（包装、转换、校验）

### 5.2: 代码注释规范要求

⚠️ **核心原则**：代码不仅要能运行，还要能让人快速理解。注释是给后续维护者的导航地图。

#### 5.2.1: 接口与实现类注释（必须）

**接口注释要求**：
- 接口**必须**有类级别的 doc 注释，说明接口的职责和使用场景
- 接口中的每个方法**必须**有完整的方法注释

```java
/**
 * 订单金额计算服务接口
 *
 * <p>负责订单相关的金额计算，包括：
 * <ul>
 *   <li>基础金额计算</li>
 *   <li>折扣优惠计算</li>
 *   <li>运费计算</li>
 * </ul>
 *
 * @author xxx
 * @since 1.0.0
 */
public interface OrderCalculationService {

    /**
     * 计算订单总金额
     *
     * @param order 订单对象，不能为空
     * @return 订单总金额，单位：元
     * @throws IllegalArgumentException 当订单为空或订单项为空时
     */
    BigDecimal calculateTotalAmount(Order order);
}
```

```go
// OrderCalculationService 订单金额计算服务接口
// 负责订单相关的金额计算，包括基础金额、折扣优惠、运费等
type OrderCalculationService interface {
    // CalculateTotalAmount 计算订单总金额
    // 参数：order - 订单对象，不能为 nil
    // 返回：订单总金额（单位：元），error 为空表示成功
    CalculateTotalAmount(ctx context.Context, order *Order) (decimal.Decimal, error)
}
```

**实现类注释要求**：
- 实现类**必须**有类级别注释，说明具体实现策略
- 实现类的方法注释与接口保持一致

```java
/**
 * 订单金额计算服务默认实现
 *
 * <p>实现策略：
 * <ul>
 *   <li>先计算商品原价总和</li>
 *   <li>应用折扣规则（满减 > 优惠券 > 会员折扣）</li>
 *   <li>最后加上运费</li>
 * </ul>
 *
 * @author xxx
 * @since 1.0.0
 */
@Service
public class OrderCalculationServiceImpl implements OrderCalculationService {

    /**
     * 计算订单总金额
     *
     * @param order 订单对象，不能为空
     * @return 订单总金额，单位：元
     * @throws IllegalArgumentException 当订单为空或订单项为空时
     */
    @Override
    public BigDecimal calculateTotalAmount(Order order) {
        // 实现代码
    }
}
```

```go
// OrderCalculationServiceImpl 订单金额计算服务默认实现
// 实现策略：先计算商品原价 -> 应用折扣规则 -> 加上运费
type OrderCalculationServiceImpl struct {
    discountService DiscountService
    shippingService ShippingService
}

// CalculateTotalAmount 计算订单总金额
// 实现说明：采用分步计算策略，便于后续扩展折扣规则
func (s *OrderCalculationServiceImpl) CalculateTotalAmount(ctx context.Context, order *Order) (decimal.Decimal, error) {
    // 实现代码
}
```

#### 5.2.2: 方法注释要求（必须）

**公开方法（public）**：
- **必须**有完整的方法注释
- 注释格式：功能说明、参数说明、返回值说明、异常说明
- 使用项目统一的注释风格（JavaDoc、GoDoc等）

```java
/**
 * 根据用户ID查询用户详情
 *
 * @param userId 用户ID，必须大于0
 * @return 用户详情DTO，用户不存在时返回null
 * @throws IllegalArgumentException 当userId小于等于0时
 */
public UserDTO getUserById(Long userId) {
    // 实现代码
}
```

```go
// GetUserByID 根据用户ID查询用户详情
// 参数：userId - 用户ID，必须大于0
// 返回：用户详情，用户不存在时返回nil；error为空表示成功
func (s *UserService) GetUserByID(ctx context.Context, userID int64) (*UserDTO, error) {
    // 实现代码
}
```

**私有方法/子方法**：
- **必须**有方法注释，说明此子方法的具体职责
- 注释需说明：做什么、为什么抽取为独立方法、调用时机

```java
/**
 * 应用折扣规则到订单金额
 *
 * @param baseAmount 商品原价总额
 * @param discounts 适用的折扣列表，按优先级排序
 * @return 折扣后的金额
 */
private BigDecimal applyDiscounts(BigDecimal baseAmount, List<Discount> discounts) {
    // 实现代码
}
```

```go
// applyDiscounts 应用折扣规则到订单金额
// 参数：baseAmount - 商品原价总额，discounts - 适用的折扣列表
// 返回：折扣后的金额
func (s *OrderCalculationServiceImpl) applyDiscounts(baseAmount decimal.Decimal, discounts []*Discount) decimal.Decimal {
    // 实现代码
}
```

#### 5.2.3: 方法调用行注释（必须）

**核心要求**：调用其他方法时，**必须**在调用行添加注释，说明调用目的，让阅读者无需跳转即可理解。

**注释格式**：`// [动作]: [目的/结果]`

**Java 示例**：
```java
public OrderDTO createOrder(CreateOrderRequest request) {
    // 1. 参数校验: 校验订单请求参数完整性
    validateOrderRequest(request);

    // 2. 查询商品: 获取订单中所有商品的详细信息
    List<Product> products = productService.getProductsByIds(request.getProductIds());

    // 3. 库存检查: 确认所有商品库存充足
    inventoryService.checkStock(products, request.getQuantities());

    // 4. 计算金额: 根据商品和优惠信息计算订单总金额
    BigDecimal totalAmount = orderCalculationService.calculateTotalAmount(products, request.getCoupons());

    // 5. 创建订单: 生成订单记录并保存到数据库
    Order order = orderRepository.save(buildOrder(request, products, totalAmount));

    // 6. 扣减库存: 锁定商品库存防止超卖
    inventoryService.deductStock(products, request.getQuantities());

    // 7. 发送通知: 异步通知用户订单创建成功
    notificationService.sendOrderCreatedNotification(order);

    return OrderConverter.toDTO(order);
}
```

**Go 示例**：
```go
func (s *OrderService) CreateOrder(ctx context.Context, req *CreateOrderRequest) (*OrderDTO, error) {
    // 1. 参数校验: 校验订单请求参数完整性
    if err := s.validateOrderRequest(req); err != nil {
        return nil, err
    }

    // 2. 查询商品: 获取订单中所有商品的详细信息
    products, err := s.productService.GetProductsByIDs(ctx, req.ProductIDs)
    if err != nil {
        return nil, fmt.Errorf("查询商品失败: %w", err)
    }

    // 3. 库存检查: 确认所有商品库存充足
    if err := s.inventoryService.CheckStock(ctx, products, req.Quantities); err != nil {
        return nil, fmt.Errorf("库存检查失败: %w", err)
    }

    // 4. 计算金额: 根据商品和优惠信息计算订单总金额
    totalAmount, err := s.calculationService.CalculateTotalAmount(ctx, products, req.Coupons)
    if err != nil {
        return nil, fmt.Errorf("计算金额失败: %w", err)
    }

    // 5. 创建订单: 生成订单记录并保存到数据库
    order, err := s.orderRepo.Save(ctx, s.buildOrder(req, products, totalAmount))
    if err != nil {
        return nil, fmt.Errorf("保存订单失败: %w", err)
    }

    // 6. 扣减库存: 锁定商品库存防止超卖
    if err := s.inventoryService.DeductStock(ctx, products, req.Quantities); err != nil {
        return nil, fmt.Errorf("扣减库存失败: %w", err)
    }

    // 7. 发送通知: 异步通知用户订单创建成功（失败不影响主流程）
    go s.notificationService.SendOrderCreatedNotification(ctx, order)

    return convertToDTO(order), nil
}
```

**链式调用注释**：
```java
// 构建用户查询条件: 按部门筛选 + 只查激活用户 + 按创建时间倒序分页
List<User> users = userRepository.findAll(
    Specification.where(UserSpec.byDepartment(deptId))
        .and(UserSpec.isActive()),
    PageRequest.of(page, size, Sort.by("createdAt").descending())
);
```

#### 5.2.4: 关键逻辑注释

- 复杂业务逻辑添加解释性注释
- 算法实现添加步骤说明注释
- 重要的判断条件添加原因说明
- 对外部依赖的调用添加说明注释
- **按数据样例实现解析逻辑**（如果任务有 `dataSamples` 字段）：
  - 解析逻辑必须能正确处理样例中的所有字段和结构
  - 字段名、层级关系、数据类型必须与样例一致
  - 对可选字段做空值保护
- **代码行长度**：单行不超过 120 字符，超过时换行：
  - 在运算符、逗号、点号后换行
  - 下一行适当缩进（4 空格或 1 tab）
  - 长字符串用 `+` 分行连接
- **疑似确认**（防止误改）：
  - 如果发现相似但不确定是否要改的地方，记录到问题列表
  - 格式：`[边界确认] 疑似需要修改：[位置] - [原因]`
  - 选项：A) 一并修改 B) 保持不变
  - 阶段结束时统一确认

### 5.3: 用户交互机制指导

**询问时机**：
- 发现多种可行的实现方式时
- 对关键技术选择（如文件处理方式、数据存储方案）不确定时
- 参考方法存在但适配方式不明确时
- 工具类使用方法有歧义时
- 发现需要修改核心逻辑或架构时

**询问方式**：
- 提供具体的建议方案，不抛出开放性问题
- 说明每种方案的优缺点和适用场景
- 包含具体的代码示例或伪代码
- 明确需要用户决策的具体问题

**询问模板**：
- **方案选择型**："我发现了以下几种实现方式，建议使用方案A因为[具体理由]，您认为如何？"
  ```
  方案A：使用XxxUtil.method()调用
  - 优点：与项目现有模式一致，维护简单
  - 缺点：功能有限，可能需要额外处理

  方案B：扩展XxxUtil添加新方法
  - 优点：功能完整，可复用性好
  - 缺点：影响范围更大，需要更多测试

  我的建议：优先选择方案A，理由是[详细说明]
  ```

- **技术确认型**："关于[具体问题]，我的建议是[具体方案]，理由是[详细说明]，您是否同意？"

- **架构决策型**："此实现可能影响[具体模块]，建议的处理方式是[方案]，是否需要调整？"

**建议方案质量要求**：
- 必须基于对现有代码的深入分析
- 必须考虑项目的整体架构和规范
- 必须包含具体的实现细节
- 必须说明选择理由和风险评估

**换行示例**：
```java
// 方法调用换行
String result = someService.processData(param1, param2,
    param3, param4);

// 条件表达式换行
boolean isValid = StringUtils.isNotEmpty(name) && value > 0
    && status == Status.ACTIVE;

// 长字符串换行
String message = "This is a very long error message that exceeds "
    + "the maximum line length limit";
```

```go
// Go 方法调用换行
result, err := someService.ProcessData(ctx, param1, param2,
    param3, param4)

// Go 长字符串
message := "This is a very long error message that exceeds " +
    "the maximum line length limit"
```

### 5.4: Service 方法抽取决策流程

每当实现新方法时，按以下流程评估：

```
新增方法 → 评估复杂度 → 决策抽取
    ↓
1. 方法功能分析：
   ├─ 纯业务逻辑？ → 考虑抽取到 BusinessService
   ├─ 数据操作？ → 考虑抽取到 DataService/Repository
   ├─ 外部调用？ → 考虑抽取到 IntegrationService
   ├─ 工具性质？ → 考虑抽取到 UtilsService
   └─ 简单转换？ → 保留在当前类

2. 复杂度判断：
   ├─ 超过 10 行 → 强烈建议抽取
   ├─ 包含分支判断 → 建议抽取
   ├─ 有错误处理 → 建议抽取
   └─ 简单赋值 → 不抽取

3. 可复用性：
   ├─ 其他地方可能用到 → 必须抽取
   ├─ 只有当前场景使用 → 根据复杂度决定
   └─ 与当前类强绑定 → 保留

4. 已有 Service 匹配度：
   ├─ 完全匹配已有 service 职责 → 添加到已有 service
   ├─ 部分匹配 → 评估是否扩展已有 service
   └─ 不匹配 → 创建新 service（需慎重）
```

**抽取示例场景**：

**✅ 应该抽取**：
```java
// 复杂的订单计算逻辑 → OrderCalculationService
public BigDecimal calculateOrderAmount(Order order) {
    BigDecimal baseAmount = order.getBasePrice();
    if (order.hasDiscount()) {
        baseAmount = applyDiscount(baseAmount, order.getDiscountRate());
    }
    if (order.hasShippingFee()) {
        baseAmount = baseAmount.add(calculateShippingFee(order));
    }
    return applyTax(baseAmount, order.getTaxRate());
}

// 数据库复杂查询 → UserRepository/UserDataService
public List<User> findActiveUsersWithConditions(UserQuery query) {
    // 复杂的 SQL 构建和执行逻辑
}
```

**❌ 不需要抽取**：
```java
// 简单属性设置
public void updateUserLastLogin(User user) {
    user.setLastLoginTime(new Date());
    user.setLoginCount(user.getLoginCount() + 1);
}

// 简单格式转换
public String formatUserDisplayName(User user) {
    return user.getFirstName() + " " + user.getLastName();
}
```

### 5.5: 异常处理规范（避免过度 try-catch）

**核心原则**：只在必要时使用 try-catch，避免防御性过度编程。

**何时需要 try-catch**：
| 场景 | 是否需要 | 理由 |
|------|---------|------|
| 外部 I/O 操作（文件、网络、数据库） | ✅ 需要 | 外部系统不可控，必须处理失败 |
| 解析外部输入（JSON、XML） | ✅ 需要 | 输入格式不可控 |
| 调用第三方库且文档说明会抛异常 | ✅ 需要 | 按库设计使用 |
| 业务逻辑需要优雅降级 | ✅ 需要 | 明确的业务需求 |
| 框架要求捕获特定异常 | ✅ 需要 | 遵循框架规范 |

**何时不需要 try-catch**：
| 场景 | 是否需要 | 正确做法 |
|------|---------|----------|
| 可提前校验的参数 | ❌ 不需要 | 用 if 判断，如 `if (obj == null)` |
| 内部方法调用 | ❌ 不需要 | 信任内部代码，让异常向上传播 |
| 已知不会失败的操作 | ❌ 不需要 | 不要防御性编程 |
| 仅为了打印日志 | ❌ 不需要 | 用全局异常处理器 |
| catch 后只是重新抛出 | ❌ 不需要 | 删除无意义的 try-catch |

**反模式示例**：

```java
// ❌ 错误：不必要的 try-catch，可用 if 判断
try {
    return user.getName().toUpperCase();
} catch (NullPointerException e) {
    return "";
}

// ✅ 正确：提前校验
if (user == null || user.getName() == null) {
    return "";
}
return user.getName().toUpperCase();
```

```java
// ❌ 错误：catch 后只是重新抛出，毫无意义
try {
    return service.process(data);
} catch (Exception e) {
    throw e;
}

// ✅ 正确：直接调用，让异常自然传播
return service.process(data);
```

```java
// ❌ 错误：内部方法调用不需要 try-catch
try {
    validateInput(input);
    processData(data);
    saveResult(result);
} catch (Exception e) {
    log.error("处理失败", e);
    throw new BusinessException("处理失败", e);
}

// ✅ 正确：让异常自然传播到全局处理器
validateInput(input);
processData(data);
saveResult(result);
```

**异常日志记录规范**：

当确实需要 try-catch 时，**必须**在 catch 块中打印 error 日志，包含以下关键信息：

| 必须包含 | 说明 | 示例 |
|---------|------|------|
| 业务标识 | 单号、订单号、用户ID等 | `orderNo={}`、`userId={}` |
| 操作描述 | 正在执行什么操作 | `处理订单失败`、`解析响应失败` |
| 关键参数 | 有助于复现问题的输入，**对象类型必须 JSON 序列化** | `requestId={}`、`param={}` |
| 缺失信息 | 导致异常的缺失字段或属性 | `缺失字段: username`、`缺少属性: config.timeout` |
| 异常堆栈 | **必须**将异常对象作为最后一个参数传入 | `log.error("...", e)` |

**日志格式模板**：
```java
// 通用格式 - 对象参数使用 JSON 序列化，最后的 e 打印完整堆栈
log.error("[操作描述] 业务标识={}, 关键参数={}", bizId, JSON.toJSONString(param), e);

// 字段缺失场景
log.error("[解析失败] orderNo={}, 缺失字段={}, 原始数据={}", orderNo, "username", rawData, e);
```

```go
// 通用格式 - 对象参数使用 json.Marshal 序列化，%+v 打印完整错误链
paramJson, _ := json.Marshal(param)
log.Error("[操作描述] 业务标识=%s, 关键参数=%s, error=%+v", bizId, string(paramJson), err)

// 或使用 errors 包获取堆栈
log.Error("[操作描述] 业务标识=%s, stack=%+v", bizId, errors.WithStack(err))
```

**正确使用示例**：

```java
// ✅ 正确：外部 I/O 需要 try-catch，记录关键信息 + 完整堆栈
try {
    String content = Files.readString(path);
    return parseJson(content);
} catch (IOException e) {
    // 最后的 e 参数会打印完整异常堆栈
    log.error("[文件读取失败] filePath={}, orderNo={}", path, orderNo, e);
    return defaultValue;
}

// ✅ 正确：JSON 解析失败，记录缺失字段 + 堆栈
try {
    UserDTO user = objectMapper.readValue(json, UserDTO.class);
    return user;
} catch (JsonProcessingException e) {
    // 记录缺失字段信息，e 作为最后参数打印堆栈
    log.error("[JSON解析失败] orderNo={}, 缺失或异常字段={}, 原始JSON={}",
        orderNo, extractMissingField(e), truncate(json, 200), e);
    throw new BusinessException("用户数据解析失败", e);
}
```

```go
// ✅ 正确：Go 语言记录关键信息 + 错误详情
result, err := externalAPI.Call(ctx, request)
if err != nil {
    // 使用 %+v 打印完整错误链和堆栈（如果 err 支持）
    log.Error("[调用外部API失败] orderNo=%s, requestId=%s, error=%+v",
        orderNo, request.ID, err)
    return nil, fmt.Errorf("调用外部API失败, orderNo=%s: %w", orderNo, err)
}
return result, nil

// ✅ 正确：配置解析失败，记录缺失属性
config, err := parseConfig(data)
if err != nil {
    log.Error("[配置解析失败] configId=%s, 缺失属性=%s, error=%+v",
        configId, extractMissingField(err), err)
    return nil, fmt.Errorf("配置解析失败, 缺失属性: %w", err)
}
```

**自检清单**（写 try-catch 前必须问自己）：
- [ ] 这个异常真的可能发生吗？
- [ ] 能否用 if 提前判断来避免异常？
- [ ] catch 之后我要做什么有意义的事？
- [ ] 是否应该让异常传播到全局处理器？
- [ ] 项目是否有统一的异常处理机制？
- [ ] catch 块是否打印了 error 日志？
- [ ] 日志是否包含关键业务标识（单号、用户ID等）？
- [ ] 日志是否说明了缺失的字段或属性（如适用）？
- [ ] 日志最后是否传入了异常对象以打印完整堆栈？

⛔ **阶段门控**：如有待确认问题，必须在进入 GREEN 阶段前向用户统一确认

## 阶段 6: GREEN 🟢

1. 运行测试 → 必须全部通过
2. 检查 `acceptance` 数组每项是否满足
3. **数据样例验证**（如果任务有 `dataSamples` 字段）：
   - 用样例数据实际运行或断言验证解析/处理结果
   - 确认输出与预期一致（字段值、结构、格式）
   - 如果样例包含多种情况，逐一验证
4. **参考方法使用验证**（如果任务有 `references` 字段）：
   - 确认实现代码中确实调用了指定的方法/工具
   - 确认调用方式符合其设计规范
5. **边界验证**：
   - 确认只修改了应该修改的内容
   - 确认没有误改相似但不相关的代码
6. 快速 self-check：
   - ✓ 边界：API 兼容？跨模块调用正常？
   - ✓ 健壮：错误处理？边界情况？
   - ✓ 精准：只改了该改的？没碰不该碰的？

**日志**:
```
[时间戳] [Green] Task N: 实现完成
├─ 状态: green → committing
├─ 决策: 实现要点/权衡取舍
├─ 文件: impl.ts, test.spec.ts（已完成）
├─ Service 抽取: 新增 XXXService.methodName() | 保留在当前类（原因）
├─ 问题: 遇到 XXX → 通过 YYY 解决（或 none）
└─ 下一步: 标记任务完成，提交
---
```

## 阶段 7: COMMIT

1. 设置 `passes: true` 在 features.json
2. 写最终日志

**日志**:
```
[时间戳] [Done] Task N: ✅ 完成
├─ 状态: done
├─ 决策: 关键架构决策总结
├─ 文件: 所有变更文件列表
├─ 问题: 主要问题及解决方案总结
└─ 下一步: /plan-next 继续下一任务
---
```

## 成功标准

任务完成前必须满足：
1. ✅ 测试通过（RED → GREEN）
2. ✅ `acceptance` 全部满足
3. ✅ `passes: true` 已设置
4. ✅ `logs/task-{id}.log` 包含 3-4 条日志

## 恢复指南

**新会话恢复流程**：
```
1. 读 features.json → 找到当前任务
2. 读 logs/task-{id}.log 最后一条 → 查看"状态"和"下一步"
3. 从"下一步"继续执行
```

## 状态对应表

| 状态 | 含义 | 下一步 |
|------|------|--------|
| exploring | 正在分析 | 继续分析或进入 planning |
| planning | 正在规划 | 写测试，进入 red |
| pending-confirm | 阶段结束，等待用户确认问题列表 | 用户确认后进入下一阶段 |
| red | 测试已写，待实现 | 写实现代码 |
| implementing | 正在实现 | 继续实现，然后测试 |
| green | 测试通过 | 检查 acceptance，提交 |
| blocked | 其他阻塞情况 | 解决问题后继续 |
| done | 完成 | /plan-next |

## 完成后输出

```
✅ 任务 [ID] 完成！

📄 日志: logs/task-{id}.log
→ 运行 /plan-next 继续下一任务
```
