package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.Tag;
import org.apache.ibatis.annotations.Mapper;

/**
 * 热门标签 Mapper：继承 BaseMapper 即拥有通用 CRUD。
 */
@Mapper
public interface TagMapper extends BaseMapper<Tag> {
}
