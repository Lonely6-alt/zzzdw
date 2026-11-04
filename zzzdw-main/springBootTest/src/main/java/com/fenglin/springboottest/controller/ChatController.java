package com.fenglin.springboottest.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.fenglin.springboottest.common.BizException;
import com.fenglin.springboottest.entity.ChatMessage;
import com.fenglin.springboottest.entity.ChatSession;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.mapper.ChatMessageMapper;
import com.fenglin.springboottest.mapper.ChatSessionMapper;
import com.fenglin.springboottest.service.UserService;
import com.fenglin.springboottest.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 私信（一对一聊天）接口：
 * - GET  /api/chat/unread                     当前用户未读消息总数（导航红点用）
 * - GET  /api/chat/sessions                   会话列表（含对方昵称、最后消息、未读数）
 * - POST /api/chat/sessions                   获取或创建与某用户的会话
 * - GET  /api/chat/sessions/{id}/messages     会话消息记录（拉取即把对方发来的消息置为已读）
 * - POST /api/chat/sessions/{id}/messages     发送消息
 */
@RestController
@RequestMapping("/api/chat")
public class ChatController {

    private final ChatSessionMapper sessionMapper;
    private final ChatMessageMapper messageMapper;
    private final UserService userService;
    private final JwtUtil jwtUtil;

    public ChatController(ChatSessionMapper sessionMapper, ChatMessageMapper messageMapper,
                          UserService userService, JwtUtil jwtUtil) {
        this.sessionMapper = sessionMapper;
        this.messageMapper = messageMapper;
        this.userService = userService;
        this.jwtUtil = jwtUtil;
    }

    /** 当前登录用户 */
    private User currentUser(HttpServletRequest request) {
        String username = jwtUtil.requireUsername(request);
        User user = userService.findByUsername(username);
        if (user == null) {
            throw new BizException(404, "用户不存在");
        }
        return user;
    }

    /** 校验当前用户是会话成员，并返回会话 */
    private ChatSession requireMember(Long sessionId, Long userId) {
        ChatSession s = sessionMapper.selectById(sessionId);
        if (s == null) {
            throw new BizException(404, "会话不存在");
        }
        if (!userId.equals(s.getUserAId()) && !userId.equals(s.getUserBId())) {
            throw new BizException(403, "无权访问该会话");
        }
        return s;
    }

    /** 会话对方用户 ID */
    private Long peerId(ChatSession s, Long userId) {
        return userId.equals(s.getUserAId()) ? s.getUserBId() : s.getUserAId();
    }

    /** 未读总数：GET /api/chat/unread */
    @GetMapping("/unread")
    public Map<String, Object> unread(HttpServletRequest request) {
        Long uid = currentUser(request).getId();
        Long cnt = messageMapper.selectCount(new LambdaQueryWrapper<ChatMessage>()
                .eq(ChatMessage::getReceiverId, uid)
                .eq(ChatMessage::getIsRead, 0));
        Map<String, Object> res = new HashMap<>();
        res.put("unread", cnt == null ? 0 : cnt);
        return res;
    }

    /** 会话列表：GET /api/chat/sessions */
    @GetMapping("/sessions")
    public List<Map<String, Object>> sessions(HttpServletRequest request) {
        User me = currentUser(request);
        Long uid = me.getId();
        List<ChatSession> list = sessionMapper.selectList(new LambdaQueryWrapper<ChatSession>()
                .and(w -> w.eq(ChatSession::getUserAId, uid).or().eq(ChatSession::getUserBId, uid))
                .orderByDesc(ChatSession::getLastTime)
                .orderByDesc(ChatSession::getSessionId));
        List<Map<String, Object>> res = new ArrayList<>();
        for (ChatSession s : list) {
            Long pid = peerId(s, uid);
            User peer = userService.getById(pid);
            Long unread = messageMapper.selectCount(new LambdaQueryWrapper<ChatMessage>()
                    .eq(ChatMessage::getSessionId, s.getSessionId())
                    .eq(ChatMessage::getSenderId, pid)
                    .eq(ChatMessage::getIsRead, 0));
            Map<String, Object> m = new HashMap<>();
            m.put("sessionId", s.getSessionId());
            m.put("peerId", pid);
            m.put("peerName", peer == null ? "未知用户" : peer.getUsername());
            m.put("lastMsg", s.getLastMsg() == null ? "" : s.getLastMsg());
            m.put("lastTime", s.getLastTime() == null ? s.getCreateTime() : s.getLastTime());
            m.put("unread", unread == null ? 0 : unread);
            res.add(m);
        }
        return res;
    }

