package com.fenglin.springboottest.dto;

/**
 * 返回给前端的用户信息（不含密码）
 */
public record UserVO(String username) {

    public static UserVO of(com.fenglin.springboottest.entity.User u) {
        return new UserVO(u.getUsername());
    }
}
