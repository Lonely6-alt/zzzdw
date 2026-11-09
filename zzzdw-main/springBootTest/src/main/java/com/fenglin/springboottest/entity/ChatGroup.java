package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 群聊实体，对应表 food_db.chat_group。
 */
@Data
@TableName("chat_group")
public class ChatGroup {

    /** 群 ID */
    @TableId(value = "group_id", type = IdType.AUTO)
    private Long groupId;

    /** 群名称 */
    private String groupName;

    /** 群主用户 ID */
    private Long ownerId;

    /** 群头像图标（emoji） */
    private String emoji;

    /** 群公告 */
    private String notice;

    /** 建群时间 */
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createTime;

    /** 最后一条消息摘要 */
    private String lastMsg;

    /** 最后一条消息时间 */
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime lastTime;
}
