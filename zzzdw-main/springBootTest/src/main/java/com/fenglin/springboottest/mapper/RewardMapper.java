package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.Reward;
import org.apache.ibatis.annotations.Mapper;

/**
 * 积分好礼目录 Mapper
 */
@Mapper
public interface RewardMapper extends BaseMapper<Reward> {
}
