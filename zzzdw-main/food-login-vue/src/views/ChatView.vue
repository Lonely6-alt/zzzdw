<script setup>
import { ref, computed, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getToken } from '../composables/useAuth.js'

const route = useRoute()
const router = useRouter()

const sessions = ref([])
const activeId = ref(null)
const activePeer = ref({ id: null, name: '' })
const messages = ref([])
const draft = ref('')
const loading = ref(false)
const err = ref('')
const listTimer = ref(null)
const msgTimer = ref(null)
const bubbleBox = ref(null)

const auth = ref(localStorage.getItem('food_user') || '')

const API = '/api/chat'
function h(extra = {}) {
  return { 'Content-Type': 'application/json', Authorization: `Bearer ${getToken()}`, ...extra }
}

async function loadSessions() {
  try {
    const r = await fetch(`${API}/sessions`, { headers: h() })
    if (!r.ok) throw new Error('加载会话失败')
    sessions.value = await r.json()
  } catch (e) { err.value = e.message }
}

async function openSession(id, peerId, peerName) {
  activeId.value = id
  activePeer.value = { id: peerId, name: peerName }
  clearInterval(msgTimer.value)
  await loadMessages()
  // 当前会话已读，清掉列表上的未读角标
  const s = sessions.value.find(x => x.sessionId === id)
  if (s) s.unread = 0
  msgTimer.value = setInterval(loadMessages, 4000)
}

async function loadMessages() {
  if (!activeId.value) return
  try {
    const r = await fetch(`${API}/sessions/${activeId.value}/messages`, { headers: h() })
    if (!r.ok) return
    const fresh = await r.json()
    const changed = fresh.length !== messages.value.length ||
      (fresh.length && messages.value.length &&
        fresh[fresh.length - 1].msgId !== messages.value[messages.value.length - 1].msgId)
    messages.value = fresh
    if (changed) nextTick(scrollBottom)
    // 同步左侧列表摘要
    const s = sessions.value.find(x => x.sessionId === activeId.value)
    if (s && fresh.length) {
      s.lastMsg = fresh[fresh.length - 1].content
      s.lastTime = fresh[fresh.length - 1].sendTime
    }
  } catch { /* 静默轮询 */ }
}

async function openByPeerName(name) {
  if (!name) return
  loading.value = true
  try {
    const r = await fetch(`${API}/sessions`, {
      method: 'POST', headers: h(),
      body: JSON.stringify({ peerUsername: name })
    })
    const d = await r.json().catch(() => ({}))
    if (!r.ok) throw new Error(d.message || '打开会话失败')
    await loadSessions()
    openSession(d.sessionId, d.peerId, d.peerName)
  } catch (e) { err.value = e.message }
  finally { loading.value = false }
}

async function send() {
  const content = draft.value.trim()
  if (!content || !activeId.value) return
  try {
    const r = await fetch(`${API}/sessions/${activeId.value}/messages`, {
      method: 'POST', headers: h(),
      body: JSON.stringify({ content })
    })
    if (!r.ok) throw new Error('发送失败')
    draft.value = ''
    await loadMessages()
    loadSessions()
  } catch (e) { err.value = e.message }
}

function scrollBottom() {
  const el = bubbleBox.value
  if (el) el.scrollTop = el.scrollHeight
}

function fmtTime(t) {
  if (!t) return ''
  return t.replace('T', ' ').slice(5, 16)
}
function isMine(m) { return m.senderId !== activePeer.value.id }
function shortTime(t) { return t ? t.replace('T', ' ').slice(11, 16) : '' }

onMounted(async () => {
  await loadSessions()
  // 支持 /chat?peer=xxx 直接打开与某人的会话（帖子页跳转）
  const peer = route.query.peer
  if (peer) openByPeerName(String(peer))
  listTimer.value = setInterval(loadSessions, 6000)
})
onBeforeUnmount(() => { clearInterval(listTimer.value); clearInterval(msgTimer.value) })

const sortedSessions = computed(() => sessions.value)
</script>

