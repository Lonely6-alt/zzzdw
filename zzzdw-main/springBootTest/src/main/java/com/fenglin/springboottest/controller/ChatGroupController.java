package com.fenglin.springboottest.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.common.BizException;
import com.fenglin.springboottest.entity.ChatGroup;
import com.fenglin.springboottest.entity.ChatGroupMember;
import com.fenglin.springboottest.entity.ChatGroupMessage;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.mapper.ChatGroupMapper;
import com.fenglin.springboottest.mapper.ChatGroupMemberMapper;
import com.fenglin.springboottest.mapper.ChatGroupMessageMapper;
import com.fenglin.springboottest.service.FriendService;
import com.fenglin.springboottest.service.UserService;
import com.fenglin.springboottest.util.JwtUtil;
import com.fenglin.springboottest.ws.ChatWsHandler;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 群聊接口（与私信接口 /api/chat/** 同前缀，路径不重叠）：
 * - GET  /api/chat/contacts                 可邀请的用户列表（建群选人用）
 * - GET  /api/chat/groups                   我加入的群（含未读数）
 * - GET  /api/chat/groups/{id}              群详情（含成员列表）
 * - POST /api/chat/groups                   建群 { groupName, emoji, memberIds }
 * - GET  /api/chat/groups/{id}/messages     群消息记录（拉取即推进已读位）
 * - POST /api/chat/groups/{id}/messages     群发消息，并实时推送
 */
@RestController
@RequestMapping("/api/chat")
public class ChatGroupController {

    private final ChatGroupMapper groupMapper;
    private final ChatGroupMemberMapper memberMapper;
    private final ChatGroupMessageMapper messageMapper;
    private final UserService userService;
    private final FriendService friendService;
    private final JwtUtil jwtUtil;
    private final ChatWsHandler ws;

    public ChatGroupController(ChatGroupMapper groupMapper, ChatGroupMemberMapper memberMapper,
                               ChatGroupMessageMapper messageMapper, UserService userService,
                               FriendService friendService, JwtUtil jwtUtil, ChatWsHandler ws) {
        this.groupMapper = groupMapper;
        this.memberMapper = memberMapper;
        this.messageMapper = messageMapper;
        this.userService = userService;
        this.friendService = friendService;
        this.jwtUtil = jwtUtil;
        this.ws = ws;
    }

    /** 当前登录用户 */
    private User currentUser(HttpServletRequest request) {
        User user = userService.findByUsername(jwtUtil.requireUsername(request));
        if (user == null) {
            throw new BizException(404, "用户不存在");
        }
        return user;
    }

    /** 校验我是群成员，返回成员记录 */
    private ChatGroupMember requireMember(Long groupId, Long userId) {
        ChatGroup g = groupMapper.selectById(groupId);
        if (g == null) {
            throw new BizException(404, "群聊不存在");
        }
        ChatGroupMember m = memberMapper.selectOne(new LambdaQueryWrapper<ChatGroupMember>()
                .eq(ChatGroupMember::getGroupId, groupId)
                .eq(ChatGroupMember::getUserId, userId)
                .last("LIMIT 1"));
        if (m == null) {
            throw new BizException(403, "无权访问该群聊");
        }
        return m;
    }

    /** 可邀请的用户：仅限我的好友（最多 100 个） */
    @GetMapping("/contacts")
    public List<Map<String, Object>> contacts(HttpServletRequest request) {
        Long me = currentUser(request).getId();
        List<Map<String, Object>> friends = friendService.listFriends(me);
        if (friends.size() > 100) {
            friends = friends.subList(0, 100);
        }
        return friends;
    }

