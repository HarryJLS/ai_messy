# Frontend 自动修复规则

React/TypeScript/Tailwind 自动修复项。

## AUTO 修复项

### 1. 列表 key 属性

**检测**:
```tsx
{items.map((item) => <Item />)}
```

**修复**:
```tsx
{items.map((item) => <Item key={item.id} />)}
```

### 2. index 作为 key

**检测**:
```tsx
{items.map((item, index) => <Item key={index} />)}
```

**修复** (如果项目有唯一 id):
```tsx
{items.map((item) => <Item key={item.id} />)}
```

### 3. 事件处理器类型

**检测**:
```tsx
const handleClick = (e) => { ... }
```

**修复**:
```tsx
const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => { ... }
```

### 4. 空依赖数组修复

**检测**: useEffect 引用外部变量但依赖数组为空
**修复**: 添加缺失的依赖

```tsx
// 检测
useEffect(() => {
    console.log(value);
}, []);

// 修复
useEffect(() => {
    console.log(value);
}, [value]);
```

### 5. any 类型注释

**检测**: `: any` 无注释
**修复**: 添加 TODO 注释

```tsx
// 检测
const data: any = response;

// 修复
// TODO: Replace any with proper type
const data: any = response;
```

---

## CONFIRM 修复项

### 1. 组件拆分

**条件**: 组件超过 300 行
**确认内容**: 提供拆分方案

### 2. 状态提升

**检测**: props drilling 超过 2 层
**建议**: 使用 Context 或状态管理

### 3. useMemo/useCallback

**检测**: 大型计算或频繁创建的回调未优化
**建议**: 添加 useMemo 或 useCallback

### 4. React Query 替换

**检测**: useEffect 中直接 fetch
**建议**: 改用 React Query

### 5. useEffect 竞态条件修复

**检测**: async useEffect 无 cleanup
**建议**: 添加 cancelled flag 或 AbortController

```tsx
// 检测
useEffect(() => {
    fetchData(id).then(setData);
}, [id]);

// 建议修复
useEffect(() => {
    let cancelled = false;
    fetchData(id).then(data => {
        if (!cancelled) setData(data);
    });
    return () => { cancelled = true; };
}, [id]);
```

### 6. 闭包陈旧状态修复

**检测**: setTimeout/setInterval 中直接使用 state 值
**建议**: 改用函数式更新 `setState(prev => ...)` 或 useRef

```tsx
// 检测
setInterval(() => {
    setCount(count + 1);
}, 1000);

// 建议修复
setInterval(() => {
    setCount(prev => prev + 1);
}, 1000);
```

---

## SKIP 项 (禁止修改)

### 变量/组件命名
即使不符合规范也不修改：
- 组件名
- props 名
- 状态变量名
- 回调函数名

**仅在报告中提示**:
```
[SKIP] Button.tsx:10 组件 `btn` 建议改为 `Button`（已跳过，不修改命名）
```
