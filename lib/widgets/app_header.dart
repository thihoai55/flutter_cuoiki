import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/saved_posts_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/notification_screen.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final chatProvider = context.watch<ChatProvider>();
    final unreadChat = user == null ? 0 : chatProvider.getUnreadCount(user.id);
    final unreadNotif = user == null ? 0 : context.watch<NotificationProvider>().forUser(user.id).where((n) => !n.read).length;

    return SafeArea(
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: surfaceColor,
          elevation: 0,
          title: Flexible(
            child: GestureDetector(
              onTap: () {
                // Navigate back to home
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Row(
                children: [
                  Icon(Icons.store, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Sàn Trao Đổi SV',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: theme.colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
          // Saved posts
          Builder(
            builder: (context) {
              final postProvider = context.watch<PostProvider>();
              final savedCount = user != null ? postProvider.savedPostsForUser(user.id).length : 0;
              return _buildIconButton(
                icon: Icons.bookmark,
                color: const Color(0xFFEAB308),
                badgeCount: savedCount > 0 ? savedCount : null,
                onTap: () {
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng đăng nhập')),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
                    );
                  }
                },
              );
            },
          ),

          // Chat
          _buildIconButton(
            icon: Icons.chat_bubble,
            color: const Color(0xFF10B981), // Green
            badgeCount: unreadChat > 0 ? unreadChat : null,
            onTap: () {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng đăng nhập')),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen()),
                );
              }
            },
          ),

          // Notifications
          _buildIconButton(
            icon: Icons.notifications,
            color: const Color(0xFFEF4444), // Red
            badgeCount: unreadNotif > 0 ? unreadNotif : null,
            onTap: () {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng đăng nhập')),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              }
            },
          ),
          const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = const Color(0xFF2563EB),
    int? badgeCount,
  }) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, size: 26),
          color: color,
          onPressed: onTap,
        ),
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
