package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 群聊消息实体，对应表 food_db.chat_group_message。
 */
@Data
@TableName("chat_group_message")
public class ChatGroupMessage {

    /** 群消息 ID */
    @TableId(value = "msg_id", type = IdType.AUTO)
    private Long msgId;

    /** 所属群 ID */
    private Long groupId;

    /** 发送方用户 ID */
    private Long senderId;

    /** 消息内容 */
    private String content;

    /** 发送时间 */
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime sendTime;
}
