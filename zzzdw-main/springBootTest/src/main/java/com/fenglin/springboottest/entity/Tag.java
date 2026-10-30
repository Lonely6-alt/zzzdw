package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 热门标签实体，对应表 food_db.tag。
 */
@Data
@TableName("tag")
public class Tag {

    /** 标签 ID，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 标签名称（唯一） */
    private String name;

    /** 热度 */
    private Integer heat;
}
