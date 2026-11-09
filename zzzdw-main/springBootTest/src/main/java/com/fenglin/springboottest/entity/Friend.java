package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 好友关系实体，对应表 food_db.friend。
 * 一条 status=accepted 的记录代表一对双向好友（requester 与 receiver 互为好友）。
 */
@Data
@TableName("friend")
public class Friend {

    /** 记录 ID，数据库自增 */
    @TableId(value = "friend_id", type = IdType.AUTO)
    private Long friendId;

    /** 发起申请的用户 ID，对应列 requester_id */
    private Long requesterId;

    /** 被申请的用户 ID，对应列 receiver_id */
    private Long receiverId;

    /** 状态：pending=待处理，accepted=已同意，rejected=已拒绝 */
    private String status;

    /** 申请时间 */
    private LocalDateTime createTime;

    /** 处理时间（同意/拒绝时写入） */
    private LocalDateTime handleTime;

    /** 非库字段：对方用户名（前端展示用） */
    @com.baomidou.mybatisplus.annotation.TableField(exist = false)
    private String peerName;
}
