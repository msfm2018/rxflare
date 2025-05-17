/*
 Navicat Premium Data Transfer

 Source Server         : test
 Source Server Type    : MySQL
 Source Server Version : 90200 (9.2.0)
 Source Host           : localhost:3306
 Source Schema         : xiyi

 Target Server Type    : MySQL
 Target Server Version : 90200 (9.2.0)
 File Encoding         : 65001

 Date: 17/05/2025 12:32:54
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for info
-- ----------------------------
DROP TABLE IF EXISTS `info`;
CREATE TABLE `info`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `xm` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `age` int NULL DEFAULT NULL,
  `phone` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `birthday` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `cardid` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of info
-- ----------------------------
INSERT INTO `info` VALUES (1, '张三', 21, '138000000', '2000/4/5', '110119118117221');
INSERT INTO `info` VALUES (2, '李四', 90, '13900000000', '2025/9/2', '119119118228112');
INSERT INTO `info` VALUES (3, '王二麻子', 45, '13200000000', '2022/2/2', '119808678903');

-- ----------------------------
-- Table structure for yifu
-- ----------------------------
DROP TABLE IF EXISTS `yifu`;
CREATE TABLE `yifu`  (
  `id` int NOT NULL AUTO_INCREMENT,
  `pdid` int NULL DEFAULT NULL,
  `count` int NULL DEFAULT NULL,
  `payed` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `price` decimal(10, 2) NULL DEFAULT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `phone` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `cardname` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `cardid` int NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of yifu
-- ----------------------------
INSERT INTO `yifu` VALUES (1, 21736, 2, '未付', 165.00, '李艾想', '138000000', '七折卡', 80203);
INSERT INTO `yifu` VALUES (2, 21735, 9, '刷卡', 200.00, '王女士', '1390000000', '八折卡', 80922);

-- ----------------------------
-- Table structure for yifudetail
-- ----------------------------
DROP TABLE IF EXISTS `yifudetail`;
CREATE TABLE `yifudetail`  (
  `id` int NULL DEFAULT NULL,
  `server` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `color` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `guayihao` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `region` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `条码号` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `memo` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `pdid` int NULL DEFAULT NULL
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of yifudetail
-- ----------------------------
INSERT INTO `yifudetail` VALUES (1, '普洗', '羽绒马甲', '浅色', '453', '输送', '248173', '油渍划伤', 21736);
INSERT INTO `yifudetail` VALUES (2, '精洗', '羽绒上衣', '黑色', '445', '输送线', '248174', '油渍', 21736);
INSERT INTO `yifudetail` VALUES (1, '精洗', '背心', '红色', '445', '输送线', '248175', '油渍', 21735);
INSERT INTO `yifudetail` VALUES (2, '精洗', '裤子', '黑色', '445', '输送线', '248176', '油渍', 21735);

SET FOREIGN_KEY_CHECKS = 1;
