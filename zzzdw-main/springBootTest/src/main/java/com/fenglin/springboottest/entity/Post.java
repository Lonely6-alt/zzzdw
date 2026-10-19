package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 美食帖子实体，对应表 food_db.post。
 * 在原有字段基础上扩展：category_id（分级分类关联）、rating（平均评分）、
 * review_count / favorite_count / order_count（计数聚合）、price（参考单价）。
 */
@Data
@TableName("post")
public class Post {

    /** 帖子 ID，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 标题 */
    private String title;

    /** 分类名称（叶子分类，便于展示与兼容） */
    private String category;

    /** 所属叶子分类 ID，关联 category.id（支持分级分类搜索） */
    private Long categoryId;

    /** 作者用户名 */
    private String author;

    /** 封面表情图标 */
    private String emoji;

    /** 内容 */
    private String content;

    /** 平均评分 0.0~5.0 */
    private BigDecimal rating;

    /** 点评数 */
    private Integer reviewCount;

    /** 收藏数 */
    private Integer favoriteCount;

    /** 点单数 */
    private Integer orderCount;

    /** 参考单价 */
    private BigDecimal price;

    /** 发布时间；序列化为 ISO 格式字符串，前端 new Date() 可直接解析 */
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;
}
