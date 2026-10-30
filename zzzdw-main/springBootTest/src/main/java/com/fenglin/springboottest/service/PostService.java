package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.fenglin.springboottest.dto.PostRequest;
import com.fenglin.springboottest.dto.ReviewRequest;
import com.fenglin.springboottest.entity.Post;
import com.fenglin.springboottest.entity.Review;
import com.fenglin.springboottest.vo.HomeVO;

import java.util.List;

/**
 * 美食帖子 Service：在通用 CRUD 之上补充首页展示与搜索相关能力。
 */
public interface PostService extends IService<Post> {

    /**
     * 首页搜索：支持关键词（标题/内容/作者/分类）+ 分级分类（叶子 categoryId 或 一级 parentId）+ 排序 + 分页。
     *
     * @param keyword    关键词，可空
     * @param categoryId 二级叶子分类 ID，可空
     * @param parentId   一级分组 ID（分级分类搜索），可空；命中其下所有叶子
     * @param sort       new=最新 / hot=人气 / rating=好评，默认 new
     * @param page       页码，从 1 开始
     * @param size       每页条数
     */
    Page<Post> search(String keyword, Long categoryId, Long parentId, String sort, long page, long size);

    /** 首页聚合数据：统计 + 分级分类树 + 热门词 + 精选 + 最新 */
    HomeVO getHome();

    /** 发布帖子（作者取自登录用户），并解析分级分类 category_id */
    Post createPost(PostRequest req, String author);

    /** 给帖子写点评，并刷新帖子平均评分与点评数 */
    Review addReview(Long postId, String author, ReviewRequest req);

    /** 某帖子的全部点评（按时间倒序） */
    List<Review> reviews(Long postId);

    /** 全部点评（按 id 倒序，供首页热门点评/排行榜与后台评论管理使用） */
    List<Review> allReviews();

    /** 重新计算帖子的平均评分与点评数（点评增删后调用） */
    void refreshPostStats(Long postId);

    /** 切换收藏状态，刷新收藏数，返回当前是否已收藏 */
    boolean toggleFavorite(Long postId, Long userId);

    /** 某用户的收藏帖子列表（按收藏时间倒序） */
    List<Post> favorites(Long userId);
}
