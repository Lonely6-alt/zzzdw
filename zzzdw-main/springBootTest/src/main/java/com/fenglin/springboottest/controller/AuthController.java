package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.BizException;
import com.fenglin.springboottest.dto.AuthVO;
import com.fenglin.springboottest.dto.LoginRequest;
import com.fenglin.springboottest.dto.RegisterRequest;
import com.fenglin.springboottest.dto.UserVO;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.service.CaptchaService;
import com.fenglin.springboottest.service.UserService;
import com.fenglin.springboottest.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * 认证接口：注册 / 登录 / 当前用户。
 * 注册与登录均需携带图片验证码（captchaId + captchaCode）。
 * 响应格式与前端 food-login-vue 约定保持一致：
 *   成功 -> { "token": "...", "user": { "username": "..." } }
 *   失败 -> { "message": "..." } + 400/401/404/409
 */
@RestController
@RequestMapping("/api")
public class AuthController {

    private final UserService userService;
    private final CaptchaService captchaService;
    private final JwtUtil jwtUtil;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    public AuthController(UserService userService, CaptchaService captchaService, JwtUtil jwtUtil) {
        this.userService = userService;
        this.captchaService = captchaService;
        this.jwtUtil = jwtUtil;
    }

    /** 注册：校验（含验证码）-> 查重 -> 密码明文入库 -> 自动返回 token（注册即登录）；注册用户一律默认权限 perm=1 */
    @PostMapping("/register")
    public AuthVO register(@RequestBody RegisterRequest req) {
        String username = trim(req.username());
        String password = req.password();

        if (username == null || username.length() < 3) {
            throw new BizException(400, "用户名至少 3 个字符");
        }
        if (password == null || password.length() < 6) {
            throw new BizException(400, "密码至少 6 位");
        }
        captchaService.verify(req.captchaId(), req.captchaCode());
        if (userService.findByUsername(username) != null) {
            throw new BizException(409, "该用户名已存在");
        }

        User user = new User();
        user.setUsername(username);
        // 按需求密码明文存储，不加密
        user.setPasswordHash(password);
        user.setRole("user");
        user.setPerm(1);
        user.setCreatedAt(LocalDateTime.now());
        userService.save(user);

        return new AuthVO(jwtUtil.createToken(username), new UserVO(user.getId(), username, "user", 1, user.getPoints()));
    }

    /** 登录：先校验验证码，再按用户名查询并校验密码（明文直比，兼容历史 bcrypt 数据） */
    @PostMapping("/login")
    public AuthVO login(@RequestBody LoginRequest req) {
        String username = trim(req.username());
        String password = req.password();

        if (username == null || username.isEmpty() || password == null || password.isEmpty()) {
            throw new BizException(400, "请输入用户名和密码");
        }
        // 验证码可选：前端带 captchaId 就校验（普通用户登录），不带则跳过（后台管理员登录）
        if (req.captchaId() != null && !req.captchaId().isBlank()) {
            captchaService.verify(req.captchaId(), req.captchaCode());
        }
        User user = userService.findByUsername(username);
        // 明文密码直接比对；老账号库里还是 bcrypt 哈希，用 encoder 兜底兼容
        boolean pwdOk = password.equals(user == null ? "" : user.getPasswordHash())
                || (user != null && encoder.matches(password, user.getPasswordHash()));
        if (user == null || !pwdOk) {
            throw new BizException(401, "用户名或密码不正确");
        }
        if ("disabled".equals(user.getStatus())) {
            throw new BizException(403, "该账号已被禁用，请联系管理员");
        }
        // 角色由权限字段决定：perm=0 才是管理员，token 写入对应角色供 /api/admin/** 鉴权
        String role = user.isAdminPerm() ? "admin" : "user";
        return new AuthVO(jwtUtil.createToken(user.getUsername(), role), UserVO.of(user));
    }

    /** 当前登录用户：需要请求头 Authorization: Bearer <token> */
    @GetMapping("/me")
    public Map<String, UserVO> me(HttpServletRequest request) {
        String username = jwtUtil.requireUsername(request);
        User user = userService.findByUsername(username);
        if (user == null) {
            throw new BizException(404, "用户不存在");
        }
        return Map.of("user", UserVO.of(user));
    }

    private static String trim(String s) {
        return s == null ? null : s.trim();
    }
}
