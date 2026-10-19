package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.entity.Category;
import com.fenglin.springboottest.entity.Post;
import com.fenglin.springboottest.mapper.CategoryMapper;
import com.fenglin.springboottest.mapper.PostMapper;
import com.fenglin.springboottest.service.CategoryService;
import com.fenglin.springboottest.vo.CategoryNode;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 分级分类 Service 实现：直接借助 PostMapper 统计每类帖子数，避免与 PostService 形成循环依赖。
 */
@Service
public class CategoryServiceImpl extends ServiceImpl<CategoryMapper, Category> implements CategoryService {

    private final PostMapper postMapper;

    public CategoryServiceImpl(PostMapper postMapper) {
        this.postMapper = postMapper;
    }

    @Override
    public List<CategoryNode> treeWithCounts() {
        List<Category> all = list(new LambdaQueryWrapper<Category>().orderByAsc(Category::getSort));

        // 统计每个叶子分类的帖子数：优先按 category_id 关联，回退按 category 名称匹配
        Map<Long, Integer> countById = new HashMap<>();
        Map<String, Integer> countByName = new HashMap<>();
        for (Post p : postMapper.selectList(null)) {
            if (p.getCategoryId() != null) {
                countById.merge(p.getCategoryId(), 1, Integer::sum);
            }
            if (p.getCategory() != null) {
                countByName.merge(p.getCategory(), 1, Integer::sum);
            }
        }

        // 组装节点
        Map<Long, CategoryNode> nodeMap = new HashMap<>();
        for (Category c : all) {
            CategoryNode node = new CategoryNode();
            node.setId(c.getId());
            node.setName(c.getName());
            node.setParentId(c.getParentId());
            node.setIcon(c.getIcon());
            node.setLevel(c.getLevel());
            node.setChildren(new ArrayList<>());
            // 叶子分类直接取数量；分组分类数量稍后累加
            Integer self = (c.getParentId() != null && c.getParentId() == 0)
                    ? 0
                    : Math.max(countById.getOrDefault(c.getId(), 0), countByName.getOrDefault(c.getName(), 0));
            node.setCount(self);
            nodeMap.put(c.getId(), node);
        }

        // 挂接父子关系并累加分组总数
        List<CategoryNode> roots = new ArrayList<>();
        for (CategoryNode node : nodeMap.values()) {
            if (node.getParentId() != null && node.getParentId() != 0 && nodeMap.containsKey(node.getParentId())) {
                CategoryNode parent = nodeMap.get(node.getParentId());
                parent.getChildren().add(node);
                parent.setCount(parent.getCount() + node.getCount());
            } else {
                roots.add(node);
            }
        }
        // 一级分组按 sort 排序
        roots.sort((a, b) -> Integer.compare(sortOf(all, a.getId()), sortOf(all, b.getId())));
        return roots;
    }

    private int sortOf(List<Category> all, Long id) {
        return all.stream().filter(c -> c.getId().equals(id)).map(Category::getSort).findFirst().orElse(0);
    }
}
