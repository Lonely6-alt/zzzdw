package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.common.BizException;
import com.fenglin.springboottest.dto.PostRequest;
import com.fenglin.springboottest.dto.ReviewRequest;
import com.fenglin.springboottest.entity.Category;
import com.fenglin.springboottest.entity.Favorite;
import com.fenglin.springboottest.entity.Post;
import com.fenglin.springboottest.entity.Review;
import com.fenglin.springboottest.mapper.PostMapper;
import com.fenglin.springboottest.service.CategoryService;
import com.fenglin.springboottest.service.FavoriteService;
import com.fenglin.springboottest.service.PostService;
import com.fenglin.springboottest.service.ReviewService;
import com.fenglin.springboottest.vo.HomeVO;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * 美食帖子 Service 实现：搜索 / 首页聚合 / 发布 / 点评 / 收藏。
 */
@Service
public class PostServiceImpl extends ServiceImpl<PostMapper, Post> implements PostService {

    private final CategoryService categoryService;
    private final ReviewService reviewService;
    private final FavoriteService favoriteService;

    public PostServiceImpl(CategoryService categoryService,
                           ReviewService reviewService,
                           FavoriteService favoriteService) {
        this.categoryService = categoryService;
        this.reviewService = reviewService;
        this.favoriteService = favoriteService;
    }

    @Override
    public Page<Post> search(String keyword, Long categoryId, Long parentId, String sort, long page, long size) {
        LambdaQueryWrapper<Post> w = new LambdaQueryWrapper<>();

        // 仅展示审核通过的帖子
        w.eq(Post::getStatus, "approved");

        // 关键词：标题/内容/作者/分类 任意包含即命中
        if (keyword != null && !keyword.trim().isEmpty()) {
            String kw = keyword.trim();
            w.and(q -> q.like(Post::getTitle, kw)
                    .or().like(Post::getContent, kw)
                    .or().like(Post::getAuthor, kw)
                    .or().like(Post::getCategory, kw));
        }

        // 分级分类：指定叶子分类，或指定一级分组（命中其下所有叶子）
        if (categoryId != null) {
            w.eq(Post::getCategoryId, categoryId);
        } else if (parentId != null) {
            List<Category> leaves = categoryService.list(
                    new LambdaQueryWrapper<Category>().eq(Category::getParentId, parentId));
            List<Long> ids = leaves.stream().map(Category::getId).collect(Collectors.toList());
            List<String> names = leaves.stream().map(Category::getName).collect(Collectors.toList());
            if (ids.isEmpty()) {
                w.eq(Post::getCategoryId, -1L); // 无匹配叶子，返回空集
            } else {
                w.and(q -> q.in(Post::getCategoryId, ids).or().in(Post::getCategory, names));
            }
        }

        // 排序
        String s = (sort == null || sort.isEmpty()) ? "new" : sort;
        if ("hot".equals(s)) {
            w.orderByDesc(Post::getReviewCount).orderByDesc(Post::getOrderCount);
        } else if ("rating".equals(s)) {
            w.orderByDesc(Post::getRating).orderByDesc(Post::getReviewCount);
        } else {
            w.orderByDesc(Post::getCreatedAt);
        }

        // 手动分页（MyBatis-Plus 3.5.9 不再内置 PaginationInnerInterceptor）：
        // 先 count 得到总数，再 LIMIT 取当前页。
        long current = page < 1 ? 1 : page;
        long pageSize = size < 1 ? 10 : size;
        long total = count(w);
        long offset = (current - 1) * pageSize;
        w.last("LIMIT " + offset + ", " + pageSize);
        List<Post> records = list(w);

        Page<Post> pg = new Page<>(current, pageSize, total);
        pg.setRecords(records);
        return pg;
    }

    @Override
    public HomeVO getHome() {
        HomeVO vo = new HomeVO();

        long posts = count();
        long authors = list().stream().map(Post::getAuthor).filter(Objects::nonNull).distinct().count();
        long reviews = reviewService.count();
        long leafCats = categoryService.count(new LambdaQueryWrapper<Category>().ne(Category::getParentId, 0));

        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("posts", posts);
        stats.put("authors", authors);
        stats.put("reviews", reviews);
        stats.put("categories", leafCats);
        vo.setStats(stats);

        vo.setHotWords(Arrays.asList("拉面", "寿司", "炸鸡", "抹茶", "拿铁", "火锅", "轻食", "烧烤"));
        vo.setCategories(categoryService.treeWithCounts());
        vo.setFeatured(featured(6));
        vo.setLatest(latest(8));
        return vo;
    }

