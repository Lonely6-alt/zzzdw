package com.fenglin.springboottest.dto;

/**
 * 积分变动请求：前端行为（点赞/收藏/评价/发笔记/任务领取）上报
 */
public record PointsRequest(Integer delta, String reason) {
}
