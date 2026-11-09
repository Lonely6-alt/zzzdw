package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.common.BizException;
import com.fenglin.springboottest.dto.ShopRequest;
import com.fenglin.springboottest.entity.Post;
import com.fenglin.springboottest.entity.Shop;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.mapper.PostMapper;
import com.fenglin.springboottest.mapper.ShopMapper;
import com.fenglin.springboottest.service.ShopService;
import com.fenglin.springboottest.service.UserService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 店铺 Service 实现：我的店铺查询 / 开店改资料 / 店铺列表 / 店内菜品。
 */
@Service
public class ShopServiceImpl extends ServiceImpl<ShopMapper, Shop> implements ShopService {

    /** 允许的营业状态：active=营业中 closed=休息 */
    private static final Set<String> STATUS = Set.of("active", "closed");

    private final UserService userService;
    private final PostMapper postMapper;

    public ShopServiceImpl(UserService userService, PostMapper postMapper) {
        this.userService = userService;
        this.postMapper = postMapper;
    }

    @Override
    public Shop findByOwnerName(String username) {
        User owner = userService.findByUsername(username);
        if (owner == null) {
            return null;
        }
        Shop shop = getOne(new LambdaQueryWrapper<Shop>().eq(Shop::getOwnerId, owner.getId()).last("LIMIT 1"), false);
        if (shop != null) {
            fillStats(List.of(shop));
        }
        return shop;
    }

    @Override
    public Shop detail(Long shopId) {
        Shop shop = getById(shopId);
        if (shop == null) {
            throw new BizException(404, "店铺不存在");
        }
        fillStats(List.of(shop));
        return shop;
    }

    @Override
    public List<Shop> listShops(String keyword, String district) {
        LambdaQueryWrapper<Shop> w = new LambdaQueryWrapper<>();
        if (keyword != null && !keyword.isBlank()) {
            String kw = keyword.trim();
            w.and(q -> q.like(Shop::getShopName, kw).or().like(Shop::getDescription, kw));
        }
        if (district != null && !district.isBlank()) {
            w.eq(Shop::getDistrict, district.trim());
        }
        w.orderByDesc(Shop::getShopId);
        List<Shop> shops = list(w);
        fillStats(shops);
        return shops;
    }

    @Override
    @Transactional
    public Shop saveMine(ShopRequest req, String username) {
        User owner = userService.findByUsername(username);
        if (owner == null) {
            throw new BizException(404, "用户不存在");
        }

        String name = req.shopName() == null ? "" : req.shopName().trim();
        if (name.isEmpty()) {
            throw new BizException(400, "店铺名称不能为空");
        }
        if (name.length() > 60) {
            throw new BizException(400, "店铺名称不能超过 60 个字");
        }

        Shop shop = findByOwnerName(username);
        boolean creating = shop == null;

        // 店铺名全局唯一：命中别家店则 409
        Shop same = getOne(new LambdaQueryWrapper<Shop>().eq(Shop::getShopName, name).last("LIMIT 1"), false);
        if (same != null && (creating || !same.getShopId().equals(shop.getShopId()))) {
            throw new BizException(409, "店铺名称「" + name + "」已被占用，换一个吧");
        }

        String status = req.status() == null ? "" : req.status().trim();
        if (!STATUS.contains(status)) {
            // 未传或不合法：开店默认营业中，改资料则保留原状态
            status = creating ? "active" : shop.getStatus();
        }

        if (creating) {
            shop = new Shop();
            shop.setOwnerId(owner.getId());
            shop.setCreateTime(LocalDateTime.now());
        }

        shop.setShopName(name);
        shop.setEmoji(req.emoji() != null && !req.emoji().isBlank()
                ? req.emoji().trim() : (creating ? "🏠" : shop.getEmoji()));
        shop.setDescription(req.description() == null ? shop.getDescription() : req.description().trim());
        shop.setDistrict(req.district() == null ? shop.getDistrict() : req.district().trim());
        shop.setPhone(req.phone() == null ? shop.getPhone() : req.phone().trim());
        shop.setStatus(status);
        shop.setUpdateTime(LocalDateTime.now());

        if (creating) {
            save(shop);
            // 开店前发布的菜品（shop_id 为空）自动归到新店名下，历史内容不至于丢在店外
            postMapper.update(null, new LambdaUpdateWrapper<Post>()
                    .eq(Post::getAuthor, username)
                    .isNull(Post::getShopId)
                    .set(Post::getShopId, shop.getShopId()));
        } else {
            updateById(shop);
        }

        fillStats(List.of(shop));
        return shop;
    }

    @Override
    public List<Post> myPosts(String username) {
        Shop shop = findByOwnerName(username);
        if (shop == null) {
            return new ArrayList<>();
        }
        // 店家视角：待审核的菜品也要能看到，前端用状态标签区分
        return postMapper.selectList(new LambdaQueryWrapper<Post>()
                .eq(Post::getShopId, shop.getShopId())
                .orderByDesc(Post::getCreatedAt)
                .orderByDesc(Post::getId));
    }

    @Override
    public List<Post> publicPosts(Long shopId) {
        // 食客视角：只展示已上架的菜品，下架（off）/待审核/驳回一律不出现
        return postMapper.selectList(new LambdaQueryWrapper<Post>()
                .eq(Post::getShopId, shopId)
                .eq(Post::getStatus, "approved")
                .orderByDesc(Post::getCreatedAt)
                .orderByDesc(Post::getId));
    }

    /** 批量回填店主用户名与店内统计（菜品数 / 均分 / 点评数 / 收藏数） */
    private void fillStats(List<Shop> shops) {
        if (shops == null || shops.isEmpty()) {
            return;
        }
        Set<Long> shopIds = shops.stream().map(Shop::getShopId)
                .filter(Objects::nonNull).collect(Collectors.toSet());
        if (shopIds.isEmpty()) {
            return;
        }

        // 只统计审核通过的菜品，避免待审核内容影响店铺口碑
        List<Post> posts = postMapper.selectList(new LambdaQueryWrapper<Post>()
                .in(Post::getShopId, shopIds)
                .eq(Post::getStatus, "approved"));
        Map<Long, List<Post>> byShop = posts.stream()
                .filter(p -> p.getShopId() != null)
                .collect(Collectors.groupingBy(Post::getShopId));

        Set<Long> ownerIds = shops.stream().map(Shop::getOwnerId)
                .filter(Objects::nonNull).collect(Collectors.toSet());
        Map<Long, String> ownerNames = ownerIds.isEmpty() ? Map.of()
                : userService.listByIds(ownerIds).stream()
                        .collect(Collectors.toMap(User::getId, User::getUsername, (a, b) -> a));

        for (Shop s : shops) {
            List<Post> own = byShop.getOrDefault(s.getShopId(), List.of());
            double avg = own.stream()
                    .map(Post::getRating).filter(Objects::nonNull)
                    .mapToDouble(BigDecimal::doubleValue).average().orElse(0.0);
            s.setPostCount(own.size());
            s.setAvgRating(BigDecimal.valueOf(Math.round(avg * 10.0) / 10.0));
            s.setReviewCount(own.stream()
                    .mapToInt(p -> p.getReviewCount() == null ? 0 : p.getReviewCount()).sum());
            s.setFavoriteCount(own.stream()
                    .mapToInt(p -> p.getFavoriteCount() == null ? 0 : p.getFavoriteCount()).sum());
            s.setOwnerName(ownerNames.get(s.getOwnerId()));
        }
    }
}
