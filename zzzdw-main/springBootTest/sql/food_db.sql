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

 Date: 06/11/2026 16:56:47
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
  `bg` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '卡片背景(CSS gradient/颜色)',
  `sort` int NOT NULL DEFAULT 0 COMMENT '同级排序',
  `level` tinyint NOT NULL DEFAULT 1 COMMENT '层级：1=分组 2=叶子',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_parent`(`parent_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 32 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '美食分级分类表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of category
-- ----------------------------
INSERT INTO `category` VALUES (1, '中式风味', 0, '🥢', 'linear-gradient(140deg,#fff5e8,#ffdfba)', 1, 1);
INSERT INTO `category` VALUES (2, '西式快餐', 0, '🍟', 'linear-gradient(140deg,#fff9e2,#ffe1a3)', 2, 1);
INSERT INTO `category` VALUES (3, '日韩料理', 0, '🍱', 'linear-gradient(140deg,#eaf4ff,#c9e2ff)', 3, 1);
INSERT INTO `category` VALUES (4, '咖啡甜点', 0, '🍮', 'linear-gradient(140deg,#fff2f9,#ffd4e8)', 4, 1);
INSERT INTO `category` VALUES (10, '面食控', 1, '🍜', 'linear-gradient(140deg,#fff5e8,#ffdfba)', 1, 2);
INSERT INTO `category` VALUES (11, '火锅江湖', 1, '🍲', 'linear-gradient(140deg,#fff2ef,#ffcdc3)', 2, 2);
INSERT INTO `category` VALUES (12, '烧烤夜宵', 1, '🍢', 'linear-gradient(140deg,#ffeee7,#ffd0ba)', 3, 2);
INSERT INTO `category` VALUES (13, '轻食沙拉', 1, '🥗', 'linear-gradient(140deg,#eafaf0,#c8efd6)', 4, 2);
INSERT INTO `category` VALUES (14, '汉堡炸鸡', 2, '🍔', 'linear-gradient(140deg,#fff9e2,#ffe1a3)', 1, 2);
INSERT INTO `category` VALUES (15, '日料局', 3, '🍣', 'linear-gradient(140deg,#eaf4ff,#c9e2ff)', 1, 2);
INSERT INTO `category` VALUES (16, '甜品时间', 4, '🍰', 'linear-gradient(140deg,#fff2f9,#ffd4e8)', 1, 2);
INSERT INTO `category` VALUES (17, '咖啡馆', 4, '☕', 'linear-gradient(140deg,#f4efff,#dbcdff)', 2, 2);

