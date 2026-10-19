package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.Post;
import org.apache.ibatis.annotations.Mapper;

/**
 * 美食帖子 Mapper：继承 BaseMapper 即拥有通用 CRUD
 */
@Mapper
public interface PostMapper extends BaseMapper<Post> {
}
