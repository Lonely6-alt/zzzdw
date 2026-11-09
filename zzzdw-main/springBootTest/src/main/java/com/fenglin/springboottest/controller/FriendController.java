package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.BizException;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.service.FriendService;
import com.fenglin.springboottest.service.UserService;
import com.fenglin.springboottest.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * 好友关系接口：
 * - GET    /api/friends                 我的好友列表
 * - POST   /api/friends                 发申请 { username }
 * - GET    /api/friends/pending         我收到的待处理申请
 * - GET    /api/friends/sent            我发出的待处理申请
 * - POST   /api/friends/{id}/accept     同意申请
 * - POST   /api/friends/{id}/reject     拒绝申请
 * - DELETE /api/friends/{id}            删除好友
 */
@RestController
@RequestMapping("/api/friends")
public class FriendController {

    private final FriendService friendService;
    private final UserService userService;
    private final JwtUtil jwtUtil;

    public FriendController(FriendService friendService, UserService userService, JwtUtil jwtUtil) {
        this.friendService = friendService;
        this.userService = userService;
        this.jwtUtil = jwtUtil;
    }

    private Long meId(HttpServletRequest request) {
        User me = userService.findByUsername(jwtUtil.requireUsername(request));
        if (me == null) {
            throw new BizException(404, "用户不存在");
        }
        return me.getId();
    }

    @GetMapping
    public List<Map<String, Object>> friends(HttpServletRequest request) {
        return friendService.listFriends(meId(request));
    }

    @PostMapping
    public Map<String, Object> request(@RequestBody Map<String, String> body, HttpServletRequest request) {
        Long id = friendService.request(meId(request), body.get("username"));
        return Map.of("requestId", id);
    }

    @GetMapping("/pending")
    public List<Map<String, Object>> pending(HttpServletRequest request) {
        return friendService.pendingIncoming(meId(request));
    }

    @GetMapping("/sent")
    public List<Map<String, Object>> sent(HttpServletRequest request) {
        return friendService.pendingSent(meId(request));
    }

    @PostMapping("/{id}/accept")
    public Map<String, Object> accept(@PathVariable Long id, HttpServletRequest request) {
        friendService.accept(meId(request), id);
        return Map.of("ok", true);
    }

    @PostMapping("/{id}/reject")
    public Map<String, Object> reject(@PathVariable Long id, HttpServletRequest request) {
        friendService.reject(meId(request), id);
        return Map.of("ok", true);
    }

    @DeleteMapping("/{id}")
    public Map<String, Object> remove(@PathVariable Long id, HttpServletRequest request) {
        friendService.removeFriend(meId(request), id);
        return Map.of("ok", true);
    }

    /** 按对方用户 ID 删除好友（好友列表里只有对方 id，没有关系记录 id） */
    @DeleteMapping("/by-peer/{peerId}")
    public Map<String, Object> removeByPeer(@PathVariable Long peerId, HttpServletRequest request) {
        friendService.removeFriendByPeer(meId(request), peerId);
        return Map.of("ok", true);
    }
}
