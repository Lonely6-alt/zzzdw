<script setup>
// 店铺管理：列表 / 关键词搜索 / 营业状态切换 / 关店
import { ref, computed, onMounted } from 'vue'
import { adminFetch } from '../../composables/useAdminAuth.js'
import { useToast } from '../../composables/useToast.js'

const { toast } = useToast()
const shops = ref([])
const keyword = ref('')
const filter = ref('')   // '' | active | closed
const err = ref('')
const loading = ref(false)

async function load() {
  loading.value = true
  try {
    const q = keyword.value.trim() ? `?keyword=${encodeURIComponent(keyword.value.trim())}` : ''
    shops.value = await adminFetch(`/api/admin/shops${q}`)
    err.value = ''
  } catch (e) {
    err.value = e.message
  } finally {
    loading.value = false
  }
}
onMounted(load)

const list = computed(() =>
  filter.value ? shops.value.filter(s => s.status === filter.value) : shops.value
)

async function toggle(s) {
  const status = s.status === 'active' ? 'closed' : 'active'
  try {
    await adminFetch(`/api/admin/shops/${s.shopId}`, { method: 'PATCH', body: JSON.stringify({ status }) })
    toast(status === 'active' ? '已恢复营业' : '已设为休息', 'success')
    load()
  } catch (e) { toast(e.message, 'error') }
}

async function remove(s) {
  if (!confirm(`确定关闭店铺「${s.shopName}」？店内菜品会保留，只是不再归属于店铺。`)) return
  try {
    await adminFetch(`/api/admin/shops/${s.shopId}`, { method: 'DELETE' })
    toast('店铺已关闭', 'success')
    load()
  } catch (e) { toast(e.message, 'error') }
}

function fmtDate(v) { return (v || '').slice(0, 10) }
function avg(v) { return Number(v || 0).toFixed(1) }
</script>

<template>
  <div>
    <h2>店铺管理</h2>

    <div class="bar">
      <input v-model.trim="keyword" placeholder="搜索店名或简介…" @keyup.enter="load" />
      <button class="search" @click="load">搜索</button>
      <span class="spacer"></span>
      <button v-for="f in [
        { v: '', label: '全部' },
        { v: 'active', label: '营业中' },
        { v: 'closed', label: '休息中' }
      ]" :key="f.v" :class="{ active: filter === f.v }" @click="filter = f.v">{{ f.label }}</button>
    </div>

    <p v-if="err" class="err">{{ err }}</p>
    <p v-else-if="loading" class="empty">加载中…</p>
    <p v-else-if="!list.length" class="empty">暂无店铺</p>
    <table v-else>
      <thead>
        <tr>
          <th>店铺</th><th>店主</th><th>商圈</th><th>菜品</th>
          <th>均分</th><th>点评</th><th>收藏</th><th>状态</th><th>开店时间</th><th>操作</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="s in list" :key="s.shopId">
          <td>
            <span class="shop-emoji">{{ s.emoji || '🏠' }}</span>
            <b>{{ s.shopName }}</b>
            <div class="desc">{{ s.description || '—' }}</div>
          </td>
          <td>@{{ s.ownerName || '未知' }}</td>
          <td>{{ s.district || '—' }}</td>
          <td>{{ s.postCount ?? 0 }}</td>
          <td>{{ avg(s.avgRating) }}</td>
          <td>{{ s.reviewCount ?? 0 }}</td>
          <td>{{ s.favoriteCount ?? 0 }}</td>
          <td><span :class="['st', s.status]">{{ s.status === 'active' ? '营业中' : '休息中' }}</span></td>
          <td>{{ fmtDate(s.createTime) }}</td>
          <td class="ops">
            <button @click="toggle(s)">{{ s.status === 'active' ? '设为休息' : '恢复营业' }}</button>
            <button class="danger" @click="remove(s)">关店</button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<style scoped>
h2{ margin: 0 0 16px; color: #3a2f2a; }
.bar{ display: flex; gap: 8px; margin-bottom: 16px; flex-wrap: wrap; align-items: center; }
input{
  padding: 9px 12px; border: 1.5px solid #eee0d2; border-radius: 10px; font-size: 13px; outline: none;
  min-width: 200px;
}
input:focus{ border-color: #ff5a3c; }
.bar button{
  padding: 8px 16px; border: 1.5px solid #eee0d2; border-radius: 10px; background: #fff;
  cursor: pointer; font-size: 13px;
}
.bar button:hover{ border-color: #ff5a3c; color: #ff5a3c; }
.bar button.active{ background: linear-gradient(120deg, #ff7a45, #ff5a3c); color: #fff; border-color: transparent; }
.bar button.search{ background: linear-gradient(120deg, #ff7a45, #ff5a3c); color: #fff; border-color: transparent; font-weight: 700; }
.spacer{ flex: 1; }

table{ width: 100%; border-collapse: collapse; background: #fff; border-radius: 14px; overflow: hidden; }
th, td{ padding: 11px 12px; text-align: left; font-size: 13px; border-bottom: 1px solid #f3ece4; vertical-align: middle; }
th{ background: #faf5ee; color: #8a7a6d; font-weight: 700; white-space: nowrap; }
td b{ font-weight: 700; }
.shop-emoji{ font-size: 18px; margin-right: 6px; }
.desc{ font-size: 11.5px; color: #a49789; margin-top: 3px; max-width: 240px;
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.st{ font-size: 12px; padding: 3px 9px; border-radius: 8px; white-space: nowrap; }
.st.active{ background: #e6f6ec; color: #2e9e5b; }
.st.closed{ background: #f1ece5; color: #8a7a6d; }
.ops{ white-space: nowrap; }
.ops button{
  margin-right: 6px; padding: 5px 10px; border: 1.5px solid #eee0d2; border-radius: 8px;
  background: #fff; cursor: pointer; font-size: 12px;
}
.ops button:hover{ border-color: #ff5a3c; color: #ff5a3c; }
.ops button.danger{ color: #e5484d; }
.ops button.danger:hover{ border-color: #e5484d; }
.err{ color: #e5484d; }
.empty{ color: #999; }
</style>
