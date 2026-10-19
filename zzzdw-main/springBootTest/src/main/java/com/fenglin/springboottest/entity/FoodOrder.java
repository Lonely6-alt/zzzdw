package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 点单实体，对应表 food_db.food_order。
 */
@Data
@TableName("food_order")
public class FoodOrder {

    /** 订单 ID */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 帖子 ID */
    private Long postId;

    /** 用户 ID */
    private Long userId;

    /** 数量 */
    private Integer qty;

    /** 备注 */
    private String note;

    /** 下单时间 */
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;
}
