package com.fenglin.springboottest.dto;

/**
 * 发布帖子请求体：{ "title": "...", "category": "...", "content": "...", "emoji": "🍜" }
 */
public record PostRequest(String title, String category, String content, String emoji) {
}
