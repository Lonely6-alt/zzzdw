package com.fenglin.springboottest.util;

import com.fenglin.springboottest.common.BizException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/**
 * JWT 工具：签发 / 校验 token。
 * 前端把 token 存 localStorage，请求时放到 Authorization: Bearer <token> 头里。
 */
@Component
public class JwtUtil {

    /**
     * 签名密钥：从配置 jwt.secret 读取（HMAC-SHA256 要求至少 32 字节）。
     * 默认为演示值；生产环境建议用环境变量 JWT_SECRET 覆盖，避免写死在代码里。
     */
    @Value("${jwt.secret:food-login-springboot-mybatis-plus-jwt-secret-2026}")
    private String secret;

    /** token 有效期（天），从配置 jwt.expire-days 读取，默认 7 天 */
    @Value("${jwt.expire-days:7}")
    private long expireDays;

    private SecretKey key;

    /** Bean 初始化时构建签名密钥并校验长度 */
    @PostConstruct
    void initKey() {
        byte[] secretBytes = secret.getBytes(StandardCharsets.UTF_8);
        if (secretBytes.length < 32) {
            throw new IllegalStateException("jwt.secret 至少需要 32 字节（HMAC-SHA256 要求），当前仅 " + secretBytes.length + " 字节");
        }
        key = Keys.hmacShaKeyFor(secretBytes);
    }

    /** 为指定用户名签发 token */
    public String createToken(String username) {
        return Jwts.builder()
                .subject(username)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expireDays * 24 * 60 * 60 * 1000L))
                .signWith(key)
                .compact();
    }

    /** 校验 token 并返回用户名；无效或过期抛出 401 业务异常 */
    public String verify(String token) {
        try {
            return Jwts.parser().verifyWith(key).build()
                    .parseSignedClaims(token).getPayload().getSubject();
        } catch (JwtException | IllegalArgumentException e) {
            throw new BizException(401, "未登录或登录已过期");
        }
    }

    /**
     * 从请求头 Authorization: Bearer <token> 中解析出用户名。
     * 供需要登录的接口（/api/me、POST /api/posts）调用。
     */
    public String requireUsername(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        String token = (header != null && header.startsWith("Bearer ")) ? header.substring(7) : "";
        if (token.isEmpty()) {
            throw new BizException(401, "未登录或登录已过期");
        }
        return verify(token);
    }
}
