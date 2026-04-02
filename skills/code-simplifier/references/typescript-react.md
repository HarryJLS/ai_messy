# TypeScript + React 简化模式

## 1. 可选链和空值合并替代嵌套判断

```typescript
// Before
const cityName =
  user && user.address && user.address.city
    ? user.address.city.name
    : "Unknown";

// After
const cityName = user?.address?.city?.name ?? "Unknown";
```

`?.` 短路返回 undefined，`??` 只在 null/undefined 时取默认值（不像 `||` 会对 `0`、`""` 也生效）。

## 2. 组件拆分（过大组件 → 子组件）

```tsx
// Before — 一个组件做了太多事
function UserProfile({ user }: Props) {
  return (
    <div>
      <div className="avatar-section">
        <img src={user.avatar} alt={user.name} />
        <h2>{user.name}</h2>
        <span>{user.role}</span>
      </div>
      <div className="stats-section">
        <div>{user.posts} posts</div>
        <div>{user.followers} followers</div>
        <div>{user.following} following</div>
      </div>
      <div className="bio-section">
        <p>{user.bio}</p>
        <a href={user.website}>{user.website}</a>
      </div>
    </div>
  );
}

// After — 拆分为语义明确的子组件
function UserAvatar({ user }: Pick<Props, "user">) {
  return (
    <div className="avatar-section">
      <img src={user.avatar} alt={user.name} />
      <h2>{user.name}</h2>
      <span>{user.role}</span>
    </div>
  );
}

function UserStats({ user }: Pick<Props, "user">) {
  return (
    <div className="stats-section">
      <div>{user.posts} posts</div>
      <div>{user.followers} followers</div>
      <div>{user.following} following</div>
    </div>
  );
}

function UserProfile({ user }: Props) {
  return (
    <div>
      <UserAvatar user={user} />
      <UserStats user={user} />
      <div className="bio-section">
        <p>{user.bio}</p>
        <a href={user.website}>{user.website}</a>
      </div>
    </div>
  );
}
```

拆分的信号：组件超过 150 行、内部有明显的逻辑分区、或同一段 JSX 可能在其他地方复用。

## 3. 自定义 Hook 提取重复状态逻辑

```tsx
// Before — 多个组件重复相同的 fetch 逻辑
function UserList() {
  const [data, setData] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    fetch("/api/users")
      .then((res) => res.json())
      .then(setData)
      .catch(setError)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;
  return <List items={data} />;
}

// After — 提取为通用 Hook
function useFetch<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    fetch(url)
      .then((res) => res.json())
      .then(setData)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [url]);

  return { data, loading, error };
}

function UserList() {
  const { data, loading, error } = useFetch<User[]>("/api/users");
  if (loading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;
  return <List items={data!} />;
}
```

提取的信号：2 个以上组件有相同的 useState + useEffect 组合。

## 4. 类型收窄替代类型断言

```typescript
// Before — 用 as 强制断言，运行时可能出错
function processEvent(event: Event) {
  const target = event.target as HTMLInputElement;
  console.log(target.value);
}

// After — 用类型守卫安全收窄
function processEvent(event: Event) {
  const target = event.target;
  if (target instanceof HTMLInputElement) {
    console.log(target.value);
  }
}
```

`as` 断言绕过了类型检查，类型守卫让 TypeScript 在收窄后的块内自动推断正确类型。

## 5. 条件渲染简化

```tsx
// Before — 冗余的三元
function Banner({ show }: { show: boolean }) {
  return (
    <div>
      {show ? <Alert message="Warning!" /> : null}
    </div>
  );
}

// After — && 短路
function Banner({ show }: { show: boolean }) {
  return (
    <div>
      {show && <Alert message="Warning!" />}
    </div>
  );
}
```