<template>
  <div class="chat-page">
    <div class="chat-shell">
      <!-- 会话列表 -->
      <aside class="chat-side">
        <div class="side-head">💬 私信会话</div>
        <ul class="s-list">
          <li
            v-for="s in sortedSessions"
            :key="s.sessionId"
            :class="{ on: s.sessionId === activeId }"
            @click="openSession(s.sessionId, s.peerId, s.peerName)"
          >
            <span class="s-avatar">{{ (s.peerName || '?')[0] }}</span>
            <div class="s-main">
              <div class="s-top">
                <span class="s-name">@{{ s.peerName }}</span>
                <span class="s-time">{{ shortTime(s.lastTime) }}</span>
              </div>
              <div class="s-msg">{{ s.lastMsg || '开始聊天吧～' }}</div>
            </div>
            <span v-if="s.unread > 0" class="s-dot">{{ s.unread > 99 ? '99+' : s.unread }}</span>
          </li>
          <li v-if="!sortedSessions.length" class="s-empty">
            <span class="s-empty-emoji">🍽️</span>
            还没有会话<br />去帖子卡片点作者昵称，发起第一句私聊吧
          </li>
        </ul>
      </aside>

      <!-- 聊天窗口 -->
      <section class="chat-main">
        <template v-if="activeId">
          <div class="c-head">
            <button class="back" @click="router.push('/')">‹ 返回首页</button>
            <span class="c-peer">与 @{{ activePeer.name }} 聊天</span>
            <span class="c-live"><i></i>在线（轮询刷新中）</span>
          </div>
          <div class="c-box" ref="bubbleBox">
            <div
              v-for="m in messages"
              :key="m.msgId"
              class="row"
              :class="{ mine: isMine(m) }"
            >
              <div class="bubble" :class="{ mine: isMine(m) }">
                <p class="b-text">{{ m.content }}</p>
                <span class="b-time">{{ fmtTime(m.sendTime) }}</span>
              </div>
            </div>
            <div v-if="!messages.length" class="c-empty">打个招呼吧 👋</div>
          </div>
          <div class="c-input">
            <input
              v-model="draft"
              type="text"
              placeholder="输入消息，回车发送…"
              maxlength="1000"
              @keydown.enter="send"
            />
            <button :disabled="!draft.trim()" @click="send">发送</button>
          </div>
        </template>
        <div v-else class="c-placeholder">
          <span class="p-emoji">💬</span>
          <p>选择左侧会话，或从帖子卡片点击作者昵称发起私信</p>
        </div>
      </section>
    </div>
    <p v-if="err" class="chat-err">{{ err }}</p>
  </div>
</template>