    /** 我加入的群列表：GET /api/chat/groups */
    @GetMapping("/groups")
    public List<Map<String, Object>> groups(HttpServletRequest request) {
        Long me = currentUser(request).getId();
        List<ChatGroupMember> mine = memberMapper.selectList(
                new LambdaQueryWrapper<ChatGroupMember>().eq(ChatGroupMember::getUserId, me));
        if (mine.isEmpty()) {
            return List.of();
        }
        Set<Long> gids = mine.stream().map(ChatGroupMember::getGroupId).collect(Collectors.toCollection(LinkedHashSet::new));
        List<ChatGroup> groups = groupMapper.selectBatchIds(gids);
        Map<Long, ChatGroupMember> memberOf = mine.stream()
                .collect(Collectors.toMap(ChatGroupMember::getGroupId, m -> m, (a, b) -> a));

        List<Map<String, Object>> res = new ArrayList<>();
        for (ChatGroup g : groups) {
            ChatGroupMember m = memberOf.get(g.getGroupId());
            long base = m == null || m.getLastReadMsgId() == null ? 0L : m.getLastReadMsgId();
            Long unread = messageMapper.selectCount(new LambdaQueryWrapper<ChatGroupMessage>()
                    .eq(ChatGroupMessage::getGroupId, g.getGroupId())
                    .gt(ChatGroupMessage::getMsgId, base)
                    .ne(ChatGroupMessage::getSenderId, me));
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("groupId", g.getGroupId());
            item.put("groupName", g.getGroupName());
            item.put("emoji", g.getEmoji());
            item.put("notice", g.getNotice());
            item.put("ownerId", g.getOwnerId());
            item.put("lastMsg", g.getLastMsg() == null ? "" : g.getLastMsg());
            item.put("lastTime", g.getLastTime() == null ? g.getCreateTime() : g.getLastTime());
            item.put("unread", unread == null ? 0 : unread);
            res.add(item);
        }
        // 最近有消息的群排在前面
        res.sort((a, b) -> String.valueOf(b.get("lastTime")).compareTo(String.valueOf(a.get("lastTime"))));
        return res;
    }

