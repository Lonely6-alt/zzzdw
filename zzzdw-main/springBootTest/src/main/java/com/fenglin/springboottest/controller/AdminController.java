package com.fenglin.springboottest.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.common.BizException;
import com.fenglin.springboottest.entity.Category;
import com.fenglin.springboottest.entity.Favorite;
import com.fenglin.springboottest.entity.Post;
import com.fenglin.springboottest.entity.Review;
import com.fenglin.springboottest.entity.Tag;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.service.CategoryService;
import com.fenglin.springboottest.service.FavoriteService;
import com.fenglin.springboottest.service.PostService;
import com.fenglin.springboottest.service.ReviewService;
import com.fenglin.springboottest.service.TagService;
import com.fenglin.springboottest.service.UserService;
import com.fenglin.springboottest.util.JwtUtil;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 后台管理接口（/api/admin/**），全部需要管理员 token（Authorization: Bearer，JWT role=admin）。
 * 覆盖：数据仪表盘 / 用户管理 / 笔记审核 / 分类管理 / 标签管理 / 评论管理。
 * 响应格式与前端 food-login-vue 后台页面约定一致。
 */
@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private static final String DEFAULT_BG = "linear-gradient(140deg,#fdf6ee,#f3e6d6)";

    private final UserService userService;
    private final PostService postService;
    private final ReviewService reviewService;
    private final CategoryService categoryService;
    private final TagService tagService;
    private final FavoriteService favoriteService;
    private final JwtUtil jwtUtil;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    public AdminController(UserService userService, PostService postService, ReviewService reviewService,
                           CategoryService categoryService, TagService tagService,
                           FavoriteService favoriteService, JwtUtil jwtUtil) {
        this.userService = userService;
        this.postService = postService;
        this.reviewService = reviewService;
        this.categoryService = categoryService;
        this.tagService = tagService;
        this.favoriteService = favoriteService;
        this.jwtUtil = jwtUtil;
    }

    // ==================== 数据仪表盘 ====================

    /** 统计数据：GET /api/admin/stats */
    @GetMapping("/stats")
    public Map<String, Object> stats(HttpServletRequest request) {
        requireAdmin(request);
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("users", userService.count());
        res.put("usersActive", userService.count(new LambdaQueryWrapper<User>().eq(User::getStatus, "active")));
        res.put("posts", postService.count());
        res.put("postsPending", postService.count(new LambdaQueryWrapper<Post>().eq(Post::getStatus, "pending")));
        res.put("postsApproved", postService.count(new LambdaQueryWrapper<Post>().eq(Post::getStatus, "approved")));
        res.put("comments", reviewService.count());
        res.put("categories", categoryService.count(new LambdaQueryWrapper<Category>().ne(Category::getParentId, 0)));
        res.put("tags", tagService.count());
        return res;
    }

    // ==================== 用户管理 ====================

    /** 用户列表（不含密码）：GET /api/admin/users */
    @GetMapping("/users")
    public List<Map<String, Object>> users(HttpServletRequest request) {
        requireAdmin(request);
        List<Map<String, Object>> list = new ArrayList<>();
        for (User u : userService.list(new LambdaQueryWrapper<User>().orderByAsc(User::getId))) {
            list.add(userMap(u));
        }
        return list;
    }

    /** 新增用户：POST /api/admin/users，body: {username, password, role} */
    @PostMapping("/users")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> addUser(@RequestBody Map<String, String> body, HttpServletRequest request) {
        requireAdmin(request);
        String username = trim(body.get("username"));
        String password = body.get("password");
        if (username == null || username.length() < 3) {
            throw new BizException(400, "用户名至少 3 个字符");
        }
        if (password == null || password.length() < 6) {
            throw new BizException(400, "密码至少 6 位");
        }
        if (userService.findByUsername(username) != null) {
            throw new BizException(409, "该用户名已存在");
        }
        User u = new User();
        u.setUsername(username);
        u.setPasswordHash(encoder.encode(password));
        u.setRole("admin".equals(body.get("role")) ? "admin" : "user");
        u.setStatus("active");
        u.setCreatedAt(LocalDateTime.now());
        userService.save(u);
        return userMap(u);
    }

    /** 修改用户状态/角色：PATCH /api/admin/users/{username}，body: {status, role} 可选 */
    @PatchMapping("/users/{username}")
    public Map<String, Object> patchUser(@PathVariable String username,
                                         @RequestBody Map<String, String> body,
                                         HttpServletRequest request) {
        requireAdmin(request);
        User u = mustFindUser(username);
        if (body.containsKey("status")) {
            u.setStatus("disabled".equals(body.get("status")) ? "disabled" : "active");
        }
        if (body.containsKey("role")) {
            u.setRole("admin".equals(body.get("role")) ? "admin" : "user");
        }
        userService.updateById(u);
        return userMap(u);
    }

    /** 删除用户：DELETE /api/admin/users/{username}（管理员账号不可删除） */
    @DeleteMapping("/users/{username}")
    public Map<String, Object> deleteUser(@PathVariable String username, HttpServletRequest request) {
        String operator = requireAdmin(request);
        User u = mustFindUser(username);
        if ("admin".equals(u.getRole())) {
            throw new BizException(400, "管理员账号不可删除");
        }
        if (u.getUsername().equals(operator)) {
            throw new BizException(400, "不能删除当前登录账号");
        }
        userService.removeById(u.getId());
        return Map.of("ok", true);
    }

    // ==================== 笔记审核 ====================

    /** 帖子列表（可按状态筛选）：GET /api/admin/posts?status=pending */
    @GetMapping("/posts")
    public List<Post> adminPosts(@RequestParam(required = false) String status, HttpServletRequest request) {
        requireAdmin(request);
        LambdaQueryWrapper<Post> w = new LambdaQueryWrapper<Post>()
                .eq(status != null && !status.isEmpty(), Post::getStatus, status)
                .orderByDesc(Post::getId);
        return postService.list(w);
    }

    /** 审核帖子：PATCH /api/admin/posts/{id}，body: {status: approved/rejected/pending} */
    @PatchMapping("/posts/{id}")
    public Post reviewPost(@PathVariable Long id, @RequestBody Map<String, String> body,
                           HttpServletRequest request) {
        requireAdmin(request);
        String status = body.get("status");
        if (!List.of("approved", "rejected", "pending").contains(status)) {
            throw new BizException(400, "非法的审核状态");
        }
        Post post = postService.getById(id);
        if (post == null) {
            throw new BizException(404, "笔记不存在");
        }
        post.setStatus(status);
        postService.updateById(post);
        return post;
    }

    /** 删除帖子（连同其点评与收藏）：DELETE /api/admin/posts/{id} */
    @DeleteMapping("/posts/{id}")
    public Map<String, Object> deletePost(@PathVariable Long id, HttpServletRequest request) {
        requireAdmin(request);
        if (postService.getById(id) == null) {
            throw new BizException(404, "笔记不存在");
        }
        reviewService.remove(new LambdaQueryWrapper<Review>().eq(Review::getPostId, id));
        favoriteService.remove(new LambdaQueryWrapper<Favorite>().eq(Favorite::getPostId, id));
        postService.removeById(id);
        return Map.of("ok", true);
    }

    // ==================== 分类管理（叶子分类，扁平视图） ====================

    /** 叶子分类列表：GET /api/admin/categories -> [{name, icon, bg}] */
    @GetMapping("/categories")
    public List<Map<String, Object>> adminCategories(HttpServletRequest request) {
        requireAdmin(request);
        List<Map<String, Object>> list = new ArrayList<>();
        for (Category c : leafCategories()) {
            list.add(categoryMap(c));
        }
        return list;
    }

    /** 新增叶子分类：POST /api/admin/categories，body: {name, icon, bg, parentId?} */
    @PostMapping("/categories")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> addCategory(@RequestBody Map<String, String> body, HttpServletRequest request) {
        requireAdmin(request);
        String name = trim(body.get("name"));
        if (name == null || name.isEmpty()) {
            throw new BizException(400, "分类名称不能为空");
        }
        if (categoryService.getOne(new LambdaQueryWrapper<Category>().eq(Category::getName, name), false) != null) {
            throw new BizException(409, "分类已存在");
        }
        Category c = new Category();
        c.setName(name);
        c.setIcon(isBlank(body.get("icon")) ? "🍽️" : body.get("icon"));
        c.setBg(isBlank(body.get("bg")) ? DEFAULT_BG : body.get("bg"));
        c.setLevel(2);
        // 默认挂到第一个一级分组下（前端不传 parentId 时）
        Long parentId = body.get("parentId") != null ? Long.valueOf(body.get("parentId")) : null;
        if (parentId == null) {
            Category first = categoryService.getOne(
                    new LambdaQueryWrapper<Category>().eq(Category::getParentId, 0).orderByAsc(Category::getSort)
                            .last("LIMIT 1"), false);
            parentId = first != null ? first.getId() : 0L;
        }
        c.setParentId(parentId);
        long maxSort = categoryService.list(new LambdaQueryWrapper<Category>().eq(Category::getParentId, parentId))
                .stream().mapToInt(x -> x.getSort() == null ? 0 : x.getSort()).max().orElse(0);
        c.setSort((int) maxSort + 1);
        categoryService.save(c);
        return categoryMap(c);
    }

    /** 编辑分类图标/背景：PUT /api/admin/categories/{name}，body: {icon, bg} 可选 */
    @PutMapping("/categories/{name}")
    public Map<String, Object> putCategory(@PathVariable String name, @RequestBody Map<String, String> body,
                                           HttpServletRequest request) {
        requireAdmin(request);
        Category c = mustFindCategory(name);
        if (!isBlank(body.get("icon"))) {
            c.setIcon(body.get("icon"));
        }
        if (!isBlank(body.get("bg"))) {
            c.setBg(body.get("bg"));
        }
        categoryService.updateById(c);
        return categoryMap(c);
    }

    /** 删除叶子分类，其下帖子归入「未分类」：DELETE /api/admin/categories/{name} */
    @DeleteMapping("/categories/{name}")
    public Map<String, Object> deleteCategory(@PathVariable String name, HttpServletRequest request) {
        requireAdmin(request);
        Category c = mustFindCategory(name);
        if (c.getParentId() == null || c.getParentId() == 0) {
            throw new BizException(400, "一级分组不可删除，请删除其下的叶子分类");
        }
        categoryService.removeById(c.getId());
        // 该分类下的笔记归到「未分类」
        List<Post> posts = postService.list(new LambdaQueryWrapper<Post>().eq(Post::getCategory, name));
        for (Post p : posts) {
            p.setCategory("未分类");
            p.setCategoryId(null);
            postService.updateById(p);
        }
        return Map.of("ok", true);
    }

    // ==================== 标签管理 ====================

    /** 标签列表（按热度倒序）：GET /api/admin/tags */
    @GetMapping("/tags")
    public List<Tag> adminTags(HttpServletRequest request) {
        requireAdmin(request);
        return tagService.list(new LambdaQueryWrapper<Tag>().orderByDesc(Tag::getHeat));
    }

    /** 新增标签：POST /api/admin/tags，body: {name} */
    @PostMapping("/tags")
    @ResponseStatus(HttpStatus.CREATED)
    public Tag addTag(@RequestBody Map<String, String> body, HttpServletRequest request) {
        requireAdmin(request);
        String name = trim(body.get("name"));
        if (name == null || name.isEmpty()) {
            throw new BizException(400, "标签名称不能为空");
        }
        if (tagService.getOne(new LambdaQueryWrapper<Tag>().eq(Tag::getName, name), false) != null) {
            throw new BizException(409, "标签已存在");
        }
        Tag t = new Tag();
        t.setName(name);
        t.setHeat(0);
        tagService.save(t);
        return t;
    }

    /** 删除标签：DELETE /api/admin/tags/{name} */
    @DeleteMapping("/tags/{name}")
    public Map<String, Object> deleteTag(@PathVariable String name, HttpServletRequest request) {
        requireAdmin(request);
        Tag t = tagService.getOne(new LambdaQueryWrapper<Tag>().eq(Tag::getName, name), false);
        if (t == null) {
            throw new BizException(404, "标签不存在");
        }
        tagService.removeById(t.getId());
        return Map.of("ok", true);
    }

    // ==================== 评论管理 ====================

    /** 全部评论（含所属帖子标题）：GET /api/admin/comments */
    @GetMapping("/comments")
    public List<Map<String, Object>> adminComments(HttpServletRequest request) {
        requireAdmin(request);
        List<Map<String, Object>> list = new ArrayList<>();
        for (Review r : reviewService.list(new LambdaQueryWrapper<Review>().orderByDesc(Review::getId))) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", r.getId());
            m.put("postId", r.getPostId());
            m.put("author", r.getAuthor());
            m.put("rating", r.getRating());
            m.put("comment", r.getComment());
            m.put("createdAt", r.getCreatedAt());
            Post post = postService.getById(r.getPostId());
            m.put("postTitle", post != null ? post.getTitle() : "（笔记已删除）");
            list.add(m);
        }
        return list;
    }

    /** 删除评论（并刷新帖子评分）：DELETE /api/admin/comments/{id} */
    @DeleteMapping("/comments/{id}")
    public Map<String, Object> deleteComment(@PathVariable Long id, HttpServletRequest request) {
        requireAdmin(request);
        Review r = reviewService.getById(id);
        if (r == null) {
            throw new BizException(404, "评论不存在");
        }
        reviewService.removeById(id);
        postService.refreshPostStats(r.getPostId());
        return Map.of("ok", true);
    }

    // ==================== 私有工具 ====================

    private String requireAdmin(HttpServletRequest request) {
        return jwtUtil.requireAdmin(request);
    }

    private User mustFindUser(String username) {
        User u = userService.findByUsername(username);
        if (u == null) {
            throw new BizException(404, "用户不存在");
        }
        return u;
    }

    private Category mustFindCategory(String name) {
        Category c = categoryService.getOne(new LambdaQueryWrapper<Category>().eq(Category::getName, name), false);
        if (c == null) {
            throw new BizException(404, "分类不存在");
        }
        return c;
    }

    private List<Category> leafCategories() {
        return categoryService.list(new LambdaQueryWrapper<Category>()
                .ne(Category::getParentId, 0).orderByAsc(Category::getSort).orderByAsc(Category::getId));
    }

    private Map<String, Object> userMap(User u) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("username", u.getUsername());
        m.put("role", u.getRole());
        m.put("status", u.getStatus());
        m.put("createdAt", u.getCreatedAt());
        return m;
    }

    private Map<String, Object> categoryMap(Category c) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("name", c.getName());
        m.put("icon", c.getIcon());
        m.put("bg", isBlank(c.getBg()) ? DEFAULT_BG : c.getBg());
        return m;
    }

    private static String trim(String s) {
        return s == null ? null : s.trim();
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
