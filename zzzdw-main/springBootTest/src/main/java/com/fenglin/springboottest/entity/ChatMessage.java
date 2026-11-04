package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 私信消息实体，对应表 food_db.chat_message。
 */
@Data
@TableName("chat_message")
public class ChatMessage {

    /** 消息 ID */
    @TableId(value = "msg_id", type = IdType.AUTO)
    private Long msgId;

    /** 所属会话 ID */
    private Long sessionId;

    /** 发送方用户 ID */
    private Long senderId;

    /** 接收方用户 ID */
    private Long receiverId;

    /** 消息内容 */
    private String content;

    /** 发送时间 */
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime sendTime;

    /** 是否已读：0=未读 1=已读 */
    private Integer isRead;
}
