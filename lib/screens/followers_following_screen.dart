import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/follow_provider.dart';
import '../services/user_api.dart';
import 'chat_screen.dart';
import 'user_profile_screen.dart';
import '../widgets/main_layout.dart';

class FollowersFollowingScreen extends StatefulWidget {
  const FollowersFollowingScreen({
    super.key,
    required this.userId,
    this.initialTab = 0,
  });

  final String userId;
  final int initialTab; // 0 = Followers, 1 = Following

  @override
  State<FollowersFollowingScreen> createState() => _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppUser> _followers = [];
  List<AppUser> _following = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    final followProvider = context.read<FollowProvider>();
    final followerIds = followProvider.getFollowers(widget.userId);
    final followingIds = followProvider.getFollowing(widget.userId);
    
    final allUsers = await UserApi.getAllUsers();
    
    setState(() {
      _followers = allUsers.where((u) => followerIds.contains(u.id)).toList();
      _following = allUsers.where((u) => followingIds.contains(u.id)).toList();
      _loading = false;
    });
  }

  Future<void> _toggleFollow(AppUser targetUser) async {
    final auth = context.read<AuthProvider>();
    final followProvider = context.read<FollowProvider>();
    final currentUser = auth.currentUser;
    
    if (currentUser == null) return;

    final isFollowing = await followProvider.isFollowing(currentUser.id, targetUser.id);

    await followProvider.toggleFollow(
      userId: currentUser.id,
      targetId: targetUser.id,
      userName: currentUser.name,
      userAvatar: currentUser.avatar,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFollowing
              ? 'Đã hủy theo dõi ${targetUser.name}'
              : 'Đã theo dõi ${targetUser.name}'),
        ),
      );
      
      // Reload data để cập nhật UI
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayoutWithCustomAppBar(
      title: 'Người theo dõi',
      showDrawer: true,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Material(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF2563EB),
                    labelColor: const Color(0xFF2563EB),
                    unselectedLabelColor: Colors.black54,
                    tabs: [
                      Tab(text: 'Người theo dõi (${_followers.length})'),
                      Tab(text: 'Đang theo dõi (${_following.length})'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFollowersList(),
                      _buildFollowingList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFollowersList() {
    final auth = context.watch<AuthProvider>();
    final followProvider = context.watch<FollowProvider>();
    final currentUser = auth.currentUser;

    if (_followers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có người theo dõi',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _followers.length,
      itemBuilder: (context, index) {
        final user = _followers[index];
        final isCurrentUser = currentUser?.id == user.id;
        
        // Kiểm tra xem currentUser có đang follow user này không
        final isFollowingBack = currentUser != null
            ? followProvider.getFollowing(currentUser.id).contains(user.id)
            : false;

        return _buildUserCard(
          user: user,
          isCurrentUser: isCurrentUser,
          showFollowButton: !isCurrentUser,
          isFollowing: isFollowingBack,
        );
      },
    );
  }

  Widget _buildFollowingList() {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;

    if (_following.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa theo dõi ai',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _following.length,
      itemBuilder: (context, index) {
        final user = _following[index];
        final isCurrentUser = currentUser?.id == user.id;

        return _buildUserCard(
          user: user,
          isCurrentUser: isCurrentUser,
          showFollowButton: false, // Tab "Đang theo dõi" chỉ hiển thị nút nhắn tin
          isFollowing: true,
        );
      },
    );
  }

  Widget _buildUserCard({
    required AppUser user,
    required bool isCurrentUser,
    required bool showFollowButton,
    required bool isFollowing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(user: user),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundImage: user.avatar != null
                    ? NetworkImage(user.avatar!)
                    : null,
                child: user.avatar == null
                    ? Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.bio ?? user.email,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.rating > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${user.rating.toStringAsFixed(1)} (${user.ratingCount})',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action buttons
              if (!isCurrentUser) ...[
                const SizedBox(width: 8),
                if (showFollowButton)
                  // Nút "Theo dõi lại" (chỉ hiển thị ở tab Người theo dõi)
                  ElevatedButton(
                    onPressed: () => _toggleFollow(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing
                          ? Colors.grey[300]
                          : const Color(0xFF2563EB),
                      foregroundColor: isFollowing ? Colors.black87 : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(90, 36),
                    ),
                    child: Text(
                      isFollowing ? 'Đang theo dõi' : 'Theo dõi lại',
                      style: const TextStyle(fontSize: 13),
                    ),
                  )
                else
                  // Nút "Nhắn tin" (hiển thị ở tab Đang theo dõi hoặc khi đã follow back)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUserId: user.id,
                            otherUserName: user.name,
                            otherUserAvatar: user.avatar,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Nhắn tin', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(90, 36),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
