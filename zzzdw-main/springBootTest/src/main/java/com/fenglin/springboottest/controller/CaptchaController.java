package com.fenglin.springboottest.controller;

import cn.hutool.captcha.AbstractCaptcha;
import com.fenglin.springboottest.service.CaptchaService;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.util.Map;

/**
 * 图片验证码接口：GET /api/captcha?id=xxx 直接返回 PNG 图片流。
 * 前端把返回的图片放进 <img> 标签，点击图片换一个新 id 重新请求即可刷新。
 */
@RestController
@RequestMapping("/api")
public class CaptchaController {

    private static final Logger log = LoggerFactory.getLogger(CaptchaController.class);

    private final CaptchaService captchaService;

    public CaptchaController(CaptchaService captchaService) {
        this.captchaService = captchaService;
    }

    @GetMapping(value = "/captcha")
    public void captcha(@RequestParam("id") String id, HttpServletResponse response) throws IOException {
        AbstractCaptcha captcha = captchaService.create(id);
        // 联调期把验证码答案打到后端日志，方便测试；生产环境应删除此行
        log.info("[captcha] id={}, code={}", id, captcha.getCode());

        response.setContentType("image/png");
        // 禁止浏览器/代理缓存，保证每次点击都能拿到新图
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);
        captcha.write(response.getOutputStream());
    }

    /**
     * JSON 版验证码：GET /api/captcha/json
     * 服务端自动生成 captchaId，返回 { "id": "...", "image": "data:image/png;base64,..." }，
     * 前端直接把 image 放进 <img :src>，提交时带 id + 用户输入即可。
     */
    @GetMapping("/captcha/json")
    public Map<String, String> captchaJson() {
        String id = java.util.UUID.randomUUID().toString().replace("-", "");
        AbstractCaptcha captcha = captchaService.create(id);
        log.info("[captcha] id={}, code={}", id, captcha.getCode());
        return Map.of("id", id, "image", captcha.getImageBase64Data());
    }
}
