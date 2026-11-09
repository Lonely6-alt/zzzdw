package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.ChatGroupMessage;
import org.apache.ibatis.annotations.Mapper;

/**
 * 群消息 Mapper：继承 BaseMapper 即拥有通用 CRUD
 */
@Mapper
public interface ChatGroupMessageMapper extends BaseMapper<ChatGroupMessage> {
}
