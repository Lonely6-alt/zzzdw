package com.fenglin.springboottest.dto;

/**
 * 兑换结果：返回最新积分与刚兑换的好礼
 */
public record ExchangeResultVO(Integer points, RedeemedRewardVO reward) {
}
