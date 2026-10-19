package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户实体，对应表 food_db.user
 */
@Data
@TableName("user")
public class User {

    /** 用户 ID，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 用户名（唯一） */
    private String username;

    /** BCrypt 密码哈希，对应列 password_hash */
    private String passwordHash;

    /** 注册时间 */
    private LocalDateTime createdAt;
}
