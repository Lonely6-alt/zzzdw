package com.fenglin.springboottest.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fenglin.springboottest.entity.Post;
import com.fenglin.springboottest.service.CategoryService;
import com.fenglin.springboottest.service.PostService;
import com.fenglin.springboottest.vo.CategoryNode;
import com.fenglin.springboottest.vo.HomeVO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 首页与搜索接口：
 *   GET /api/home      首页聚合（统计 + 分级分类树 + 精选 + 最新）
 *   GET /api/search    搜索（关键词 + 分级分类 + 排序 + 分页）
 *   GET /api/categories 分级分类树（带每类帖子数）
 */
@RestController
@RequestMapping("/api")
public class HomeController {

    private final PostService postService;
    private final CategoryService categoryService;

    public HomeController(PostService postService, CategoryService categoryService) {
        this.postService = postService;
        this.categoryService = categoryService;
    }

    /** 首页聚合数据 */
    @GetMapping("/home")
    public HomeVO home() {
        return postService.getHome();
    }

    /**
     * 首页搜索（支持分级分类搜索）：
     *   keyword    关键词
     *   categoryId 二级叶子分类 ID
     *   parentId   一级分组 ID（命中其下所有叶子，即“分级分类搜索”）
     *   sort       new / hot / rating
     *   page,size  分页
     */
    @GetMapping("/search")
    public Map<String, Object> search(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) Long parentId,
            @RequestParam(required = false, defaultValue = "new") String sort,
            @RequestParam(required = false, defaultValue = "1") long page,
            @RequestParam(required = false, defaultValue = "10") long size) {

        Page<Post> pg = postService.search(keyword, categoryId, parentId, sort, page, size);
        Map<String, Object> res = new HashMap<>();
        res.put("list", pg.getRecords());
        res.put("total", pg.getTotal());
        res.put("page", pg.getCurrent());
        res.put("size", pg.getSize());
        res.put("keyword", keyword);
        res.put("categoryId", categoryId);
        res.put("parentId", parentId);
        res.put("sort", sort);
        return res;
    }

    /** 分级分类树（一级分组 → 二级叶子，带每类帖子数），供前端“分级分类”筛选 UI 使用 */
    @GetMapping("/categories")
    public List<CategoryNode> categories() {
        return categoryService.treeWithCounts();
    }
}
