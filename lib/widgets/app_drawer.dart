import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/post_provider.dart';
import '../providers/wallet_provider.dart';
import 'avatar_image.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.onNavigate,
  });

  final Function(String route, {dynamic param}) onNavigate;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final notifProvider = context.watch<NotificationProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final postProvider = context.watch<PostProvider>();
    final walletProvider = context.watch<WalletProvider>();

    if (user == null) return const SizedBox.shrink();

    final unreadNotifications = notifProvider.forUser(user.id).where((n) => !n.read).length;
    final unreadChats = chatProvider.getUnreadCount(user.id);
    final savedPosts = postProvider.savedPostsForUser(user.id);
    final favoriteCount = savedPosts.length;
    final balance = walletProvider.balanceForUser(user.id);
    final pendingRequests = postProvider.getPendingTransactionsCount(user.id);

    return Drawer(
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header với avatar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AvatarImage(
                      url: user.avatar,
                      size: 64,
                      initials: user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Trang chủ
              _buildDrawerItem(
                context,
                icon: Icons.home,
                iconColor: const Color(0xFF2563EB),
                label: 'Trang chủ',
                onTap: () {
                  // Đóng drawer rồi quay về trang gốc
                  Navigator.pop(context);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),

              // Wallet balance display
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showBalanceDetail(context, balance, onNavigate);
                },
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Số dư ví của bạn',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${balance.toStringAsFixed(0)}đ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Menu items
              _buildDrawerItem(
                context,
                icon: Icons.person,
                iconColor: const Color(0xFF2563EB),
                label: 'Xem trang cá nhân',
                onTap: () {
                  Navigator.pop(context);
                  onNavigate('profile', param: user.id);
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildDrawerItem(
                context,
                icon: Icons.account_balance_wallet,
                iconColor: const Color(0xFF10B981),
                label: 'Nạp tiền',
                onTap: () {
                  Navigator.pop(context);
                  onNavigate('wallet');
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.star_rate,
                iconColor: const Color(0xFFFBBF24),
                label: 'Đánh giá người mua/bán',
                onTap: () {
                  Navigator.pop(context);
                  onNavigate('ratings');
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.history,
                iconColor: const Color(0xFF8B5CF6),
                label: 'Lịch sử giao dịch',
                onTap: () {
                  Navigator.pop(context);
                  onNavigate('transactions');
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.shopping_bag,
                iconColor: const Color(0xFFF59E0B),
                label: 'Thông tin người mua',
                badge: pendingRequests > 0 ? pendingRequests.toString() : null,
                onTap: () {
                  Navigator.pop(context);
                  onNavigate('buyer-requests');
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.receipt_long,
                iconColor: const Color(0xFF8B5CF6),
                label: 'Đơn hàng của tôi',
                badge: _getPendingOrdersCount(postProvider, user.id) > 0
                    ? _getPendingOrdersCount(postProvider, user.id).toString()
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onNavigate('my-orders');
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildDrawerItem(
                context,
                icon: Icons.favorite,
                iconColor: const Color(0xFFEC4899),
                label: 'Yêu thích',
                badge: favoriteCount > 0 ? favoriteCount.toString() : null,
                onTap: () {
                  Navigator.pop(context);
                  onNavigate('saved');
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.chat,
                iconColor: const Color(0xFF06B6D4),
                label: 'Tin nhắn',
                badge: unreadChats > 0 ? unreadChats.toString() : null,
                onTap: () {
                  Navigator.pop(context);
                  onNavigate('chat');
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.notifications,
                iconColor: const Color(0xFFEF4444),
                label: 'Thông báo',
                badge: unreadNotifications > 0 ? unreadNotifications.toString() : null,
                onTap: () {
                  Navigator.pop(context);
                  onNavigate('notifications');
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildDrawerItem(
                context,
                icon: Icons.edit,
                label: 'Chỉnh sửa thông tin cá nhân',
                onTap: () {
                  Navigator.pop(context);
                  onNavigate('edit-profile');
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.settings,
                label: 'Cài đặt',
                onTap: () {
                  Navigator.pop(context);
                  onNavigate('settings');
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.logout,
                label: 'Đăng xuất',
                textColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  auth.logout();
                  onNavigate('login');
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Sàn Trao Đổi SV v1.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getPendingOrdersCount(PostProvider postProvider, String userId) {
    return postProvider.transactions
        .where((tx) =>
            tx.buyerId == userId &&
            (tx.status == 'pending' ||
                tx.status == 'approved' ||
                tx.status == 'awaiting_payment' ||
                tx.status == 'payment_confirmed' ||
                tx.status == 'shipping'))
        .length;
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? badge,
    Color? iconColor,
    Color textColor = Colors.black87,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFFEFF6FF),
        splashColor: const Color(0xFF2563EB).withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? textColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showBalanceDetail(
    BuildContext context,
    double balance,
    Function(String, {dynamic param}) onNavigate,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Ví điện tử'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Số dư hiện tại',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${balance.toStringAsFixed(0)}đ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onNavigate('wallet');
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Nạp tiền'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onNavigate('transactions');
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Lịch sử'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
