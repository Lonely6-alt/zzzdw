package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.entity.Review;
import com.fenglin.springboottest.mapper.ReviewMapper;
import com.fenglin.springboottest.service.ReviewService;
import org.springframework.stereotype.Service;

/**
 * 点评 Service 实现。
 */
@Service
public class ReviewServiceImpl extends ServiceImpl<ReviewMapper, Review> implements ReviewService {
}