```tsx
// Before — 多层嵌套条件
function Status({ status }: { status: string }) {
  return (
    <div>
      {status === "loading" ? (
        <Spinner />
      ) : status === "error" ? (
        <Error />
      ) : status === "empty" ? (
        <Empty />
      ) : (
        <Content />
      )}
    </div>
  );
}

// After — 提前 return 或 map
const statusComponents: Record<string, React.FC> = {
  loading: Spinner,
  error: Error,
  empty: Empty,
};

function Status({ status }: { status: string }) {
  const Component = statusComponents[status] ?? Content;
  return (
    <div>
      <Component />
    </div>
  );
}
```

## 6. useMemo/useCallback 合理使用

```tsx
// Before — 过度优化：原始值和简单计算不需要 memo
const label = useMemo(() => `${firstName} ${lastName}`, [firstName, lastName]);
const handleClick = useCallback(() => setOpen(true), []);

// After — 只 memo 开销大的计算或引用稳定性关键的回调
const label = `${firstName} ${lastName}`;
const handleClick = () => setOpen(true);

// 真正需要 memo 的场景：
const sortedItems = useMemo(
  () => items.toSorted((a, b) => a.score - b.score),
  [items]
);
```

useMemo/useCallback 本身有开销。只在以下场景使用：昂贵计算、作为依赖传给子组件的 memo、作为 useEffect 依赖。

## 7. 函数提取

非组件的工具函数/服务方法同样需要拆分。提取后在跳转处加注释。

```typescript
// Before — 一个函数做四件事
async function processCheckout(cart: Cart, user: User): Promise<Order> {
  // 校验库存
  for (const item of cart.items) {
    const stock = await inventoryApi.getStock(item.skuId);
    if (stock < item.quantity) {
      throw new InsufficientStockError(item.skuId);
    }
  }

  // 计算折扣
  const subtotal = cart.items.reduce((sum, i) => sum + i.price * i.quantity, 0);
  const discount = await promotionApi.getDiscount(user.id, subtotal);
  const total = subtotal - discount;

  // 创建支付
  const paymentIntent = await paymentApi.create({
    amount: total,
    userId: user.id,
  });
  const order = await orderApi.create({
    cartId: cart.id,
    paymentId: paymentIntent.id,
    total,
  });

  // 发确认邮件
  await emailApi.sendConfirmation(user.email, order);
  return order;
}

// After — 编排入口 + 模块内函数
async function processCheckout(cart: Cart, user: User): Promise<Order> {
  // 库存不足抛 InsufficientStockError，前端据此展示补货提示
  await validateStock(cart.items);
  const total = await calculateTotal(cart, user);
  const order = await createPaymentAndOrder(cart, user, total);
  // fire-and-forget：邮件失败不阻塞结账
  emailApi.sendConfirmation(user.email, order).catch(console.error);
  return order;
}

async function validateStock(items: CartItem[]): Promise<void> {
  for (const item of items) {
    const stock = await inventoryApi.getStock(item.skuId);
    if (stock < item.quantity) {
      throw new InsufficientStockError(item.skuId);
    }
  }
}

async function calculateTotal(cart: Cart, user: User): Promise<number> {
  const subtotal = cart.items.reduce((sum, i) => sum + i.price * i.quantity, 0);
  const discount = await promotionApi.getDiscount(user.id, subtotal);
  return subtotal - discount;
}

async function createPaymentAndOrder(
  cart: Cart,
  user: User,
  total: number,
): Promise<Order> {
  const paymentIntent = await paymentApi.create({ amount: total, userId: user.id });
  return orderApi.create({
    cartId: cart.id,
    paymentId: paymentIntent.id,
    total,
  });
}
```

两处注释：`validateStock` 可能中断流程，`sendConfirmation` 改为 fire-and-forget 模式——这些跳转行为需要读者注意。

## 语言特有反模式

- `any` 类型 — 用 `unknown` + 类型守卫，或定义具体类型
- `enum` — 用 `as const` 对象或联合类型（tree-shaking 更友好）
- `index.ts` 只做 re-export — 除非是公共 API 边界，否则直接导入源文件
- 内联样式对象在 render 中创建 — 提到组件外或用 useMemo
- `useEffect` 做数据派生 — 用 useMemo 或直接计算
- 把所有 props 透传 `{...props}` — 明确列出需要的 props
