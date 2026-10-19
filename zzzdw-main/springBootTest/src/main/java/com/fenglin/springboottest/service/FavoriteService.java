package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.fenglin.springboottest.entity.Favorite;

/**
 * 收藏 Service：继承 IService 即拥有通用 CRUD。
 */
public interface FavoriteService extends IService<Favorite> {
}
