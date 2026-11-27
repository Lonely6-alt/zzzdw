package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.dto.ExchangeRequest;
import com.fenglin.springboottest.dto.ExchangeResultVO;
import com.fenglin.springboottest.dto.PointsRequest;
import com.fenglin.springboottest.dto.RedeemedRewardVO;
import com.fenglin.springboottest.dto.RewardVO;
import com.fenglin.springboottest.service.GrowthService;
import com.fenglin.springboottest.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * 吃货成长体系接口：积分、好礼目录、兑换记录。
 * 所有接口都需要登录，身份从 Authorization: Bearer <token> 解析。
 */
@RestController
@RequestMapping("/api")
public class GrowthController {

    private final GrowthService growthService;
    private final JwtUtil jwtUtil;

    public GrowthController(GrowthService growthService, JwtUtil jwtUtil) {
        this.growthService = growthService;
        this.jwtUtil = jwtUtil;
    }

    /** 成长体系快照：积分 + 已兑好礼 */
    @GetMapping("/growth/me")
    public Map<String, Object> me(HttpServletRequest request) {
        String username = jwtUtil.requireUsername(request);
        List<RedeemedRewardVO> rewards = growthService.myRewards(username);
        return Map.of(
                "points", growthService.getPoints(username),
                "rewards", rewards,
                "rewardCount", rewards.size()
        );
    }

    /** 行为积分上报：点赞/收藏/评价/发笔记/任务领取 */
    @PostMapping("/growth/points")
    public Map<String, Object> addPoints(HttpServletRequest request, @RequestBody PointsRequest req) {
        String username = jwtUtil.requireUsername(request);
        int delta = req.delta() == null ? 0 : req.delta();
        int points = growthService.addPoints(username, delta);
        return Map.of("points", points);
    }

    /** 可兑换好礼目录 */
    @GetMapping("/rewards")
    public List<RewardVO> rewards() {
        return growthService.activeRewards();
    }

    /** 当前用户已兑好礼 */
    @GetMapping("/rewards/mine")
    public List<RedeemedRewardVO> myRewards(HttpServletRequest request) {
        return growthService.myRewards(jwtUtil.requireUsername(request));
    }

    /** 兑换好礼：事务内扣积分、扣库存、写兑换记录 */
    @PostMapping("/rewards/exchange")
    public ExchangeResultVO exchange(HttpServletRequest request, @RequestBody ExchangeRequest req) {
        String rewardId = req.rewardId() == null ? "" : req.rewardId().trim();
        if (rewardId.isEmpty()) {
            throw new com.fenglin.springboottest.common.BizException(400, "请选择要兑换的好礼");
        }
        return growthService.exchange(jwtUtil.requireUsername(request), rewardId);
    }
}
