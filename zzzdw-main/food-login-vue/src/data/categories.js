// 美食分类元信息：图标 + 封面渐变色卡 + 主题辅助色 + 实拍封面图
// 首页、发现页、卡片、地图、排行榜共用同一份定义，保证视觉一致
export const CAT_META = {
  '面食控':   { icon: '🍜', bg: 'linear-gradient(140deg,#fff5e8,#ffdfba)', accent: '#d98b1f', soft: '#fff3e0' },
  '日料局':   { icon: '🍣', bg: 'linear-gradient(140deg,#eaf4ff,#c9e2ff)', accent: '#2e7fc4', soft: '#e8f2fc' },
  '汉堡炸鸡': { icon: '🍔', bg: 'linear-gradient(140deg,#fff9e2,#ffe1a3)', accent: '#d49415', soft: '#fff6df' },
  '轻食沙拉': { icon: '🥗', bg: 'linear-gradient(140deg,#eafaf0,#c8efd6)', accent: '#2f9a5d', soft: '#e7f6ec' },
  '甜品时间': { icon: '🍰', bg: 'linear-gradient(140deg,#fff2f9,#ffd4e8)', accent: '#d4578c', soft: '#ffe9f3' },
  '咖啡馆':   { icon: '☕', bg: 'linear-gradient(140deg,#f4efff,#dbcdff)', accent: '#85593f', soft: '#f1e7df' },
  '烧烤夜宵': { icon: '🍢', bg: 'linear-gradient(140deg,#ffeee7,#ffd0ba)', accent: '#cf6a2c', soft: '#ffece0' },
  '火锅江湖': { icon: '🍲', bg: 'linear-gradient(140deg,#fff2ef,#ffcdc3)', accent: '#c93b2e', soft: '#fde6e2' }
}

export const CAT_NAMES = Object.keys(CAT_META)
export const CATEGORIES = ['全部', ...CAT_NAMES]

export const catIcon = c => CAT_META[c]?.icon || '🍽️'
export const catBg = c => CAT_META[c]?.bg || 'linear-gradient(140deg,#fdf6ee,#f3e6d6)'
export const catAccent = c => CAT_META[c]?.accent || '#ff8c42'
export const catSoft = c => CAT_META[c]?.soft || '#fff3e6'

// 兜底插画色卡（无实拍图时按分类取不同渐变，避免千篇一律）
export const catBgFallback = c => catBg(c)
