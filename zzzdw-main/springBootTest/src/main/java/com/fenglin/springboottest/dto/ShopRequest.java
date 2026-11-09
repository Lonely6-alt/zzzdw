package com.fenglin.springboottest.dto;

/**
 * 开店 / 改店铺资料请求体：
 * { "shopName": "老张牛肉面", "emoji": "🍜", "description": "...", "district": "老城区",
 *   "phone": "400-1001-001", "status": "active" }
 */
public record ShopRequest(String shopName, String emoji, String description,
                          String district, String phone, String status) {
}
