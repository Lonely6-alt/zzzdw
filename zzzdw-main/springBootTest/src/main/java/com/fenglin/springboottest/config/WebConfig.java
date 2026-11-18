package com.fenglin.springboottest.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.io.File;

/**
 * 跨域配置：允许前端开发服务器（如 http://localhost:5173）直接访问后端 /api/**。
 * 注意：开发时 vite 已配置代理（同源），此配置是额外保险，方便前端直连后端调试。
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    /**
     * 静态图片映射：
     * - /api/chat/images/**  → uploads/chat   （聊天发送的图片）
     * - /api/food/images/**  → uploads/food   （笔记/菜品封面图，供 post.image_url 使用）
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String chatDir = new File(System.getProperty("user.dir"), "uploads/chat").getAbsolutePath();
        registry.addResourceHandler("/api/chat/images/**")
                .addResourceLocations("file:" + chatDir + "/");

        String foodDir = new File(System.getProperty("user.dir"), "uploads/food").getAbsolutePath();
        registry.addResourceHandler("/api/food/images/**")
                .addResourceLocations("file:" + foodDir + "/")
                // 封面图很少变动，让客户端与浏览器缓存 7 天，减少重复加载
                .setCachePeriod(604800);
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOriginPatterns("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .maxAge(3600);
    }
}
