package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 美食分级分类实体，对应表 food_db.category。
 * parent_id = 0 为一级分组；>0 为二级叶子分类，挂在某个分组下。
 */
@Data
@TableName("category")
public class Category {

    /** 分类 ID，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 分类名称 */
    private String name;

    /** 父分类 ID，0 表示一级分类 */
    private Long parentId;

    /** 分类图标（emoji） */
    private String icon;

    /** 同级排序 */
    private Integer sort;

    /** 层级：1=分组 2=叶子 */
    private Integer level;
}
