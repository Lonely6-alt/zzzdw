package com.fenglin.springboottest.service;

import cn.hutool.captcha.AbstractCaptcha;
import cn.hutool.captcha.CaptchaUtil;
import cn.hutool.captcha.generator.RandomGenerator;
import com.fenglin.springboottest.common.BizException;
import org.springframework.stereotype.Service;

import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 图片验证码服务：内存存储（单机演示够用）。
 * 流程：前端生成随机 id -> GET /api/captcha?id=xxx 取图 -> 提交 id+code 到登录/注册接口校验。
 * 规则：5 分钟有效、一次一用（校验后立即删除）、不区分大小写。
 */
@Service
public class CaptchaService {

    /** 验证码有效期：5 分钟 */
    private static final long EXPIRE_MS = 5 * 60 * 1000L;

    /** 内存中最多缓存的验证码条目，防止恶意刷接口撑爆内存 */
    private static final int MAX_ENTRIES = 10_000;

    /** 存储结构：captchaId -> {code, expireAt} */
    private final Map<String, Entry> store = new ConcurrentHashMap<>();

    /** 单条验证码记录 */
    private record Entry(String code, long expireAt) {
    }

    /**
     * 为指定 id 生成一张 144x48 的线段干扰验证码图片（4 位字符）。
     * 字符集去掉易混淆的 I/O/0/1/L，提升可读性；RandomGenerator 的 verify 自带忽略大小写。
     */
    public AbstractCaptcha create(String id) {
        // 先清理过期条目，控制内存占用
        cleanExpired();

        AbstractCaptcha captcha = CaptchaUtil.createLineCaptcha(144, 48, 4, 30);
        captcha.setGenerator(new RandomGenerator("ABCDEFGHJKMNPQRSTUVWXYZ23456789", 4));
        captcha.createCode();

        if (store.size() >= MAX_ENTRIES) {
            throw new BizException(429, "验证码请求过于频繁，请稍后再试");
        }
        store.put(id, new Entry(captcha.getCode(), System.currentTimeMillis() + EXPIRE_MS));
        return captcha;
    }

    /**
     * 校验验证码：不存在 / 已过期 / 不匹配均抛 400。
     * 无论成功失败都把该 id 删除（一次一用），防止重放。
     */
    public void verify(String captchaId, String captchaCode) {
        if (captchaId == null || captchaId.isBlank() || captchaCode == null || captchaCode.isBlank()) {
            throw new BizException(400, "请输入验证码");
        }
        Entry entry = store.remove(captchaId);
        if (entry == null) {
            throw new BizException(400, "验证码已过期或不存在，请刷新后重试");
        }
        if (System.currentTimeMillis() > entry.expireAt()) {
            throw new BizException(400, "验证码已过期，请刷新后重试");
        }
        if (!entry.code().equalsIgnoreCase(captchaCode.trim())) {
            throw new BizException(400, "验证码不正确");
        }
    }

    /** 清理已过期的验证码条目 */
    private void cleanExpired() {
        long now = System.currentTimeMillis();
        if (store.isEmpty()) {
            return;
        }
        Iterator<Map.Entry<String, Entry>> it = store.entrySet().iterator();
        while (it.hasNext()) {
            if (now > it.next().getValue().expireAt()) {
                it.remove();
            }
        }
    }
}
