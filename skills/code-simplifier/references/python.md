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

## 语言特有反模式

- `type(x) == str` — 用 `isinstance(x, str)`
- 手写 `__init__` 只做赋值 — 用 `@dataclass`
- `except:` 或 `except Exception:` 吞掉所有异常 — 捕获具体异常
- 可变默认参数 `def f(items=[])` — 用 `def f(items=None)` + `items = items or []`
- 字符串拼接循环 `s += chunk` — 用 `"".join(chunks)`
- `os.system()` 执行命令 — 用 `subprocess.run()`
- 嵌套 dict 取值链 `d["a"]["b"]["c"]` — 用 `d.get("a", {}).get("b", {}).get("c")` 或专用函数
