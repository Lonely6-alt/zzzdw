// 下单（纯前端，localStorage 持久化）。订单数据仅存本地用于演示，
// 真实下单请走后端 POST /api/orders（此处预留，不调用）。
import { ref } from 'vue'

const KEY = 'food_orders'
let store = []
try { store = JSON.parse(localStorage.getItem(KEY) || '[]') } catch { store = [] }
const orders = ref(store)

const current = ref(null) // 当前要下单的食物 { id, emoji, title, category, author }
const visible = ref(false)
const done = ref(false)

function persist() {
  localStorage.setItem(KEY, JSON.stringify(orders.value))
}

export function useOrder() {
  function openOrder(item) {
    current.value = item
    done.value = false
    visible.value = true
  }
  function closeOrder() {
    visible.value = false
  }
  function placeOrder({ qty = 1, note = '' } = {}) {
    if (!current.value) return
    const item = current.value
    // === 后端接口预留（暂不调用）===
    // await fetch('/api/orders', { method:'POST', headers:{...}, body: JSON.stringify({ postId:item.id, qty, note }) })
    const entry = {
      id: Date.now(),
      postId: item.id ?? null,
      title: item.title,
      emoji: item.emoji,
      category: item.category,
      author: item.author || '',
      qty,
      note,
      at: Date.now()
    }
    orders.value = [entry, ...orders.value]
    persist()
    done.value = true
  }
  function orderCount() {
    return orders.value.length
  }
  return { current, visible, done, orders, openOrder, closeOrder, placeOrder, orderCount }
}
