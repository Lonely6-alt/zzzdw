-- 积分好礼：用户积分字段 + 好礼目录 + 兑换记录
-- 一次性迁移脚本；重复执行前请先确认 user.points 是否已存在。

ALTER TABLE `user`
  ADD COLUMN `points` int NOT NULL DEFAULT 120 COMMENT '吃货积分' AFTER `perm`;

-- 已有用户给同样的起始积分，方便直接体验兑换
UPDATE `user` SET `points` = 120 WHERE `points` = 0;

CREATE TABLE IF NOT EXISTS `reward` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '好礼ID',
  `code` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '好礼编码（前端 id）',
  `name` varchar(80) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '好礼名称',
  `category` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '分类：配送/满减/饮品/甜品/惊喜/特权/现金/周边',
  `cost` int NOT NULL COMMENT '所需积分',
  `emoji` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '展示图标',
  `description` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '好礼说明',
  `stock` int NOT NULL DEFAULT 999 COMMENT '库存，-1 表示不限量',
  `status` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'active' COMMENT '状态：active=可兑换',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE INDEX `uk_reward_code`(`code` ASC)
) ENGINE = InnoDB AUTO_INCREMENT = 11 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '积分好礼目录';

CREATE TABLE IF NOT EXISTS `user_reward` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '兑换记录ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `reward_id` bigint NOT NULL COMMENT '好礼ID',
  `reward_code` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '好礼编码',
  `name` varchar(80) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '好礼名称',
  `category` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '好礼分类快照',
  `emoji` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '展示图标',
  `description` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '好礼说明快照',
  `cost` int NOT NULL COMMENT '兑换消耗积分',
  `exchange_code` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '兑换码',
  `exchanged_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '兑换时间',
  PRIMARY KEY (`id`),
  UNIQUE INDEX `uk_exchange_code`(`exchange_code` ASC),
  INDEX `idx_user_reward_user`(`user_id` ASC)
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户兑换记录';

INSERT INTO `reward` (`id`, `code`, `name`, `category`, `cost`, `emoji`, `description`, `stock`, `status`) VALUES
  (1, 'delivery', '免配送费券', '配送', 40,  '🛵', '下一单免配送费，懒人必备', 999, 'active'),
  (2, 'c5',        '满 30 减 5 优惠券', '满减', 50,  '🎟️', '点单立减，攒够就能兑', 999, 'active'),
  (3, 'drink',     '饮品升杯券', '饮品', 70,  '🥤', '奶茶咖啡免费升大杯', 999, 'active'),
  (4, 'c12',       '满 60 减 12 优惠券', '满减', 90,  '🎫', '聚餐更划算的万能券', 999, 'active'),
  (5, 'dessert',   '甜品 8 折券', '甜品', 120, '🍰', '甜品时间专区通用', 999, 'active'),
  (6, 'c25',       '满 100 减 25 优惠券', '满减', 150, '🧧', '大额满减，请客首选', 999, 'active'),
  (7, 'blind',     '美食盲盒', '惊喜', 180, '🎁', '随机掉落隐藏款好礼', 999, 'active'),
  (8, 'vip',       '吃货月卡', '特权', 200, '👑', '专属身份标识，月月有效', 999, 'active'),
  (9, 'fund',      '探店基金 20 元', '现金', 260, '💰', '下次探店直接抵扣', 999, 'active'),
  (10, 'merch',    '社区定制帆布袋', '周边', 300, '🛍️', '限量周边，背着去觅食', 20,  'active')
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`), `category` = VALUES(`category`), `cost` = VALUES(`cost`),
  `emoji` = VALUES(`emoji`), `description` = VALUES(`description`),
  `stock` = VALUES(`stock`), `status` = VALUES(`status`);
