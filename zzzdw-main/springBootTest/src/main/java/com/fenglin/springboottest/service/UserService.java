package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.fenglin.springboottest.entity.User;

/**
 * 用户 Service：继承 IService 即拥有 save/getById/list 等通用方法
 */
public interface UserService extends IService<User> {

    /** 按用户名查询用户，不存在返回 null */
    User findByUsername(String username);
}