-- ----------------------------
-- Table structure for chat_group
-- ----------------------------
DROP TABLE IF EXISTS `chat_group`;
CREATE TABLE `chat_group`  (
  `group_id` bigint NOT NULL AUTO_INCREMENT COMMENT '群ID',
  `group_name` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '群名称',
  `owner_id` bigint NOT NULL COMMENT '群主用户ID',
  `emoji` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT '?' COMMENT '群头像图标',
  `notice` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '群公告',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '建群时间',
  `last_msg` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '最后一条消息摘要',
  `last_time` datetime NULL DEFAULT NULL COMMENT '最后一条消息时间',
  PRIMARY KEY (`group_id`) USING BTREE,
  INDEX `idx_group_owner`(`owner_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '群聊表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of chat_group
-- ----------------------------
INSERT INTO `chat_group` VALUES (1, '周末探店小分队', 5, '🍜', '每周六上午集合，专挑巷子里的老店', '2026-10-25 16:34:57', '我们去吃什么', '2026-11-06 16:48:56');
INSERT INTO `chat_group` VALUES (2, '美食社区官方群', 4, '📣', '社区公告、活动预告与问题反馈都在这里', '2026-10-25 16:34:57', '收到，我这周有三家想推荐', '2026-11-06 11:44:57');
INSERT INTO `chat_group` VALUES (3, '深夜食堂交流群', 8, '🌙', '十点以后才开聊，专供夜宵党', '2026-10-25 16:34:57', '那我一会儿过去，来二十串', '2026-11-06 15:06:57');

-- ----------------------------
-- Table structure for chat_group_member
-- ----------------------------
DROP TABLE IF EXISTS `chat_group_member`;
CREATE TABLE `chat_group_member`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `group_id` bigint NOT NULL COMMENT '群ID',
  `user_id` bigint NOT NULL COMMENT '成员用户ID',
  `role` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'member' COMMENT '角色：owner=群主 member=成员',
  `join_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
  `last_read_msg_id` bigint NOT NULL DEFAULT 0 COMMENT '最后已读的群消息ID（用于未读数）',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_group_user`(`group_id` ASC, `user_id` ASC) USING BTREE,
  INDEX `idx_member_user`(`user_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '群成员表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of chat_group_member
-- ----------------------------
INSERT INTO `chat_group_member` VALUES (1, 1, 5, 'owner', '2026-11-06 16:34:57', 4);
INSERT INTO `chat_group_member` VALUES (2, 1, 8, 'member', '2026-11-06 16:34:57', 15);
INSERT INTO `chat_group_member` VALUES (3, 1, 9, 'member', '2026-11-06 16:34:57', 4);
INSERT INTO `chat_group_member` VALUES (4, 1, 10, 'member', '2026-11-06 16:34:57', 4);
INSERT INTO `chat_group_member` VALUES (5, 2, 4, 'owner', '2026-11-06 16:34:57', 7);
INSERT INTO `chat_group_member` VALUES (6, 2, 5, 'member', '2026-11-06 16:34:57', 7);
INSERT INTO `chat_group_member` VALUES (7, 2, 8, 'member', '2026-11-06 16:34:57', 7);
INSERT INTO `chat_group_member` VALUES (8, 2, 11, 'member', '2026-11-06 16:34:57', 7);
INSERT INTO `chat_group_member` VALUES (9, 3, 8, 'owner', '2026-11-06 16:34:57', 10);
INSERT INTO `chat_group_member` VALUES (10, 3, 5, 'member', '2026-11-06 16:34:57', 10);
INSERT INTO `chat_group_member` VALUES (11, 3, 12, 'member', '2026-11-06 16:34:57', 10);

-- ----------------------------
-- Table structure for chat_group_message
-- ----------------------------
DROP TABLE IF EXISTS `chat_group_message`;
CREATE TABLE `chat_group_message`  (
  `msg_id` bigint NOT NULL AUTO_INCREMENT COMMENT '群消息ID',
  `group_id` bigint NOT NULL COMMENT '群ID',
  `sender_id` bigint NOT NULL COMMENT '发送方用户ID',
  `content` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '消息内容',
  `send_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
  PRIMARY KEY (`msg_id`) USING BTREE,
  INDEX `idx_group_time`(`group_id` ASC, `send_time` ASC) USING BTREE,
  INDEX `idx_group_sender`(`sender_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '群聊消息表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of chat_group_message
-- ----------------------------
INSERT INTO `chat_group_message` VALUES (1, 1, 5, '这周六去老城区扫街，有人一起吗？', '2026-11-06 13:34:57');
INSERT INTO `chat_group_message` VALUES (2, 1, 8, '我去！听说老张牛肉面换新汤底了', '2026-11-06 13:38:57');
INSERT INTO `chat_group_message` VALUES (3, 1, 9, '欢迎来店里，给你们留窗边位置', '2026-11-06 13:43:57');
INSERT INTO `chat_group_message` VALUES (4, 1, 5, '那就定了，十点店门口见 🍜', '2026-11-06 13:46:57');
INSERT INTO `chat_group_message` VALUES (5, 2, 4, '本周「今日精选」已更新，共 6 道菜上墙', '2026-11-06 11:34:57');
INSERT INTO `chat_group_message` VALUES (6, 2, 4, '欢迎大家把好吃的小店都发上来～', '2026-11-06 11:38:57');
INSERT INTO `chat_group_message` VALUES (7, 2, 8, '收到，我这周有三家想推荐', '2026-11-06 11:44:57');
INSERT INTO `chat_group_message` VALUES (8, 3, 8, '半夜饿了，谁家烧烤还开着', '2026-11-06 14:58:57');
INSERT INTO `chat_group_message` VALUES (9, 3, 12, '我们家到凌晨两点，炭火小串管够', '2026-11-06 15:02:57');
INSERT INTO `chat_group_message` VALUES (10, 3, 5, '那我一会儿过去，来二十串', '2026-11-06 15:06:57');
INSERT INTO `chat_group_message` VALUES (15, 1, 8, '我们去吃什么', '2026-11-06 16:48:56');

-- ----------------------------
-- Table structure for chat_message
-- ----------------------------
DROP TABLE IF EXISTS `chat_message`;
CREATE TABLE `chat_message`  (
  `msg_id` bigint NOT NULL AUTO_INCREMENT COMMENT '消息ID',
  `session_id` bigint NOT NULL COMMENT '所属会话ID，关联 chat_session.session_id',
  `sender_id` bigint NOT NULL COMMENT '发送方用户ID',
  `receiver_id` bigint NOT NULL COMMENT '接收方用户ID',
  `content` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '消息内容',
  `send_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
  `is_read` tinyint NOT NULL DEFAULT 0 COMMENT '是否已读：0=未读 1=已读',
  PRIMARY KEY (`msg_id`) USING BTREE,
  INDEX `idx_session`(`session_id` ASC, `send_time` ASC) USING BTREE,
  INDEX `idx_receiver_read`(`receiver_id` ASC, `is_read` ASC) USING BTREE,
  INDEX `fk_cm_sender`(`sender_id` ASC) USING BTREE,
  CONSTRAINT `fk_cm_receiver` FOREIGN KEY (`receiver_id`) REFERENCES `user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_cm_sender` FOREIGN KEY (`sender_id`) REFERENCES `user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_cm_session` FOREIGN KEY (`session_id`) REFERENCES `chat_session` (`session_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '私信消息表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of chat_message
-- ----------------------------
INSERT INTO `chat_message` VALUES (1, 1, 8, 5, 'Hilo', '2026-11-04 09:50:03', 0);

-- ----------------------------
-- Table structure for chat_session
-- ----------------------------
DROP TABLE IF EXISTS `chat_session`;
CREATE TABLE `chat_session`  (
  `session_id` bigint NOT NULL AUTO_INCREMENT COMMENT '会话ID',
  `user_a_id` bigint NOT NULL COMMENT '会话发起方用户ID（存较小ID，便于唯一约束）',
  `user_b_id` bigint NOT NULL COMMENT '会话另一方用户ID（存较大ID）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '会话创建时间',
  `last_msg` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '最后一条消息摘要',
  `last_time` datetime NULL DEFAULT NULL COMMENT '最后一条消息时间',
  PRIMARY KEY (`session_id`) USING BTREE,
  UNIQUE INDEX `uk_a_b`(`user_a_id` ASC, `user_b_id` ASC) USING BTREE,
  INDEX `idx_user_b`(`user_b_id` ASC) USING BTREE,
  CONSTRAINT `fk_cs_user_a` FOREIGN KEY (`user_a_id`) REFERENCES `user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_cs_user_b` FOREIGN KEY (`user_b_id`) REFERENCES `user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '私信会话表（一对一）' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of chat_session
-- ----------------------------
INSERT INTO `chat_session` VALUES (1, 5, 8, '2026-11-04 09:49:54', 'Hilo', '2026-11-04 09:50:03');
INSERT INTO `chat_session` VALUES (2, 4, 8, '2026-11-04 09:50:10', NULL, NULL);
INSERT INTO `chat_session` VALUES (3, 4, 5, '2026-11-04 09:50:39', NULL, '2026-11-06 16:46:37');

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
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '收藏表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of favorite
-- ----------------------------

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
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '点单表' ROW_FORMAT = DYNAMIC;

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
  `shop_id` bigint NULL DEFAULT NULL COMMENT '所属店铺ID，关联 shop.shop_id',
  `emoji` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT '?' COMMENT '封面表情',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '内容',
  `rating` decimal(2, 1) NOT NULL DEFAULT 0.0 COMMENT '平均评分(0.0~5.0)',
  `review_count` int NOT NULL DEFAULT 0 COMMENT '点评数',
  `favorite_count` int NOT NULL DEFAULT 0 COMMENT '收藏数',
  `order_count` int NOT NULL DEFAULT 0 COMMENT '点单数',
  `price` decimal(8, 2) NULL DEFAULT NULL COMMENT '参考单价',
  `featured` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否首页今日精选置顶：1=精选 0=否',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'approved' COMMENT '审核状态：pending=待审核 approved=通过 rejected=驳回',
  `district` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '所在商圈',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_category`(`category` ASC) USING BTREE,
  INDEX `idx_category_id`(`category_id` ASC) USING BTREE,
  INDEX `idx_rating`(`rating` ASC) USING BTREE,
  INDEX `idx_created`(`created_at` ASC) USING BTREE,
  INDEX `idx_shop`(`shop_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 201 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '美食帖子表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of post
-- ----------------------------
INSERT INTO `post` VALUES (1, '巷子里那碗牛肉面，汤头熬了六小时', '面食控', 10, 'admin', 2, '🍜', '牛肉给得很实在，汤是清亮的琥珀色，喝一口有股淡淡的药膳香。面条偏细，泡久了也不坨，冬天来一碗整个人都活了。', 5.0, 2, 36, 58, 26.00, 1, 'approved', '老城区', '2026-11-01 12:20:00');
INSERT INTO `post` VALUES (2, '红油抄手配小酥肉，辣得刚刚好', '面食控', 10, 'test', 3, '🥟', '红油香而不燥，抄手皮薄馅大。小酥肉现炸的，外脆里嫩，撒了花椒面，一口一个停不下来。', 4.0, 1, 21, 34, 32.00, 0, 'approved', '大学城', '2026-10-31 18:40:00');
INSERT INTO `post` VALUES (3, '九宫格牛油锅，毛肚七上八下', '火锅江湖', 11, 'admin', 10, '🍲', '锅底牛油味很足，微辣对大多数人刚好。毛肚脆，鸭肠爽，最后煮一份宽粉收尾，幸福感直接拉满。', 5.0, 1, 64, 92, 88.00, 1, 'approved', '万象城', '2026-10-30 20:10:00');
INSERT INTO `post` VALUES (4, '学校门口的烤串摊，五块钱三串', '烧烤夜宵', 12, 'test', 17, '🍢', '老板撒料手很稳，羊肉串带点焦边最香。夜里十点去还排队，建议避开高峰，或者干脆多等十分钟。', 4.4, 0, 18, 47, 15.00, 0, 'approved', '三里屯', '2026-10-29 22:30:00');
INSERT INTO `post` VALUES (5, '鸡胸肉沙拉也能很好吃，关键在酱', '轻食沙拉', 13, 'test', 24, '🥗', '鸡胸是低温慢煮的，一点都不柴。油醋汁是自己调的，酸度刚好，配上牛油果和烤南瓜，减脂期也能吃得很开心。', 4.5, 0, 29, 22, 28.00, 0, 'approved', '科技园', '2026-10-28 12:05:00');
INSERT INTO `post` VALUES (6, '双层芝士汉堡，酱汁会流下来', '汉堡炸鸡', 14, 'admin', 25, '🍔', '面包是现烤的，边缘微脆。牛肉饼厚实有肉汁，芝士融化得彻底。薯条换成了粗切的，蘸蜂蜜芥末很好吃。', 4.7, 0, 41, 66, 39.00, 0, 'approved', '五道口', '2026-10-27 19:15:00');
INSERT INTO `post` VALUES (7, '这家炸鸡的脆皮值得专门跑一趟', '汉堡炸鸡', 14, 'test', 26, '🍗', '外壳是真的脆，咬下去能听到声音。腌得透，肉不干。建议点半半口味，原味和甜辣各一半。', 4.6, 0, 33, 51, 45.00, 0, 'approved', '大学城', '2026-10-26 20:00:00');
INSERT INTO `post` VALUES (8, '人均六十的日料，刺身很新鲜', '日料局', 15, 'admin', 33, '🍣', '三文鱼切得厚，油脂线漂亮。鳗鱼饭酱汁偏甜但很下饭。店里位置不多，最好提前订。', 4.5, 0, 27, 19, 62.00, 0, 'approved', '三里屯', '2026-10-25 18:30:00');
INSERT INTO `post` VALUES (9, '深夜拉面，溏心蛋是灵魂', '日料局', 15, 'test', 34, '🍥', '豚骨汤浓但不腻，面偏硬刚好。叉烧炙过，有焦香。加一份溏心蛋，蛋黄流进汤里，值了。', 4.7, 0, 38, 44, 42.00, 0, 'approved', '南锣鼓巷', '2026-10-24 23:10:00');
INSERT INTO `post` VALUES (10, '手冲耶加雪菲，柑橘味很明亮', '咖啡馆', 17, 'admin', 47, '☕', '浅烘豆子，入口是柑橘和一点花香，回甘干净。店里安静，适合带电脑坐一下午。', 4.8, 0, 52, 31, 32.00, 0, 'approved', '五道口', '2026-10-23 15:20:00');
INSERT INTO `post` VALUES (11, '巴斯克芝士蛋糕，焦皮是关键', '甜品时间', 16, 'test', 42, '🍰', '中心是流心的，冷藏后更扎实。焦皮带一点微苦，正好压住甜度。配黑咖啡绝了。', 4.9, 0, 71, 39, 28.00, 0, 'approved', '滨江道', '2026-10-22 16:45:00');
INSERT INTO `post` VALUES (12, '杨枝甘露，芒果给得毫不吝啬', '甜品时间', 16, 'admin', 37, '🥭', '芒果是大块果肉，西米煮得刚好不糊。甜度可以选，我选了少糖，更清爽。夏天来一杯很解腻。', 4.6, 0, 24, 28, 18.00, 0, 'approved', '老城区', '2026-10-21 14:00:00');
INSERT INTO `post` VALUES (13, '招牌炸酱面，酱是自家熬的', '面食控', 10, 'admin', 2, '🍜', '面码给得足，黄瓜丝、豆芽、心里美萝卜堆成小山。炸酱用肥瘦相间的肉丁，咸甜口，拌开每根面都挂汁。', 3.9, 0, 20, 10, 18.00, 1, 'approved', '老城区', '2026-09-05 00:00:00');
INSERT INTO `post` VALUES (14, '红汤酸辣粉，酸笋是灵魂', '面食控', 10, 'test', 3, '🍜', '红薯粉Q弹，汤头又酸又辣还带点麻。酸笋给得多，嚼着脆，加个煎蛋更满足。', 4.6, 3, 33, 27, 29.00, 0, 'approved', '大学城', '2026-09-07 00:00:00');
INSERT INTO `post` VALUES (15, '小笼包现包现蒸，汤汁会烫嘴', '面食控', 10, 'admin', 4, '🥟', '皮薄到能看见馅，咬开先吸汤，鲜得眉毛掉。蟹粉款更香，原味肉包已经够打。', 4.2, 6, 46, 44, 25.00, 0, 'approved', '万象城', '2026-09-09 00:00:00');
INSERT INTO `post` VALUES (16, '阳春面一碗，葱油香到隔壁桌', '面食控', 10, 'test', 5, '🍜', '清汤挂面，全靠那勺熬到金黄的葱油。简简单单，吃完连汤都喝光。', 4.9, 0, 59, 61, 21.00, 0, 'approved', '三里屯', '2026-09-11 00:00:00');
INSERT INTO `post` VALUES (17, '担担面，麻辣里藏着花生香', '面食控', 10, 'admin', 6, '🍜', '芝麻酱和红油调的底，肉臊子炒得干香。花生碎一撒，层次一下就上来了。', 4.5, 3, 72, 78, 32.00, 0, 'approved', '科技园', '2026-09-13 00:00:00');
INSERT INTO `post` VALUES (18, '凉皮筋道，油泼辣子现做的', '面食控', 10, 'test', 1, '🍜', '面筋吸饱了料汁，凉皮透亮弹牙。辣子是温油泼的，香大于辣，夏天吃最爽。', 4.1, 6, 85, 10, 28.00, 0, 'approved', '五道口', '2026-09-15 00:00:00');
INSERT INTO `post` VALUES (19, '肥肠面，处理得一点不腥', '面食控', 10, '哈哈哈', 2, '🍲', '肥肠洗得干净，炖到软糯入味。汤底浓白，配细面，一勺辣酱下去更带劲。', 4.8, 0, 28, 27, 24.00, 0, 'approved', '南锣鼓巷', '2026-09-17 00:00:00');
INSERT INTO `post` VALUES (20, '意式番茄肉丸面，酸甜开胃', '面食控', 10, 'test', 3, '🍝', '肉丸手打，番茄熬出沙。面煮得偏硬，裹着酱汁，酸甜味很提神。', 4.4, 3, 41, 44, 20.00, 0, 'approved', '滨江道', '2026-09-19 00:00:00');
INSERT INTO `post` VALUES (21, '番茄锅底，喝汤比涮肉还香', '火锅江湖', 11, 'admin', 10, '🍲', '番茄熬得浓稠，带点罗勒清香。先喝一碗汤，再下虾滑和牛肉，鲜上加鲜。', 4.0, 6, 54, 61, 87.00, 0, 'approved', '老城区', '2026-09-21 00:00:00');
INSERT INTO `post` VALUES (22, '猪肚鸡锅，胡椒香得很暖胃', '火锅江湖', 11, 'test', 11, '🍲', '整鸡和猪肚慢炖，汤奶白。胡椒味足但不呛，天冷来一锅，从头暖到脚。', 4.7, 0, 67, 78, 98.00, 0, 'approved', '大学城', '2026-09-23 00:00:00');
INSERT INTO `post` VALUES (23, '麻辣牛油锅，鸭血嫩到入口化', '火锅江湖', 11, 'admin', 12, '🌶', '牛油厚重，辣得绵长。鸭血和脑花必点，嫩得不用嚼，宽粉最后收尾。', 4.3, 3, 80, 10, 109.00, 0, 'approved', '万象城', '2026-09-25 00:00:00');
INSERT INTO `post` VALUES (24, '寿喜锅，牛肉裹蛋液绝了', '火锅江湖', 11, 'test', 7, '🥗', '汤头偏甜，肥牛涮三秒就起。蘸生鸡蛋液，滑嫩还解腻，配乌冬刚好。', 3.9, 6, 23, 27, 120.00, 0, 'approved', '三里屯', '2026-09-27 00:00:00');
INSERT INTO `post` VALUES (25, '椰子鸡锅，清甜不腻很养生', '火锅江湖', 11, 'admin', 8, '🥗', '文昌鸡配椰青水，汤清甜。蘸青柠酱油，鸡肉嫩，喝两碗汤整个人都轻了。', 4.6, 0, 36, 44, 70.00, 0, 'approved', '科技园', '2026-09-29 00:00:00');
INSERT INTO `post` VALUES (26, '烤茄子，蒜蓉多到看不见茄肉', '烧烤夜宵', 12, '哈哈哈', 15, '🍂', '茄子烤到软糯，铺满金黄蒜蓉和剁椒。筷子一压就化，实打实的米饭杀手。', 4.2, 3, 49, 61, 34.00, 0, 'approved', '五道口', '2026-10-01 00:00:00');
INSERT INTO `post` VALUES (27, '烤生蚝，现开现烤汁水足', '烧烤夜宵', 12, 'admin', 16, '🦪', '蚝肉饱满，烤到刚熟就上。蒜蓉粉丝垫底，一口爆汁，鲜味直冲。', 4.9, 6, 62, 78, 45.00, 0, 'approved', '南锣鼓巷', '2026-10-03 00:00:00');
INSERT INTO `post` VALUES (28, '羊肉串肥瘦相间，孜然给得狠', '烧烤夜宵', 12, 'test', 17, '🍂', '炭火烤到边缘焦脆，肥肉化开。孜然辣椒面撒得足，香得路人都要回头。', 4.5, 0, 75, 10, 25.00, 1, 'approved', '滨江道', '2026-10-05 00:00:00');
INSERT INTO `post` VALUES (29, '烤面筋，刷酱是老板秘方', '烧烤夜宵', 12, 'admin', 18, '🍡', '面筋烤得外焦里嫩，刷两层酱。辣中带甜，越嚼越香，一串接一串。', 4.1, 3, 88, 27, 36.00, 0, 'approved', '老城区', '2026-10-07 00:00:00');
INSERT INTO `post` VALUES (30, '烤鱿鱼须，弹牙又入味', '烧烤夜宵', 12, 'test', 13, '🍂', '须子烤到卷边，刷甜辣酱。咬下去弹牙，蒜香和孜然混在一起，停不下来。', 4.8, 6, 31, 44, 16.00, 0, 'approved', '大学城', '2026-10-09 00:00:00');
INSERT INTO `post` VALUES (31, '牛油果鸡胸沙拉，酱是自己调的', '轻食沙拉', 13, 'admin', 20, '🥗', '鸡胸低温慢煮不柴，牛油果给得大方。油醋汁加第戎芥末，酸度刚好。', 4.4, 0, 44, 61, 29.00, 0, 'approved', '万象城', '2026-10-11 00:00:00');
INSERT INTO `post` VALUES (32, '藜麦碗，饱腹感一整个下午', '轻食沙拉', 13, 'test', 21, '🥗', '三色藜麦打底，配烤时蔬和鹰嘴豆。坚果碎提香，淋柠檬汁，清爽又有满足感。', 4.0, 3, 57, 78, 27.00, 0, 'approved', '三里屯', '2026-10-13 00:00:00');
INSERT INTO `post` VALUES (33, '凯撒沙拉，面包丁现烤的', '轻食沙拉', 13, '哈哈哈', 22, '🥙', '罗马生菜脆，帕玛森刨得厚。面包丁现烤到酥，凯撒酱顺滑，简单但经典。', 4.7, 6, 70, 10, 38.00, 0, 'approved', '科技园', '2026-10-15 00:00:00');
INSERT INTO `post` VALUES (34, '羽衣甘蓝碗，坚果酱很惊喜', '轻食沙拉', 13, 'test', 23, '🥗', '甘蓝撕小段揉过，软而不涩。配烤南瓜和腰果酱，咸甜交织，减脂也不委屈。', 4.3, 0, 83, 27, 36.00, 0, 'approved', '五道口', '2026-10-17 00:00:00');
INSERT INTO `post` VALUES (35, '安格斯牛肉堡，肉饼会爆汁', '汉堡炸鸡', 14, 'admin', 30, '🍔', '牛肉饼厚切现煎，咬开汁水横流。车达芝士融化裹住，酸黄瓜解腻，扎实管饱。', 3.9, 3, 26, 44, 39.00, 0, 'approved', '南锣鼓巷', '2026-10-19 00:00:00');
INSERT INTO `post` VALUES (36, '辣炸鸡翅，外壳脆到能听见', '汉堡炸鸡', 14, 'test', 25, '🍗', '双炸工艺，皮薄而脆。辣酱是韩式甜辣，肉嫩脱骨，纸巾要备一打。', 4.6, 6, 39, 61, 29.00, 0, 'approved', '滨江道', '2026-10-21 00:00:00');
INSERT INTO `post` VALUES (37, '芝士薯条，拉丝能拉半米', '汉堡炸鸡', 14, 'admin', 26, '🍟', '粗切薯条现炸，铺满融化的芝士。趁热拌开，拉丝到手软，罪恶但快乐。', 4.2, 0, 52, 78, 40.00, 0, 'approved', '老城区', '2026-10-23 00:00:00');
INSERT INTO `post` VALUES (38, '鳕鱼堡，鱼肉嫩得不用嚼', '汉堡炸鸡', 14, 'test', 27, '🍔', '鳕鱼柳炸到金黄，内里雪白。塔塔酱给得多，配酸菜，清爽不油腻。', 4.9, 3, 65, 10, 30.00, 0, 'approved', '大学城', '2026-10-25 00:00:00');
INSERT INTO `post` VALUES (39, '韩式炸鸡配啤酒，夜宵顶配', '汉堡炸鸡', 14, 'admin', 28, '🍗', '炸鸡裹甜辣酱，撒花生碎。配冰啤，外脆里嫩，追剧宵夜首选。', 4.5, 6, 78, 27, 41.00, 0, 'approved', '万象城', '2026-10-27 00:00:00');
INSERT INTO `post` VALUES (40, '三文鱼刺身，油脂线漂亮', '日料局', 15, '哈哈哈', 35, '🍣', '鱼腩部位，切得厚。入口即化，油脂香在舌尖化开。蘸一点酱油山葵，鲜味更突出。', 4.1, 0, 21, 44, 48.00, 0, 'approved', '三里屯', '2026-10-29 00:00:00');
INSERT INTO `post` VALUES (41, '鳗鱼饭，蒲烧酱汁偏甜', '日料局', 15, 'admin', 36, '🍱', '鳗鱼现烤，皮脆肉糯。酱汁刷了三遍，甜咸适中，铺在热米饭上，连吃两碗。', 4.8, 3, 34, 61, 59.00, 1, 'approved', '科技园', '2026-10-31 00:00:00');
INSERT INTO `post` VALUES (42, '寿司卷，蟹柳和牛油果很搭', '日料局', 15, 'test', 31, '🍙', '醋饭温度刚好，蟹柳蟹籽牛油果卷在一起。一口一个，米香和鲜味平衡得不错。', 4.4, 6, 47, 78, 70.00, 0, 'approved', '五道口', '2026-11-02 00:00:00');
INSERT INTO `post` VALUES (43, '天妇罗，面衣薄得透光', '日料局', 15, 'admin', 32, '🍤', '虾和时蔬裹薄衣现炸，不挂油。蘸萝卜泥酱油，酥脆清润，吃得出食材本味。', 4.0, 0, 60, 10, 40.00, 0, 'approved', '南锣鼓巷', '2026-11-04 00:00:00');
INSERT INTO `post` VALUES (44, '味噌拉面，汤浓面硬刚刚好', '日料局', 15, 'test', 33, '🍥', '味噌汤底醇厚，叉烧厚切。面偏硬有嚼劲，加玉米和笋干，暖心暖胃。', 4.7, 3, 73, 27, 51.00, 0, 'approved', '滨江道', '2026-11-06 00:00:00');
INSERT INTO `post` VALUES (45, '舒芙蕾松饼，现烤要等十五分', '甜品时间', 16, 'admin', 40, '🥞', '端上来还在颤，切开像云朵。枫糖和奶油给得足，趁热吃，幸福感爆棚。', 4.3, 6, 86, 44, 28.00, 0, 'approved', '老城区', '2026-11-08 00:00:00');
INSERT INTO `post` VALUES (46, '抹茶千层，茶味浓到微苦', '甜品时间', 16, 'test', 41, '🍰', '可丽饼皮薄如纸，奶油里混了真抹茶。微苦压住甜，一口一层，越吃越上头。', 3.9, 0, 29, 61, 20.00, 0, 'approved', '大学城', '2026-11-10 00:00:00');
INSERT INTO `post` VALUES (47, '提拉米苏，酒香藏在手指饼里', '甜品时间', 16, '哈哈哈', 42, '🍮', '马斯卡彭顺滑，可可粉不苦。手指饼浸了咖啡酒，挖一勺，层次慢慢化开。', 4.6, 3, 42, 78, 31.00, 0, 'approved', '万象城', '2026-11-12 00:00:00');
INSERT INTO `post` VALUES (48, '芒果班戟，皮薄馅大', '甜品时间', 16, 'test', 37, '🥧', '班戟皮软糯，包着整块芒果和淡奶油。咬下去果肉爆汁，甜而不腻，夏天必点。', 4.2, 6, 55, 10, 23.00, 0, 'approved', '三里屯', '2026-11-14 00:00:00');
INSERT INTO `post` VALUES (49, '燕麦拿铁，奶香盖过咖啡苦', '咖啡馆', 17, 'admin', 44, '☕', '燕麦奶打发出绵密泡，和浓缩融合得顺。温润不刺激，乳糖不耐也能喝得很开心。', 4.9, 0, 68, 27, 28.00, 0, 'approved', '科技园', '2026-11-16 00:00:00');
INSERT INTO `post` VALUES (50, '脏脏咖啡，可可粉撒满杯沿', '咖啡馆', 17, 'test', 45, '☕', '冰美式上淋厚奶，喝前搅匀。可可粉带微苦，冰凉爽口，外观也出片。', 4.5, 3, 81, 44, 24.00, 0, 'approved', '五道口', '2026-11-18 00:00:00');
INSERT INTO `post` VALUES (51, '鸡肉卷，老北京口味', '汉堡炸鸡', 14, 'admin', 28, '🍗', '薄饼卷炸鸡条、黄瓜条和大葱，抹甜面酱。分量扎实，两个人点一份也够。', 4.0, 3, 54, 53, 20.00, 1, 'approved', '老城区', '2026-07-22 16:26:34');
INSERT INTO `post` VALUES (52, '鸡胸肉卷饼，全麦饼皮，一口满足', '轻食沙拉', 13, 'test', 23, '🥑', '饼皮夹鸡胸、生菜、番茄和酸奶酱，方便带走。性价比不错，人均不贵，适合日常。', 4.5, 0, 13, 23, 28.00, 0, 'approved', '三里屯', '2026-07-22 16:26:34');
INSERT INTO `post` VALUES (53, '炒花甲，蒜香辣味，粉丝吸汁', '烧烤夜宵', 12, '哈哈哈', 18, '🍂', '花甲吐沙干净，爆炒后加粉丝收汁，鲜辣。分量扎实，两个人点一份也够。', 4.9, 10, 69, 18, 45.00, 0, 'approved', '南锣鼓巷', '2026-06-05 16:26:34');
INSERT INTO `post` VALUES (54, '虾堡，整只虾饼，弹牙', '汉堡炸鸡', 14, 'admin', 25, '🍟', '虾饼煎到两面金黄，配生菜和柠檬蛋黄酱。老板人很客气，会主动问口味轻重。', 4.2, 3, 24, 8, 36.00, 0, 'approved', '大学城', '2026-04-29 16:26:34');
INSERT INTO `post` VALUES (55, '烤鸡腿肉沙拉，腿肉比胸肉更香', '轻食沙拉', 13, 'test', 20, '🥙', '去骨鸡腿烤到皮脆，切片铺在沙拉上，酱汁减半。老板人很客气，会主动问口味轻重。', 4.4, 8, 57, 8, 40.00, 0, 'approved', '科技园', '2026-09-06 16:26:34');
INSERT INTO `post` VALUES (56, '白桃乌龙冷萃，茶咖融合，香得高级', '咖啡馆', 17, '哈哈哈', 45, '🧋', '乌龙冷泡加白桃，再混一点冷萃，果香回甘。周末人多，最好提前打个电话。', 4.4, 10, 62, 82, 32.00, 0, 'approved', '滨江道', '2026-04-24 16:26:34');
INSERT INTO `post` VALUES (57, '手卷寿司，海苔脆，现卷现吃', '日料局', 15, 'admin', 34, '🍱', '海苔裹醋饭和蟹柳或鳗鱼，一口塞进嘴里。分量扎实，两个人点一份也够。', 4.7, 1, 47, 53, 32.00, 0, 'approved', '万象城', '2026-07-16 16:26:34');
INSERT INTO `post` VALUES (58, '烤鸡爪，卤过再烤，胶质满满', '烧烤夜宵', 12, 'test', 17, '🍆', '鸡爪先卤后烤，皮糯骨酥，辣味渗进关节。分量扎实，两个人点一份也够。', 4.3, 1, 88, 36, 30.00, 0, 'approved', '五道口', '2026-08-10 16:26:34');
INSERT INTO `post` VALUES (59, '兰州牛肉面，一清二白三红四绿', '面食控', 10, '哈哈哈', 6, '🍜', '汤头清亮，萝卜白净，辣油红亮，香菜蒜苗翠绿。面条选了二细，筋道有嚼劲。周末人多，最好提前打个电话。', 4.8, 7, 93, 25, 26.00, 0, 'approved', '老城区', '2026-09-27 16:26:34');
INSERT INTO `post` VALUES (60, '杏仁摩卡，巧克力加坚果香', '咖啡馆', 17, 'admin', 43, '🧋', '可可酱挂杯，浓缩加牛奶，撒杏仁碎。老板人很客气，会主动问口味轻重。', 4.6, 7, 20, 38, 32.00, 0, 'approved', '三里屯', '2026-07-21 16:26:34');
INSERT INTO `post` VALUES (61, '香辣鸡腿堡，辣味够冲，面包软', '汉堡炸鸡', 14, 'test', 26, '🍟', '鸡腿肉腌制入味炸到酥脆，生菜多，辣酱偏中式。分量扎实，两个人点一份也够。', 4.6, 11, 81, 83, 26.00, 0, 'approved', '南锣鼓巷', '2026-10-13 16:26:34');
INSERT INTO `post` VALUES (62, '味增拉面，汤头浓，笋干脆', '日料局', 15, '哈哈哈', 33, '🍤', '白味增汤底微甜，叉烧软烂，溏心蛋一戳就流。分量扎实，两个人点一份也够。', 4.5, 9, 38, 85, 48.00, 0, 'approved', '大学城', '2026-10-18 16:26:34');
INSERT INTO `post` VALUES (63, '双层鳕鱼堡，鱼肉厚到爆出来', '汉堡炸鸡', 14, 'admin', 28, '🍟', '两块鳕鱼柳夹芝士，塔塔酱多一点更好吃。环境干净，出餐速度还行。', 4.8, 1, 61, 88, 40.00, 0, 'approved', '科技园', '2026-04-18 16:26:34');
INSERT INTO `post` VALUES (64, '桂花糕，米香配桂花蜜', '甜品时间', 16, 'test', 41, '🍮', '糯米粉蒸制，口感软糯，淋桂花蜜，清甜。分量扎实，两个人点一份也够。', 4.0, 10, 14, 50, 15.00, 0, 'approved', '滨江道', '2026-09-01 16:26:34');
INSERT INTO `post` VALUES (65, '上海葱油拌面，葱油慢熬到焦香', '面食控', 10, '哈哈哈', 6, '🍜', '小火把葱段熬到深褐，酱油加糖调成的汁拌进细面，简单却上瘾。周末人多，最好提前打个电话。', 3.9, 1, 34, 58, 16.00, 0, 'approved', '万象城', '2026-04-18 16:26:34');
INSERT INTO `post` VALUES (66, '豆米火锅，贵州风味，酸辣下饭', '火锅江湖', 11, 'admin', 7, '🥘', '豆米熬成糊状，加酸菜和腊肉，汤浓稠，泡饭最佳。店不大，饭点要等位，建议早点去。', 4.5, 0, 91, 76, 78.00, 0, 'approved', '五道口', '2026-10-04 16:26:34');
INSERT INTO `post` VALUES (67, '提拉米苏，咖啡酒香，不甜腻', '甜品时间', 16, 'test', 38, '🍮', '手指饼吸足咖啡液，马斯卡彭糊厚厚一层，撒可可粉。老板人很客气，会主动问口味轻重。', 3.9, 4, 33, 79, 36.00, 0, 'approved', '老城区', '2026-08-28 16:26:34');
INSERT INTO `post` VALUES (68, '巴斯克芝士蛋糕，焦面微苦，内里流心', '甜品时间', 16, '哈哈哈', 39, '🍨', '表面烤到深褐，中间半熟，芝士味浓，冷藏后更紧实。店不大，饭点要等位，建议早点去。', 4.5, 7, 54, 53, 38.00, 0, 'approved', '三里屯', '2026-08-29 16:26:34');
INSERT INTO `post` VALUES (69, '杨枝甘露，芒果西柚，清爽', '甜品时间', 16, 'admin', 40, '🥧', '芒果泥打底，加西米和西柚粒，椰浆一浇，冰凉爽口。性价比不错，人均不贵，适合日常。', 4.7, 7, 42, 49, 26.00, 0, 'approved', '南锣鼓巷', '2026-08-04 16:26:34');
INSERT INTO `post` VALUES (70, '榴莲酥，榴莲肉塞到溢出', '甜品时间', 16, 'test', 41, '🍨', '酥皮层层分明，榴莲馅浓，趁热吃最香。周末人多，最好提前打个电话。', 4.2, 7, 86, 38, 32.00, 0, 'approved', '大学城', '2026-10-16 16:26:34');
INSERT INTO `post` VALUES (71, '焦糖布丁，敲碎焦糖层', '甜品时间', 16, '哈哈哈', 42, '🥧', '布丁滑嫩，表面焦糖用火枪烧到脆，甜中带苦。分量扎实，两个人点一份也够。', 4.3, 9, 42, 40, 26.00, 0, 'approved', '科技园', '2026-05-11 16:26:34');
INSERT INTO `post` VALUES (72, '烤鸡翅，蜜汁刷两遍，外焦里嫩', '烧烤夜宵', 12, 'admin', 13, '🍂', '鸡翅提前腌一夜，烤时刷两层蜜汁，皮脆肉嫩。分量扎实，两个人点一份也够。', 4.0, 1, 60, 56, 36.00, 0, 'approved', '滨江道', '2026-09-30 16:26:34');
INSERT INTO `post` VALUES (73, '纸包鱼，锡纸包着烤，汁多味浓', '火锅江湖', 11, 'test', 8, '🥘', '整条鱼包在锡纸里加辣椒蒜末焖烤，鱼肉嫩，汁水拌面。老板人很客气，会主动问口味轻重。', 4.5, 4, 79, 88, 98.00, 0, 'approved', '万象城', '2026-09-19 16:26:34');
INSERT INTO `post` VALUES (74, '炸鸡腿饭，配卤汁米饭', '汉堡炸鸡', 14, '哈哈哈', 27, '🍟', '大鸡腿炸脆，米饭淋卤汁，加一份高丽菜丝。周末人多，最好提前打个电话。', 4.4, 5, 45, 43, 30.00, 0, 'approved', '五道口', '2026-08-07 16:26:34');
INSERT INTO `post` VALUES (75, '超大汉堡套餐，双层肉饼双层芝士', '汉堡炸鸡', 14, 'admin', 28, '🍟', '加培根、洋葱圈和煎蛋，配薯条和可乐。店不大，饭点要等位，建议早点去。', 4.4, 8, 39, 71, 58.00, 0, 'approved', '老城区', '2026-05-15 16:26:34');
INSERT INTO `post` VALUES (76, '红豆双皮奶冰，红豆沙绵密', '甜品时间', 16, 'test', 41, '🍨', '红豆熬到起沙，铺在双皮奶上，加碎冰。老板人很客气，会主动问口味轻重。', 4.5, 11, 85, 28, 24.00, 0, 'approved', '三里屯', '2026-10-09 16:26:34');
INSERT INTO `post` VALUES (77, '北京炸酱面，六必居的酱，菜码摆一桌', '面食控', 10, '哈哈哈', 6, '🍜', '黄酱甜面酱小火慢炸出油，配黄瓜丝、豆芽、青豆，拌匀后每根面都挂酱。周末人多，最好提前打个电话。', 4.9, 1, 54, 54, 28.00, 0, 'approved', '南锣鼓巷', '2026-09-21 16:26:34');
INSERT INTO `post` VALUES (78, '越南春卷，透亮米皮，蘸鱼露', '轻食沙拉', 13, 'admin', 19, '🥑', '虾仁、生菜、薄荷卷在米皮里，蘸酸甜鱼露。环境干净，出餐速度还行。', 4.1, 7, 12, 71, 32.00, 0, 'approved', '大学城', '2026-05-31 16:26:34');
INSERT INTO `post` VALUES (79, '新疆拉条子，过油肉拌面，大盘装', '面食控', 10, '哈哈哈', 2, '🍲', '手工拉条子筋道，过油肉带番茄酸香，拌开后酱汁裹住每根面。性价比不错，人均不贵，适合日常。', 4.2, 5, 14, 53, 35.00, 0, 'approved', '滨江道', '2026-09-10 16:26:34');
INSERT INTO `post` VALUES (80, '烤鱼豆腐，外皮起泡，里面嫩', '烧烤夜宵', 12, 'admin', 15, '🍆', '鱼豆腐烤到鼓胀，撒辣椒面和孜然，蘸干碟。环境干净，出餐速度还行。', 4.3, 4, 55, 56, 22.00, 0, 'approved', '万象城', '2026-09-25 16:26:34');
INSERT INTO `post` VALUES (81, '跷脚牛肉锅，汤鲜肉嫩，配干碟', '火锅江湖', 11, 'test', 10, '🌶️', '牛骨药材汤清鲜，牛杂软糯，蘸辣椒面干碟香辣。店不大，饭点要等位，建议早点去。', 4.5, 1, 37, 79, 88.00, 0, 'approved', '五道口', '2026-09-01 16:26:34');
INSERT INTO `post` VALUES (82, '芋泥啵啵奶茶，芋泥沉底，吸管能挖', '甜品时间', 16, '哈哈哈', 41, '🍨', '芋泥绵密带颗粒，鲜奶打底，啵啵弹牙。性价比不错，人均不贵，适合日常。', 3.8, 11, 90, 17, 22.00, 0, 'approved', '老城区', '2026-09-21 16:26:34');
INSERT INTO `post` VALUES (83, '气泡水美式，清爽解腻', '咖啡馆', 17, 'admin', 48, '🧋', '汤力水加浓缩，气泡带出柑橘感，夏天首选。性价比不错，人均不贵，适合日常。', 4.0, 12, 69, 15, 28.00, 0, 'approved', '三里屯', '2026-10-25 16:26:34');
INSERT INTO `post` VALUES (84, '麻辣香锅，干香不腻，自选食材', '火锅江湖', 11, 'test', 7, '🌶️', '藕片、虾滑、午餐肉、花菜炒香锅底料，干辣带麻，配米饭。分量扎实，两个人点一份也够。', 4.9, 12, 82, 55, 68.00, 0, 'approved', '南锣鼓巷', '2026-10-15 16:26:34');
INSERT INTO `post` VALUES (85, '蛋挞，酥皮一层一层', '甜品时间', 16, '哈哈哈', 38, '🥧', '挞皮起酥明显，蛋液微颤，烤到表面有焦斑最好。老板人很客气，会主动问口味轻重。', 4.6, 1, 48, 17, 12.00, 0, 'approved', '大学城', '2026-10-27 16:26:34');
INSERT INTO `post` VALUES (86, '日式炸猪排，面衣酥，肉厚', '日料局', 15, 'admin', 33, '🍤', '猪里脊裹粗面包糠炸到金黄，配卷心菜丝和猪排酱。周末人多，最好提前打个电话。', 4.8, 1, 29, 52, 56.00, 0, 'approved', '科技园', '2026-08-26 16:26:34');
INSERT INTO `post` VALUES (87, '韩式炸鸡，甜辣酱裹满', '汉堡炸鸡', 14, 'test', 28, '🍗', '炸鸡裹甜辣酱和白芝麻，外脆里嫩，配腌萝卜。分量扎实，两个人点一份也够。', 4.0, 10, 46, 66, 68.00, 0, 'approved', '滨江道', '2026-07-13 16:26:34');
INSERT INTO `post` VALUES (88, '可颂，一层一层的酥', '甜品时间', 16, '哈哈哈', 41, '🥧', '现烤可颂，黄油香明显，掰开能看到蜂窝组织。性价比不错，人均不贵，适合日常。', 4.4, 6, 24, 54, 18.00, 0, 'approved', '万象城', '2026-05-06 16:26:34');
INSERT INTO `post` VALUES (89, '亲子丼，滑蛋裹鸡肉', '日料局', 15, 'admin', 36, '🍙', '鸡肉和洋葱煮软，蛋液半熟盖在饭上，撒海苔。老板人很客气，会主动问口味轻重。', 4.4, 3, 75, 47, 38.00, 0, 'approved', '五道口', '2026-08-09 16:26:34');
INSERT INTO `post` VALUES (90, '南宁老友粉，酸笋豆豉，闻着冲吃着香', '面食控', 10, 'test', 1, '🍝', '酸笋、豆豉、辣椒先爆香再下汤，粉滑汤浓，冬天吃出一身汗。周末人多，最好提前打个电话。', 4.2, 0, 71, 77, 22.00, 0, 'approved', '老城区', '2026-05-20 16:26:34');
INSERT INTO `post` VALUES (91, '双皮奶，奶皮厚，勺子能挂住', '甜品时间', 16, '哈哈哈', 38, '🍰', '顺德做法，水牛奶蒸两遍，甜度低，奶香纯。店不大，饭点要等位，建议早点去。', 4.7, 6, 38, 8, 20.00, 0, 'approved', '三里屯', '2026-07-05 16:26:34');
INSERT INTO `post` VALUES (92, '澳白，奶泡薄，咖啡味重', '咖啡馆', 17, 'admin', 45, '🥤', '双份 ristretto 配微泡牛奶，咖啡味更突出。环境干净，出餐速度还行。', 3.9, 9, 40, 19, 32.00, 0, 'approved', '南锣鼓巷', '2026-06-28 16:26:34');
INSERT INTO `post` VALUES (93, '椰子鸡火锅，清甜椰水，鸡肉嫩', '火锅江湖', 11, 'test', 10, '🌶️', '现开椰青做锅底，文昌鸡皮薄肉嫩，蘸青桔酱油沙姜。环境干净，出餐速度还行。', 4.8, 9, 48, 43, 128.00, 0, 'approved', '大学城', '2026-05-04 16:26:34');
INSERT INTO `post` VALUES (94, '辣味鸡块，外酥里嫩，辣得刚好', '汉堡炸鸡', 14, '哈哈哈', 29, '🍗', '鸡腿肉切块炸，辣味裹在面衣里，越嚼越香。环境干净，出餐速度还行。', 4.0, 8, 32, 60, 24.00, 0, 'approved', '科技园', '2026-10-08 16:26:34');
INSERT INTO `post` VALUES (95, '豆乳盒子，豆香浓，不腻', '甜品时间', 16, 'test', 42, '🥧', '豆乳卡仕达和蛋糕胚交替铺，撒黄豆粉。性价比不错，人均不贵，适合日常。', 4.2, 9, 36, 81, 30.00, 0, 'approved', '万象城', '2026-06-30 16:26:34');
INSERT INTO `post` VALUES (96, '三文鱼牛油果饭，两种油脂的碰撞', '轻食沙拉', 13, '哈哈哈', 19, '🥙', '三文鱼微炙，牛油果绵，米饭里拌一点寿司醋。分量扎实，两个人点一份也够。', 4.6, 4, 67, 77, 52.00, 1, 'approved', '五道口', '2026-04-19 16:26:34');
INSERT INTO `post` VALUES (97, '烤鸡架，沈阳风味，啃着香', '烧烤夜宵', 12, 'admin', 14, '🍆', '鸡架腌透再烤，撒甜辣料，肉不多但上头。老板人很客气，会主动问口味轻重。', 4.5, 8, 38, 12, 25.00, 0, 'approved', '老城区', '2026-05-29 16:26:34');
INSERT INTO `post` VALUES (98, '希腊沙拉，羊奶酪咸香，橄榄解腻', '轻食沙拉', 13, 'test', 21, '🥗', '黄瓜番茄洋葱切块，配黑橄榄和菲达芝士，橄榄油一浇。周末人多，最好提前打个电话。', 4.0, 3, 73, 27, 38.00, 0, 'approved', '三里屯', '2026-05-08 16:26:34');
INSERT INTO `post` VALUES (99, '冰粉，红糖水配山楂碎', '甜品时间', 16, '哈哈哈', 40, '🍰', '手搓冰粉微弹，加红糖水、葡萄干、山楂和花生碎。店不大，饭点要等位，建议早点去。', 3.8, 12, 80, 23, 16.00, 0, 'approved', '南锣鼓巷', '2026-05-21 16:26:34');
INSERT INTO `post` VALUES (100, '奥尔良烤翅，甜辣腌透，烤箱现烤', '汉堡炸鸡', 14, 'admin', 29, '🍗', '鸡翅腌一夜，烤到边缘焦香，肉质紧实。周末人多，最好提前打个电话。', 3.9, 6, 81, 75, 28.00, 0, 'approved', '大学城', '2026-05-05 16:26:34');
INSERT INTO `post` VALUES (101, '大阪烧，厚厚一层，酱汁刷满', '日料局', 15, 'test', 36, '🍤', '卷心菜丝拌面糊煎，加培根和虾，淋大阪烧酱和蛋黄酱。店不大，饭点要等位，建议早点去。', 4.3, 6, 90, 41, 42.00, 0, 'approved', '科技园', '2026-07-31 16:26:34');
INSERT INTO `post` VALUES (102, '潮汕牛肉火锅，现切吊龙，八秒起锅', '火锅江湖', 11, '哈哈哈', 7, '🌶️', '清汤锅底只放萝卜和芹菜，吊龙、匙柄、胸口油按部位涮，鲜甜。店不大，饭点要等位，建议早点去。', 4.5, 9, 30, 14, 158.00, 0, 'approved', '滨江道', '2026-05-06 16:26:34');
INSERT INTO `post` VALUES (103, '天津打卤面，卤子稠到挂勺', '面食控', 10, 'admin', 2, '🍜', '木耳黄花肉片熬成浓卤，浇在面上撒花椒油，咸鲜厚重。周末人多，最好提前打个电话。', 4.7, 0, 29, 72, 23.00, 0, 'approved', '万象城', '2026-09-29 16:26:34');
INSERT INTO `post` VALUES (104, '海鲜打边炉，一锅鲜，涮什么都好吃', '火锅江湖', 11, 'test', 9, '🌶️', '花胶鸡汤底，涮生蚝、象拔蚌、手打虾滑，鲜到不行。性价比不错，人均不贵，适合日常。', 4.8, 5, 42, 78, 198.00, 0, 'approved', '五道口', '2026-08-25 16:26:34');
INSERT INTO `post` VALUES (105, '牛舌定食，厚切盐烤，弹牙', '日料局', 15, '哈哈哈', 34, '🍤', '牛舌切厚片撒盐烤，配麦饭和牛尾汤。分量扎实，两个人点一份也够。', 4.6, 9, 12, 25, 88.00, 0, 'approved', '老城区', '2026-05-21 16:26:34');
INSERT INTO `post` VALUES (106, '培根蛋堡，早餐来一份', '汉堡炸鸡', 14, 'admin', 29, '🍗', '培根煎脆，鸡蛋半熟，面包烤过抹黄油。店不大，饭点要等位，建议早点去。', 4.7, 11, 15, 85, 24.00, 0, 'approved', '三里屯', '2026-04-15 16:26:34');
INSERT INTO `post` VALUES (107, '锡纸金针菇，蒜蓉汁泡着，鲜得很', '烧烤夜宵', 12, 'test', 18, '🍂', '金针菇加粉丝和蒜蓉，锡纸包着焖烤，汤汁鲜美。环境干净，出餐速度还行。', 3.9, 1, 52, 82, 24.00, 0, 'approved', '南锣鼓巷', '2026-09-02 16:26:34');
INSERT INTO `post` VALUES (108, '延边烤黄牛肉，现切现烤，嫩到出汁', '烧烤夜宵', 12, '哈哈哈', 13, '🍂', '黄牛肉切薄片，炭火快烤，蘸盐和辣酱都好吃。店不大，饭点要等位，建议早点去。', 4.4, 2, 65, 49, 68.00, 0, 'approved', '大学城', '2026-10-14 16:26:34');
INSERT INTO `post` VALUES (109, '青岛大虾面，整只大虾铺满碗面', '面食控', 10, 'admin', 2, '🍲', '虾油炒香葱姜做底汤，面条吸足虾鲜，虾肉紧实弹牙。店不大，饭点要等位，建议早点去。', 4.7, 9, 28, 84, 38.00, 0, 'approved', '科技园', '2026-10-18 16:26:34');
INSERT INTO `post` VALUES (110, '鹰嘴豆泥蔬菜条，蘸着吃，越吃越上瘾', '轻食沙拉', 13, 'test', 21, '🥑', '鹰嘴豆泥加芝麻酱和柠檬，配胡萝卜、黄瓜条。周末人多，最好提前打个电话。', 4.7, 6, 43, 48, 24.00, 0, 'approved', '滨江道', '2026-09-07 16:26:34');
INSERT INTO `post` VALUES (111, '湖南米粉，酸豆角加剁椒，够味', '面食控', 10, '哈哈哈', 4, '🥟', '圆粉爽滑，码子选酸辣鸡杂，汤里加一勺剁椒，辣得过瘾。周末人多，最好提前打个电话。', 3.8, 5, 76, 8, 21.00, 0, 'approved', '万象城', '2026-07-25 16:26:34');
INSERT INTO `post` VALUES (112, '纳豆饭，爱的人很爱', '日料局', 15, 'admin', 35, '🍤', '纳豆搅出丝，配生鸡蛋和葱花，加一点酱油拌饭。老板人很客气，会主动问口味轻重。', 4.1, 11, 22, 73, 20.00, 0, 'approved', '五道口', '2026-06-29 16:26:34');
INSERT INTO `post` VALUES (113, '羊蝎子火锅，啃骨头喝汤，冬天必点', '火锅江湖', 11, 'test', 12, '🍲', '羊脊骨炖到脱骨，汤里加白萝卜和香菜，越煮越浓。环境干净，出餐速度还行。', 4.3, 10, 29, 35, 138.00, 0, 'approved', '老城区', '2026-05-09 16:26:34');
INSERT INTO `post` VALUES (114, '草莓奶油蛋糕，奶油轻盈，草莓多', '甜品时间', 16, '哈哈哈', 37, '🍮', '戚风胚松软，奶油不多不少，草莓带酸解甜。店不大，饭点要等位，建议早点去。', 4.4, 10, 23, 21, 45.00, 0, 'approved', '三里屯', '2026-07-21 16:26:34');
INSERT INTO `post` VALUES (115, '番茄牛腩锅，酸甜汤底，拌饭一绝', '火锅江湖', 11, 'admin', 8, '🍲', '番茄熬到融化，牛腩炖得软糯，汤泡饭能吃两碗。性价比不错，人均不贵，适合日常。', 4.7, 7, 13, 18, 98.00, 0, 'approved', '南锣鼓巷', '2026-05-02 16:26:34');
INSERT INTO `post` VALUES (116, '水果酸奶碗，希腊酸奶配莓果', '轻食沙拉', 13, 'test', 21, '🥙', '无糖希腊酸奶打底，加蓝莓、草莓、奇亚籽和燕麦脆。性价比不错，人均不贵，适合日常。', 4.1, 1, 58, 58, 26.00, 0, 'approved', '大学城', '2026-06-02 16:26:34');
INSERT INTO `post` VALUES (117, '烤蔬菜沙拉，烤过的蔬菜更甜', '轻食沙拉', 13, '哈哈哈', 22, '🥑', '南瓜、彩椒、西葫芦烤出焦糖味，拌油醋汁。周末人多，最好提前打个电话。', 4.7, 7, 82, 22, 34.00, 0, 'approved', '科技园', '2026-06-10 16:26:34');
INSERT INTO `post` VALUES (118, '陕西油泼面，热油泼在辣子上那一声响', '面食控', 10, 'admin', 5, '🍲', '宽面片厚实，铺满辣椒面和蒜末，滚油一泼香气炸开，拌开咸香带辣。分量扎实，两个人点一份也够。', 4.0, 8, 80, 30, 24.00, 0, 'approved', '滨江道', '2026-10-30 16:26:34');
INSERT INTO `post` VALUES (119, '脏脏包，可可粉能吃一手', '甜品时间', 16, 'test', 42, '🍰', '可颂里夹巧克力酱，表面筛厚厚可可粉，掰开爆浆。环境干净，出餐速度还行。', 4.7, 8, 51, 25, 28.00, 0, 'approved', '万象城', '2026-07-27 16:26:34');
INSERT INTO `post` VALUES (120, '黑糖珍珠鲜奶，珍珠现煮，软糯', '咖啡馆', 17, '哈哈哈', 43, '🥤', '黑糖挂壁，鲜奶加珍珠，甜度高但顺口。分量扎实，两个人点一份也够。', 4.7, 8, 69, 74, 24.00, 0, 'approved', '五道口', '2026-06-07 16:26:34');
INSERT INTO `post` VALUES (121, '和牛寿喜烧定食，一片牛肉一片葱', '日料局', 15, 'admin', 32, '🍤', '和牛薄片涮甜咸酱汁，蘸蛋液，配米饭和味增汤。环境干净，出餐速度还行。', 4.8, 7, 78, 70, 128.00, 0, 'approved', '老城区', '2026-06-11 16:26:34');
INSERT INTO `post` VALUES (122, '凯撒沙拉，帕玛森撒厚厚一层', '轻食沙拉', 13, 'test', 21, '🥙', '罗马生菜脆，面包丁香，凯撒酱浓郁带蒜香。老板人很客气，会主动问口味轻重。', 4.8, 3, 44, 64, 36.00, 0, 'approved', '三里屯', '2026-07-12 16:26:34');
INSERT INTO `post` VALUES (123, '盐烤秋刀鱼，内脏微苦才是精髓', '日料局', 15, '哈哈哈', 34, '🍣', '整条撒盐烤到皮脆，挤柠檬，配白萝卜泥。周末人多，最好提前打个电话。', 3.8, 8, 81, 36, 44.00, 0, 'approved', '南锣鼓巷', '2026-09-28 16:26:34');
INSERT INTO `post` VALUES (124, '章鱼小丸子，外皮脆内里糊', '日料局', 15, 'test', 35, '🍙', '里面有大块章鱼，撒木鱼花和海苔粉，酱汁甜咸。性价比不错，人均不贵，适合日常。', 4.7, 1, 42, 78, 26.00, 0, 'approved', '科技园', '2026-11-03 16:26:34');
INSERT INTO `post` VALUES (125, '关东煮，汤鲜，萝卜入味', '日料局', 15, '哈哈哈', 36, '🍱', '萝卜、竹轮、魔芋、油豆腐在清汤里煮，蘸芥末。性价比不错，人均不贵，适合日常。', 4.2, 2, 61, 35, 28.00, 0, 'approved', '滨江道', '2026-06-30 16:26:34');
INSERT INTO `post` VALUES (126, '炭烤羊肉串，肥瘦相间，孜然撒足', '烧烤夜宵', 12, 'admin', 13, '🍢', '肉块现穿现烤，油脂滴在炭上冒烟，孜然辣椒面一撒，香得勾人。分量扎实，两个人点一份也够。', 4.7, 11, 60, 68, 45.00, 0, 'approved', '万象城', '2026-06-21 16:26:34');
INSERT INTO `post` VALUES (127, '抹茶拿铁，宇治抹茶，微苦', '咖啡馆', 17, 'test', 44, '🧋', '抹茶粉现打，与牛奶分层，喝前搅匀。老板人很客气，会主动问口味轻重。', 4.1, 3, 41, 40, 30.00, 0, 'approved', '五道口', '2026-07-16 16:26:34');
INSERT INTO `post` VALUES (128, '牛肉卷饼，墨西哥风味', '汉堡炸鸡', 14, '哈哈哈', 27, '🍟', '牛肉粒炒洋葱，卷饼夹芝士和莎莎酱。老板人很客气，会主动问口味轻重。', 3.8, 3, 89, 77, 34.00, 0, 'approved', '老城区', '2026-09-05 16:26:34');
INSERT INTO `post` VALUES (129, '红茶拿铁，茶味重，咖啡因足', '咖啡馆', 17, 'admin', 46, '🥤', '锡兰红茶浓缩加牛奶，茶多咖啡少。性价比不错，人均不贵，适合日常。', 4.4, 5, 52, 64, 26.00, 0, 'approved', '三里屯', '2026-09-20 16:26:34');
INSERT INTO `post` VALUES (130, '炸鸡桶，外皮咔嚓，肉汁流', '汉堡炸鸡', 14, 'test', 29, '🍗', '裹粉炸两遍，皮脆肉嫩，配蜂蜜芥末和辣酱。性价比不错，人均不贵，适合日常。', 4.3, 12, 40, 62, 88.00, 0, 'approved', '南锣鼓巷', '2026-09-14 16:26:34');
INSERT INTO `post` VALUES (131, '铁板鱿鱼，滋啦作响，酱香浓', '烧烤夜宵', 12, '哈哈哈', 18, '🍂', '鱿鱼刷酱快烤，加洋葱和青椒，弹牙带甜。周末人多，最好提前打个电话。', 4.4, 12, 48, 32, 32.00, 0, 'approved', '大学城', '2026-05-05 16:26:34');
INSERT INTO `post` VALUES (132, '鳕鱼堡，鱼肉雪白，塔塔酱酸', '汉堡炸鸡', 14, 'admin', 25, '🍔', '鳕鱼柳裹粉炸，塔塔酱带酸黄瓜粒，清爽不腻。老板人很客气，会主动问口味轻重。', 3.9, 11, 87, 53, 32.00, 0, 'approved', '科技园', '2026-10-25 16:26:34');
INSERT INTO `post` VALUES (133, '苏州焖肉面，焖肉入口即化', '面食控', 10, 'test', 2, '🥟', '五花肉焖到酥烂，肥而不腻，红汤细面，撒一把青蒜。分量扎实，两个人点一份也够。', 4.5, 5, 21, 56, 29.00, 0, 'approved', '滨江道', '2026-08-23 16:26:34');
INSERT INTO `post` VALUES (134, '重庆小面，麻辣鲜香，早上就来一碗', '面食控', 10, '哈哈哈', 3, '🍜', '红油辣子香气冲鼻，花椒面点到为止的麻，配一碗免费的豆浆刚好。性价比不错，人均不贵，适合日常。', 4.0, 10, 34, 78, 20.00, 0, 'approved', '万象城', '2026-04-28 16:26:34');
INSERT INTO `post` VALUES (135, '烟熏三文鱼沙拉，咸鲜配芝麻菜', '轻食沙拉', 13, 'admin', 22, '🥙', '三文鱼烟熏香，芝麻菜微苦，配柠檬汁和黑胡椒刚好。周末人多，最好提前打个电话。', 4.0, 8, 43, 18, 48.00, 0, 'approved', '五道口', '2026-04-17 16:26:34');
INSERT INTO `post` VALUES (136, '镇江锅盖面，面锅里面煮锅盖', '面食控', 10, 'test', 5, '🍜', '面条偏硬有嚼劲，浇头选长鱼或腰花，汤头咸鲜回甜。老板人很客气，会主动问口味轻重。', 4.2, 4, 57, 88, 23.00, 0, 'approved', '老城区', '2026-09-10 16:26:34');
INSERT INTO `post` VALUES (137, '重庆九宫格老火锅，牛油翻滚，涮毛肚七上八下', '火锅江湖', 11, '哈哈哈', 12, '🥘', '牛油锅底香辣厚重，毛肚脆、鸭肠嫩，配蒜泥香油碟解辣。性价比不错，人均不贵，适合日常。', 4.3, 7, 47, 44, 128.00, 0, 'approved', '三里屯', '2026-08-17 16:26:34');
INSERT INTO `post` VALUES (138, '手冲耶加雪菲，柑橘酸质，回甘明显', '咖啡馆', 17, 'admin', 43, '🥤', '水温 92 度，三段注水，前段花香，后段像红茶。周末人多，最好提前打个电话。', 4.4, 11, 42, 39, 38.00, 0, 'approved', '南锣鼓巷', '2026-08-08 16:26:34');
INSERT INTO `post` VALUES (139, '成都担担面，一口麻一口香', '面食控', 10, 'test', 2, '🥟', '细面配肉臊、花生碎、芽菜，红油和芝麻酱在碗底，拌起来特别香。分量扎实，两个人点一份也够。', 4.2, 3, 12, 38, 19.00, 0, 'approved', '大学城', '2026-10-03 16:26:34');
INSERT INTO `post` VALUES (140, '小龙虾，十三香麻辣，手套备好', '烧烤夜宵', 12, '哈哈哈', 15, '🍢', '虾壳薄易剥，汤汁浓，配啤酒能吃到凌晨。性价比不错，人均不贵，适合日常。', 4.5, 12, 38, 27, 128.00, 0, 'approved', '科技园', '2026-06-01 16:26:34');
INSERT INTO `post` VALUES (141, '毛血旺，红油里全是料', '火锅江湖', 11, 'admin', 10, '🍲', '鸭血滑、毛肚脆、黄喉爽，加豆芽打底，麻辣够劲。性价比不错，人均不贵，适合日常。', 4.0, 8, 49, 50, 78.00, 0, 'approved', '滨江道', '2026-05-01 16:26:34');
INSERT INTO `post` VALUES (142, '麻辣烫，自选食材，麻酱多加', '烧烤夜宵', 12, 'test', 17, '🍢', '骨汤煮菜，麻酱、蒜水、辣油自己调，便宜管饱。老板人很客气，会主动问口味轻重。', 4.3, 10, 71, 39, 26.00, 1, 'approved', '万象城', '2026-05-10 16:26:34');
INSERT INTO `post` VALUES (143, '柠檬气泡冰咖，酸甜清爽', '咖啡馆', 17, '哈哈哈', 48, '🧋', '柠檬片加冰块，浓缩淋在最上层，渐层好看。周末人多，最好提前打个电话。', 3.9, 9, 27, 24, 26.00, 0, 'approved', '五道口', '2026-06-28 16:26:34');
INSERT INTO `post` VALUES (144, '抹茶千层，二十层薄饼叠成', '甜品时间', 16, 'admin', 37, '🍰', '抹茶奶油微苦，薄饼柔软，切开发出沙沙声。周末人多，最好提前打个电话。', 4.3, 6, 65, 81, 42.00, 0, 'approved', '老城区', '2026-11-02 16:26:34');
INSERT INTO `post` VALUES (145, '烤玉米，黄油抹匀，粒粒爆汁', '烧烤夜宵', 12, 'test', 14, '🍂', '甜玉米刷黄油烤，撒一点海盐，甜香。老板人很客气，会主动问口味轻重。', 4.2, 5, 80, 69, 15.00, 0, 'approved', '三里屯', '2026-10-05 16:26:34');
INSERT INTO `post` VALUES (146, '双层芝士牛肉堡，两手都握不住', '汉堡炸鸡', 14, '哈哈哈', 27, '🍔', '两片牛肉饼夹车达芝士，酸黄瓜和洋葱解腻，酱汁带烟熏味。老板人很客气，会主动问口味轻重。', 4.6, 10, 86, 70, 42.00, 0, 'approved', '南锣鼓巷', '2026-09-26 16:26:34');
INSERT INTO `post` VALUES (147, '老北京铜锅涮肉，手切羊肉配麻酱', '火锅江湖', 11, 'admin', 10, '🍲', '铜锅清汤，羊肉片薄，麻酱里加韭菜花和腐乳，一口下去暖。环境干净，出餐速度还行。', 4.5, 8, 24, 78, 118.00, 0, 'approved', '大学城', '2026-09-29 16:26:34');
INSERT INTO `post` VALUES (148, '烤青花鱼，皮脆肉嫩，柠檬提味', '日料局', 15, 'test', 35, '🍤', '青花鱼撒盐烤，油脂香，挤柠檬汁解腻。店不大，饭点要等位，建议早点去。', 3.9, 0, 36, 32, 52.00, 0, 'approved', '科技园', '2026-09-03 16:26:34');
INSERT INTO `post` VALUES (149, '厦门沙茶面，沙茶酱浓，海鲜给得足', '面食控', 10, '哈哈哈', 6, '🍜', '汤头沙茶味厚重带微甜，配鲜虾、豆干、猪肝，吸饱汤汁特别香。性价比不错，人均不贵，适合日常。', 4.8, 9, 67, 55, 32.00, 0, 'approved', '滨江道', '2026-08-04 16:26:34');
INSERT INTO `post` VALUES (150, '梭边鱼火锅，鱼肉无刺，麻辣过瘾', '火锅江湖', 11, 'admin', 7, '🥘', '鱼片薄如纸，麻辣锅底香，配青笋和魔芋吸味。环境干净，出餐速度还行。', 3.9, 11, 69, 44, 128.00, 0, 'approved', '万象城', '2026-09-08 16:26:34');
INSERT INTO `post` VALUES (151, '天妇罗拼盘，面衣薄，炸得脆', '日料局', 15, 'test', 32, '🍤', '虾和时蔬裹薄糊炸，蘸天妇罗汁加萝卜泥。环境干净，出餐速度还行。', 4.3, 11, 91, 59, 58.00, 0, 'approved', '五道口', '2026-06-23 16:26:34');
INSERT INTO `post` VALUES (152, '炸鸡翅拼盘，三种口味一次吃', '汉堡炸鸡', 14, '哈哈哈', 27, '🍗', '原味、蜂蜜、辣味各三只，配酸黄瓜。环境干净，出餐速度还行。', 4.4, 6, 52, 58, 48.00, 0, 'approved', '老城区', '2026-05-29 16:26:34');
INSERT INTO `post` VALUES (153, '炸串，裹糊现炸，撒料够味', '烧烤夜宵', 12, 'admin', 16, '🍆', '土豆片、鸡柳、豆皮裹糊炸脆，撒孜然辣椒。老板人很客气，会主动问口味轻重。', 4.0, 1, 63, 25, 35.00, 0, 'approved', '三里屯', '2026-09-27 16:26:34');
INSERT INTO `post` VALUES (154, '山西刀削面，面条中间厚两边薄', '面食控', 10, 'test', 5, '🍲', '削面入口外滑内筋，浇上番茄鸡蛋卤，酸鲜开胃，越吃越顺口。环境干净，出餐速度还行。', 4.8, 4, 44, 74, 22.00, 0, 'approved', '南锣鼓巷', '2026-09-26 16:26:34');
INSERT INTO `post` VALUES (155, '冰美式，醒脑，不加糖', '咖啡馆', 17, '哈哈哈', 48, '🧋', '双份浓缩加冰水，苦味干净，尾段微酸。环境干净，出餐速度还行。', 4.3, 1, 12, 31, 22.00, 0, 'approved', '大学城', '2026-10-21 16:26:34');
INSERT INTO `post` VALUES (156, '鳗鱼饭，酱汁焦糖香', '日料局', 15, 'admin', 31, '🍱', '鳗鱼烤到皮脆，刷三次酱汁，铺在热饭上，甜咸下饭。环境干净，出餐速度还行。', 4.1, 8, 29, 65, 78.00, 0, 'approved', '科技园', '2026-08-06 16:26:34');
INSERT INTO `post` VALUES (157, '藜麦鸡丝碗，主食换成藜麦，无负担', '轻食沙拉', 13, 'test', 20, '🥙', '藜麦弹牙，鸡丝细嫩，配紫甘蓝和胡萝卜丝。环境干净，出餐速度还行。', 4.2, 4, 88, 54, 38.00, 0, 'approved', '滨江道', '2026-10-15 16:26:34');
INSERT INTO `post` VALUES (158, '卡布奇诺，奶泡厚，撒可可粉', '咖啡馆', 17, '哈哈哈', 45, '🥤', '奶泡占三分之一，入口绵密，咖啡香在最后。周末人多，最好提前打个电话。', 4.3, 3, 32, 40, 28.00, 0, 'approved', '万象城', '2026-08-11 16:26:34');
INSERT INTO `post` VALUES (159, '潮汕粿条汤，汤清味鲜，粿条滑溜', '面食控', 10, 'test', 4, '🍝', '猪骨汤底清透，粿条软滑，配牛肉丸、猪杂和炸蒜蓉，暖胃。店不大，饭点要等位，建议早点去。', 4.2, 11, 74, 45, 27.00, 0, 'approved', '老城区', '2026-05-23 16:26:34');
INSERT INTO `post` VALUES (160, '牛油果虾仁碗，搭得好看，吃着饱', '轻食沙拉', 13, '哈哈哈', 23, '🥗', '牛油果绵密，虾仁弹，加藜麦和鹰嘴豆，一份能顶到晚饭。店不大，饭点要等位，建议早点去。', 4.8, 11, 33, 57, 42.00, 0, 'approved', '三里屯', '2026-05-23 16:26:34');
INSERT INTO `post` VALUES (161, '波奇饭，夏威夷风，色彩满分', '轻食沙拉', 13, 'admin', 24, '🥙', '三文鱼丁、牛油果、毛豆、海苔铺在米饭上，淋酱油。环境干净，出餐速度还行。', 4.0, 10, 87, 9, 46.00, 0, 'approved', '南锣鼓巷', '2026-10-06 16:26:34');
INSERT INTO `post` VALUES (162, '可可碎片冰沙，巧克力味浓', '咖啡馆', 17, 'test', 43, '🥤', '可可粉加牛奶打成冰沙，加巧克力碎，冰爽。环境干净，出餐速度还行。', 4.2, 4, 26, 15, 30.00, 0, 'approved', '大学城', '2026-10-30 16:26:34');
INSERT INTO `post` VALUES (163, '烤韭菜，刷油撒盐，简单好吃', '烧烤夜宵', 12, '哈哈哈', 14, '🍆', '韭菜一把烤到断生，撒盐和辣椒面，脆嫩带甜。店不大，饭点要等位，建议早点去。', 4.9, 4, 95, 74, 18.00, 0, 'approved', '科技园', '2026-04-18 16:26:34');
INSERT INTO `post` VALUES (164, '桂花拿铁，秋天限定，香得明显', '咖啡馆', 17, 'admin', 45, '🥤', '桂花蜜打底，加浓缩和牛奶，甜度刚好。环境干净，出餐速度还行。', 4.2, 10, 56, 63, 30.00, 0, 'approved', '滨江道', '2026-08-24 16:26:34');
INSERT INTO `post` VALUES (165, '鸡米花，一口一个，越吃越快', '汉堡炸鸡', 14, '哈哈哈', 28, '🍔', '鸡胸切小丁腌入味，裹粉炸到金黄，撒椒盐。周末人多，最好提前打个电话。', 4.5, 7, 63, 23, 18.00, 0, 'approved', '五道口', '2026-11-05 16:26:34');
INSERT INTO `post` VALUES (166, '酸汤鱼火锅，红酸汤开胃，鱼肉嫩', '火锅江湖', 11, 'admin', 11, '🥘', '凯里红酸汤发酵香浓，江团鱼片薄，蘸上折耳根蘸水特别提味。周末人多，最好提前打个电话。', 4.1, 7, 88, 83, 138.00, 0, 'approved', '老城区', '2026-05-04 16:26:34');
INSERT INTO `post` VALUES (167, '鸡胸肉沙拉，低脂高蛋白，酱汁另装', '轻食沙拉', 13, 'test', 24, '🥙', '鸡胸煎到微焦，配生菜、圣女果、玉米粒，油醋汁清爽。性价比不错，人均不贵，适合日常。', 3.9, 12, 32, 17, 32.00, 0, 'approved', '三里屯', '2026-07-23 16:26:34');
INSERT INTO `post` VALUES (168, '日式咖喱饭，浓稠微甜，配炸猪排', '日料局', 15, '哈哈哈', 31, '🍤', '咖喱块熬到浓稠，加土豆胡萝卜，配一块炸猪排。老板人很客气，会主动问口味轻重。', 4.3, 11, 35, 48, 46.00, 0, 'approved', '南锣鼓巷', '2026-06-06 16:26:34');
INSERT INTO `post` VALUES (169, '贵阳肠旺面，红油配脆哨，够江湖', '面食控', 10, 'admin', 2, '🍝', '汤头红亮，血旺嫩、脆哨香，面条鸡蛋加碱，弹牙爽口。分量扎实，两个人点一份也够。', 3.8, 5, 37, 12, 24.00, 0, 'approved', '大学城', '2026-10-17 16:26:34');
INSERT INTO `post` VALUES (170, '烤五花肉，厚切带皮，脆到出声', '烧烤夜宵', 12, 'test', 15, '🍂', '带皮五花烤到金黄，肥肉透明不腻，包生菜蘸酱。性价比不错，人均不贵，适合日常。', 4.8, 11, 20, 77, 48.00, 0, 'approved', '科技园', '2026-04-29 16:26:34');
INSERT INTO `post` VALUES (171, '豆腐蔬菜煲，素食者也能吃饱', '轻食沙拉', 13, '哈哈哈', 22, '🥗', '嫩豆腐配香菇、娃娃菜和豆皮，清汤煮，鲜甜。周末人多，最好提前打个电话。', 4.1, 3, 80, 34, 30.00, 0, 'approved', '滨江道', '2026-06-03 16:26:34');
INSERT INTO `post` VALUES (172, '金枪鱼玉米沙拉，罐头金枪鱼也香', '轻食沙拉', 13, 'admin', 23, '🥑', '金枪鱼拌沙拉酱，玉米粒甜，夹在生菜里吃。环境干净，出餐速度还行。', 4.7, 12, 12, 34, 30.00, 0, 'approved', '万象城', '2026-05-12 16:26:34');
INSERT INTO `post` VALUES (173, '薯格，边角酥脆，孩子最爱', '汉堡炸鸡', 14, 'test', 30, '🍗', '土豆切格状炸，面积大更脆，撒海苔盐。性价比不错，人均不贵，适合日常。', 4.5, 8, 57, 61, 16.00, 0, 'approved', '五道口', '2026-06-07 16:26:34');
INSERT INTO `post` VALUES (174, '生椰拿铁，椰香配咖啡，很上头', '咖啡馆', 17, '哈哈哈', 43, '☕', '生椰乳浓稠，甜度可调，冰饮最爽。周末人多，最好提前打个电话。', 4.7, 9, 19, 17, 28.00, 0, 'approved', '老城区', '2026-08-16 16:26:34');
INSERT INTO `post` VALUES (175, '烤生蚝，蒜蓉铺满，一口爆汁', '烧烤夜宵', 12, 'admin', 14, '🍢', '蚝肉肥美，蒜蓉加粉丝和小米辣，烤到边缘微焦最香。性价比不错，人均不贵，适合日常。', 4.0, 0, 45, 27, 60.00, 0, 'approved', '三里屯', '2026-09-23 16:26:34');
INSERT INTO `post` VALUES (176, '海盐芝士咖啡，咸甜平衡，奶盖厚', '咖啡馆', 17, 'test', 45, '🥤', '芝士奶盖咸香，咖啡底微苦，不搅拌更好喝。老板人很客气，会主动问口味轻重。', 4.9, 7, 25, 22, 34.00, 0, 'approved', '南锣鼓巷', '2026-09-22 16:26:34');
INSERT INTO `post` VALUES (177, '河南烩面，羊汤浓白，面片宽厚', '面食控', 10, '哈哈哈', 4, '🥟', '羊骨熬足八小时的奶白汤，配海带丝、豆腐皮、粉丝，一碗下去浑身暖。老板人很客气，会主动问口味轻重。', 4.0, 5, 65, 38, 30.00, 0, 'approved', '大学城', '2026-08-08 16:26:34');
INSERT INTO `post` VALUES (178, '云南菌子火锅，一锅山珍，汤鲜到掉眉', '火锅江湖', 11, 'admin', 11, '🍲', '鸡枞、牛肝菌、松茸下土鸡汤，煮开后汤色金黄，鲜得有层次。老板人很客气，会主动问口味轻重。', 4.0, 4, 24, 56, 188.00, 0, 'approved', '科技园', '2026-05-24 16:26:34');
INSERT INTO `post` VALUES (179, '南瓜浓汤配全麦面包，暖胃又低卡', '轻食沙拉', 13, 'test', 24, '🥑', '南瓜和土豆熬成糊，加一点淡奶油，配烤过的全麦片。性价比不错，人均不贵，适合日常。', 4.4, 2, 71, 62, 26.00, 0, 'approved', '滨江道', '2026-08-11 16:26:34');
INSERT INTO `post` VALUES (180, '照烧鸡胸藜麦饭，减脂期也不难吃', '轻食沙拉', 13, '哈哈哈', 19, '🥑', '照烧汁刷薄薄一层，配藜麦和西兰花，咸甜刚好。分量扎实，两个人点一份也够。', 4.5, 12, 52, 72, 36.00, 0, 'approved', '万象城', '2026-09-17 16:26:34');
INSERT INTO `post` VALUES (181, '东北铁锅炖，大鹅贴饼子，越炖越香', '火锅江湖', 11, 'admin', 8, '🍲', '铁锅里大鹅炖到软烂，锅边贴玉米饼子吸汁，酸菜解腻。环境干净，出餐速度还行。', 3.8, 7, 90, 40, 148.00, 0, 'approved', '五道口', '2026-07-07 16:26:34');
INSERT INTO `post` VALUES (182, '海鲜丼，一碗十种海鲜', '日料局', 15, 'test', 33, '🍱', '金枪鱼、三文鱼、甜虾、海胆、鱼籽铺满，酱油淋一圈。环境干净，出餐速度还行。', 4.6, 12, 65, 17, 98.00, 0, 'approved', '老城区', '2026-06-04 16:26:34');
INSERT INTO `post` VALUES (183, '茶碗蒸，蛋羹滑到颤抖', '日料局', 15, '哈哈哈', 34, '🍤', '蛋液与高汤按比例调，加虾仁和香菇，蒸到镜面光滑。性价比不错，人均不贵，适合日常。', 4.4, 9, 19, 59, 22.00, 0, 'approved', '三里屯', '2026-04-12 16:26:34');
INSERT INTO `post` VALUES (184, '烤脑花，川渝夜宵的狠角色', '烧烤夜宵', 12, 'admin', 17, '🍢', '脑花用锡纸盒装，红油、花椒、葱花，滑嫩无腥。分量扎实，两个人点一份也够。', 4.7, 1, 94, 52, 38.00, 0, 'approved', '南锣鼓巷', '2026-07-20 16:26:34');
INSERT INTO `post` VALUES (185, '武汉热干面，芝麻酱拌到每根都裹上', '面食控', 10, 'test', 6, '🥟', '碱水面过水后拌上浓稠芝麻酱，加酸豆角、萝卜丁和解腻的葱花，干香浓郁。店不大，饭点要等位，建议早点去。', 3.8, 9, 14, 49, 18.00, 0, 'approved', '大学城', '2026-09-17 16:26:34');
INSERT INTO `post` VALUES (186, '薯条加芝士酱，粗切现炸，拉丝', '汉堡炸鸡', 14, '哈哈哈', 25, '🍗', '薯条外脆内绵，淋上融化芝士酱，罪恶但满足。性价比不错，人均不贵，适合日常。', 4.8, 6, 49, 56, 22.00, 0, 'approved', '科技园', '2026-09-15 16:26:34');
INSERT INTO `post` VALUES (187, '寿司拼盘，十贯，师傅现握', '日料局', 15, 'admin', 32, '🍱', '醋饭温度刚好，鱼生新鲜，山葵抹在鱼与饭之间。环境干净，出餐速度还行。', 4.7, 2, 33, 37, 108.00, 1, 'approved', '滨江道', '2026-07-26 16:26:34');
INSERT INTO `post` VALUES (188, '广东云吞面，竹升面弹到能跳', '面食控', 10, 'test', 3, '🥟', '全蛋竹升面爽脆，云吞里有整只鲜虾，清汤撒韭黄，鲜得很干净。店不大，饭点要等位，建议早点去。', 4.8, 10, 66, 49, 25.00, 0, 'approved', '万象城', '2026-10-11 16:26:34');
INSERT INTO `post` VALUES (189, '舒芙蕾松饼，抖三抖的松软', '甜品时间', 16, '哈哈哈', 40, '🍮', '现做现上，蛋香浓，淋枫糖浆加一球冰淇淋。周末人多，最好提前打个电话。', 4.1, 10, 95, 53, 44.00, 0, 'approved', '五道口', '2026-10-18 16:26:34');
INSERT INTO `post` VALUES (190, '腊排骨火锅，丽江风味，咸香耐煮', '火锅江湖', 11, 'admin', 11, '🍲', '腊排骨提前泡发，汤里加土豆和豆皮，越煮越出味。店不大，饭点要等位，建议早点去。', 4.8, 3, 75, 34, 118.00, 0, 'approved', '老城区', '2026-04-14 16:26:34');
INSERT INTO `post` VALUES (191, '寿喜烧，甜咸酱汁，牛肉裹蛋液', '火锅江湖', 11, 'test', 12, '🌶️', '酱汁偏甜，肥牛涮几秒起锅蘸生蛋液，滑嫩解腻。老板人很客气，会主动问口味轻重。', 4.3, 10, 72, 35, 118.00, 0, 'approved', '三里屯', '2026-05-10 16:26:34');
INSERT INTO `post` VALUES (192, '三文鱼刺身，厚切带油脂线', '日料局', 15, '哈哈哈', 31, '🍙', '鱼片厚实，油脂分布漂亮，蘸山葵酱油，入口化开。店不大，饭点要等位，建议早点去。', 4.7, 2, 65, 76, 88.00, 0, 'approved', '南锣鼓巷', '2026-05-14 16:26:34');
INSERT INTO `post` VALUES (193, '冷萃咖啡，慢萃十二小时', '咖啡馆', 17, 'admin', 44, '🥤', '口感柔和不酸，冰镇后带一点酒香。性价比不错，人均不贵，适合日常。', 4.2, 8, 44, 15, 34.00, 0, 'approved', '大学城', '2026-05-08 16:26:34');
INSERT INTO `post` VALUES (194, '蘑菇芝士堡，素食友好的选择', '汉堡炸鸡', 14, 'test', 27, '🍔', '大蘑菇烤出汁水当肉饼，配芝士和番茄，鲜味足。店不大，饭点要等位，建议早点去。', 4.4, 0, 64, 76, 34.00, 0, 'approved', '科技园', '2026-06-10 16:26:34');
INSERT INTO `post` VALUES (195, '猪肚鸡火锅，胡椒味冲，汤白如奶', '火锅江湖', 11, '哈哈哈', 10, '🍲', '猪肚脆、鸡肉滑，白胡椒暖胃，先喝汤再涮菜。老板人很客气，会主动问口味轻重。', 4.5, 7, 69, 25, 108.00, 0, 'approved', '滨江道', '2026-09-07 16:26:34');
INSERT INTO `post` VALUES (196, '螺蛳粉，酸笋臭得地道', '面食控', 10, 'test', 5, '🍜', '汤底用螺蛳和田螺熬，酸笋够冲，加腐竹、木耳和花生，辣度可调。吃完一身味但很值。', 4.6, 8, 72, 66, 28.00, 0, 'approved', '大学城', '2026-10-04 16:26:47');
INSERT INTO `post` VALUES (197, '冬阴功汤河粉', '面食控', 10, 'admin', 6, '🍤', '酸辣汤头带香茅和柠檬叶的香气，河粉滑，配虾仁和草菇，开胃。', 4.3, 4, 41, 38, 32.00, 0, 'approved', '万象城', '2026-09-09 16:26:47');
INSERT INTO `post` VALUES (198, '潮汕蚝烙，边缘焦脆', '烧烤夜宵', 12, '哈哈哈', 13, '🍳', '生蚝加番薯粉煎到边缘焦脆，中间软嫩，蘸鱼露或甜辣酱都好吃。', 4.4, 2, 35, 29, 42.00, 0, 'approved', '滨江道', '2026-10-25 16:26:47');
INSERT INTO `post` VALUES (199, '抹茶生巧塔', '甜品时间', 16, 'test', 38, '🍫', '塔皮酥，抹茶生巧微苦回甘，冷藏后切面整齐，配无糖茶刚好。', 4.7, 5, 58, 44, 36.00, 0, 'approved', '三里屯', '2026-10-30 16:26:47');
INSERT INTO `post` VALUES (200, '花生汤配油条', '甜品时间', 16, 'admin', 39, '🥣', '花生煮到软糯起沙，汤色乳白微甜，油条现炸蘸着吃，早餐常见。', 4.1, 1, 26, 31, 15.00, 0, 'approved', '老城区', '2026-08-07 16:26:47');

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
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '美食点评表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of review
-- ----------------------------
INSERT INTO `review` VALUES (1, 1, 'test', 5, '汤头确实香，面也好吃，会再去。', '2026-11-01 13:00:00');
INSERT INTO `review` VALUES (2, 1, 'admin', 5, '牛肉份量足，性价比高。', '2026-11-01 19:30:00');
INSERT INTO `review` VALUES (3, 2, 'admin', 4, '红油很香，抄手皮薄，下次试试干拌。', '2026-10-31 20:00:00');
INSERT INTO `review` VALUES (4, 3, 'test', 5, '毛肚真的脆，锅底够味！', '2026-10-30 21:10:00');

-- ----------------------------
-- Table structure for shop
-- ----------------------------
DROP TABLE IF EXISTS `shop`;
CREATE TABLE `shop`  (
  `shop_id` bigint NOT NULL AUTO_INCREMENT COMMENT '店铺ID',
  `owner_id` bigint NOT NULL COMMENT '店主用户ID，关联 user.id',
  `shop_name` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '店铺名称（店家可自定义修改）',
  `emoji` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT '?' COMMENT '店铺图标',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '店铺简介',
  `district` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '所在商圈',
  `phone` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '联系电话',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'active' COMMENT '状态：active=营业中 closed=休息',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
  PRIMARY KEY (`shop_id`) USING BTREE,
  UNIQUE INDEX `uk_shop_owner`(`owner_id` ASC) USING BTREE,
  UNIQUE INDEX `uk_shop_name`(`shop_name` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 49 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '店铺信息表（店家可自定义店铺名称）' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of shop
-- ----------------------------
INSERT INTO `shop` VALUES (1, 9, '老张牛肉面', '🍜', '三十年老汤牛肉面，手工拉面现煮', '老城区', '400-1001-001', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (2, 10, '兰州拉面·马师傅', '🍲', '一清二白三红四绿，汤头清亮', '科技园', '400-1002-002', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (3, 11, '晋味刀削面', '🥢', '刀削面配陈醋辣油，面片厚实', '五道口', '400-1003-003', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (4, 12, '苏式汤面馆', '🍥', '红汤白汤都有，浇头现炒', '万象城', '400-1004-004', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (5, 13, '川渝小面研究所', '🌶️', '重庆小面，麻辣鲜香可调辣度', '大学城', '400-1005-005', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (6, 14, '馄饨与烧麦', '🥟', '现包小馄饨，皮薄馅大', '南锣鼓巷', '400-1006-006', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (7, 15, '川味老灶火锅', '🔥', '牛油老灶锅底，越煮越香', '三里屯', '400-1007-007', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (8, 16, '潮汕牛肉火锅', '🐂', '当日现宰黄牛肉，八秒即涮', '滨江道', '400-1008-008', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (9, 17, '椰子鸡小馆', '🥥', '文昌鸡配椰青锅底，清甜', '万象城', '400-1009-009', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (10, 18, '番茄鱼火锅', '🍅', '番茄酸汤配黑鱼片，先喝汤', '大学城', '400-1010-010', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (11, 19, '毛肚江湖', '🍲', '鲜毛肚七上八下，脆得响', '老城区', '400-1011-011', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (12, 20, '九宫格老火锅', '🔥', '九宫格分格煮，麻辣层次分明', '科技园', '400-1012-012', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (13, 21, '炭火小串', '🍢', '铁签小串炭火慢烤，孜然给足', '三里屯', '400-1013-013', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (14, 22, '夜市烤生蚝', '🦪', '蒜蓉粉丝烤生蚝，个头实在', '滨江道', '400-1014-014', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (15, 23, '东北烧烤大排档', '🍻', '烤串配冰啤，量大管饱', '五道口', '400-1015-015', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (16, 24, '新疆羊肉串', '🐑', '现串羊腿肉，肥瘦相间', '南锣鼓巷', '400-1016-016', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (17, 25, '深夜卤味铺', '🍗', '卤鸭脖卤豆干，越嚼越香', '老城区', '400-1017-017', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (18, 26, '铁板鱿鱼小站', '🦑', '铁板压鱿鱼，刷甜辣酱', '大学城', '400-1018-018', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (19, 27, '绿野轻食', '🥗', '每日现洗鲜蔬，酱汁自选', '科技园', '400-1019-019', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (20, 28, '牛油果厨房', '🥑', '牛油果配溏心蛋，饱腹不腻', '三里屯', '400-1020-020', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (21, 29, '鸡胸肉研究所', '🍗', '低温慢煮鸡胸，嫩而不柴', '万象城', '400-1021-021', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (22, 30, '藜麦时光', '🌾', '藜麦谷物碗，粗粮打底', '大学城', '400-1022-022', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (23, 31, '低卡食堂', '🥬', '每份标注热量，控卡友好', '五道口', '400-1023-023', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (24, 32, '蔬果鲜配', '🍏', '现切果蔬盒，办公室加餐', '滨江道', '400-1024-024', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (25, 33, '双层牛肉汉堡屋', '🍔', '现烤双层牛肉饼，芝士拉丝', '三里屯', '400-1025-025', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (26, 34, '脆皮炸鸡铺', '🍗', '现炸脆皮鸡，皮脆肉多汁', '老城区', '400-1026-026', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (27, 35, '热狗与薯条', '🌭', '德式香肠热狗，粗薯现炸', '五道口', '400-1027-027', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (28, 36, '芝士汉堡工坊', '🧀', '现刨芝士，汉堡现做现出', '万象城', '400-1028-028', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (29, 37, '手作汉堡实验室', '🍔', '自制面包胚，酱料可换', '大学城', '400-1029-029', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (30, 38, '韩式炸鸡吧', '🍗', '甜辣酱炸鸡配腌萝卜', '滨江道', '400-1030-030', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (31, 39, '築地寿司', '🍣', '每日空运鱼生，醋饭温热', '三里屯', '400-1031-031', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (32, 40, '居酒屋小町', '🏮', '炭烤鸡皮和清酒，深夜营业', '南锣鼓巷', '400-1032-032', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (33, 41, '天妇罗专门店', '🍤', '面衣薄脆，油温精准', '万象城', '400-1033-033', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (34, 42, '鳗鱼饭本铺', '🍱', '现烤鳗鱼刷三次酱汁', '滨江道', '400-1034-034', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (35, 43, '清酒与刺身', '🐟', '厚切刺身拼盘，配纯米吟酿', '科技园', '400-1035-035', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (36, 44, '御好烧小屋', '🥞', '铁板现煎，酱料和美乃滋', '大学城', '400-1036-036', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (37, 45, '抹茶甜品社', '🍵', '宇治抹茶现打，微苦回甘', '三里屯', '400-1037-037', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (38, 46, '法式甜点坊', '🍰', '可颂和慕斯当日现做', '万象城', '400-1038-038', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (39, 47, '双皮奶老铺', '🥛', '水牛奶双皮奶，奶皮厚', '老城区', '400-1039-039', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (40, 48, '芋圆糖水铺', '🍠', '手搓芋圆配红豆沙', '大学城', '400-1040-040', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (41, 49, '冰淇淋研究所', '🍦', '低糖手工冰淇淋，口味常换', '五道口', '400-1041-041', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (42, 50, '舒芙蕾小屋', '🥞', '现烤舒芙蕾，出炉即食', '滨江道', '400-1042-042', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (43, 51, '山里咖啡', '☕', '自家烘焙豆，手冲为主', '南锣鼓巷', '400-1043-043', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (44, 52, '豆子与手冲', '🫘', '单品豆单每周更新', '科技园', '400-1044-044', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (45, 53, '社区咖啡角', '☕', '楼下小店，拿铁扎实', '老城区', '400-1045-045', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (46, 54, '拉花实验室', '🥛', '拉花好看，奶泡细腻', '三里屯', '400-1046-046', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (47, 55, '老房子咖啡馆', '🏠', '院子里的老房子，安静', '五道口', '400-1047-047', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');
INSERT INTO `shop` VALUES (48, 56, '冷萃事务所', '🧊', '冷萃和白日梦，冰滴现出', '万象城', '400-1048-048', 'active', '2026-11-06 16:34:57', '2026-11-06 16:34:57');

-- ----------------------------
-- Table structure for tag
-- ----------------------------
DROP TABLE IF EXISTS `tag`;
CREATE TABLE `tag`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '标签ID',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '标签名称',
  `heat` int NOT NULL DEFAULT 0 COMMENT '热度',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_tag_name`(`name` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '热门标签表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of tag
-- ----------------------------
INSERT INTO `tag` VALUES (1, '一人食', 128);
INSERT INTO `tag` VALUES (2, '深夜食堂', 96);
INSERT INTO `tag` VALUES (3, '学生党', 143);
INSERT INTO `tag` VALUES (4, '高性价比', 211);
INSERT INTO `tag` VALUES (5, '拍照好看', 87);
INSERT INTO `tag` VALUES (6, '碳水快乐', 175);
INSERT INTO `tag` VALUES (7, '减脂餐', 64);
INSERT INTO `tag` VALUES (8, '隐藏小店', 132);

-- ----------------------------
-- Table structure for user
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '用户名',
  `password_hash` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '密码哈希(BCrypt)',
  `role` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'user' COMMENT '角色：user=普通用户 admin=管理员',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'active' COMMENT '账号状态：active=正常 disabled=禁用',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_username`(`username` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 57 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of user
-- ----------------------------
INSERT INTO `user` VALUES (4, 'admin', '$2a$10$bw2vRfpxf7FPSKoI977KPO4vMRDDHcO/G6OOLxECqQF2yFt4b36se', 'admin', 'active', '2026-11-02 10:49:08');
INSERT INTO `user` VALUES (5, 'test', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-02 10:49:08');
INSERT INTO `user` VALUES (8, '哈哈哈', '$2a$10$Hc76SRxcm/xCAyFCkIUelO1x.JkWAaxqpPb3v7O.jz0w9mMUSUn0u', 'user', 'active', '2026-11-02 11:01:13');
INSERT INTO `user` VALUES (9, 'shop01', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (10, 'shop02', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (11, 'shop03', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (12, 'shop04', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (13, 'shop05', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (14, 'shop06', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (15, 'shop07', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (16, 'shop08', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (17, 'shop09', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (18, 'shop10', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (19, 'shop11', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (20, 'shop12', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (21, 'shop13', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (22, 'shop14', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (23, 'shop15', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (24, 'shop16', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (25, 'shop17', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (26, 'shop18', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (27, 'shop19', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (28, 'shop20', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (29, 'shop21', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (30, 'shop22', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (31, 'shop23', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (32, 'shop24', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (33, 'shop25', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (34, 'shop26', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (35, 'shop27', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (36, 'shop28', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (37, 'shop29', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (38, 'shop30', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (39, 'shop31', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (40, 'shop32', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (41, 'shop33', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (42, 'shop34', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (43, 'shop35', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (44, 'shop36', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (45, 'shop37', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (46, 'shop38', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (47, 'shop39', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (48, 'shop40', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (49, 'shop41', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (50, 'shop42', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (51, 'shop43', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (52, 'shop44', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (53, 'shop45', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (54, 'shop46', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (55, 'shop47', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');
INSERT INTO `user` VALUES (56, 'shop48', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-06 16:34:57');

SET FOREIGN_KEY_CHECKS = 1;
