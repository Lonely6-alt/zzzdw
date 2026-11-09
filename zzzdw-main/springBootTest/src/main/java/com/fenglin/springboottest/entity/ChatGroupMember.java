package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 群成员实体，对应表 food_db.chat_group_member。
 * last_read_msg_id 记录我在此群已读到的最大消息 ID，用于计算群未读数。
 */
@Data
@TableName("chat_group_member")
public class ChatGroupMember {

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 群 ID */
    private Long groupId;

    /** 成员用户 ID */
    private Long userId;

    /** 角色：owner=群主 member=成员 */
    private String role;

    /** 加入时间 */
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime joinTime;

    /** 最后已读的群消息 ID（未读数基线） */
    private Long lastReadMsgId;
}
