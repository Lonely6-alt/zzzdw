package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.common.BizException;
import com.fenglin.springboottest.entity.Friend;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.mapper.FriendMapper;
import com.fenglin.springboottest.service.FriendService;
import com.fenglin.springboottest.service.UserService;
import com.fenglin.springboottest.ws.ChatWsHandler;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Service
public class FriendServiceImpl implements FriendService {

    private static final String STATUS_PENDING = "pending";
    private static final String STATUS_ACCEPTED = "accepted";

    private final FriendMapper friendMapper;
    private final UserService userService;
    private final ChatWsHandler ws;

    public FriendServiceImpl(FriendMapper friendMapper, UserService userService, ChatWsHandler ws) {
        this.friendMapper = friendMapper;
        this.userService = userService;
        this.ws = ws;
    }

    @Override
    public List<Map<String, Object>> listFriends(Long meId) {
        List<Friend> rows = friendMapper.selectList(new LambdaQueryWrapper<Friend>()
                .eq(Friend::getStatus, STATUS_ACCEPTED)
                .and(w -> w.eq(Friend::getRequesterId, meId).or().eq(Friend::getReceiverId, meId))
                .orderByDesc(Friend::getHandleTime));
        List<Map<String, Object>> res = new ArrayList<>();
        for (Friend f : rows) {
            Long peerId = Objects.equals(f.getRequesterId(), meId) ? f.getReceiverId() : f.getRequesterId();
            User peer = userService.getById(peerId);
            if (peer == null || !"active".equals(peer.getStatus())) {
                continue;
            }
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", peer.getId());
            m.put("username", peer.getUsername());
            m.put("since", f.getHandleTime() == null ? f.getCreateTime() : f.getHandleTime());
            res.add(m);
        }
        return res;
    }

    @Override
    public List<Map<String, Object>> pendingIncoming(Long meId) {
        List<Friend> rows = friendMapper.selectList(new LambdaQueryWrapper<Friend>()
                .eq(Friend::getReceiverId, meId)
                .eq(Friend::getStatus, STATUS_PENDING)
                .orderByDesc(Friend::getCreateTime));
        return mapRequests(rows, true);
    }

    @Override
    public List<Map<String, Object>> pendingSent(Long meId) {
        List<Friend> rows = friendMapper.selectList(new LambdaQueryWrapper<Friend>()
                .eq(Friend::getRequesterId, meId)
                .eq(Friend::getStatus, STATUS_PENDING)
                .orderByDesc(Friend::getCreateTime));
        return mapRequests(rows, false);
    }

    /** incoming=true 时展示发起人，否则展示接收人 */
    private List<Map<String, Object>> mapRequests(List<Friend> rows, boolean incoming) {
        List<Map<String, Object>> res = new ArrayList<>();
        for (Friend f : rows) {
            Long peerId = incoming ? f.getRequesterId() : f.getReceiverId();
            User peer = userService.getById(peerId);
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("requestId", f.getFriendId());
            m.put("peerId", peerId);
            m.put("peerName", peer == null ? "未知用户" : peer.getUsername());
            m.put("createTime", f.getCreateTime());
            res.add(m);
        }
        return res;
    }

    @Override
    public Long request(Long meId, String username) {
        if (username == null || username.isBlank()) {
            throw new BizException(400, "请输入对方用户名");
        }
        User peer = userService.findByUsername(username.trim());
        if (peer == null) {
            throw new BizException(404, "对方用户不存在");
        }
        if (Objects.equals(peer.getId(), meId)) {
            throw new BizException(400, "不能添加自己为好友");
        }
        if (!"active".equals(peer.getStatus())) {
            throw new BizException(403, "对方账号已被禁用");
        }
        // 双向任一 pending 或 accepted 都视为已占用
        Friend exist = friendMapper.selectOne(new LambdaQueryWrapper<Friend>()
                .and(w -> w.eq(Friend::getRequesterId, meId).eq(Friend::getReceiverId, peer.getId()))
                .or(w -> w.eq(Friend::getRequesterId, peer.getId()).eq(Friend::getReceiverId, meId))
                .last("LIMIT 1"));
        if (exist != null) {
            if (STATUS_ACCEPTED.equals(exist.getStatus())) {
                throw new BizException(409, "你们已经是好友了");
            }
            throw new BizException(409, Objects.equals(exist.getRequesterId(), meId)
                    ? "你已申请过，等待对方处理" : "对方已向你发出申请，请去好友申请列表处理");
        }
        Friend f = new Friend();
        f.setRequesterId(meId);
        f.setReceiverId(peer.getId());
        // 冗余写入双方用户名，数据库里不用查 user 表也能看清好友关系是谁和谁
        User meUser = userService.getById(meId);
        f.setRequesterName(meUser == null ? "" : meUser.getUsername());
        f.setReceiverName(peer.getUsername());
        f.setStatus(STATUS_PENDING);
        f.setCreateTime(LocalDateTime.now());
        friendMapper.insert(f);
        // 实时通知对方
        Map<String, Object> event = new HashMap<>();
        event.put("type", "friend_request");
        event.put("requestId", f.getFriendId());
        event.put("fromId", meId);
        User me = userService.getById(meId);
        event.put("fromName", me == null ? "" : me.getUsername());
        ws.push(List.of(peer.getId()), event);
        return f.getFriendId();
    }

