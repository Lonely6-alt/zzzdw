<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { authUser } from '../composables/useAuth.js'

const router = useRouter()
const posts = ref([])
const activeCat = ref('全部')
const loading = ref(false)

const categories = ['全部', '面食控', '日料局', '汉堡炸鸡', '轻食沙拉', '甜品时间', '咖啡馆']

const filtered = computed(() =>
  activeCat.value === '全部'
    ? posts.value
    : posts.value.filter(p => p.category === activeCat.value)
)

async function loadPosts() {
  loading.value = true
  try {
    const r = await fetch('/api/posts')
    posts.value = await r.json()
  } finally {
    loading.value = false
  }
}

// 发布表单
const showForm = ref(false)
const form = ref({ title: '', category: '面食控', content: '', emoji: '🍴' })
const formMsg = ref('')

async function publish() {
  formMsg.value = ''
  try {
    const r = await fetch('/api/posts', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${localStorage.getItem('food_token')}`
      },
      body: JSON.stringify(form.value)
    })
    const data = await r.json().catch(() => ({}))
    if (!r.ok) { formMsg.value = data.message || '发布失败'; return }
    showForm.value = false
    form.value = { title: '', category: '面食控', content: '', emoji: '🍴' }
    await loadPosts()
  } catch (e) {
    formMsg.value = '网络错误'
  }
}

function openPost(id) {
  router.push(`/post/${id}`)
}

onMounted(loadPosts)
</script>

<template>
  <div class="home">
    <header class="top">
      <div class="hi">美食广场 <span v-if="authUser">· {{ authUser }}</span></div>
      <button class="publish" @click="showForm = true">＋ 发布美食</button>
    </header>

    <nav class="chips">
      <button
        v-for="c in categories"
        :key="c"
        :class="{ on: activeCat === c }"
        @click="activeCat = c"
      >{{ c }}</button>
    </nav>

    <p v-if="loading" class="hint">加载中…</p>
    <p v-else-if="!filtered.length" class="hint">这个分类还没有美食，来当第一个吧～</p>

    <div class="grid">
      <article
        v-for="p in filtered"
        :key="p.id"
        class="card"
        @click="openPost(p.id)"
      >
        <div class="emoji">{{ p.emoji }}</div>
        <div class="body">
          <span class="tag">{{ p.category }}</span>
          <h3>{{ p.title }}</h3>
          <p class="excerpt">{{ p.content }}</p>
          <div class="meta">@{{ p.author }}</div>
        </div>
      </article>
    </div>

    <!-- 发布弹窗 -->
    <div v-if="showForm" class="modal" @click.self="showForm = false">
      <div class="sheet">
        <h3>发布一道美食</h3>
        <div class="field">
          <label>标题</label>
          <input v-model="form.title" placeholder="例如：巷子里的无名拉面" />
        </div>
        <div class="field">
          <label>分类</label>
          <select v-model="form.category">
            <option v-for="c in categories.filter(c => c !== '全部')" :key="c" :value="c">{{ c }}</option>
          </select>
        </div>
        <div class="field">
          <label>Emoji（可选）</label>
          <input v-model="form.emoji" maxlength="2" placeholder="🍜" />
        </div>
        <div class="field">
          <label>内容</label>
          <textarea v-model="form.content" rows="4" placeholder="分享一下味道、位置和心得…"></textarea>
        </div>
        <div class="msg">{{ formMsg }}</div>
        <div class="actions">
          <button class="ghost" @click="showForm = false">取消</button>
          <button class="btn" @click="publish">发布</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.home{ max-width:980px; margin:0 auto; padding:28px 24px 60px; }
.top{ display:flex; align-items:center; justify-content:space-between; margin-bottom:18px; }
.hi{ font-size:24px; font-weight:800; }
.hi span{ color:var(--tomato); font-size:15px; font-weight:600; }
.publish{
  border:0; border-radius:12px; padding:10px 16px; font-weight:700; color:#fff; cursor:pointer;
  background:linear-gradient(120deg,var(--orange),var(--tomato));
  box-shadow:0 8px 18px rgba(255,90,60,.3);
}
.publish:hover{ transform:translateY(-1px); }

.chips{ display:flex; flex-wrap:wrap; gap:8px; margin-bottom:20px; }
.chips button{
  border:1.5px solid #ecdfd2; background:#fff; color:var(--muted);
  padding:7px 14px; border-radius:20px; font-size:13.5px; cursor:pointer; transition:.2s;
}
.chips button.on{ background:var(--tomato); border-color:var(--tomato); color:#fff; }

.hint{ color:var(--muted); padding:30px 0; text-align:center; }

.grid{ display:grid; grid-template-columns:repeat(3,1fr); gap:16px; }
.card{
  background:#fff; border-radius:16px; overflow:hidden; cursor:pointer;
  box-shadow:0 8px 20px rgba(0,0,0,.05); transition:.2s; display:flex; flex-direction:column;
}
.card:hover{ transform:translateY(-4px); box-shadow:0 14px 28px rgba(255,90,60,.18); }
.emoji{ font-size:40px; padding:18px 18px 0; }
.body{ padding:14px 18px 18px; }
.tag{ display:inline-block; font-size:11.5px; color:var(--tomato); background:#fff0ea;
  padding:3px 9px; border-radius:10px; margin-bottom:8px; }
.card h3{ font-size:16px; margin-bottom:6px; }
.excerpt{ font-size:13px; color:var(--muted); line-height:1.5;
  display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
.meta{ margin-top:10px; font-size:12px; color:#bba; }

@media (max-width:760px){ .grid{ grid-template-columns:repeat(2,1fr); } }

/* 弹窗 */
.modal{ position:fixed; inset:0; background:rgba(0,0,0,.4); display:flex; align-items:center;
  justify-content:center; padding:20px; z-index:20; }
.sheet{ background:#fff; border-radius:18px; padding:24px; width:min(440px,100%);
  box-shadow:0 20px 50px rgba(0,0,0,.25); }
.sheet h3{ margin-bottom:16px; }
.field{ margin-bottom:12px; }
.field label{ display:block; font-size:13px; color:var(--muted); margin-bottom:6px; font-weight:600; }
.field input, .field select, .field textarea{
  width:100%; padding:11px 13px; border:1.5px solid #ecdfd2; border-radius:11px;
  font-size:14px; outline:none; font-family:inherit; resize:vertical;
}
.field input:focus, .field select:focus, .field textarea:focus{ border-color:var(--orange); }
.msg{ color:var(--err); font-size:12.5px; min-height:16px; margin-bottom:8px; }
.actions{ display:flex; gap:10px; }
.actions .btn{ flex:1; padding:12px; border:0; border-radius:12px; font-weight:700; color:#fff;
  background:linear-gradient(120deg,var(--orange),var(--tomato)); cursor:pointer; }
.actions .ghost{ flex:1; padding:12px; border:1.5px solid #ecdfd2; border-radius:12px;
  background:#fff; cursor:pointer; font-weight:600; color:var(--muted); }
</style>
