<script setup>
// 评论管理：列表 / 删除
import { ref, onMounted } from 'vue'
import { adminFetch } from '../../composables/useAdminAuth.js'
import { useToast } from '../../composables/useToast.js'

const { toast } = useToast()
const comments = ref([])
const err = ref('')

async function load() {
  try { comments.value = await adminFetch('/api/admin/comments') }
  catch (e) { err.value = e.message }
}
onMounted(load)

async function remove(c) {
  if (!confirm('确定删除该评论？')) return
  try {
    await adminFetch(`/api/admin/comments/${c.id}`, { method: 'DELETE' })
    toast('已删除', 'success')
    load()
  } catch (e) { toast(e.message, 'error') }
}
</script>

<template>
  <div>
    <h2>评论管理</h2>
    <p v-if="err" class="err">{{ err }}</p>
    <p v-else-if="!comments.length" class="empty">暂无评论</p>
    <div v-else class="list">
      <div v-for="c in comments" :key="c.id" class="item">
        <div class="head">
          <b>{{ c.author || c.username || '匿名用户' }}</b>
          <span class="meta">评论于「{{ c.postTitle }}」 · {{ (c.createdAt || '').slice(0, 10) }}</span>
          <button class="danger" @click="remove(c)">删除</button>
        </div>
        <p class="content">{{ c.content }}</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
h2{ margin: 0 0 16px; color: #3a2f2a; }
.list{ display: flex; flex-direction: column; gap: 12px; }
.item{ background: #fff; border-radius: 14px; padding: 14px 18px; box-shadow: 0 4px 16px rgba(60,40,20,.06); }
.head{ display: flex; align-items: center; gap: 10px; }
.head b{ font-size: 14px; }
.meta{ font-size: 12px; color: #999; flex: 1; }
.danger{
  padding: 4px 12px; border: 1.5px solid #fdecec; border-radius: 8px; background: #fff;
  color: #e5484d; cursor: pointer; font-size: 12px;
}
.danger:hover{ background: #fdecec; }
.content{ margin: 8px 0 0; font-size: 13px; color: #666; line-height: 1.6; }
.err, .empty{ color: #999; }
</style>
