package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.entity.Reward;
import com.fenglin.springboottest.mapper.RewardMapper;
import com.fenglin.springboottest.service.RewardService;
import org.springframework.stereotype.Service;

/**
 * 积分好礼目录 Service 实现
 */
@Service
public class RewardServiceImpl extends ServiceImpl<RewardMapper, Reward> implements RewardService {
}
