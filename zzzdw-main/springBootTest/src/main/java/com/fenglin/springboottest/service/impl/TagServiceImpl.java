package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.entity.Tag;
import com.fenglin.springboottest.mapper.TagMapper;
import com.fenglin.springboottest.service.TagService;
import org.springframework.stereotype.Service;

/**
 * 热门标签 Service 实现。
 */
@Service
public class TagServiceImpl extends ServiceImpl<TagMapper, Tag> implements TagService {
}
