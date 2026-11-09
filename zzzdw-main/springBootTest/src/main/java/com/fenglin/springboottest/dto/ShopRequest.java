package com.fenglin.springboottest.dto;

/**
 * 开店 / 改店铺资料请求体：
 * { "shopName": "老张牛肉面", "emoji": "🍜", "description": "...", "district": "老城区",
 *   "phone": "400-1001-001", "status": "active", "openTime": "09:00", "closeTime": "21:30" }
 * <p>
 * openTime / closeTime 为 null 表示「不修改」，为空字符串表示「清空不展示」。
 */
public record ShopRequest(String shopName, String emoji, String description,
                          String district, String phone, String status,
                          String openTime, String closeTime) {
}
