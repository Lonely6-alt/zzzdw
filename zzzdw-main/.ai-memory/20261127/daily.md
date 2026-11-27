session-id: 20261127-1553

## [15:53] - 功能实现: 个人页积分商城奖品直接展示并扩充品类

- **文件**: `food-login-vue/src/views/ProfileView.vue`, `food-login-vue/src/composables/useGrowth.js`
- **决策**: 保留 `COUPON_SHOP` / `COUPON_KEY` 名称，避免已有 localStorage 数据失效；奖品从 3 种优惠券扩到 10 种（配送、饮品、甜品、盲盒、会员、周边等）；积分不足时按钮显示「还差 N 分」。
- **验证**: `npm run build` 成功（91 modules transformed，1.61s，无错误）；浏览器截图确认 10 件奖品直接展示、无「去兑换」按钮，积分不足显示「还差 N 分」；点击「40 分兑换」后积分 120→80 且已兑换列表新增「免配送费券」。

## [16:10] - 功能实现: 积分与兑换接入 Spring Boot 后端

- **文件**: `springBootTest/sql/growth_rewards.sql`, `springBootTest/sql/food_db.sql`, `springBootTest/src/main/java/com/fenglin/springboottest/{entity,mapper,service,service/impl,controller,dto}` 新增好礼/成长体系文件, `User.java`, `UserVO.java`, `AuthController.java`, `food-login-vue/src/composables/{useGrowth.js,useAuth.js}`, `food-login-vue/src/App.vue`, `food-login-vue/src/views/ProfileView.vue`
- **决策**: 后端为积分真相源；`user.points` 默认 120；兑换事务内原子扣积分/库存并写 `user_reward`；前端 localStorage 降级为缓存；好礼目录由 `reward` 表提供。
- **验证**: 后端离线编译通过（使用 C 盘 Maven 仓库）；前端 `npm run build` 通过；API 实测 `/api/growth/me`、`/api/rewards`、`/api/rewards/exchange`、`/api/growth/points` 均正常，积分不足返回 400；浏览器实测前端积分被后端值覆盖、兑换后积分与已兑列表同步；测试数据已清理。
