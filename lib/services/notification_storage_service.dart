import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';

class NotificationStorageService {
  static late SharedPreferences _prefs;
  static const String _notificationsKey = 'user_notifications_key';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save all notifications
  static Future<void> saveNotifications(List<AppNotification> notifications) async {
    final jsonList = notifications.map((n) => _notificationToJson(n)).toList();
    await _prefs.setString(_notificationsKey, jsonEncode(jsonList));
  }

  /// Load all notifications
  static Future<List<AppNotification>> loadNotifications() async {
    final jsonStr = _prefs.getString(_notificationsKey);
    if (jsonStr == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonStr);
    return jsonList.map((json) => _notificationFromJson(json)).toList();
  }

  /// Add a new notification
  static Future<void> addNotification(AppNotification notification) async {
    final notifications = await loadNotifications();
    notifications.insert(0, notification); // Newest first
    await saveNotifications(notifications);
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    final notifications = await loadNotifications();
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      notifications[index] = AppNotification(
        id: notifications[index].id,
        userId: notifications[index].userId,
        type: notifications[index].type,
        time: notifications[index].time,
        title: notifications[index].title,
        message: notifications[index].message,
        postId: notifications[index].postId,
        fromUserId: notifications[index].fromUserId,
        fromUserName: notifications[index].fromUserName,
        fromUserAvatar: notifications[index].fromUserAvatar,
        timestamp: notifications[index].timestamp,
        isRead: true,
      );
      await saveNotifications(notifications);
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead(String userId) async {
    final notifications = await loadNotifications();
    final updated = notifications.map((n) {
      if (n.userId == userId && !n.isRead) {
        return AppNotification(
          id: n.id,
          userId: n.userId,
          type: n.type,
          time: n.time,
          title: n.title,
          message: n.message,
          postId: n.postId,
          fromUserId: n.fromUserId,
          fromUserName: n.fromUserName,
          fromUserAvatar: n.fromUserAvatar,
          timestamp: n.timestamp,
          isRead: true,
        );
      }
      return n;
    }).toList();
    await saveNotifications(updated);
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    final notifications = await loadNotifications();
    notifications.removeWhere((n) => n.id == notificationId);
    await saveNotifications(notifications);
  }

  /// Get notifications for specific user
  static Future<List<AppNotification>> getNotificationsForUser(String userId) async {
    final all = await loadNotifications();
    return all.where((n) => n.userId == userId).toList();
  }

  /// Convert notification to JSON
  static Map<String, dynamic> _notificationToJson(AppNotification notification) {
    return {
      'id': notification.id,
      'userId': notification.userId,
      'type': notification.type,
      'title': notification.title,
      'message': notification.message,
      'postId': notification.postId,
      'fromUserId': notification.fromUserId,
      'fromUserName': notification.fromUserName,
      'fromUserAvatar': notification.fromUserAvatar,
      'timestamp': notification.timestamp?.toIso8601String() ?? notification.time.toIso8601String(),
      'isRead': notification.isRead,
    };
  }

  /// Convert JSON to notification
  static AppNotification _notificationFromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? 'other',
      time: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      postId: json['postId'],
      fromUserId: json['fromUserId'],
      fromUserName: json['fromUserName'],
      fromUserAvatar: json['fromUserAvatar'],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      isRead: json['isRead'] ?? false,
    );
  }
}
