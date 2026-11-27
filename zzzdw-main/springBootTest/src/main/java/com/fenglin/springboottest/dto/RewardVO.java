package com.fenglin.springboottest.dto;

/**
 * 前端积分好礼卡片所需字段
 */
public record RewardVO(
        String id,
        String name,
        String tag,
        Integer cost,
        String emoji,
        String desc
) {
}
