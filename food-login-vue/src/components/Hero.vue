<template>
  <aside class="hero">
    <div class="brand"><div class="logo">🍲</div>食光 · 美食社区</div>
    <div class="emoji-row">
      <span class="e1">🍜</span><span class="e2">🍣</span><span class="e3">🍔</span>
      <span class="e4">🍰</span><span class="e5">🥗</span><span class="e6">☕</span>
    </div>
    <h1>发现城市里的<br />每一口好味道
      <small>记录、分享、收藏你的私藏美食地图</small>
    </h1>
    <div class="badge">🔥 已有 12,800+ 吃货在这里安家</div>
  </aside>
</template>

<script setup>
// 纯展示组件，无需逻辑
</script>

<style scoped>
.hero{
  flex:1.1; position:relative; display:flex; flex-direction:column; justify-content:space-between;
  padding:42px 40px; color:#fff;
  background:linear-gradient(150deg,#ff8c42 0%,#ff5a3c 55%,#e23b3b 100%);
  overflow:hidden;
}
.hero::before{
  content:""; position:absolute; inset:0;
  background:radial-gradient(circle at 80% 15%,rgba(255,255,255,.25),transparent 45%);
  pointer-events:none;
}
.brand{ display:flex; align-items:center; gap:12px; font-weight:800; font-size:22px; letter-spacing:1px; z-index:2; }
.brand .logo{
  width:42px; height:42px; border-radius:13px; background:rgba(255,255,255,.22);
  display:flex; align-items:center; justify-content:center; font-size:24px;
}
.hero h1{ font-size:34px; line-height:1.25; z-index:2; margin-top:auto; }
.hero h1 small{ display:block; font-size:15px; font-weight:500; opacity:.9; margin-top:10px; }
.emoji-row{ position:absolute; inset:0; z-index:1; pointer-events:none; }
.emoji-row span{ position:absolute; font-size:34px; opacity:.85; animation:float 6s ease-in-out infinite; }
.e1{ left:12%; top:20%; } .e2{ left:60%; top:30%; } .e3{ left:30%; top:62%; }
.e4{ left:74%; top:66%; } .e5{ left:45%; top:12%; } .e6{ left:85%; top:48%; }
@keyframes float{
  0%,100%{ transform:translateY(0) rotate(-4deg); }
  50%{ transform:translateY(-14px) rotate(6deg); }
}
.hero .badge{
  position:relative; z-index:2; font-size:12.5px; background:rgba(0,0,0,.12);
  padding:8px 12px; border-radius:20px; width:fit-content;
}
</style>
