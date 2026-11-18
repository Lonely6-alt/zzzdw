package com.fenglin.springboottest.ws;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.service.UserService;
import com.fenglin.springboottest.util.JwtUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 聊天 WebSocket 处理器：前端连 /ws/chat?token=xxx，服务端按用户 ID 维护在线连接。
 * 收到 "ping" 回 {"type":"pong"} 作为心跳；业务消息由 HTTP 接口写库后通过 {@link #push} 实时推送。
 * <p>
 * 推送事件格式（与前端 ChatView 约定一致）：
 * 私信 { type:"private", sessionId, senderName, msg:{...} }
 * 群聊 { type:"group",   groupId,   senderName, msg:{...} }
 * 群变更 { type:"group_members", groupId }
 */
@Component
public class ChatWsHandler extends TextWebSocketHandler {

    private static final Logger log = LoggerFactory.getLogger(ChatWsHandler.class);

    /** session 属性中保存当前登录用户 ID 的 key */
    private static final String ATTR_USER_ID = "userId";

    /** 一个用户可能多端在线，故用 Set 保存其全部连接 */
    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final Map<Long, Set<WebSocketSession>> online = new ConcurrentHashMap<>();

    private final JwtUtil jwtUtil;
    private final UserService userService;

    public ChatWsHandler(JwtUtil jwtUtil, UserService userService) {
        this.jwtUtil = jwtUtil;
        this.userService = userService;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        Long userId = resolveUserId(session);
        if (userId == null) {
            // token 缺失或无效：直接关闭，前端会重试并在登录后重新连接
            session.close(CloseStatus.NOT_ACCEPTABLE.withReason("未登录或登录已过期"));
            return;
        }
        session.getAttributes().put(ATTR_USER_ID, userId);
        online.computeIfAbsent(userId, k -> ConcurrentHashMap.newKeySet()).add(session);
        broadcastPresence(userId, true);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        // 仅处理心跳，其它客户端上行文本忽略（发消息走 HTTP 接口，保证落库）
        if ("ping".equalsIgnoreCase(message.getPayload())) {
            send(session, "{\"type\":\"pong\"}");
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        Object uid = session.getAttributes().get(ATTR_USER_ID);
        if (uid instanceof Long userId) {
            Set<WebSocketSession> set = online.get(userId);
            if (set != null) {
                set.remove(session);
                if (set.isEmpty()) {
                    online.remove(userId);
                    broadcastPresence(userId, false);
                }
            }
        }
    }

    /** 判断某用户是否在线 */
    public boolean isOnline(Long userId) {
        Set<WebSocketSession> set = userId == null ? null : online.get(userId);
        return set != null && !set.isEmpty();
    }

    /** 当前在线用户 ID 快照，供会话列表显示在线圆点 */
    public Set<Long> onlineUserIds() {
        return Set.copyOf(online.keySet());
    }

    /** 向所有在线连接广播某用户的上线/下线事件 */
    private void broadcastPresence(Long userId, boolean isOnline) {
        Map<String, Object> event = new HashMap<>();
        event.put("type", "presence");
        event.put("userId", userId);
        event.put("online", isOnline);
        push(online.keySet(), event);
    }

    /**
     * 把事件推给指定用户（其所有在线连接）；离线用户自动忽略，消息仍已落库，靠前端轮询兜底。
     */
    public void push(Collection<Long> userIds, Map<String, Object> event) {
        if (userIds == null || userIds.isEmpty() || event == null) {
            return;
        }
        String json;
        try {
            json = MAPPER.writeValueAsString(event);
        } catch (Exception e) {
            log.warn("聊天事件序列化失败: {}", e.getMessage());
            return;
        }
        for (Long userId : userIds) {
            if (userId == null) {
                continue;
            }
            Set<WebSocketSession> sessions = online.get(userId);
            if (sessions == null) {
                continue;
            }
            for (WebSocketSession s : sessions) {
                send(s, json);
            }
        }
    }

    /** WebSocketSession 非线程安全，发送时加锁 */
    private void send(WebSocketSession session, String json) {
        if (session == null || !session.isOpen()) {
            return;
        }
        synchronized (session) {
            try {
                session.sendMessage(new TextMessage(json));
            } catch (Exception e) {
                log.debug("推送失败（连接可能已断开）：{}", e.getMessage());
            }
        }
    }

    /** 从握手 URL 的 ?token=xxx 解析出用户 ID，失败返回 null */
    private Long resolveUserId(WebSocketSession session) {
        try {
            URI uri = session.getUri();
            if (uri == null || uri.getQuery() == null) {
                return null;
            }
            String token = null;
            for (String kv : uri.getQuery().split("&")) {
                int i = kv.indexOf('=');
                if (i > 0 && "token".equals(kv.substring(0, i))) {
                    token = URLDecoder.decode(kv.substring(i + 1), StandardCharsets.UTF_8);
                    break;
                }
            }
            if (token == null || token.isEmpty()) {
                return null;
            }
            String username = jwtUtil.verify(token);
            User user = userService.findByUsername(username);
            return user == null ? null : user.getId();
        } catch (Exception e) {
            return null;
        }
    }
}