<style scoped>
.chat-page{ max-width:1040px; margin:0 auto; padding:20px 24px 60px; }
.chat-shell{ display:flex; height:calc(100vh - 190px); min-height:460px; background:#fff;
  border:1.5px solid #f0e6db; border-radius:20px; overflow:hidden; box-shadow:0 12px 30px rgba(255,90,60,.08); }

/* 左侧会话列表 */
.chat-side{ width:280px; flex-shrink:0; border-right:1.5px solid #f0e6db; background:#fffaf4; display:flex; flex-direction:column; }
.side-head{ padding:16px; font-size:15px; font-weight:800; color:#7e5a3e; border-bottom:1.5px solid #f0e6db; }
.s-list{ flex:1; overflow-y:auto; list-style:none; margin:0; padding:8px; }
.s-list li{ display:flex; align-items:center; gap:10px; padding:10px; border-radius:12px; cursor:pointer; transition:.2s; position:relative; }
.s-list li:hover{ background:#fff0e4; }
.s-list li.on{ background:#ffe9d8; }
.s-avatar{ width:38px; height:38px; flex-shrink:0; border-radius:50%; display:flex; align-items:center; justify-content:center;
  background:linear-gradient(135deg,#ffb26b,#ff5f3d); color:#fff; font-weight:800; font-size:16px; }
.s-main{ flex:1; min-width:0; }
.s-top{ display:flex; justify-content:space-between; align-items:baseline; gap:6px; }
.s-name{ font-size:13.5px; font-weight:700; color:#4a3526; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.s-time{ font-size:11px; color:#b99b82; flex-shrink:0; }
.s-msg{ font-size:12px; color:#9a8270; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; margin-top:2px; }
.s-dot{ position:absolute; right:10px; top:8px; min-width:18px; height:18px; padding:0 5px; border-radius:9px;
  background:#ff3b30; color:#fff; font-size:11px; font-weight:800; display:flex; align-items:center; justify-content:center; }
.s-empty{ text-align:center; color:#b99b82; font-size:12.5px; padding:40px 16px; line-height:2; cursor:default; }
.s-empty-emoji{ display:block; font-size:40px; margin-bottom:8px; }

/* 右侧聊天窗口 */
.chat-main{ flex:1; min-width:0; display:flex; flex-direction:column; }
.c-head{ display:flex; align-items:center; gap:12px; padding:12px 16px; border-bottom:1.5px solid #f0e6db; }
.back{ border:1.5px solid #ecdfd2; background:#fff; color:var(--muted,#8a7a6a); border-radius:999px; padding:5px 12px;
  font-size:12.5px; cursor:pointer; transition:.2s; font-family:inherit; }
.back:hover{ border-color:var(--orange,#ff9a52); color:var(--tomato,#ff5f3d); }
.c-peer{ font-size:14.5px; font-weight:800; color:#4a3526; flex:1; }
.c-live{ font-size:11.5px; color:#2f9a5d; display:flex; align-items:center; gap:5px; }
.c-live i{ width:7px; height:7px; border-radius:50%; background:#2f9a5d; animation:pulse 1.6s infinite; }
@keyframes pulse{ 0%,100%{ opacity:1; } 50%{ opacity:.35; } }

.c-box{ flex:1; overflow-y:auto; padding:18px 20px; background:#fffaf4; }
.row{ display:flex; margin-bottom:14px; }
.row.mine{ justify-content:flex-end; }
.bubble{ max-width:72%; background:#fff; border:1.5px solid #f0e6db; border-radius:14px 14px 14px 4px; padding:9px 13px; }
.row .bubble{ margin-right:auto; }
.bubble.mine{ background:linear-gradient(130deg,#ff9a52,#ff5f3d); color:#fff; border:none; border-radius:14px 14px 4px 14px; margin-left:auto; }
.b-text{ margin:0; font-size:14px; line-height:1.6; word-break:break-word; white-space:pre-wrap; }
.b-time{ display:block; font-size:10.5px; opacity:.6; margin-top:4px; }
.c-empty{ text-align:center; color:#c4ab94; font-size:13px; padding-top:60px; }

.c-input{ display:flex; gap:10px; padding:12px 16px; border-top:1.5px solid #f0e6db; background:#fff; }
.c-input input{ flex:1; border:1.5px solid #ecdfd2; border-radius:999px; padding:10px 16px; font-size:14px; outline:none;
  transition:border-color .2s; font-family:inherit; }
.c-input input:focus{ border-color:var(--orange,#ff9a52); }
.c-input button{ border:none; border-radius:999px; padding:10px 22px; font-size:14px; font-weight:800; color:#fff; cursor:pointer;
  background:linear-gradient(120deg,#ff9a52,#ff5f3d); transition:.2s; font-family:inherit; }
.c-input button:disabled{ opacity:.45; cursor:not-allowed; }
.c-input button:not(:disabled):hover{ transform:translateY(-1px); box-shadow:0 6px 14px rgba(255,90,60,.3); }

.c-placeholder{ flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center; color:#c4ab94; gap:10px; }
.p-emoji{ font-size:52px; }
.chat-err{ color:#d64541; font-size:13px; text-align:center; margin-top:10px; }

@media (max-width:720px){
  .chat-shell{ flex-direction:column; height:auto; }
  .chat-side{ width:100%; max-height:220px; border-right:none; border-bottom:1.5px solid #f0e6db; }
  .chat-main{ min-height:420px; }
}
</style>
