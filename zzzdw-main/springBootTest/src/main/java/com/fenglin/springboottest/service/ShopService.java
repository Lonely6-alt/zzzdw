package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.fenglin.springboottest.dto.ShopRequest;
import com.fenglin.springboottest.entity.Post;
import com.fenglin.springboottest.entity.Shop;

import java.util.List;

/**
 * 店铺 Service：在通用 CRUD 之上补充「我的店铺」相关能力。
 * 店铺与用户一对一（owner_id 唯一），店铺名全局唯一。
 */
public interface ShopService extends IService<Shop> {

    /**
     * 查某个用户名名下的店铺，未开店返回 null。
     * 返回值已回填统计字段（postCount / avgRating / reviewCount / favoriteCount / ownerName）。
     */
    Shop findByOwnerName(String username);

    /** 按 ID 查店铺详情（含统计），不存在抛 404 */
    Shop detail(Long shopId);

    /** 店铺列表：可按店名/简介关键词与商圈筛选，按 ID 倒序；已回填统计 */
    List<Shop> listShops(String keyword, String district);

    /**
     * 开店或修改店铺资料：未开店则创建，已开店则更新。
     * 店名重复抛 409；开店时把该用户此前发布、尚未归属店铺的菜品自动归到新店名下。
     */
    Shop saveMine(ShopRequest req, String username);

    /** 某用户名名下店铺的全部菜品（含待审核，按发布时间倒序）；未开店返回空列表 */
    List<Post> myPosts(String username);
}