    /** 获取或创建会话：POST /api/chat/sessions，body: { "peerUsername": "test" } */
    @PostMapping("/sessions")
    public Map<String, Object> getOrCreate(@RequestBody Map<String, String> body, HttpServletRequest request) {
        User me = currentUser(request);
        String peerUsername = body.get("peerUsername");
        if (peerUsername == null || peerUsername.isBlank()) {
            throw new BizException(400, "缺少对方用户名");
        }
        if (peerUsername.equals(me.getUsername())) {
            throw new BizException(400, "不能给自己发私信");
        }
        User peer = userService.findByUsername(peerUsername);
        if (peer == null) {
            throw new BizException(404, "对方用户不存在");
        }
        // 约定小 ID 存 userAId，大 ID 存 userBId，配合唯一索引天然去重
        long a = Math.min(me.getId(), peer.getId());
        long b = Math.max(me.getId(), peer.getId());
        ChatSession s = sessionMapper.selectOne(new LambdaQueryWrapper<ChatSession>()
                .eq(ChatSession::getUserAId, a)
                .eq(ChatSession::getUserBId, b));
        if (s == null) {
            s = new ChatSession();
            s.setUserAId(a);
            s.setUserBId(b);
            s.setCreateTime(LocalDateTime.now());
            sessionMapper.insert(s);
        }
        Map<String, Object> res = new HashMap<>();
        res.put("sessionId", s.getSessionId());
        res.put("peerId", peer.getId());
        res.put("peerName", peer.getUsername());
        return res;
    }

    /** 消息记录：GET /api/chat/sessions/{id}/messages，同时把对方发来的消息置为已读 */
    @GetMapping("/sessions/{id}/messages")
    public List<ChatMessage> messages(@PathVariable Long id, HttpServletRequest request) {
        Long uid = currentUser(request).getId();
        requireMember(id, uid);
        List<ChatMessage> list = messageMapper.selectList(new LambdaQueryWrapper<ChatMessage>()
                .eq(ChatMessage::getSessionId, id)
                .orderByAsc(ChatMessage::getSendTime)
                .orderByAsc(ChatMessage::getMsgId));
        // 拉取即已读：把该会话中我收到的未读消息全部置 1
        messageMapper.update(null, new LambdaUpdateWrapper<ChatMessage>()
                .eq(ChatMessage::getSessionId, id)
                .eq(ChatMessage::getReceiverId, uid)
                .eq(ChatMessage::getIsRead, 0)
                .set(ChatMessage::getIsRead, 1));
        return list;
    }

    /** 发送消息：POST /api/chat/sessions/{id}/messages，body: { "content": "..." } */
    @PostMapping("/sessions/{id}/messages")
    @ResponseStatus(HttpStatus.CREATED)
    public ChatMessage send(@PathVariable Long id, @RequestBody Map<String, String> body,
                            HttpServletRequest request) {
        User me = currentUser(request);
        Long uid = me.getId();
        ChatSession s = requireMember(id, uid);
        String content = body.get("content");
        if (content == null || content.isBlank()) {
            throw new BizException(400, "消息内容不能为空");
        }
        content = content.trim();
        if (content.length() > 1000) {
            content = content.substring(0, 1000);
        }
        Long pid = peerId(s, uid);
        ChatMessage msg = new ChatMessage();
        msg.setSessionId(id);
        msg.setSenderId(uid);
        msg.setReceiverId(pid);
        msg.setContent(content);
        msg.setSendTime(LocalDateTime.now());
        msg.setIsRead(0);
        messageMapper.insert(msg);
        // 同步会话摘要
        s.setLastMsg(content);
        s.setLastTime(msg.getSendTime());
        sessionMapper.updateById(s);
        return msg;
    }
}
