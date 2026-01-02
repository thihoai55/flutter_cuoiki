class AppNotification {
  AppNotification({
    required this.id,
    required this.userId,
    required this.message,
    required this.type,
    required this.time,
    this.title,
    this.postId,
    this.transactionId,
    this.fromUserId,
    this.fromUserName,
    this.fromUserAvatar,
    this.timestamp,
    this.isRead = false,
    this.read = false,
    this.payload,
  });

  final String id;
  final String userId;
  final String message;
  final String type;
  final DateTime time;
  final String? title;
  final String? postId;
  final String? transactionId;
  final String? fromUserId;
  final String? fromUserName;
  final String? fromUserAvatar;
  final DateTime? timestamp;
  final bool isRead;
  final Map<String, dynamic>? payload;
  bool read;
}
