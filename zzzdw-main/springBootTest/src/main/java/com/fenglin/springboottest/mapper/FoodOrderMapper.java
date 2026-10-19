package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.FoodOrder;
import org.apache.ibatis.annotations.Mapper;

/**
 * 点单 Mapper：继承 BaseMapper 即拥有通用 CRUD。
 */
@Mapper
public interface FoodOrderMapper extends BaseMapper<FoodOrder> {
}
