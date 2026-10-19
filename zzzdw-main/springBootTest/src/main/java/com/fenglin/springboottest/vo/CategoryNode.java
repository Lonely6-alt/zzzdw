package com.fenglin.springboottest.vo;

import lombok.Data;

import java.util.List;

/**
 * 分级分类树节点：用于首页“分级分类”展示与搜索条件。
 * count 为该分类下的帖子数；children 为二级叶子分类（一级分组才有）。
 */
@Data
public class CategoryNode {

    private Long id;
    private String name;
    private Long parentId;
    private String icon;
    private Integer level;
    private Integer count;
    private List<CategoryNode> children;
}
