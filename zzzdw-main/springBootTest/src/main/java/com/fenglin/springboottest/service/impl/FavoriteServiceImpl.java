package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.entity.Favorite;
import com.fenglin.springboottest.mapper.FavoriteMapper;
import com.fenglin.springboottest.service.FavoriteService;
import org.springframework.stereotype.Service;

/**
 * 收藏 Service 实现。
 */
@Service
public class FavoriteServiceImpl extends ServiceImpl<FavoriteMapper, Favorite> implements FavoriteService {
}
