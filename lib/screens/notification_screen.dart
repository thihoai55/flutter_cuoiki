import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart';
import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../services/notification_storage_service.dart';
import 'post_detail_screen.dart';
import 'user_profile_screen.dart';
import 'buyer_requests_screen.dart';
import 'bank_transfer_screen.dart';
import 'order_tracking_screen.dart';
import '../widgets/main_layout.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final notifications = await NotificationStorageService.getNotificationsForUser(currentUser.id);
    setState(() {
      _notifications = notifications;
      _loading = false;
    });
  }

  Future<void> _markAsRead(AppNotification notification) async {
    await NotificationStorageService.markAsRead(notification.id);
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    await NotificationStorageService.markAllAsRead(currentUser.id);
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return MainLayoutWithCustomAppBar(
      title: 'Thông báo',
      showDrawer: true,
      actions: [
        if (unreadCount > 0)
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Đánh dấu đã đọc'),
          ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có thông báo nào',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'like':
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'comment':
        icon = Icons.comment;
        iconColor = Colors.blue;
        break;
      case 'follow':
        icon = Icons.person_add;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      color: notification.isRead ? Colors.white : Colors.blue[50],
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: notification.fromUserAvatar != null
                  ? NetworkImage(notification.fromUserAvatar!)
                  : null,
              child: notification.fromUserAvatar == null
                  ? Text(notification.fromUserName?[0].toUpperCase() ?? 'N')
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(icon, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
        title: Text(
          notification.title ?? notification.message,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.timestamp ?? notification.time),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () async {
          await _markAsRead(notification);

          if (notification.type == 'bank_transfer_info') {
            // Handle bank transfer info notification
            // Parse bank info and transaction ID from message
            final message = notification.message;
            final lines = message.split('\n');
            Map<String, String> bankInfo = {};
            String? transactionId;
            
            for (var line in lines) {
              if (line.contains('Ngân hàng:')) {
                bankInfo['bankName'] = line.split(':')[1].trim();
              } else if (line.contains('Số TK:')) {
                bankInfo['accountNumber'] = line.split(':')[1].trim();
              } else if (line.contains('Chủ TK:')) {
                bankInfo['accountHolder'] = line.split(':')[1].trim();
              } else if (line.contains('TransactionID:')) {
                transactionId = line.split(':')[1].trim();
              }
            }

            if (transactionId != null && context.mounted) {
              // Get real transaction from provider
              final postProvider = context.read<PostProvider>();
              final transaction = postProvider.transactions.firstWhere(
                (tx) => tx.id == transactionId,
                orElse: () => _createDummyTransaction(),
              );
              
              // Get post data
              final post = postProvider.posts.firstWhere(
                (p) => p.id == transaction.postId,
                orElse: () => postProvider.posts.first, // fallback
              );
              
              // Navigate to bank transfer screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BankTransferScreen(
                    transaction: transaction,
                    sellerInfo: bankInfo,
                    post: post,
                  ),
                ),
              );
            }
          } else if (notification.type == 'payment_received' || notification.type == 'order_shipping' || notification.type == 'order_completed') {
            // Navigate to order tracking screen
            // Try to find transaction from postId
            if (notification.postId != null && context.mounted) {
              final postProvider = context.read<PostProvider>();
              final auth = context.read<AuthProvider>();
              final currentUser = auth.currentUser;
              
              // Find transaction by postId and current user
              final transaction = postProvider.transactions.firstWhere(
                (tx) => tx.postId == notification.postId && 
                        (tx.sellerId == currentUser?.id || tx.buyerId == currentUser?.id),
                orElse: () => _createDummyTransaction(),
              );
              
              if (transaction.id != 'dummy') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderTrackingScreen(transaction: transaction),
                  ),
                );
              }
            }
          } else if (notification.postId != null) {
            // Navigate to post detail
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(postId: notification.postId!),
              ),
            );
          } else if (notification.type == 'purchase' || notification.type == 'purchase_approved' || notification.type == 'purchase_cancelled') {
            // Navigate to buyer requests screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BuyerRequestsScreen()),
            );
          } else if (notification.fromUserId != null && notification.type == 'follow') {
            // Navigate to user profile
            final auth = context.read<AuthProvider>();
            final user = await auth.getUserById(notification.fromUserId!);
            if (user != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(user: user),
                ),
              );
            }
          }
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  // Create a dummy transaction for bank transfer screen
  PurchaseTransaction _createDummyTransaction() {
    return PurchaseTransaction(
      id: 'dummy',
      postId: '',
      sellerId: '',
      sellerName: 'Người bán',
      buyerId: '',
      buyerName: 'Bạn',
      timestamp: DateTime.now(),
      status: 'awaiting_payment',
      buyerInfo: BuyerInfo(
        name: 'Bạn',
        phone: '',
        address: '',
        paymentMethod: 'bank_transfer',
      ),
    );
  }
}

