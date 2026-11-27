package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 积分好礼目录，对应表 food_db.reward
 */
@Data
@TableName("reward")
public class Reward {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 好礼编码，与前端 rewardId 一致 */
    private String code;

    /** 好礼名称 */
    private String name;

    /** 分类：配送/满减/饮品/甜品/惊喜/特权/现金/周边 */
    private String category;

    /** 所需积分 */
    private Integer cost;

    /** 展示图标 */
    private String emoji;

    /** 好礼说明 */
    private String description;

    /** 库存，-1 表示不限量 */
    private Integer stock;

    /** active=可兑换 */
    private String status;

    private LocalDateTime createdAt;
}
