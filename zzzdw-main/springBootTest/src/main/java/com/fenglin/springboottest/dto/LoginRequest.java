package com.fenglin.springboottest.dto;

/**
 * 登录请求体：{ "username": "...", "password": "...", "captchaId": "...", "captchaCode": "..." }
 */
public record LoginRequest(String username, String password, String captchaId, String captchaCode) {
}
