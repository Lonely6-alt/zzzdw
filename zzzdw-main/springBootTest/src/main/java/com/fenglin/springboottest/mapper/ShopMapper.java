package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.Shop;
import org.apache.ibatis.annotations.Mapper;

/**
 * 店铺 Mapper：继承 BaseMapper 即拥有通用 CRUD。
 * 供 PostServiceImpl 回填菜品店铺信息，以及店铺模块自身使用。
 */
@Mapper
public interface ShopMapper extends BaseMapper<Shop> {
}
