package com.fenglin.springboottest.config;

import com.fenglin.springboottest.ws.ChatWsHandler;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

/**
 * WebSocket 配置：把聊天处理器挂到 /ws/chat（前端 vite 已把 /ws 代理到本服务）。
 */
@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    private final ChatWsHandler chatWsHandler;

    public WebSocketConfig(ChatWsHandler chatWsHandler) {
        this.chatWsHandler = chatWsHandler;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(chatWsHandler, "/ws/chat").setAllowedOriginPatterns("*");
    }
}
