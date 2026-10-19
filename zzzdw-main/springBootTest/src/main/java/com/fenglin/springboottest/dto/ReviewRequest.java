package com.fenglin.springboottest.dto;

/**
 * 提交点评请求体：{ "rating": 5, "comment": "汤头绝了" }
 */
public record ReviewRequest(Integer rating, String comment) {
}
