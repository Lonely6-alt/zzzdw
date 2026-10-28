/*
 Navicat Premium Dump SQL

 Source Server         : test
 Source Server Type    : MySQL
 Source Server Version : 80039 (8.0.39)
 Source Host           : localhost:3306
 Source Schema         : food_db

 Target Server Type    : MySQL
 Target Server Version : 80039 (8.0.39)
 File Encoding         : 65001

 Date: 28/10/2026 09:51:12
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for category
-- ----------------------------
DROP TABLE IF EXISTS `category`;
CREATE TABLE `category`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '分类ID',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '分类名称',
  `parent_id` bigint NOT NULL DEFAULT 0 COMMENT '父分类ID，0 表示一级分类',
  `icon` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT '?️' COMMENT '分类图标(emoji)',
  `sort` int NOT NULL DEFAULT 0 COMMENT '同级排序',
  `level` tinyint NOT NULL DEFAULT 1 COMMENT '层级：1=分组 2=叶子',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_parent`(`parent_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 32 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '美食分级分类表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of category
-- ----------------------------
INSERT INTO `category` VALUES (1, '招牌主食', 0, '🍚', 1, 1);
INSERT INTO `category` VALUES (2, '轻食甜饮', 0, '🥗', 2, 1);
INSERT INTO `category` VALUES (3, '深夜烟火', 0, '🔥', 3, 1);
INSERT INTO `category` VALUES (10, '面食控', 1, '🍜', 1, 2);
INSERT INTO `category` VALUES (11, '日料局', 1, '🍣', 2, 2);
INSERT INTO `category` VALUES (12, '汉堡炸鸡', 1, '🍔', 3, 2);
INSERT INTO `category` VALUES (20, '轻食沙拉', 2, '🥗', 1, 2);
INSERT INTO `category` VALUES (21, '甜品时间', 2, '🍰', 2, 2);
INSERT INTO `category` VALUES (22, '咖啡馆', 2, '☕', 3, 2);
INSERT INTO `category` VALUES (30, '烧烤夜宵', 3, '🍢', 1, 2);
INSERT INTO `category` VALUES (31, '火锅江湖', 3, '🍲', 2, 2);

-- ----------------------------
-- Table structure for favorite
-- ----------------------------
DROP TABLE IF EXISTS `favorite`;
CREATE TABLE `favorite`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '收藏ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `post_id` bigint NOT NULL COMMENT '帖子ID',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_post`(`user_id` ASC, `post_id` ASC) USING BTREE,
  INDEX `idx_post`(`post_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '收藏表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of favorite
-- ----------------------------
INSERT INTO `favorite` VALUES (1, 1, 5, '2026-09-15 16:30:00');
INSERT INTO `favorite` VALUES (2, 1, 7, '2026-09-17 20:40:00');
INSERT INTO `favorite` VALUES (3, 1, 18, '2026-09-27 10:30:00');

-- ----------------------------
-- Table structure for food_order
-- ----------------------------
DROP TABLE IF EXISTS `food_order`;
CREATE TABLE `food_order`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '订单ID',
  `post_id` bigint NOT NULL COMMENT '帖子ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `qty` int NOT NULL DEFAULT 1 COMMENT '数量',
  `note` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '备注',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '下单时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_post`(`post_id` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '点单表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of food_order
-- ----------------------------

-- ----------------------------
-- Table structure for post
-- ----------------------------
DROP TABLE IF EXISTS `post`;
CREATE TABLE `post`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '帖子ID',
  `title` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '标题',
  `category` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '分类名称(叶子，便于展示与兼容)',
  `category_id` bigint NULL DEFAULT NULL COMMENT '所属叶子分类ID，关联 category.id',
  `author` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '作者用户名',
  `emoji` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT '?' COMMENT '封面表情',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '内容',
  `rating` decimal(2, 1) NOT NULL DEFAULT 0.0 COMMENT '平均评分(0.0~5.0)',
  `review_count` int NOT NULL DEFAULT 0 COMMENT '点评数',
  `favorite_count` int NOT NULL DEFAULT 0 COMMENT '收藏数',
  `order_count` int NOT NULL DEFAULT 0 COMMENT '点单数',
  `price` decimal(8, 2) NULL DEFAULT NULL COMMENT '参考单价',
  `featured` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否首页今日精选置顶：1=精选 0=否',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_category`(`category` ASC) USING BTREE,
  INDEX `idx_category_id`(`category_id` ASC) USING BTREE,
  INDEX `idx_rating`(`rating` ASC) USING BTREE,
  INDEX `idx_created`(`created_at` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 19 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '美食帖子表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of post
-- ----------------------------
INSERT INTO `post` VALUES (1, '巷子里的无名拉面', '面食控', 10, '吃货小王', '🍜', '汤头熬足 8 小时，叉烧入口即化，加份溏心蛋绝了。藏在老小区，工作日中午要排队。', 4.8, 42, 88, 120, 28.00, 0, '2026-09-10 10:00:00');
INSERT INTO `post` VALUES (2, '一人食寿司拼盘', '日料局', 11, 'mio', '🍣', '三文鱼、甜虾、鳗鱼各来一点，性价比高。吧台能看到师傅现切，很治愈。', 4.6, 31, 60, 90, 68.00, 0, '2026-09-11 12:30:00');
INSERT INTO `post` VALUES (3, '深夜炸鸡快乐水', '汉堡炸鸡', 12, '夜猫子', '🍔', '外脆里嫩配冰可乐，加班续命神器，建议趁热吃。', 4.5, 55, 99, 210, 39.00, 0, '2026-09-12 22:10:00');
INSERT INTO `post` VALUES (4, '牛油果鸡胸轻食碗', '轻食沙拉', 20, '健身的鹿', '🥗', '低卡又顶饱，油醋汁调得刚好，减脂期也满足。', 4.7, 28, 45, 76, 45.00, 0, '2026-09-13 09:15:00');
INSERT INTO `post` VALUES (5, '海盐芝士蛋糕', '甜品时间', 21, '甜牙齿', '🍰', '不齁甜，芝士味浓，配美式刚刚好。店员说用北海道奶油。', 4.9, 67, 130, 188, 32.00, 0, '2026-09-14 15:40:00');
INSERT INTO `post` VALUES (6, '手冲耶加雪菲', '咖啡馆', 22, '豆子控', '☕', '明亮柑橘酸调，回甘干净。店里安静，适合带本书坐一下午。', 4.8, 49, 70, 95, 38.00, 0, '2026-09-15 11:05:00');
INSERT INTO `post` VALUES (7, '麻辣牛油火锅', '火锅江湖', 31, '辣不怕', '🍲', '牛油锅底香而不燥，毛肚七上八下最嫩，蘸干碟上头。', 4.7, 73, 150, 260, 128.00, 0, '2026-09-16 19:20:00');
INSERT INTO `post` VALUES (8, '炭火烧烤大腰子', '烧烤夜宵', 30, '烟火气', '🍢', '炭火现烤，撒孜然辣椒，外焦里嫩，配冰啤绝配。', 4.6, 40, 88, 175, 58.00, 0, '2026-09-17 21:30:00');
INSERT INTO `post` VALUES (9, '番茄浓汤乌冬', '面食控', 10, '面霸', '🍜', '番茄熬出沙感，乌冬Q弹，加溏心蛋和肥牛很满足。', 4.4, 22, 33, 64, 26.00, 0, '2026-09-18 11:00:00');
INSERT INTO `post` VALUES (10, '三文鱼波奇碗', '轻食沙拉', 20, '沙拉控', '🥗', '生食级三文鱼配牛油果藜麦，健康又好看，适合拍照。', 4.5, 19, 28, 52, 52.00, 0, '2026-09-19 12:10:00');
INSERT INTO `post` VALUES (11, '抹茶千层蛋糕', '甜品时间', 21, '抹茶星人', '🍵', '二十层可丽饼，抹茶微苦不腻，配白桃乌龙绝了。', 4.8, 58, 110, 165, 42.00, 0, '2026-09-20 16:00:00');
INSERT INTO `post` VALUES (12, '冰美式续命', '咖啡馆', 22, '续命人', '☕', '深烘豆子做出来的冰美式，苦香浓郁，下午不犯困。', 4.3, 36, 50, 142, 22.00, 0, '2026-09-21 14:25:00');
INSERT INTO `post` VALUES (13, '照烧鸡腿饭', '日料局', 11, '饭团君', '🍱', '鸡腿煎到焦糖色，照烧汁裹饭，附味噌汤和小菜。', 4.5, 27, 41, 98, 36.00, 0, '2026-09-22 12:40:00');
INSERT INTO `post` VALUES (14, '脆皮炸鸡桶', '汉堡炸鸡', 12, '啃鸡王', '🍗', '整桶十块，皮脆到掉渣，原味和辣味都好吃。', 4.6, 44, 80, 230, 69.00, 0, '2026-09-23 18:50:00');
INSERT INTO `post` VALUES (15, '九宫格麻辣烫', '火锅江湖', 31, '烫嘴侠', '🍲', '自选九宫格，麻辣鲜香，人均三十吃到撑。', 4.4, 33, 60, 120, 45.00, 0, '2026-09-24 20:15:00');
INSERT INTO `post` VALUES (16, '蒜香烤茄子', '烧烤夜宵', 30, '夜市王', '🍆', '蒜蓉铺满，烤到软糯出汁，素菜里的下饭王。', 4.3, 25, 40, 88, 18.00, 0, '2026-09-25 21:00:00');
INSERT INTO `post` VALUES (17, '红油抄手', '面食控', 10, '抄手控', '🥟', '皮薄馅大，红油芝麻香，一口一个停不下来。', 4.7, 38, 55, 110, 30.00, 0, '2026-09-26 11:30:00');
INSERT INTO `post` VALUES (18, '生椰拿铁', '咖啡馆', 22, '椰青', '🥥', '椰浆撞浓缩，清甜不腻，冰块化开更好喝。', 4.9, 61, 120, 200, 35.00, 0, '2026-09-27 10:20:00');

-- ----------------------------
-- Table structure for review
-- ----------------------------
DROP TABLE IF EXISTS `review`;
CREATE TABLE `review`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '点评ID',
  `post_id` bigint NOT NULL COMMENT '帖子ID',
  `author` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '点评人',
  `rating` tinyint NOT NULL COMMENT '评分 1~5',
  `comment` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '点评内容',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '点评时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_post`(`post_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '美食点评表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of review
-- ----------------------------
INSERT INTO `review` VALUES (1, 1, 'mio', 5, '叉烧真的绝，汤头鲜到舔碗。', '2026-09-11 09:10:00');
INSERT INTO `review` VALUES (2, 1, '夜猫子', 5, '加溏心蛋是灵魂，已二刷。', '2026-09-12 12:00:00');
INSERT INTO `review` VALUES (3, 5, '豆子控', 5, '芝士控狂喜，不甜腻。', '2026-09-15 16:20:00');
INSERT INTO `review` VALUES (4, 5, '健身的鹿', 5, '下午茶来一块，罪恶又快乐。', '2026-09-16 15:00:00');
INSERT INTO `review` VALUES (5, 7, '烫嘴侠', 4, '锅底香，就是周末要排队。', '2026-09-17 20:30:00');

-- ----------------------------
-- Table structure for user
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '用户名',
  `password_hash` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '密码哈希(BCrypt)',
  `role` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'user' COMMENT '角色：user=普通用户 admin=管理员',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_username`(`username` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user
-- ----------------------------
INSERT INTO `user` VALUES (1, 'admin', '$2a$10$qXMnYVXnQNYsnrteF1mIgOkur.4mbEYgIEnonL9obQMmXznFeN5He', 'admin', '2026-09-01 09:00:00');

SET FOREIGN_KEY_CHECKS = 1;
