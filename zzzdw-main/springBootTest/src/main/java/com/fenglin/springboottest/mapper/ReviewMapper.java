package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.Review;
import org.apache.ibatis.annotations.Mapper;

/**
 * 点评 Mapper：继承 BaseMapper 即拥有通用 CRUD。
 */
@Mapper
public interface ReviewMapper extends BaseMapper<Review> {
}
