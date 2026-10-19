package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.fenglin.springboottest.entity.Category;
import com.fenglin.springboottest.vo.CategoryNode;

import java.util.List;

/**
 * 分级分类 Service：在通用 CRUD 之上提供“带帖子数的分类树”。
 */
public interface CategoryService extends IService<Category> {

    /**
     * 构建分级分类树（一级分组 → 二级叶子），并填充每个分类的帖子数。
     * 一级分组的 count 等于其下所有叶子分类帖子数之和。
     */
    List<CategoryNode> treeWithCounts();
}
