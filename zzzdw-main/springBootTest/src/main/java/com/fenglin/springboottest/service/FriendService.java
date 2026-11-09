package com.fenglin.springboottest.service;

import java.util.List;
import java.util.Map;

public interface FriendService {

    /** 我的好友列表（accepted，双向） */
    List<Map<String, Object>> listFriends(Long meId);

    /** 我收到的待处理申请 */
    List<Map<String, Object>> pendingIncoming(Long meId);

    /** 我发出的、还没被处理的申请 */
    List<Map<String, Object>> pendingSent(Long meId);

    /** 按用户名发好友申请，返回申请记录 ID */
    Long request(Long meId, String username);

    /** 同意收到的申请 */
    void accept(Long meId, Long friendId);

    /** 拒绝收到的申请（删除记录，对方之后可重新申请） */
    void reject(Long meId, Long friendId);

    /** 删除好友（双向好友关系直接解除） */
    void removeFriend(Long meId, Long friendId);

    /** 按对方用户 ID 删除好友 */
    void removeFriendByPeer(Long meId, Long peerId);
}
