package com.fenglin.springboottest.service;

import com.fenglin.springboottest.dto.ExchangeResultVO;
import com.fenglin.springboottest.dto.RedeemedRewardVO;
import com.fenglin.springboottest.dto.RewardVO;

import java.util.List;

/**
 * 吃货成长体系：积分读取、积分上报、好礼目录与兑换
 */
public interface GrowthService {

    /** 当前用户积分 */
    int getPoints(String username);

    /** 上报正向积分变动，返回变动后的积分 */
    int addPoints(String username, int delta);

    /** 可兑换好礼目录 */
    List<RewardVO> activeRewards();

    /** 当前用户已兑换好礼 */
    List<RedeemedRewardVO> myRewards(String username);

    /** 兑换好礼：事务内扣积分并写兑换记录 */
    ExchangeResultVO exchange(String username, String rewardCode);
}