    /** 群详情（含成员列表）：GET /api/chat/groups/1 */
    @GetMapping("/groups/{id}")
    public Map<String, Object> groupDetail(@PathVariable Long id, HttpServletRequest request) {
        Long me = currentUser(request).getId();
        requireMember(id, me);
        ChatGroup g = groupMapper.selectById(id);

        List<ChatGroupMember> members = memberMapper.selectList(
                new LambdaQueryWrapper<ChatGroupMember>().eq(ChatGroupMember::getGroupId, id));
        Set<Long> uids = members.stream().map(ChatGroupMember::getUserId).collect(Collectors.toSet());
        Map<Long, String> names = uids.isEmpty() ? Map.of()
                : userService.listByIds(uids).stream()
                        .collect(Collectors.toMap(User::getId, User::getUsername, (a, b) -> a));

        List<Map<String, Object>> memberList = new ArrayList<>();
        for (ChatGroupMember m : members) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("userId", m.getUserId());
            item.put("username", names.getOrDefault(m.getUserId(), "未知用户"));
            item.put("role", m.getRole());
            memberList.add(item);
        }

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("groupId", g.getGroupId());
        res.put("groupName", g.getGroupName());
        res.put("emoji", g.getEmoji());
        res.put("notice", g.getNotice());
        res.put("ownerId", g.getOwnerId());
        res.put("lastMsg", g.getLastMsg());
        res.put("lastTime", g.getLastTime());
        res.put("members", memberList);
        return res;
    }

    /** 建群：POST /api/chat/groups，body: { groupName, emoji, memberIds: [1,2] } */
    @PostMapping("/groups")
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public Map<String, Object> createGroup(@RequestBody Map<String, Object> body, HttpServletRequest request) {
        User me = currentUser(request);

        String name = body.get("groupName") == null ? "" : String.valueOf(body.get("groupName")).trim();
        if (name.length() < 2) {
            throw new BizException(400, "群名称至少 2 个字");
        }
        if (name.length() > 30) {
            throw new BizException(400, "群名称最多 30 个字");
        }
        String emoji = body.get("emoji") == null || String.valueOf(body.get("emoji")).isBlank()
                ? "👥" : String.valueOf(body.get("emoji")).trim();

        Set<Long> memberIds = new LinkedHashSet<>();
        Object raw = body.get("memberIds");
        if (raw instanceof List<?> list) {
            for (Object o : list) {
                if (o == null) {
                    continue;
                }
                try {
                    memberIds.add(Long.parseLong(String.valueOf(o)));
                } catch (NumberFormatException ignore) {
                    // 非法 ID 直接跳过
                }
            }
        }
        memberIds.remove(me.getId());
        if (memberIds.isEmpty()) {
            throw new BizException(400, "至少选择一位群成员");
        }

        ChatGroup g = new ChatGroup();
        g.setGroupName(name);
        g.setOwnerId(me.getId());
        g.setEmoji(emoji);
        g.setCreateTime(LocalDateTime.now());
        g.setLastTime(LocalDateTime.now());
        groupMapper.insert(g);

        ChatGroupMember owner = new ChatGroupMember();
        owner.setGroupId(g.getGroupId());
        owner.setUserId(me.getId());
        owner.setRole("owner");
        owner.setJoinTime(LocalDateTime.now());
        owner.setLastReadMsgId(0L);
        memberMapper.insert(owner);

        for (Long uid : memberIds) {
            ChatGroupMember m = new ChatGroupMember();
            m.setGroupId(g.getGroupId());
            m.setUserId(uid);
            m.setRole("member");
            m.setJoinTime(LocalDateTime.now());
            m.setLastReadMsgId(0L);
            memberMapper.insert(m);
        }

        // 通知被拉进群的成员刷新列表
        List<Long> all = new ArrayList<>(memberIds);
        all.add(me.getId());
        Map<String, Object> event = new HashMap<>();
        event.put("type", "group_members");
        event.put("groupId", g.getGroupId());
        ws.push(all, event);

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("groupId", g.getGroupId());
        res.put("groupName", g.getGroupName());
        res.put("emoji", g.getEmoji());
        return res;
    }

    /** 群消息记录：GET /api/chat/groups/1/messages，同时把我的已读位推到最新 */
    @GetMapping("/groups/{id}/messages")
    public List<ChatGroupMessage> messages(@PathVariable Long id, HttpServletRequest request) {
        Long me = currentUser(request).getId();
        ChatGroupMember member = requireMember(id, me);

        List<ChatGroupMessage> list = messageMapper.selectList(new LambdaQueryWrapper<ChatGroupMessage>()
                .eq(ChatGroupMessage::getGroupId, id)
                .orderByAsc(ChatGroupMessage::getMsgId));
        if (!list.isEmpty()) {
            Long latest = list.get(list.size() - 1).getMsgId();
            if (latest != null && (member.getLastReadMsgId() == null || latest > member.getLastReadMsgId())) {
                member.setLastReadMsgId(latest);
                memberMapper.updateById(member);
            }
        }
        return list;
    }

    /** 群发消息：POST /api/chat/groups/1/messages，body: { content } */
    @PostMapping("/groups/{id}/messages")
    @ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public ChatGroupMessage send(@PathVariable Long id, @RequestBody Map<String, String> body,
                                 HttpServletRequest request) {
        User me = currentUser(request);
        requireMember(id, me.getId());

        String content = body.get("content");
        if (content == null || content.isBlank()) {
            throw new BizException(400, "消息内容不能为空");
        }
        content = content.trim();
        if (content.length() > 1000) {
            content = content.substring(0, 1000);
        }

        ChatGroupMessage msg = new ChatGroupMessage();
        msg.setGroupId(id);
        msg.setSenderId(me.getId());
        msg.setContent(content);
        msg.setSendTime(LocalDateTime.now());
        messageMapper.insert(msg);

        // 同步群摘要
        ChatGroup g = groupMapper.selectById(id);
        if (g != null) {
            g.setLastMsg(content);
            g.setLastTime(msg.getSendTime());
            groupMapper.updateById(g);
        }

        // 实时推送：群内所有成员（含自己，多端同步）
        List<ChatGroupMember> members = memberMapper.selectList(
                new LambdaQueryWrapper<ChatGroupMember>().eq(ChatGroupMember::getGroupId, id));
        List<Long> uids = members.stream().map(ChatGroupMember::getUserId).collect(Collectors.toList());

        Map<String, Object> msgVo = new HashMap<>();
        msgVo.put("msgId", msg.getMsgId());
        msgVo.put("groupId", id);
        msgVo.put("senderId", me.getId());
        msgVo.put("content", content);
        msgVo.put("sendTime", msg.getSendTime()
                .format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss")));

        Map<String, Object> event = new HashMap<>();
        event.put("type", "group");
        event.put("groupId", id);
        event.put("senderName", me.getUsername());
        event.put("msg", msgVo);
        ws.push(uids, event);
        return msg;
    }

    /**
     * 撤回自己发的群消息：POST /api/chat/groups/{id}/messages/{msgId}/recall
     * 仅发送者可撤回，限发送后 2 分钟内；软删除，内容标记为 [RECALLED]。
     */
    @PostMapping("/groups/{id}/messages/{msgId}/recall")
    @Transactional
    public Map<String, Object> recallMessage(@PathVariable Long id, @PathVariable Long msgId,
                                             HttpServletRequest request) {
        User me = currentUser(request);
        requireMember(id, me.getId());
        ChatGroupMessage msg = messageMapper.selectById(msgId);
        if (msg == null || !id.equals(msg.getGroupId())) {
            throw new BizException(404, "消息不存在");
        }
        if (!me.getId().equals(msg.getSenderId())) {
            throw new BizException(403, "只能撤回自己发送的消息");
        }
        if (msg.getSendTime() != null
                && msg.getSendTime().isBefore(LocalDateTime.now().minusMinutes(2))) {
            throw new BizException(400, "超过 2 分钟的消息不能撤回");
        }
        ChatGroupMessage recalled = new ChatGroupMessage();
        recalled.setMsgId(msgId);
        recalled.setContent("[RECALLED]");
        messageMapper.updateById(recalled);

        // 群摘要同步为撤回提示
        ChatGroup g = groupMapper.selectById(id);
        if (g != null) {
            ChatGroupMessage last = messageMapper.selectOne(new LambdaQueryWrapper<ChatGroupMessage>()
                    .eq(ChatGroupMessage::getGroupId, id)
                    .orderByDesc(ChatGroupMessage::getMsgId)
                    .last("LIMIT 1"));
            g.setLastMsg(last == null ? "" : last.getContent());
            g.setLastTime(last == null ? null : last.getSendTime());
            groupMapper.updateById(g);
        }

        List<ChatGroupMember> members = memberMapper.selectList(
                new LambdaQueryWrapper<ChatGroupMember>().eq(ChatGroupMember::getGroupId, id));
        List<Long> uids = members.stream().map(ChatGroupMember::getUserId).collect(Collectors.toList());
        Map<String, Object> event = new HashMap<>();
        event.put("type", "group_recalled");
        event.put("groupId", id);
        event.put("msgId", msgId);
        event.put("senderName", me.getUsername());
        ws.push(uids, event);

        Map<String, Object> res = new HashMap<>();
        res.put("recalled", true);
        res.put("msgId", msgId);
        return res;
    }

    /** 删除自己发的群消息：DELETE /api/chat/groups/{id}/messages/{msgId} */
    @DeleteMapping("/groups/{id}/messages/{msgId}")
    @Transactional
    public Map<String, Object> deleteMessage(@PathVariable Long id, @PathVariable Long msgId,
                                             HttpServletRequest request) {
        User me = currentUser(request);
        requireMember(id, me.getId());
        ChatGroupMessage msg = messageMapper.selectById(msgId);
        if (msg == null || !id.equals(msg.getGroupId())) {
            throw new BizException(404, "消息不存在");
        }
        if (!me.getId().equals(msg.getSenderId())) {
            throw new BizException(403, "只能删除自己发送的消息");
        }
        messageMapper.deleteById(msgId);

        // 群摘要回退到最后一条剩余消息
        ChatGroup g = groupMapper.selectById(id);
        if (g != null) {
            ChatGroupMessage last = messageMapper.selectOne(new LambdaQueryWrapper<ChatGroupMessage>()
                    .eq(ChatGroupMessage::getGroupId, id)
                    .orderByDesc(ChatGroupMessage::getMsgId)
                    .last("LIMIT 1"));
            g.setLastMsg(last == null ? "" : last.getContent());
            g.setLastTime(last == null ? null : last.getSendTime());
            groupMapper.updateById(g);
        }

        List<ChatGroupMember> members = memberMapper.selectList(
                new LambdaQueryWrapper<ChatGroupMember>().eq(ChatGroupMember::getGroupId, id));
        List<Long> uids = members.stream().map(ChatGroupMember::getUserId).collect(Collectors.toList());
        Map<String, Object> event = new HashMap<>();
        event.put("type", "group_deleted");
        event.put("groupId", id);
        event.put("msgId", msgId);
        ws.push(uids, event);

        Map<String, Object> res = new HashMap<>();
        res.put("deleted", true);
        res.put("msgId", msgId);
        return res;
    }
}
