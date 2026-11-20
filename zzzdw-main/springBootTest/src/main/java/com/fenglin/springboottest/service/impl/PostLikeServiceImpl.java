package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.entity.PostLike;
import com.fenglin.springboottest.mapper.PostLikeMapper;
import com.fenglin.springboottest.service.PostLikeService;
import org.springframework.stereotype.Service;

/**
 * 点赞 Service 实现。
 */
@Service
public class PostLikeServiceImpl extends ServiceImpl<PostLikeMapper, PostLike> implements PostLikeService {
}
