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

    /** 密码（现按需求明文存储；历史 bcrypt 数据登录时兼容校验），对应列 password_hash */
    private String passwordHash;

    /** 角色：user=普通用户，admin=管理员（后台管理系统专用） */
    private String role;

    /** 权限：1=默认用户（看不到后台按钮、进不了后台），0=管理员（可用后台管理） */
    private Integer perm;

    /** 是否管理员权限（perm=0 视为管理员） */
    public boolean isAdminPerm() {
        return perm != null && perm == 0;
    }

    /** 账号状态：active=正常，disabled=禁用（后台用户管理可切换） */
    private String status;

    /** 注册时间 */
    private LocalDateTime createdAt;
}
