import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/post_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import 'create_post_screen.dart';
import 'login_screen.dart';
import 'post_detail_screen.dart';
import 'recharge_screen.dart';
import 'transaction_history_screen.dart';
import 'user_profile_screen.dart';
import 'saved_posts_screen.dart';
import 'chat_list_screen.dart';
import 'notification_screen.dart';
import 'rating_sellers_screen.dart';
import 'buyer_requests_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class PublicHomeScreen extends StatefulWidget {
  const PublicHomeScreen({super.key});

  @override
  State<PublicHomeScreen> createState() => _PublicHomeScreenState();
}

class _PublicHomeScreenState extends State<PublicHomeScreen> {
  final _searchCtrl = TextEditingController();
  String? _category;
  String _type = 'sell';

  final _categories = const [
    'Tất cả',
    'Sách & Tài liệu',
    'Đồ điện tử',
    'Đồ dùng học tập',
    'Xe đạp',
    'Quần áo',
    'Gia dụng',
    'Nội thất',
    'Thể thao',
    'Nhạc cụ',
    'Phụ kiện',
    'Khác',
  ];

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<PostProvider>().posts;
    final filtered = posts.where((p) {
      if (p.status != 'approved') return false;
      if (p.sold == true) return false; // Hide sold posts
      if (p.type != _type) return false;
      if (_category != null && _category != 'Tất cả' && p.category != _category) return false;
      final q = _searchCtrl.text.toLowerCase();
      return p.title.toLowerCase().contains(q) || p.content.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: const AppHeader(),
      drawer: AppDrawer(
        onNavigate: _handleNavigation,
      ),
      body: Column(
        children: [
          _buildTypeTabs(),
          _buildSearchBar(),
          _buildCategoryChips(),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Không tìm thấy bài viết nào'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      return _PostCard(post: p);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo bài đăng'),
      ),
    );
  }

  void _handleNavigation(String route, {dynamic param}) {
    switch (route) {
      case 'home':
        break;
      case 'create-post':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        );
        break;
      case 'login':
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        break;
      case 'profile':
        final auth = context.read<AuthProvider>();
        final userId = param ?? auth.currentUser?.id;
        if (userId != null) {
          auth.getUserById(userId).then((user) {
            if (user != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(user: user),
                ),
              );
            }
          });
        }
        break;
      case 'wallet':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RechargeScreen()),
        );
        break;
      case 'ratings':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RatingSellersScreen()),
        );
        break;
      case 'buyer-requests':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BuyerRequestsScreen()),
        );
        break;
      case 'saved':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
        );
        break;
      case 'chat':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatListScreen()),
        );
        break;
      case 'notifications':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationScreen()),
        );
        break;
      case 'transactions':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
        );
        break;
      case 'edit-profile':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
        );
        break;
      case 'settings':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Tìm bài đăng...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              label: 'Cần mua',
              icon: Icons.shopping_cart_outlined,
              selected: _type == 'buy',
              onTap: () => setState(() => _type = 'buy'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TypeButton(
              label: 'Cần bán',
              icon: Icons.sell_outlined,
              selected: _type == 'sell',
              onTap: () => setState(() => _type = 'sell'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = _category == cat || (_category == null && cat == 'Tất cả');
          return ChoiceChip(
            label: Text(cat),
            selected: selected,
            onSelected: (_) => setState(() => _category = cat == 'Tất cả' ? null : cat),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _categories.length,
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: selected ? Colors.white : const Color(0xFF2563EB)),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF2563EB) : Colors.white,
        foregroundColor: selected ? Colors.white : const Color(0xFF111827),
        side: BorderSide(color: selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});
  final PostItem post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  post.images.isNotEmpty ? post.images.first : (post.image ?? ''),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        post.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.price,
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.favorite_border, size: 14, color: Color(0xFFDB2777)),
                        const SizedBox(width: 4),
                        Text('${post.likes}', style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 8),
                        const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text('${post.views}', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