    @Override
    public Post createPost(PostRequest req, String author) {
        String title = req.title() == null ? "" : req.title().trim();
        String category = req.category() == null ? "" : req.category().trim();
        String content = req.content() == null ? "" : req.content().trim();
        String emoji = (req.emoji() == null || req.emoji().isBlank()) ? "🍴" : req.emoji();

        if (title.isEmpty() || category.isEmpty() || content.isEmpty()) {
            throw new BizException(400, "标题、分类、内容都不能为空");
        }

        // 解析分级分类 category_id：优先按叶子分类名匹配，回退按任意分类名匹配
        Long catId = null;
        Category leaf = categoryService.getOne(
                new LambdaQueryWrapper<Category>().eq(Category::getName, category).eq(Category::getParentId, 0L), false);
        if (leaf == null) {
            leaf = categoryService.getOne(new LambdaQueryWrapper<Category>().eq(Category::getName, category), false);
        }
        if (leaf != null) {
            catId = leaf.getId();
        }

        Post post = new Post();
        post.setTitle(title);
        post.setCategory(category);
        post.setCategoryId(catId);
        post.setAuthor(author);
        post.setEmoji(emoji);
        post.setContent(content);
        post.setRating(BigDecimal.ZERO);
        post.setReviewCount(0);
        post.setFavoriteCount(0);
        post.setOrderCount(0);
        post.setStatus("pending"); // 新帖需后台审核通过后展示
        post.setCreatedAt(LocalDateTime.now());
        save(post);
        return post;
    }

    @Override
    public Review addReview(Long postId, String author, ReviewRequest req) {
        if (getById(postId) == null) {
            throw new BizException(404, "帖子不存在");
        }
        Integer rating = req.rating();
        if (rating == null || rating < 1 || rating > 5) {
            throw new BizException(400, "评分需在 1~5 之间");
        }
        Review r = new Review();
        r.setPostId(postId);
        r.setAuthor(author);
        r.setRating(rating);
        r.setComment(req.comment() == null ? "" : req.comment().trim());
        r.setCreatedAt(LocalDateTime.now());
        reviewService.save(r);
        recompute(postId);
        return r;
    }

    @Override
    public List<Review> reviews(Long postId) {
        return reviewService.list(
                new LambdaQueryWrapper<Review>().eq(Review::getPostId, postId).orderByDesc(Review::getCreatedAt));
    }

    @Override
    public List<Review> allReviews() {
        return reviewService.list(new LambdaQueryWrapper<Review>().orderByDesc(Review::getId));
    }

    @Override
    public void refreshPostStats(Long postId) {
        recompute(postId);
    }

    @Override
    public boolean toggleFavorite(Long postId, Long userId) {
        if (getById(postId) == null) {
            throw new BizException(404, "帖子不存在");
        }
        LambdaQueryWrapper<Favorite> q = new LambdaQueryWrapper<Favorite>()
                .eq(Favorite::getUserId, userId).eq(Favorite::getPostId, postId);
        Favorite exist = favoriteService.getOne(q, false);

        boolean favorited;
        if (exist == null) {
            Favorite f = new Favorite();
            f.setUserId(userId);
            f.setPostId(postId);
            f.setCreatedAt(LocalDateTime.now());
            favoriteService.save(f);
            favorited = true;
        } else {
            favoriteService.removeById(exist.getId());
            favorited = false;
        }

        long cnt = favoriteService.count(new LambdaQueryWrapper<Favorite>().eq(Favorite::getPostId, postId));
        Post post = getById(postId);
        post.setFavoriteCount((int) cnt);
        updateById(post);
        return favorited;
    }

    @Override
    public List<Post> favorites(Long userId) {
        List<Favorite> fs = favoriteService.list(
                new LambdaQueryWrapper<Favorite>().eq(Favorite::getUserId, userId).orderByDesc(Favorite::getCreatedAt));
        if (fs.isEmpty()) {
            return new ArrayList<>();
        }
        List<Long> ids = fs.stream().map(Favorite::getPostId).collect(Collectors.toList());
        return new ArrayList<>(listByIds(ids));
    }

    /** 根据点评重新计算帖子的平均评分与点评数 */
    private void recompute(Long postId) {
        Post p = getById(postId);
        if (p == null) {
            return;
        }
        List<Review> rs = reviewService.list(new LambdaQueryWrapper<Review>().eq(Review::getPostId, postId));
        int n = rs.size();
        double avg = rs.stream().mapToInt(Review::getRating).average().orElse(0.0);
        p.setReviewCount(n);
        p.setRating(BigDecimal.valueOf(Math.round(avg * 10.0) / 10.0));
        updateById(p);
    }

    private List<Post> featured(int n) {
        // 优先展示管理员置顶的「今日精选」（featured=1），其余按评分/点评数补足；仅展示审核通过的
        List<Post> pinned = list(new LambdaQueryWrapper<Post>()
                .eq(Post::getFeatured, 1)
                .eq(Post::getStatus, "approved")
                .orderByDesc(Post::getRating).orderByDesc(Post::getReviewCount));
        if (pinned.size() >= n) {
            return pinned.stream().limit(n).collect(Collectors.toList());
        }
        List<Post> rest = list(new LambdaQueryWrapper<Post>()
                .ne(Post::getFeatured, 1)
                .eq(Post::getStatus, "approved")
                .orderByDesc(Post::getRating).orderByDesc(Post::getReviewCount));
        List<Post> combined = new java.util.ArrayList<>(pinned);
        combined.addAll(rest);
        return combined.stream().limit(n).collect(Collectors.toList());
    }

    private List<Post> latest(int n) {
        return list(new LambdaQueryWrapper<Post>()
                .eq(Post::getStatus, "approved")
                .orderByDesc(Post::getCreatedAt)
                .last("LIMIT " + n));
    }
}
