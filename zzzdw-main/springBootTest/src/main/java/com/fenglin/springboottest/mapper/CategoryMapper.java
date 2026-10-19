package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.Category;
import org.apache.ibatis.annotations.Mapper;

/**
 * 分级分类 Mapper：继承 BaseMapper 即拥有通用 CRUD。
 */
@Mapper
public interface CategoryMapper extends BaseMapper<Category> {
}
