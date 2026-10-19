// 美食分类元信息：图标 + 封面渐变色卡
// 首页、发现页共用同一份定义，避免各处重复维护导致视觉不一致
export const CAT_META = {
  '面食控':   { icon: '🍜', bg: 'linear-gradient(140deg,#fff5e8,#ffdfba)' },
  '日料局':   { icon: '🍣', bg: 'linear-gradient(140deg,#eaf4ff,#c9e2ff)' },
  '汉堡炸鸡': { icon: '🍔', bg: 'linear-gradient(140deg,#fff9e2,#ffe1a3)' },
  '轻食沙拉': { icon: '🥗', bg: 'linear-gradient(140deg,#eafaf0,#c8efd6)' },
  '甜品时间': { icon: '🍰', bg: 'linear-gradient(140deg,#fff2f9,#ffd4e8)' },
  '咖啡馆':   { icon: '☕', bg: 'linear-gradient(140deg,#f4efff,#dbcdff)' },
  '烧烤夜宵': { icon: '🍢', bg: 'linear-gradient(140deg,#ffeee7,#ffd0ba)' },
  '火锅江湖': { icon: '🍲', bg: 'linear-gradient(140deg,#fff2ef,#ffcdc3)' }
}

export const CAT_NAMES = Object.keys(CAT_META)
export const CATEGORIES = ['全部', ...CAT_NAMES]

export const catIcon = c => CAT_META[c]?.icon || '🍽️'
export const catBg = c => CAT_META[c]?.bg || 'linear-gradient(140deg,#fdf6ee,#f3e6d6)'
