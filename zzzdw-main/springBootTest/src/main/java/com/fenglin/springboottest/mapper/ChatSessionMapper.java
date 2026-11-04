package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.ChatSession;
import org.apache.ibatis.annotations.Mapper;

/**
 * 私信会话 Mapper：继承 BaseMapper 即拥有通用 CRUD。
 */
@Mapper
public interface ChatSessionMapper extends BaseMapper<ChatSession> {
}
