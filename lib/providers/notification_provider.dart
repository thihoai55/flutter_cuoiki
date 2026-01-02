import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_storage_service.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _items = [];
  bool _initialized = false;

  // Load notifications from storage
  Future<void> init() async {
    if (_initialized) return;
    final notifications = await NotificationStorageService.loadNotifications();
    _items.addAll(notifications);
    _initialized = true;
    notifyListeners();
  }

  List<AppNotification> forUser(String userId) =>
      _items.where((n) => n.userId == userId).toList();

  AppNotification addNotification({
    required String userId,
    required String message,
    required String type,
    String? postId,
    String? transactionId,
    Map<String, dynamic>? payload,
  }) {
    final n = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      message: message,
      type: type,
      postId: postId,
      transactionId: transactionId,
      time: DateTime.now(),
      payload: payload,
    );
    _items.insert(0, n);
    // Save to storage
    NotificationStorageService.addNotification(n);
    notifyListeners();
    return n;
  }

  void markAsRead(String id) {
    final n = _items.firstWhere((e) => e.id == id, orElse: () => throw Exception('Not found'));
    n.read = true;
    notifyListeners();
  }

  void markAllAsRead(String userId) {
    for (final n in _items.where((e) => e.userId == userId)) {
      n.read = true;
    }
    notifyListeners();
  }
}
