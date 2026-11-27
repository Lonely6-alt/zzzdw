package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.UserReward;
import org.apache.ibatis.annotations.Mapper;

/**
 * 用户兑换记录 Mapper
 */
@Mapper
public interface UserRewardMapper extends BaseMapper<UserReward> {
}