    @Override
    public void accept(Long meId, Long friendId) {
        Friend f = friendMapper.selectById(friendId);
        if (f == null) {
            throw new BizException(404, "申请不存在");
        }
        if (!Objects.equals(f.getReceiverId(), meId)) {
            throw new BizException(403, "只能处理发给你的申请");
        }
        if (!STATUS_PENDING.equals(f.getStatus())) {
            throw new BizException(400, "该申请已处理过");
        }
        f.setStatus(STATUS_ACCEPTED);
        f.setHandleTime(LocalDateTime.now());
        // 同意时刷新冗余用户名，避免改名后数据库里还是旧名字
        User requester = userService.getById(f.getRequesterId());
        User receiver = userService.getById(f.getReceiverId());
        f.setRequesterName(requester == null ? f.getRequesterName() : requester.getUsername());
        f.setReceiverName(receiver == null ? f.getReceiverName() : receiver.getUsername());
        friendMapper.updateById(f);
        // 实时通知申请人
        Map<String, Object> event = new HashMap<>();
        event.put("type", "friend_accepted");
        event.put("friendId", f.getFriendId());
        User me = userService.getById(meId);
        event.put("fromName", me == null ? "" : me.getUsername());
        ws.push(List.of(f.getRequesterId()), event);
    }

    @Override
    public void reject(Long meId, Long friendId) {
        Friend f = requirePendingIncoming(meId, friendId);
        friendMapper.deleteById(f.getFriendId());
        notifyHandled(f, "friend_rejected");
    }

    @Override
    public void removeFriend(Long meId, Long friendId) {
        Friend f = friendMapper.selectById(friendId);
        if (f == null) {
            throw new BizException(404, "好友关系不存在");
        }
        boolean involved = Objects.equals(f.getRequesterId(), meId) || Objects.equals(f.getReceiverId(), meId);
        if (!involved) {
            throw new BizException(403, "只能删除自己的好友");
        }
        if (!STATUS_ACCEPTED.equals(f.getStatus())) {
            throw new BizException(400, "该记录还不是好友关系");
        }
        friendMapper.deleteById(f.getFriendId());
        notifyHandled(f, "friend_removed");
    }

    @Override
    public void removeFriendByPeer(Long meId, Long peerId) {
        Friend f = friendMapper.selectOne(new LambdaQueryWrapper<Friend>()
                .and(w -> w
                        .and(x -> x.eq(Friend::getRequesterId, meId).eq(Friend::getReceiverId, peerId))
                        .or(x -> x.eq(Friend::getRequesterId, peerId).eq(Friend::getReceiverId, meId)))
                .eq(Friend::getStatus, STATUS_ACCEPTED)
                .last("LIMIT 1"));
        if (f == null) {
            throw new BizException(404, "你们还不是好友");
        }
        friendMapper.deleteById(f.getFriendId());
        notifyHandled(f, "friend_removed");
    }

    private Friend requirePendingIncoming(Long meId, Long friendId) {
        Friend f = friendMapper.selectById(friendId);
        if (f == null) {
            throw new BizException(404, "申请不存在");
        }
        if (!Objects.equals(f.getReceiverId(), meId)) {
            throw new BizException(403, "只能处理发给你的申请");
        }
        if (!STATUS_PENDING.equals(f.getStatus())) {
            throw new BizException(400, "该申请已处理过");
        }
        return f;
    }

    private void notifyHandled(Friend f, String type) {
        Map<String, Object> event = new HashMap<>();
        event.put("type", type);
        event.put("requestId", f.getFriendId());
        ws.push(List.of(f.getRequesterId()), event);
    }
}
