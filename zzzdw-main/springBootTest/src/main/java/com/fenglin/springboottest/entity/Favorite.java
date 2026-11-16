package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 收藏实体，对应表 food_db.favorite。唯一键 (user_id, post_id)。
 */
@Data
@TableName("favorite")
public class Favorite {

    /** 收藏 ID */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 用户 ID */
    private Long userId;

    /** 帖子 ID */
    private Long postId;

    /** 商家名称（冗余列，收藏时从帖子所属店铺写入，方便在数据库里直接查看） */
    private String shopName;

    /** 收藏时间 */
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    /** 修改日期（数据库 ON UPDATE CURRENT_TIMESTAMP 自动维护） */
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime updatedAt;
}
