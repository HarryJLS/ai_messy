# 代码风格参考

本文档包含 Java 和 Go 的代码注释与异常处理示例。

## 目录

- [接口与实现类注释](#接口与实现类注释)
- [方法调用行注释](#方法调用行注释)
- [异常处理规范](#异常处理规范)

---

## 接口与实现类注释

### Java 接口示例

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

### Java 实现类示例

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

### Go 接口示例

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

### Go 实现示例

```go
// OrderCalculationServiceImpl 订单金额计算服务默认实现
// 实现策略：先计算商品原价 -> 应用折扣规则 -> 加上运费
type OrderCalculationServiceImpl struct {
    discountService DiscountService
    shippingService ShippingService
}

// CalculateTotalAmount 计算订单总金额
func (s *OrderCalculationServiceImpl) CalculateTotalAmount(ctx context.Context, order *Order) (decimal.Decimal, error) {
    // 实现代码
}
```

---

## 方法调用行注释

### Java 示例

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

### Go 示例

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

    // 7. 发送通知: 异步通知用户订单创建成功
    go s.notificationService.SendOrderCreatedNotification(ctx, order)

    return convertToDTO(order), nil
}
```

### 链式调用注释

```java
// 构建用户查询条件: 按部门筛选 + 只查激活用户 + 按创建时间倒序分页
List<User> users = userRepository.findAll(
    Specification.where(UserSpec.byDepartment(deptId))
        .and(UserSpec.isActive()),
    PageRequest.of(page, size, Sort.by("createdAt").descending())
);
```

---

## 异常处理规范

### 何时需要 try-catch

| 场景 | 是否需要 | 理由 |
|------|---------|------|
| 外部 I/O 操作（文件、网络、数据库） | ✅ | 外部系统不可控 |
| 解析外部输入（JSON、XML） | ✅ | 输入格式不可控 |
| 调用第三方库且文档说明会抛异常 | ✅ | 按库设计使用 |
| 业务逻辑需要优雅降级 | ✅ | 明确的业务需求 |

### 何时不需要 try-catch

| 场景 | 正确做法 |
|------|----------|
| 可提前校验的参数 | 用 if 判断 |
| 内部方法调用 | 让异常向上传播 |
| catch 后只是重新抛出 | 删除无意义的 try-catch |

### 反模式示例

```java
// ❌ 错误：不必要的 try-catch
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
// ❌ 错误：catch 后只是重新抛出
try {
    return service.process(data);
} catch (Exception e) {
    throw e;
}

// ✅ 正确：直接调用
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

### 异常日志记录

**必须包含**：业务标识、操作描述、关键参数（对象用 JSON 序列化）、异常堆栈

```java
// Java 日志格式
log.error("[操作描述] 业务标识={}, 关键参数={}", bizId, JSON.toJSONString(param), e);

// 字段缺失场景
log.error("[解析失败] orderNo={}, 缺失字段={}, 原始数据={}", orderNo, "username", rawData, e);
```

```go
// Go 日志格式
paramJson, _ := json.Marshal(param)
log.Error("[操作描述] 业务标识=%s, 关键参数=%s, error=%+v", bizId, string(paramJson), err)
```

### 正确使用示例

```java
// ✅ 外部 I/O 需要 try-catch
try {
    String content = Files.readString(path);
    return parseJson(content);
} catch (IOException e) {
    log.error("[文件读取失败] filePath={}, orderNo={}", path, orderNo, e);
    return defaultValue;
}
```

```go
// ✅ Go 语言错误处理
result, err := externalAPI.Call(ctx, request)
if err != nil {
    log.Error("[调用外部API失败] orderNo=%s, error=%+v", orderNo, err)
    return nil, fmt.Errorf("调用外部API失败: %w", err)
}
```

### 自检清单

写 try-catch 前必须问自己：
- 这个异常真的可能发生吗？
- 能否用 if 提前判断来避免？
- catch 之后我要做什么有意义的事？
- 日志是否包含关键业务标识？
- 日志最后是否传入了异常对象以打印完整堆栈？
