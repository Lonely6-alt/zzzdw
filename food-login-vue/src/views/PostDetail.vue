<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()
const post = ref(null)
const notFound = ref(false)

onMounted(async () => {
  try {
    const r = await fetch(`/api/posts/${route.params.id}`)
    if (r.status === 404) { notFound.value = true; return }
    post.value = await r.json()
  } catch {
    notFound.value = true
  }
})
</script>

<template>
  <div class="detail">
    <button class="back" @click="router.push('/')">← 返回广场</button>

    <p v-if="notFound" class="hint">帖子不存在或已被删除 🥲</p>

    <article v-else-if="post" class="post">
      <div class="emoji">{{ post.emoji }}</div>
      <span class="tag">{{ post.category }}</span>
      <h1>{{ post.title }}</h1>
      <div class="meta">@{{ post.author }} · {{ new Date(post.createdAt).toLocaleDateString() }}</div>
      <p class="content">{{ post.content }}</p>
    </article>
  </div>
</template>

<style scoped>
.detail{ max-width:680px; margin:0 auto; padding:28px 24px 60px; }
.back{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted); padding:8px 14px;
  border-radius:11px; cursor:pointer; font-weight:600; margin-bottom:20px; }
.back:hover{ border-color:var(--orange); color:var(--tomato); }
.hint{ color:var(--muted); padding:40px 0; text-align:center; }
.post .emoji{ font-size:54px; }
.tag{ display:inline-block; font-size:12px; color:var(--tomato); background:#fff0ea;
  padding:4px 11px; border-radius:11px; margin:14px 0 10px; }
.post h1{ font-size:26px; margin-bottom:8px; }
.meta{ color:#bba; font-size:13px; margin-bottom:20px; }
.content{ font-size:16px; line-height:1.8; color:#4a3d33; white-space:pre-wrap; }
</style>
