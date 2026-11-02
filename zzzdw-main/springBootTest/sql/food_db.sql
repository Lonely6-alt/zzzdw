/*
 Navicat Premium Dump SQL

 Source Server         : localhost_3306
 Source Server Type    : MySQL
 Source Server Version : 80039 (8.0.39)
 Source Host           : localhost:3306
 Source Schema         : food_db

 Target Server Type    : MySQL
 Target Server Version : 80039 (8.0.39)
 File Encoding         : 65001

 Date: 02/11/2026 11:51:31
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
  INDEX `idx_created`(`created_at` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 51 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '美食帖子表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of post
-- ----------------------------
INSERT INTO `post` VALUES (1, '巷子里那碗牛肉面，汤头熬了六小时', '面食控', 10, 'admin', '🍜', '牛肉给得很实在，汤是清亮的琥珀色，喝一口有股淡淡的药膳香。面条偏细，泡久了也不坨，冬天来一碗整个人都活了。', 5.0, 2, 36, 58, 26.00, 1, 'approved', '老城区', '2026-11-01 12:20:00');
INSERT INTO `post` VALUES (2, '红油抄手配小酥肉，辣得刚刚好', '面食控', 10, 'test', '🥟', '红油香而不燥，抄手皮薄馅大。小酥肉现炸的，外脆里嫩，撒了花椒面，一口一个停不下来。', 4.0, 1, 21, 34, 32.00, 0, 'approved', '大学城', '2026-10-31 18:40:00');
INSERT INTO `post` VALUES (3, '九宫格牛油锅，毛肚七上八下', '火锅江湖', 11, 'admin', '🍲', '锅底牛油味很足，微辣对大多数人刚好。毛肚脆，鸭肠爽，最后煮一份宽粉收尾，幸福感直接拉满。', 5.0, 1, 64, 92, 88.00, 1, 'approved', '万象城', '2026-10-30 20:10:00');
INSERT INTO `post` VALUES (4, '学校门口的烤串摊，五块钱三串', '烧烤夜宵', 12, 'test', '🍢', '老板撒料手很稳，羊肉串带点焦边最香。夜里十点去还排队，建议避开高峰，或者干脆多等十分钟。', 4.4, 0, 18, 47, 15.00, 0, 'approved', '三里屯', '2026-10-29 22:30:00');
INSERT INTO `post` VALUES (5, '鸡胸肉沙拉也能很好吃，关键在酱', '轻食沙拉', 13, 'test', '🥗', '鸡胸是低温慢煮的，一点都不柴。油醋汁是自己调的，酸度刚好，配上牛油果和烤南瓜，减脂期也能吃得很开心。', 4.5, 0, 29, 22, 28.00, 0, 'approved', '科技园', '2026-10-28 12:05:00');
INSERT INTO `post` VALUES (6, '双层芝士汉堡，酱汁会流下来', '汉堡炸鸡', 14, 'admin', '🍔', '面包是现烤的，边缘微脆。牛肉饼厚实有肉汁，芝士融化得彻底。薯条换成了粗切的，蘸蜂蜜芥末很好吃。', 4.7, 0, 41, 66, 39.00, 0, 'approved', '五道口', '2026-10-27 19:15:00');
INSERT INTO `post` VALUES (7, '这家炸鸡的脆皮值得专门跑一趟', '汉堡炸鸡', 14, 'test', '🍗', '外壳是真的脆，咬下去能听到声音。腌得透，肉不干。建议点半半口味，原味和甜辣各一半。', 4.6, 0, 33, 51, 45.00, 0, 'approved', '大学城', '2026-10-26 20:00:00');
INSERT INTO `post` VALUES (8, '人均六十的日料，刺身很新鲜', '日料局', 15, 'admin', '🍣', '三文鱼切得厚，油脂线漂亮。鳗鱼饭酱汁偏甜但很下饭。店里位置不多，最好提前订。', 4.5, 0, 27, 19, 62.00, 0, 'approved', '三里屯', '2026-10-25 18:30:00');
INSERT INTO `post` VALUES (9, '深夜拉面，溏心蛋是灵魂', '日料局', 15, 'test', '🍥', '豚骨汤浓但不腻，面偏硬刚好。叉烧炙过，有焦香。加一份溏心蛋，蛋黄流进汤里，值了。', 4.7, 0, 38, 44, 42.00, 0, 'approved', '南锣鼓巷', '2026-10-24 23:10:00');
INSERT INTO `post` VALUES (10, '手冲耶加雪菲，柑橘味很明亮', '咖啡馆', 17, 'admin', '☕', '浅烘豆子，入口是柑橘和一点花香，回甘干净。店里安静，适合带电脑坐一下午。', 4.8, 0, 52, 31, 32.00, 0, 'approved', '五道口', '2026-10-23 15:20:00');
INSERT INTO `post` VALUES (11, '巴斯克芝士蛋糕，焦皮是关键', '甜品时间', 16, 'test', '🍰', '中心是流心的，冷藏后更扎实。焦皮带一点微苦，正好压住甜度。配黑咖啡绝了。', 4.9, 0, 71, 39, 28.00, 0, 'approved', '滨江道', '2026-10-22 16:45:00');
INSERT INTO `post` VALUES (12, '杨枝甘露，芒果给得毫不吝啬', '甜品时间', 16, 'admin', '🥭', '芒果是大块果肉，西米煮得刚好不糊。甜度可以选，我选了少糖，更清爽。夏天来一杯很解腻。', 4.6, 0, 24, 28, 18.00, 0, 'approved', '老城区', '2026-10-21 14:00:00');
INSERT INTO `post` VALUES (13, '招牌炸酱面，酱是自家熬的', '面食控', 10, 'admin', '🍜', '面码给得足，黄瓜丝、豆芽、心里美萝卜堆成小山。炸酱用肥瘦相间的肉丁，咸甜口，拌开每根面都挂汁。', 3.9, 0, 20, 10, 18.00, 1, 'approved', '老城区', '2026-09-05 00:00:00');
INSERT INTO `post` VALUES (14, '红汤酸辣粉，酸笋是灵魂', '面食控', 10, 'test', '🍜', '红薯粉Q弹，汤头又酸又辣还带点麻。酸笋给得多，嚼着脆，加个煎蛋更满足。', 4.6, 3, 33, 27, 29.00, 0, 'approved', '大学城', '2026-09-07 00:00:00');
INSERT INTO `post` VALUES (15, '小笼包现包现蒸，汤汁会烫嘴', '面食控', 10, 'admin', '🥟', '皮薄到能看见馅，咬开先吸汤，鲜得眉毛掉。蟹粉款更香，原味肉包已经够打。', 4.2, 6, 46, 44, 25.00, 0, 'approved', '万象城', '2026-09-09 00:00:00');
INSERT INTO `post` VALUES (16, '阳春面一碗，葱油香到隔壁桌', '面食控', 10, 'test', '🍜', '清汤挂面，全靠那勺熬到金黄的葱油。简简单单，吃完连汤都喝光。', 4.9, 0, 59, 61, 21.00, 0, 'approved', '三里屯', '2026-09-11 00:00:00');
INSERT INTO `post` VALUES (17, '担担面，麻辣里藏着花生香', '面食控', 10, 'admin', '🍜', '芝麻酱和红油调的底，肉臊子炒得干香。花生碎一撒，层次一下就上来了。', 4.5, 3, 72, 78, 32.00, 0, 'approved', '科技园', '2026-09-13 00:00:00');
INSERT INTO `post` VALUES (18, '凉皮筋道，油泼辣子现做的', '面食控', 10, 'test', '🍜', '面筋吸饱了料汁，凉皮透亮弹牙。辣子是温油泼的，香大于辣，夏天吃最爽。', 4.1, 6, 85, 10, 28.00, 0, 'approved', '五道口', '2026-09-15 00:00:00');
INSERT INTO `post` VALUES (19, '肥肠面，处理得一点不腥', '面食控', 10, '哈哈哈', '🍲', '肥肠洗得干净，炖到软糯入味。汤底浓白，配细面，一勺辣酱下去更带劲。', 4.8, 0, 28, 27, 24.00, 0, 'approved', '南锣鼓巷', '2026-09-17 00:00:00');
INSERT INTO `post` VALUES (20, '意式番茄肉丸面，酸甜开胃', '面食控', 10, 'test', '🍝', '肉丸手打，番茄熬出沙。面煮得偏硬，裹着酱汁，酸甜味很提神。', 4.4, 3, 41, 44, 20.00, 0, 'approved', '滨江道', '2026-09-19 00:00:00');
INSERT INTO `post` VALUES (21, '番茄锅底，喝汤比涮肉还香', '火锅江湖', 11, 'admin', '🍲', '番茄熬得浓稠，带点罗勒清香。先喝一碗汤，再下虾滑和牛肉，鲜上加鲜。', 4.0, 6, 54, 61, 87.00, 0, 'approved', '老城区', '2026-09-21 00:00:00');
INSERT INTO `post` VALUES (22, '猪肚鸡锅，胡椒香得很暖胃', '火锅江湖', 11, 'test', '🍲', '整鸡和猪肚慢炖，汤奶白。胡椒味足但不呛，天冷来一锅，从头暖到脚。', 4.7, 0, 67, 78, 98.00, 0, 'approved', '大学城', '2026-09-23 00:00:00');
INSERT INTO `post` VALUES (23, '麻辣牛油锅，鸭血嫩到入口化', '火锅江湖', 11, 'admin', '🌶', '牛油厚重，辣得绵长。鸭血和脑花必点，嫩得不用嚼，宽粉最后收尾。', 4.3, 3, 80, 10, 109.00, 0, 'approved', '万象城', '2026-09-25 00:00:00');
INSERT INTO `post` VALUES (24, '寿喜锅，牛肉裹蛋液绝了', '火锅江湖', 11, 'test', '🥗', '汤头偏甜，肥牛涮三秒就起。蘸生鸡蛋液，滑嫩还解腻，配乌冬刚好。', 3.9, 6, 23, 27, 120.00, 0, 'approved', '三里屯', '2026-09-27 00:00:00');
INSERT INTO `post` VALUES (25, '椰子鸡锅，清甜不腻很养生', '火锅江湖', 11, 'admin', '🥗', '文昌鸡配椰青水，汤清甜。蘸青柠酱油，鸡肉嫩，喝两碗汤整个人都轻了。', 4.6, 0, 36, 44, 70.00, 0, 'approved', '科技园', '2026-09-29 00:00:00');
INSERT INTO `post` VALUES (26, '烤茄子，蒜蓉多到看不见茄肉', '烧烤夜宵', 12, '哈哈哈', '🍂', '茄子烤到软糯，铺满金黄蒜蓉和剁椒。筷子一压就化，实打实的米饭杀手。', 4.2, 3, 49, 61, 34.00, 0, 'approved', '五道口', '2026-10-01 00:00:00');
INSERT INTO `post` VALUES (27, '烤生蚝，现开现烤汁水足', '烧烤夜宵', 12, 'admin', '🦪', '蚝肉饱满，烤到刚熟就上。蒜蓉粉丝垫底，一口爆汁，鲜味直冲。', 4.9, 6, 62, 78, 45.00, 0, 'approved', '南锣鼓巷', '2026-10-03 00:00:00');
INSERT INTO `post` VALUES (28, '羊肉串肥瘦相间，孜然给得狠', '烧烤夜宵', 12, 'test', '🍂', '炭火烤到边缘焦脆，肥肉化开。孜然辣椒面撒得足，香得路人都要回头。', 4.5, 0, 75, 10, 25.00, 1, 'approved', '滨江道', '2026-10-05 00:00:00');
INSERT INTO `post` VALUES (29, '烤面筋，刷酱是老板秘方', '烧烤夜宵', 12, 'admin', '🍡', '面筋烤得外焦里嫩，刷两层酱。辣中带甜，越嚼越香，一串接一串。', 4.1, 3, 88, 27, 36.00, 0, 'approved', '老城区', '2026-10-07 00:00:00');
INSERT INTO `post` VALUES (30, '烤鱿鱼须，弹牙又入味', '烧烤夜宵', 12, 'test', '🍂', '须子烤到卷边，刷甜辣酱。咬下去弹牙，蒜香和孜然混在一起，停不下来。', 4.8, 6, 31, 44, 16.00, 0, 'approved', '大学城', '2026-10-09 00:00:00');
INSERT INTO `post` VALUES (31, '牛油果鸡胸沙拉，酱是自己调的', '轻食沙拉', 13, 'admin', '🥗', '鸡胸低温慢煮不柴，牛油果给得大方。油醋汁加第戎芥末，酸度刚好。', 4.4, 0, 44, 61, 29.00, 0, 'approved', '万象城', '2026-10-11 00:00:00');
INSERT INTO `post` VALUES (32, '藜麦碗，饱腹感一整个下午', '轻食沙拉', 13, 'test', '🥗', '三色藜麦打底，配烤时蔬和鹰嘴豆。坚果碎提香，淋柠檬汁，清爽又有满足感。', 4.0, 3, 57, 78, 27.00, 0, 'approved', '三里屯', '2026-10-13 00:00:00');
INSERT INTO `post` VALUES (33, '凯撒沙拉，面包丁现烤的', '轻食沙拉', 13, '哈哈哈', '🥙', '罗马生菜脆，帕玛森刨得厚。面包丁现烤到酥，凯撒酱顺滑，简单但经典。', 4.7, 6, 70, 10, 38.00, 0, 'approved', '科技园', '2026-10-15 00:00:00');
INSERT INTO `post` VALUES (34, '羽衣甘蓝碗，坚果酱很惊喜', '轻食沙拉', 13, 'test', '🥗', '甘蓝撕小段揉过，软而不涩。配烤南瓜和腰果酱，咸甜交织，减脂也不委屈。', 4.3, 0, 83, 27, 36.00, 0, 'approved', '五道口', '2026-10-17 00:00:00');
INSERT INTO `post` VALUES (35, '安格斯牛肉堡，肉饼会爆汁', '汉堡炸鸡', 14, 'admin', '🍔', '牛肉饼厚切现煎，咬开汁水横流。车达芝士融化裹住，酸黄瓜解腻，扎实管饱。', 3.9, 3, 26, 44, 39.00, 0, 'approved', '南锣鼓巷', '2026-10-19 00:00:00');
INSERT INTO `post` VALUES (36, '辣炸鸡翅，外壳脆到能听见', '汉堡炸鸡', 14, 'test', '🍗', '双炸工艺，皮薄而脆。辣酱是韩式甜辣，肉嫩脱骨，纸巾要备一打。', 4.6, 6, 39, 61, 29.00, 0, 'approved', '滨江道', '2026-10-21 00:00:00');
INSERT INTO `post` VALUES (37, '芝士薯条，拉丝能拉半米', '汉堡炸鸡', 14, 'admin', '🍟', '粗切薯条现炸，铺满融化的芝士。趁热拌开，拉丝到手软，罪恶但快乐。', 4.2, 0, 52, 78, 40.00, 0, 'approved', '老城区', '2026-10-23 00:00:00');
INSERT INTO `post` VALUES (38, '鳕鱼堡，鱼肉嫩得不用嚼', '汉堡炸鸡', 14, 'test', '🍔', '鳕鱼柳炸到金黄，内里雪白。塔塔酱给得多，配酸菜，清爽不油腻。', 4.9, 3, 65, 10, 30.00, 0, 'approved', '大学城', '2026-10-25 00:00:00');
INSERT INTO `post` VALUES (39, '韩式炸鸡配啤酒，夜宵顶配', '汉堡炸鸡', 14, 'admin', '🍗', '炸鸡裹甜辣酱，撒花生碎。配冰啤，外脆里嫩，追剧宵夜首选。', 4.5, 6, 78, 27, 41.00, 0, 'approved', '万象城', '2026-10-27 00:00:00');
INSERT INTO `post` VALUES (40, '三文鱼刺身，油脂线漂亮', '日料局', 15, '哈哈哈', '🍣', '鱼腩部位，切得厚。入口即化，油脂香在舌尖化开。蘸一点酱油山葵，鲜味更突出。', 4.1, 0, 21, 44, 48.00, 0, 'approved', '三里屯', '2026-10-29 00:00:00');
INSERT INTO `post` VALUES (41, '鳗鱼饭，蒲烧酱汁偏甜', '日料局', 15, 'admin', '🍱', '鳗鱼现烤，皮脆肉糯。酱汁刷了三遍，甜咸适中，铺在热米饭上，连吃两碗。', 4.8, 3, 34, 61, 59.00, 1, 'approved', '科技园', '2026-10-31 00:00:00');
INSERT INTO `post` VALUES (42, '寿司卷，蟹柳和牛油果很搭', '日料局', 15, 'test', '🍙', '醋饭温度刚好，蟹柳蟹籽牛油果卷在一起。一口一个，米香和鲜味平衡得不错。', 4.4, 6, 47, 78, 70.00, 0, 'approved', '五道口', '2026-11-02 00:00:00');
INSERT INTO `post` VALUES (43, '天妇罗，面衣薄得透光', '日料局', 15, 'admin', '🍤', '虾和时蔬裹薄衣现炸，不挂油。蘸萝卜泥酱油，酥脆清润，吃得出食材本味。', 4.0, 0, 60, 10, 40.00, 0, 'approved', '南锣鼓巷', '2026-11-04 00:00:00');
INSERT INTO `post` VALUES (44, '味噌拉面，汤浓面硬刚刚好', '日料局', 15, 'test', '🍥', '味噌汤底醇厚，叉烧厚切。面偏硬有嚼劲，加玉米和笋干，暖心暖胃。', 4.7, 3, 73, 27, 51.00, 0, 'approved', '滨江道', '2026-11-06 00:00:00');
INSERT INTO `post` VALUES (45, '舒芙蕾松饼，现烤要等十五分', '甜品时间', 16, 'admin', '🥞', '端上来还在颤，切开像云朵。枫糖和奶油给得足，趁热吃，幸福感爆棚。', 4.3, 6, 86, 44, 28.00, 0, 'approved', '老城区', '2026-11-08 00:00:00');
INSERT INTO `post` VALUES (46, '抹茶千层，茶味浓到微苦', '甜品时间', 16, 'test', '🍰', '可丽饼皮薄如纸，奶油里混了真抹茶。微苦压住甜，一口一层，越吃越上头。', 3.9, 0, 29, 61, 20.00, 0, 'approved', '大学城', '2026-11-10 00:00:00');
INSERT INTO `post` VALUES (47, '提拉米苏，酒香藏在手指饼里', '甜品时间', 16, '哈哈哈', '🍮', '马斯卡彭顺滑，可可粉不苦。手指饼浸了咖啡酒，挖一勺，层次慢慢化开。', 4.6, 3, 42, 78, 31.00, 0, 'approved', '万象城', '2026-11-12 00:00:00');
INSERT INTO `post` VALUES (48, '芒果班戟，皮薄馅大', '甜品时间', 16, 'test', '🥧', '班戟皮软糯，包着整块芒果和淡奶油。咬下去果肉爆汁，甜而不腻，夏天必点。', 4.2, 6, 55, 10, 23.00, 0, 'approved', '三里屯', '2026-11-14 00:00:00');
INSERT INTO `post` VALUES (49, '燕麦拿铁，奶香盖过咖啡苦', '咖啡馆', 17, 'admin', '☕', '燕麦奶打发出绵密泡，和浓缩融合得顺。温润不刺激，乳糖不耐也能喝得很开心。', 4.9, 0, 68, 27, 28.00, 0, 'approved', '科技园', '2026-11-16 00:00:00');
INSERT INTO `post` VALUES (50, '脏脏咖啡，可可粉撒满杯沿', '咖啡馆', 17, 'test', '☕', '冰美式上淋厚奶，喝前搅匀。可可粉带微苦，冰凉爽口，外观也出片。', 4.5, 3, 81, 44, 24.00, 0, 'approved', '五道口', '2026-11-18 00:00:00');

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
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of user
-- ----------------------------
INSERT INTO `user` VALUES (4, 'admin', '$2a$10$bw2vRfpxf7FPSKoI977KPO4vMRDDHcO/G6OOLxECqQF2yFt4b36se', 'admin', 'active', '2026-11-02 10:49:08');
INSERT INTO `user` VALUES (5, 'test', '$2a$10$Ssk/7juLfC0d4eJUh1gaiuUDp.OhTpmpE2WHi5xvm9SnsNJoskG0m', 'user', 'active', '2026-11-02 10:49:08');
INSERT INTO `user` VALUES (8, '哈哈哈', '$2a$10$Hc76SRxcm/xCAyFCkIUelO1x.JkWAaxqpPb3v7O.jz0w9mMUSUn0u', 'user', 'active', '2026-11-02 11:01:13');

SET FOREIGN_KEY_CHECKS = 1;
