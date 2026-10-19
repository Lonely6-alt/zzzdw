package com.fenglin.springboottest.dto;

/**
 * 登录/注册成功响应：{ "token": "...", "user": { "username": "..." } }
 */
public record AuthVO(String token, UserVO user) {
}
