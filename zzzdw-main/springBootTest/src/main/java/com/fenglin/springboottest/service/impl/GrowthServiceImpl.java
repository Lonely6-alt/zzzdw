package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.fenglin.springboottest.common.BizException;
import com.fenglin.springboottest.dto.ExchangeResultVO;
import com.fenglin.springboottest.dto.RedeemedRewardVO;
import com.fenglin.springboottest.dto.RewardVO;
import com.fenglin.springboottest.entity.Reward;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.entity.UserReward;
import com.fenglin.springboottest.service.GrowthService;
import com.fenglin.springboottest.service.RewardService;
import com.fenglin.springboottest.service.UserRewardService;
import com.fenglin.springboottest.service.UserService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * 吃货成长体系实现：积分与兑换均以数据库为准。
 */
@Service
public class GrowthServiceImpl implements GrowthService {

    private final UserService userService;
    private final RewardService rewardService;
    private final UserRewardService userRewardService;

    public GrowthServiceImpl(UserService userService, RewardService rewardService, UserRewardService userRewardService) {
        this.userService = userService;
        this.rewardService = rewardService;
        this.userRewardService = userRewardService;
    }

    @Override
    public int getPoints(String username) {
        User user = userService.findByUsername(username);
        if (user == null) throw new BizException(404, "用户不存在");
        return user.getPoints() == null ? 0 : user.getPoints();
    }

    @Override
    public int addPoints(String username, int delta) {
        if (delta <= 0 || delta > 1000) {
            throw new BizException(400, "积分变动值不合法");
        }
        User user = userService.findByUsername(username);
        if (user == null) throw new BizException(404, "用户不存在");
        int next = (user.getPoints() == null ? 0 : user.getPoints()) + delta;
        LambdaUpdateWrapper<User> wrapper = new LambdaUpdateWrapper<User>()
                .eq(User::getId, user.getId())
                .set(User::getPoints, next);
        if (!userService.update(wrapper)) throw new BizException(500, "积分更新失败");
        return next;
    }

    @Override
    public List<RewardVO> activeRewards() {
        List<Reward> rewards = rewardService.list(new LambdaQueryWrapper<Reward>()
                .eq(Reward::getStatus, "active")
                .orderByAsc(Reward::getId));
        return rewards.stream().map(r -> new RewardVO(
                r.getCode(), r.getName(), r.getCategory(), r.getCost(), r.getEmoji(), r.getDescription()
        )).toList();
    }

    @Override
    public List<RedeemedRewardVO> myRewards(String username) {
        User user = userService.findByUsername(username);
        if (user == null) throw new BizException(404, "用户不存在");
        List<UserReward> records = userRewardService.list(new LambdaQueryWrapper<UserReward>()
                .eq(UserReward::getUserId, user.getId())
                .orderByDesc(UserReward::getExchangedAt));
        return records.stream().map(this::toVO).toList();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ExchangeResultVO exchange(String username, String rewardCode) {
        User user = userService.findByUsername(username);
        if (user == null) throw new BizException(404, "用户不存在");
        Reward reward = rewardService.getOne(new LambdaQueryWrapper<Reward>()
                .eq(Reward::getCode, rewardCode)
                .eq(Reward::getStatus, "active"));
        if (reward == null) throw new BizException(404, "好礼不存在或已下架");
        if (reward.getStock() != null && reward.getStock() == 0) {
            throw new BizException(400, "好礼已兑完");
        }

        // 原子扣积分：积分不足时更新失败，避免并发超扣
        LambdaUpdateWrapper<User> pointUpdate = new LambdaUpdateWrapper<User>()
                .eq(User::getId, user.getId())
                .ge(User::getPoints, reward.getCost())
                .setSql("points = points - " + reward.getCost());
        if (!userService.update(pointUpdate)) throw new BizException(400, "积分不够啦，去做任务赚积分吧～");

        // 限量好礼原子扣库存，-1 表示不限量
        if (reward.getStock() != null && reward.getStock() > 0) {
            LambdaUpdateWrapper<Reward> stockUpdate = new LambdaUpdateWrapper<Reward>()
                    .eq(Reward::getId, reward.getId())
                    .gt(Reward::getStock, 0)
                    .setSql("stock = stock - 1");
            if (!rewardService.update(stockUpdate)) throw new BizException(400, "好礼已兑完");
        }

        UserReward record = new UserReward();
        record.setUserId(user.getId());
        record.setRewardId(reward.getId());
        record.setRewardCode(reward.getCode());
        record.setName(reward.getName());
        record.setCategory(reward.getCategory());
        record.setEmoji(reward.getEmoji());
        record.setDescription(reward.getDescription());
        record.setCost(reward.getCost());
        record.setExchangeCode("FOOD" + UUID.randomUUID().toString().replace("-", "").substring(0, 8).toUpperCase());
        record.setExchangedAt(LocalDateTime.now());
        if (!userRewardService.save(record)) throw new BizException(500, "兑换记录写入失败");

        return new ExchangeResultVO(getPoints(username), toVO(record));
    }

    private RedeemedRewardVO toVO(UserReward record) {
        long at = record.getExchangedAt() == null
                ? System.currentTimeMillis()
                : record.getExchangedAt().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli();
        return new RedeemedRewardVO(
                record.getId(), record.getRewardCode(), record.getName(), record.getCost(),
                record.getEmoji(), record.getCategory(), record.getDescription(), record.getExchangeCode(), at
        );
    }
}
