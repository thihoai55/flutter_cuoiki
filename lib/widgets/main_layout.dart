import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/saved_posts_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/recharge_screen.dart';
import '../screens/transaction_history_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/rating_sellers_screen.dart';
import '../screens/buyer_requests_screen.dart';
import '../screens/my_orders_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/login_screen.dart';

/// Wrapper widget để giữ nguyên header ở tất cả các màn hình
class MainLayout extends StatelessWidget {
  const MainLayout({
    super.key,
    required this.child,
    this.showDrawer = true,
    this.floatingActionButton,
  });

  final Widget child;
  final bool showDrawer;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      drawer: showDrawer
          ? AppDrawer(
              onNavigate: (route, {param}) {
                // Unified navigation mapping for Drawer
                switch (route) {
                  case 'home':
                    Navigator.pop(context);
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    break;
                  case 'saved':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
                    );
                    break;
                  case 'chat':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatListScreen()),
                    );
                    break;
                  case 'notifications':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationScreen()),
                    );
                    break;
                  case 'wallet':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RechargeScreen()),
                    );
                    break;
                  case 'transactions':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                    );
                    break;
                  case 'ratings':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RatingSellersScreen()),
                    );
                    break;
                  case 'buyer-requests':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BuyerRequestsScreen()),
                    );
                    break;
                  case 'my-orders':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                    );
                    break;
                  case 'edit-profile':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                    break;
                  case 'settings':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                    break;
                  case 'login':
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                    break;
                  case 'profile':
                    Navigator.pop(context);
                    final auth = context.read<AuthProvider>();
                    final userId = param ?? auth.currentUser?.id;
                    if (userId != null) {
                      auth.getUserById(userId).then((user) {
                        if (user != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
                          );
                        }
                      });
                    }
                    break;
                  default:
                    // No-op for routes not yet implemented
                    break;
                }
              },
            )
          : null,
      body: child,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Wrapper cho các màn hình có AppBar riêng nhưng vẫn muốn giữ header
class MainLayoutWithCustomAppBar extends StatelessWidget {
  const MainLayoutWithCustomAppBar({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.showDrawer = false,
    this.floatingActionButton,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool showDrawer;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      drawer: showDrawer
          ? AppDrawer(
              onNavigate: (route, {param}) {
                // Same mapping as above for consistency
                switch (route) {
                  case 'home':
                    Navigator.pop(context);
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    break;
                  case 'saved':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
                    );
                    break;
                  case 'chat':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatListScreen()),
                    );
                    break;
                  case 'notifications':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationScreen()),
                    );
                    break;
                  case 'wallet':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RechargeScreen()),
                    );
                    break;
                  case 'transactions':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                    );
                    break;
                  case 'ratings':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RatingSellersScreen()),
                    );
                    break;
                  case 'buyer-requests':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BuyerRequestsScreen()),
                    );
                    break;
                  case 'my-orders':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                    );
                    break;
                  case 'edit-profile':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                    break;
                  case 'settings':
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                    break;
                  case 'login':
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                    break;
                  case 'profile':
                    Navigator.pop(context);
                    final auth = context.read<AuthProvider>();
                    final userId = param ?? auth.currentUser?.id;
                    if (userId != null) {
                      auth.getUserById(userId).then((user) {
                        if (user != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
                          );
                        }
                      });
                    }
                    break;
                  default:
                    break;
                }
              },
            )
          : null,
      body: Column(
        children: [
          // Sub-header nếu cần
          if (title != null)
            Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final surface = theme.colorScheme.surface;
                final onSurface = theme.colorScheme.onSurface;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: surface,
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: onSurface),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      if (Navigator.of(context).canPop())
                        const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title!,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                      ),
                      if (actions != null) ...actions!,
                    ],
                  ),
                );
              },
            ),
          Expanded(child: child),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
