package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 私信会话实体，对应表 food_db.chat_session。
 * 约定 userAId 存较小的用户 ID、userBId 存较大的用户 ID，便于用唯一索引去重。
 */
@Data
@TableName("chat_session")
public class ChatSession {

    /** 会话 ID */
    @TableId(value = "session_id", type = IdType.AUTO)
    private Long sessionId;

    /** 会话发起方用户 ID（较小者） */
    private Long userAId;

    /** 会话另一方用户 ID（较大者） */
    private Long userBId;

    /** 会话创建时间 */
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createTime;

    /** 最后一条消息摘要 */
    private String lastMsg;

    /** 最后一条消息时间 */
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime lastTime;
}
