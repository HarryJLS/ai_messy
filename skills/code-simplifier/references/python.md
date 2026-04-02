# Python 简化模式

## 1. 推导式替代命令式循环

```python
# Before
result = []
for item in items:
    if item.active:
        result.append(item.name.upper())

# After
result = [item.name.upper() for item in items if item.active]
```

字典推导式同理：

```python
# Before
mapping = {}
for user in users:
    mapping[user.id] = user.name

# After
mapping = {user.id: user.name for user in users}
```

推导式超过一行时考虑保持循环写法——可读性优先。

## 2. dataclass 替代普通类

```python
# Before
class Config:
    def __init__(self, host, port, debug=False):
        self.host = host
        self.port = port
        self.debug = debug

    def __repr__(self):
        return f"Config(host={self.host}, port={self.port}, debug={self.debug})"

    def __eq__(self, other):
        return (self.host == other.host and
                self.port == other.port and
                self.debug == other.debug)

# After
@dataclass
class Config:
    host: str
    port: int
    debug: bool = False
```

dataclass 自动生成 `__init__`、`__repr__`、`__eq__`。数据容器场景首选。

## 3. walrus operator 简化赋值+判断（Python 3.8+）

```python
# Before
line = f.readline()
while line:
    process(line)
    line = f.readline()

# After
while (line := f.readline()):
    process(line)
```

```python
# Before
match = pattern.search(text)
if match:
    handle(match.group())

# After
if (match := pattern.search(text)):
    handle(match.group())
```

消除"先赋值再判断"的重复。只在简单场景使用，不要嵌套。

## 4. pathlib 替代 os.path

```python
# Before
import os

config_path = os.path.join(base_dir, "config", "settings.json")
if os.path.exists(config_path):
    with open(config_path) as f:
        data = f.read()
parent = os.path.dirname(config_path)
os.makedirs(parent, exist_ok=True)

# After
from pathlib import Path

config_path = Path(base_dir) / "config" / "settings.json"
if config_path.exists():
    data = config_path.read_text()
config_path.parent.mkdir(parents=True, exist_ok=True)
```

pathlib 提供面向对象的路径操作，`/` 操作符比 `os.path.join` 更直观。

## 5. contextmanager 简化资源管理

```python
# Before
class Timer:
    def __enter__(self):
        self.start = time.time()
        return self

    def __exit__(self, *args):
        self.elapsed = time.time() - self.start
        print(f"Elapsed: {self.elapsed:.2f}s")

# After
@contextmanager
def timer():
    start = time.time()
    yield
    elapsed = time.time() - start
    print(f"Elapsed: {elapsed:.2f}s")
```

简单的 enter/exit 用 `@contextmanager` 比写完整类更简洁。

## 6. 方法提取

将多职责函数拆分为 `_private` 方法。提取后在跳转处加注释。

```python
# Before — 一个方法做四件事
def process_order(self, order_data: dict) -> OrderResult:
    # 校验
    if not order_data.get("items"):
        raise ValueError("items cannot be empty")
    if not order_data.get("user_id"):
        raise ValueError("user_id is required")

    # 计算价格
    total = sum(
        item["price"] * item["quantity"]
        for item in order_data["items"]
    )
    discount = self.promotion_service.calculate_discount(order_data["user_id"], total)
    final_total = total - discount

    # 保存
    order = Order(
        user_id=order_data["user_id"],
        items=order_data["items"],
        total=final_total,
    )
    self.order_repo.save(order)

    # 通知
    self.event_bus.publish("order_created", order.id)
    return OrderResult.from_order(order)

# After — 编排入口 + _private 方法
def process_order(self, order_data: dict) -> OrderResult:
    self._validate_order(order_data)
    total = self._calculate_total(order_data["items"], order_data["user_id"])
    order = self._save_order(order_data, total)
    # 事件驱动：下游监听者异步处理库存扣减、邮件等
    self._publish_order_created(order)
    return OrderResult.from_order(order)

def _validate_order(self, order_data: dict) -> None:
    if not order_data.get("items"):
        raise ValueError("items cannot be empty")
    if not order_data.get("user_id"):
        raise ValueError("user_id is required")

def _calculate_total(self, items: list[dict], user_id: str) -> Decimal:
    total = sum(item["price"] * item["quantity"] for item in items)
    discount = self.promotion_service.calculate_discount(user_id, total)
    return total - discount

def _save_order(self, order_data: dict, total: Decimal) -> Order:
    order = Order(
        user_id=order_data["user_id"],
        items=order_data["items"],
        total=total,
    )
    self.order_repo.save(order)
    return order

def _publish_order_created(self, order: Order) -> None:
    self.event_bus.publish("order_created", order.id)
```

注释只在事件发布处——这是一个隐式跳转，读者需要知道下游由谁处理。

## 语言特有反模式

- `type(x) == str` — 用 `isinstance(x, str)`
- 手写 `__init__` 只做赋值 — 用 `@dataclass`
- `except:` 或 `except Exception:` 吞掉所有异常 — 捕获具体异常
- 可变默认参数 `def f(items=[])` — 用 `def f(items=None)` + `items = items or []`
- 字符串拼接循环 `s += chunk` — 用 `"".join(chunks)`
- `os.system()` 执行命令 — 用 `subprocess.run()`
- 嵌套 dict 取值链 `d["a"]["b"]["c"]` — 用 `d.get("a", {}).get("b", {}).get("c")` 或专用函数
