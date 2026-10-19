package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 美食点评实体，对应表 food_db.review。
 */
@Data
@TableName("review")
public class Review {

    /** 点评 ID */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 帖子 ID */
    private Long postId;

    /** 点评人用户名 */
    private String author;

    /** 评分 1~5 */
    private Integer rating;

    /** 点评内容 */
    private String comment;

    /** 点评时间 */
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;
}
