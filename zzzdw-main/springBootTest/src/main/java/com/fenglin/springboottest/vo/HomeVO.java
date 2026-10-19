package com.fenglin.springboottest.vo;

import com.fenglin.springboottest.entity.Post;
import lombok.Data;

import java.util.List;
import java.util.Map;

/**
 * 首页聚合响应：统计 + 分级分类树 + 热门搜索词 + 今日精选 + 最新上架。
 */
@Data
public class HomeVO {

    /** 站点统计：posts / authors / reviews / categories */
    private Map<String, Object> stats;

    /** 热门搜索词 */
    private List<String> hotWords;

    /** 分级分类树（一级分组 → 二级叶子，带每类帖子数） */
    private List<CategoryNode> categories;

    /** 今日精选（按评分/点评数取前 N） */
    private List<Post> featured;

    /** 最新上架（按发布时间取前 N） */
    private List<Post> latest;
}
