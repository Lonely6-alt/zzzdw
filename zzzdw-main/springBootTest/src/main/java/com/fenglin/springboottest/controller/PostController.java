package com.fenglin.springboottest.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.common.BizException;
import com.fenglin.springboottest.dto.PostRequest;
import com.fenglin.springboottest.dto.ReviewRequest;
import com.fenglin.springboottest.entity.Post;
import com.fenglin.springboottest.entity.Review;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.service.PostService;
import com.fenglin.springboottest.service.UserService;
import com.fenglin.springboottest.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 美食帖子接口：列表 / 详情 / 发布 / 点评 / 收藏。
 * 列表返回 JSON 数组（按 id 倒序，最新在前），发布成功返回 201 + 帖子对象。
 */
@RestController
@RequestMapping("/api")
public class PostController {

    private final PostService postService;
    private final UserService userService;
    private final JwtUtil jwtUtil;

    public PostController(PostService postService, UserService userService, JwtUtil jwtUtil) {
        this.postService = postService;
        this.userService = userService;
        this.jwtUtil = jwtUtil;
    }

    /** 帖子列表（仅展示审核通过的），可按分类筛选：GET /api/posts?category=面食控 */
    @GetMapping("/posts")
    public List<Post> list(@RequestParam(required = false) String category) {
        LambdaQueryWrapper<Post> wrapper = new LambdaQueryWrapper<Post>()
                .eq(Post::getStatus, "approved")
                .eq(category != null && !category.isEmpty(), Post::getCategory, category)
                .orderByDesc(Post::getId);
        return postService.list(wrapper);
    }

    /** 帖子详情：GET /api/posts/1，不存在返回 404 */
    @GetMapping("/posts/{id}")
    public Post detail(@PathVariable Long id) {
        Post post = postService.getById(id);
        if (post == null) {
            throw new BizException(404, "帖子不存在");
        }
        return post;
    }

    /** 发布帖子：POST /api/posts，需要登录（Bearer token），作者取自 token */
    @PostMapping("/posts")
    @ResponseStatus(HttpStatus.CREATED)
    public Post create(@RequestBody PostRequest req, HttpServletRequest request) {
        String author = jwtUtil.requireUsername(request);
        return postService.createPost(req, author);
    }

    /** 某帖子的全部点评：GET /api/posts/1/reviews */
    @GetMapping("/posts/{id}/reviews")
    public List<Review> reviews(@PathVariable Long id) {
        return postService.reviews(id);
    }

    /** 给帖子写点评：POST /api/posts/1/reviews，需要登录 */
    @PostMapping("/posts/{id}/reviews")
    @ResponseStatus(HttpStatus.CREATED)
    public Review addReview(@PathVariable Long id, @RequestBody ReviewRequest req, HttpServletRequest request) {
        String author = jwtUtil.requireUsername(request);
        return postService.addReview(id, author, req);
    }

    /** 全部点评列表（首页热门点评/排行榜用）：GET /api/comments，按 id 倒序 */
    @GetMapping("/comments")
    public List<Review> allComments() {
        return postService.allReviews();
    }

    /** 写点评（兼容前端的 /comments 路径）：POST /api/posts/1/comments，需要登录 */
    @PostMapping("/posts/{id}/comments")
    @ResponseStatus(HttpStatus.CREATED)
    public Review addComment(@PathVariable Long id, @RequestBody ReviewRequest req, HttpServletRequest request) {
        String author = jwtUtil.requireUsername(request);
        return postService.addReview(id, author, req);
    }

    /** 切换收藏状态：POST /api/posts/1/favorite，需要登录；返回当前是否已收藏与最新收藏数 */
    @PostMapping("/posts/{id}/favorite")
    public Map<String, Object> toggleFavorite(@PathVariable Long id, HttpServletRequest request) {
        String username = jwtUtil.requireUsername(request);
        User user = userService.findByUsername(username);
        if (user == null) {
            throw new BizException(404, "用户不存在");
        }
        boolean favorited = postService.toggleFavorite(id, user.getId());
        Post post = postService.getById(id);
        Map<String, Object> res = new HashMap<>();
        res.put("favorited", favorited);
        res.put("favoriteCount", post.getFavoriteCount());
        return res;
    }

    /** 我的收藏列表：GET /api/favorites，需要登录 */
    @GetMapping("/favorites")
    public List<Post> myFavorites(HttpServletRequest request) {
        String username = jwtUtil.requireUsername(request);
        User user = userService.findByUsername(username);
        if (user == null) {
            throw new BizException(404, "用户不存在");
        }
        return postService.favorites(user.getId());
    }
}
