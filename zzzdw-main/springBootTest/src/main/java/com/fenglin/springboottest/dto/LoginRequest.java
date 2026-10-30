package com.fenglin.springboottest.dto;

/**
 * 登录请求体：{ "username": "...", "password": "...", "captchaId": "...", "captchaCode": "..." }
 * 验证码可选：传了 captchaId 就校验，不传则跳过（兼容后台管理员登录等无验证码场景）。
 */
public record LoginRequest(String username, String password, String captchaId, String captchaCode) {
}
