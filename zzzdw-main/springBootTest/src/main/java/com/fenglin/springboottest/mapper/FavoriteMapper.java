package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.Favorite;
import org.apache.ibatis.annotations.Mapper;

/**
 * 收藏 Mapper：继承 BaseMapper 即拥有通用 CRUD。
 */
@Mapper
public interface FavoriteMapper extends BaseMapper<Favorite> {
}
