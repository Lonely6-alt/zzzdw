package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.ChatGroup;
import org.apache.ibatis.annotations.Mapper;

/**
 * 群聊 Mapper：继承 BaseMapper 即拥有通用 CRUD
 */
@Mapper
public interface ChatGroupMapper extends BaseMapper<ChatGroup> {
}
