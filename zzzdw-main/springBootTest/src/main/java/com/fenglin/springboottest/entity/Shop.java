package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 店铺实体，对应表 food_db.shop。
 * 一个用户最多开一家店（owner_id 唯一），店铺名唯一；菜品（post）通过 shop_id 归属到店铺，
 * 卡片上的店铺名实时读自本表，店家改名后所有菜品同步显示新名字。
 */
@Data
@TableName("shop")
public class Shop {

    /** 店铺 ID，数据库自增，对应列 shop_id */
    @TableId(value = "shop_id", type = IdType.AUTO)
    private Long shopId;

    /** 店主用户 ID，关联 user.id（唯一：一人一店） */
    private Long ownerId;

    /** 店铺名称（店家可自定义，全局唯一） */
    private String shopName;

    /** 店铺图标（emoji） */
    private String emoji;

    /** 店铺简介 */
    private String description;

    /** 所在商圈，如：三里屯、五道口 */
    private String district;

    /** 联系电话 */
    private String phone;

    /** 状态：active=营业中 closed=休息 */
    private String status;

    /** 创建时间 */
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createTime;

    /** 最后修改时间 */
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime updateTime;

    /** 营业开始时间，格式 HH:mm（如 09:00）；为空表示店家未设置 */
    private String openTime;

    /** 营业结束时间，格式 HH:mm（如 21:30）；为空表示店家未设置 */
    private String closeTime;

    /** 店主用户名（非数据库字段，列表查询后回填，点击可发起私信） */
    @TableField(exist = false)
    private String ownerName;

    /** 店内菜品数（非数据库字段，统计后回填） */
    @TableField(exist = false)
    private Integer postCount;

    /** 店内菜品平均评分（非数据库字段，统计后回填） */
    @TableField(exist = false)
    private BigDecimal avgRating;

    /** 店内累计点评数（非数据库字段，统计后回填） */
    @TableField(exist = false)
    private Integer reviewCount;

    /** 店内菜品累计收藏数（非数据库字段，统计后回填） */
    @TableField(exist = false)
    private Integer favoriteCount;
}
