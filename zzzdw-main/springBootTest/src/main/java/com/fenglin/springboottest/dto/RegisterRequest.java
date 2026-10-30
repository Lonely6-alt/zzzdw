package com.fenglin.springboottest.dto;

import com.fasterxml.jackson.annotation.JsonAlias;

/**
 * 注册请求体：{ "username": "...", "password": "...", "captchaId": "...", "captchaCode": "..." }
 * 兼容旧前端的 "captcha" 字段名。
 */
public record RegisterRequest(
        String username,
        String password,
        String captchaId,
        @JsonAlias("captcha") String captchaCode) {
}
