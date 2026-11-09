package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.dto.ShopRequest;
import com.fenglin.springboottest.entity.Shop;
import com.fenglin.springboottest.service.ShopService;
import com.fenglin.springboottest.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 店铺接口：店铺列表 / 店铺详情 / 我的店铺（含店内菜品）/ 开店改资料。
 * 店铺名实时读自 shop 表，菜品卡片上的店铺名与之联动。
 */
@RestController
@RequestMapping("/api")
public class ShopController {

    private final ShopService shopService;
    private final JwtUtil jwtUtil;

    public ShopController(ShopService shopService, JwtUtil jwtUtil) {
        this.shopService = shopService;
        this.jwtUtil = jwtUtil;
    }

    /** 店铺列表：GET /api/shops?keyword=面&district=老城区 */
    @GetMapping("/shops")
    public List<Shop> list(@RequestParam(required = false) String keyword,
                           @RequestParam(required = false) String district) {
        return shopService.listShops(keyword, district);
    }

    /** 店铺详情：GET /api/shops/1，不存在返回 404 */
    @GetMapping("/shops/{id}")
    public Shop detail(@PathVariable Long id) {
        return shopService.detail(id);
    }

    /**
     * 我的店铺：GET /api/shop，需要登录。
     * 未开店返回 { "opened": false }（用 200 而非 404，方便前端直接渲染开店引导）；
     * 已开店返回 { "opened": true, "shop": {...}, "posts": [...] }，posts 含待审核菜品。
     */
    @GetMapping("/shop")
    public Map<String, Object> mine(HttpServletRequest request) {
        String username = jwtUtil.requireUsername(request);
        Shop shop = shopService.findByOwnerName(username);
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("opened", shop != null);
        if (shop != null) {
            res.put("shop", shop);
            res.put("posts", shopService.myPosts(username));
        }
        return res;
    }

    /** 开店 / 保存店铺资料：PUT /api/shop，需要登录；未开店则自动创建，店名重复返回 409 */
    @PutMapping("/shop")
    public Shop save(@RequestBody ShopRequest req, HttpServletRequest request) {
        return shopService.saveMine(req, jwtUtil.requireUsername(request));
    }
}
