import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/follow_storage_service.dart';
import '../services/notification_storage_service.dart';

class FollowProvider extends ChangeNotifier {
  Map<String, List<String>> _followers = {}; // userId -> list of follower IDs
  Map<String, List<String>> _following = {}; // userId -> list of following IDs

  Future<void> loadFollowData() async {
    final relationships = await FollowStorageService.loadRelationships();
    
    // Build followers and following maps
    _followers.clear();
    _following.clear();
    
    for (var rel in relationships) {
      // Add to followers map
      _followers.putIfAbsent(rel.followedId, () => []).add(rel.followerId);
      // Add to following map
      _following.putIfAbsent(rel.followerId, () => []).add(rel.followedId);
    }
    
    notifyListeners();
  }

  List<String> getFollowers(String userId) => _followers[userId] ?? [];

  List<String> getFollowing(String userId) => _following[userId] ?? [];

  Future<bool> isFollowing(String userId, String targetId) async {
    return await FollowStorageService.isFollowing(userId, targetId);
  }

  Future<void> toggleFollow({
    required String userId,
    required String targetId,
    required String userName,
    String? userAvatar,
  }) async {
    final alreadyFollowing = await isFollowing(userId, targetId);
    
    if (alreadyFollowing) {
      // Unfollow
      await FollowStorageService.unfollow(userId, targetId);
      _followers[targetId]?.remove(userId);
      _following[userId]?.remove(targetId);
    } else {
      // Follow
      await FollowStorageService.follow(userId, targetId);
      _followers.putIfAbsent(targetId, () => []).add(userId);
      _following.putIfAbsent(userId, () => []).add(targetId);
      
      // Send notification
      final notification = AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        userId: targetId,
        type: 'follow',
        time: DateTime.now(),
        title: 'Có người theo dõi bạn',
        message: '$userName đã bắt đầu theo dõi bạn',
        fromUserId: userId,
        fromUserName: userName,
        fromUserAvatar: userAvatar,
        timestamp: DateTime.now(),
        isRead: false,
      );
      await NotificationStorageService.addNotification(notification);
    }
    
    notifyListeners();
  }
}
