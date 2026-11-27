package com.fenglin.springboottest.dto;

/**
 * 已兑换好礼，字段与前端 useGrowth 的 coupons 结构对齐
 */
public record RedeemedRewardVO(
        Long key,
        String id,
        String name,
        Integer cost,
        String emoji,
        String tag,
        String desc,
        String code,
        Long at
) {
}
