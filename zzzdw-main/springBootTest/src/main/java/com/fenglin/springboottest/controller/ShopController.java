package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.BizException;
import com.fenglin.springboottest.dto.ShopRequest;
import com.fenglin.springboottest.entity.Post;
import com.fenglin.springboottest.entity.Shop;
import com.fenglin.springboottest.service.PostService;
import com.fenglin.springboottest.service.ShopService;
import com.fenglin.springboottest.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
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
    private final PostService postService;
    private final JwtUtil jwtUtil;

    public ShopController(ShopService shopService, PostService postService, JwtUtil jwtUtil) {
        this.shopService = shopService;
        this.postService = postService;
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

    /** 店铺公开菜品（仅已上架）：GET /api/shops/1/posts */
    @GetMapping("/shops/{id}/posts")
    public List<Post> shopPosts(@PathVariable Long id) {
        // 店铺不存在时先抛 404，避免返回空数组让人误以为「店里没菜」
        shopService.detail(id);
        return shopService.publicPosts(id);
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

    /**
     * 店主上架 / 下架自己的菜品：PATCH /api/shop/posts/12，body: {status: off|approved}
     * <p>
     * 只允许在 approved（已上架）与 off（已下架）之间切换，且只能操作自己发布的菜品；
     * pending（待审核）/ rejected（已驳回）仍由管理员在后台审核，店主不能自行放行。
     */
    @PatchMapping("/shop/posts/{postId}")
    public Post togglePostStatus(@PathVariable Long postId, @RequestBody Map<String, String> body,
                                 HttpServletRequest request) {
        String username = jwtUtil.requireUsername(request);
        Post post = postService.getById(postId);
        if (post == null) {
            throw new BizException(404, "菜品不存在");
        }
        // 归属判断：自己发布的，或已归属到我的店铺（兼容历史数据里由他人代发的菜品）
        Shop myShop = shopService.findByOwnerName(username);
        boolean mine = username.equals(post.getAuthor())
                || (myShop != null && myShop.getShopId().equals(post.getShopId()));
        if (!mine) {
            throw new BizException(403, "只能操作自己店铺的菜品");
        }

        String target = body.get("status");
        if ("off".equals(target)) {
            if (!"approved".equals(post.getStatus())) {
                throw new BizException(400, "只有已上架的菜品可以下架");
            }
            post.setStatus("off");
        } else if ("approved".equals(target)) {
            if (!"off".equals(post.getStatus())) {
                throw new BizException(400, "只有已下架的菜品可以重新上架");
            }
            post.setStatus("approved");
        } else {
            throw new BizException(400, "只能设置为 off（下架）或 approved（上架）");
        }
        postService.updateById(post);
        return post;
    }
}
