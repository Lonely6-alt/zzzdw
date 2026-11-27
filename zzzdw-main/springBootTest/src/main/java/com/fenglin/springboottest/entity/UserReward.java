package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户兑换记录，对应表 food_db.user_reward
 */
@Data
@TableName("user_reward")
public class UserReward {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    private Long rewardId;

    private String rewardCode;

    private String name;

    private String category;

    private String emoji;

    private String description;

    private Integer cost;

    /** 兑换码 */
    private String exchangeCode;

    private LocalDateTime exchangedAt;
}
