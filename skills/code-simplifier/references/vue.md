# Vue 简化模式

适用于 Vue 3（Composition API）和 Vue 2（Options API）。

## 1. composables 提取重复状态逻辑（Vue 3）

```vue
<!-- Before — 多个组件重复相同的 fetch 逻辑 -->
<script setup lang="ts">
import { ref, onMounted } from 'vue'

const data = ref<User[]>([])
const loading = ref(true)
const error = ref<Error | null>(null)

onMounted(async () => {
  try {
    const res = await fetch('/api/users')
    data.value = await res.json()
  } catch (e) {
    error.value = e as Error
  } finally {
    loading.value = false
  }
})
</script>

<!-- After — 提取为 composable -->
```

```typescript
// composables/useFetch.ts
export function useFetch<T>(url: string) {
  const data = ref<T | null>(null)
  const loading = ref(true)
  const error = ref<Error | null>(null)

  onMounted(async () => {
    try {
      const res = await fetch(url)
      data.value = await res.json()
    } catch (e) {
      error.value = e as Error
    } finally {
      loading.value = false
    }
  })

  return { data, loading, error }
}
```

```vue
<script setup lang="ts">
const { data, loading, error } = useFetch<User[]>('/api/users')
</script>
```

提取信号：2 个以上组件有相同的 ref + onMounted/watch 组合。

## 2. computed 替代 watch + ref

```vue
<!-- Before — 用 watch 做数据派生 -->
<script setup lang="ts">
const items = ref<Item[]>([])
const activeCount = ref(0)

watch(items, (newItems) => {
  activeCount.value = newItems.filter(i => i.active).length
}, { immediate: true, deep: true })
</script>

<!-- After — computed 自动追踪依赖 -->
<script setup lang="ts">
const items = ref<Item[]>([])
const activeCount = computed(() => items.value.filter(i => i.active).length)
</script>
```

computed 是响应式的缓存属性。只在需要副作用（API 调用、DOM 操作）时才用 watch。

## 3. defineProps/defineEmits 类型声明简化（Vue 3.3+）

```vue
<!-- Before — 运行时声明 -->
<script setup lang="ts">
const props = defineProps({
  title: { type: String, required: true },
  count: { type: Number, default: 0 },
  items: { type: Array as PropType<Item[]>, default: () => [] }
})

const emit = defineEmits(['update', 'delete'])
</script>

<!-- After — 纯类型声明（Vue 3.3+ 支持默认值） -->
<script setup lang="ts">
const { title, count = 0, items = [] } = defineProps<{
  title: string
  count?: number
  items?: Item[]
}>()

const emit = defineEmits<{
  update: [id: string, value: number]
  delete: [id: string]
}>()
</script>
```

纯类型声明更简洁，且 IDE 类型推断更准确。Vue 3.3+ 支持解构默认值。

## 4. v-bind 简写和动态属性

```vue
<!-- Before — 冗余写法 -->
<template>
  <UserCard
    v-bind:name="user.name"
    v-bind:email="user.email"
    v-bind:avatar="user.avatar"
    v-on:click="handleClick"
  />
</template>

<!-- After — 简写 + 同名简写（Vue 3.4+） -->
<template>
  <UserCard
    :name="user.name"
    :email="user.email"
    :avatar="user.avatar"
    @click="handleClick"
  />
</template>

<!-- 当变量名与 prop 同名时（Vue 3.4+）-->
<template>
  <UserCard :name :email :avatar @click="handleClick" />
</template>
```

## 5. 模板中复杂表达式提取为 computed

```vue
<!-- Before — 模板中嵌入复杂逻辑 -->
<template>
  <div v-if="items.filter(i => i.active && i.score > 80).length > 0">
    {{ items.filter(i => i.active && i.score > 80).map(i => i.name).join(', ') }}
  </div>
</template>

<!-- After — 提取为 computed -->
<script setup lang="ts">
const highScoreNames = computed(() =>
  items.value
    .filter(i => i.active && i.score > 80)
    .map(i => i.name)
)
</script>

<template>
  <div v-if="highScoreNames.length > 0">
    {{ highScoreNames.join(', ') }}
  </div>
</template>
```

模板中的表达式应该简单到一眼能看懂。超过一行的逻辑提取为 computed。

## Vue 2 Options API 简化

Vue 2 项目中，以下模式同样适用：

```javascript
// Before — data 中放派生数据 + watch 同步
export default {
  data() {
    return {
      items: [],
      filteredItems: []
    }
  },
  watch: {
    items(newVal) {
      this.filteredItems = newVal.filter(i => i.active)
    }
  }
}

// After — 用 computed
export default {
  data() {
    return { items: [] }
  },
  computed: {
    filteredItems() {
      return this.items.filter(i => i.active)
    }
  }
}
```

## 6. setup 逻辑提取

`<script setup>` 中逻辑过长时，按职责提取为独立函数或 composable。提取后在跳转处加注释。

```vue
<!-- Before — setup 中混合了表单校验、提交、通知 -->
<script setup lang="ts">
import { ref } from 'vue'

const form = ref({ name: '', email: '' })
const loading = ref(false)
const error = ref<string | null>(null)

async function handleSubmit() {
  // 校验
  if (!form.value.name.trim()) {
    error.value = '名称不能为空'
    return
  }
  if (!form.value.email.includes('@')) {
    error.value = '邮箱格式不正确'
    return
  }

  // 提交
  loading.value = true
  error.value = null
  try {
    const res = await fetch('/api/users', {
      method: 'POST',
      body: JSON.stringify(form.value),
    })
    if (!res.ok) throw new Error('提交失败')
    const user = await res.json()

    // 通知
    ElMessage.success('创建成功')
    emit('created', user)
  } catch (e) {
    error.value = (e as Error).message
  } finally {
    loading.value = false
  }
}
</script>

<!-- After — 按职责提取 -->
<script setup lang="ts">
import { ref } from 'vue'

const form = ref({ name: '', email: '' })
const loading = ref(false)
const error = ref<string | null>(null)

function validateForm(): string | null {
  if (!form.value.name.trim()) return '名称不能为空'
  if (!form.value.email.includes('@')) return '邮箱格式不正确'
  return null
}

async function submitUser(data: { name: string; email: string }) {
  const res = await fetch('/api/users', {
    method: 'POST',
    body: JSON.stringify(data),
  })
  if (!res.ok) throw new Error('提交失败')
  return res.json()
}

async function handleSubmit() {
  // 校验失败提前返回，不发请求
  const validationError = validateForm()
  if (validationError) {
    error.value = validationError
    return
  }

  loading.value = true
  error.value = null
  try {
    const user = await submitUser(form.value)
    ElMessage.success('创建成功')
    // 通知父组件刷新列表
    emit('created', user)
  } catch (e) {
    error.value = (e as Error).message
  } finally {
    loading.value = false
  }
}
</script>
```

注释加在两处跳转：校验失败的提前返回，以及 `emit` 触发父组件行为。

## 语言特有反模式

- `this.$forceUpdate()` — 说明响应式数据结构有问题，应修复数据声明
- `v-for` 没有 `:key` — 始终提供唯一且稳定的 key
- `v-if` 和 `v-for` 在同一元素 — v-if 优先级更高（Vue 3），用 `<template v-for>` 包裹
- 直接修改 props — 用 emit 通知父组件修改
- 在 `created/mounted` 中大量初始化 — 提取为 composable 或独立函数
- 深度 watch 整个对象 `watch: { obj: { deep: true } }` — 监听具体路径 `'obj.key'`
- 事件总线（EventBus）— Vue 3 用 provide/inject 或状态管理库
